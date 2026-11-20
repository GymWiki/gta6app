import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content.dart';
import 'content_parser.dart';

/// Where content.json is hosted. Replace <USER>/<REPO> with your GitHub repo.
/// While the placeholder is in place the app never touches the network.
const String contentUrl = 'https://raw.githubusercontent.com/<USER>/<REPO>/main/content.json';

/// Asset bundled in the app; last link in the fallback chain.
const String bundledContentAsset = 'content.json';

const Duration fetchTimeout = Duration(seconds: 8);

/// Automatic checks (launch / app resume) happen at most this often.
/// raw.githubusercontent.com itself caches for ~5 minutes, so don't go lower.
const Duration autoCheckInterval = Duration(hours: 3);

enum SyncStatus { updated, notModified, failed, schemaTooNew, skippedThrottle, notConfigured, busy }

class SyncOutcome {
  final SyncStatus status;
  final ContentData? data;
  const SyncOutcome(this.status, [this.data]);
}

class UserState {
  final Set<String> unlockedIds;
  final Set<String> favoriteIds;
  final String platform;
  final bool bannerDismissed;
  final Map<String, String> seen;
  final bool seenInitialized;
  final String? dismissedAnnouncementId;
  final bool withCodeOnly;
  final bool platformChosen;
  final List<String> recentIds;
  const UserState({
    required this.unlockedIds,
    required this.favoriteIds,
    required this.platform,
    required this.bannerDismissed,
    required this.seen,
    required this.seenInitialized,
    required this.dismissedAnnouncementId,
    required this.withCodeOnly,
    required this.platformChosen,
    required this.recentIds,
  });
}

class CheatRepository {
  static const _kCache = 'content_cache';
  static const _kEtag = 'content_etag';
  static const _kLastCheck = 'content_last_check_ms';
  static const _kSchemaNew = 'content_schema_too_new';
  static const _kLegacyCache = 'cheats_cache';
  static const _kUnlocked = 'unlockedIds';
  static const _kFavs = 'favoriteIds';
  static const _kPlatform = 'selectedPlatform';
  static const _kBanner = 'bannerDismissed';
  static const _kSeen = 'seenCheats';
  static const _kAnnouncement = 'dismissedAnnouncementId';
  static const _kWithCode = 'withCodeOnly';
  static const _kPlatformChosen = 'platformChosen';
  static const _kRecent = 'recentIds';

  final SharedPreferences prefs;
  final http.Client _client;
  final String url;
  final String lang;
  final DateTime Function() _now;
  final Future<String> Function() _loadBundled;

  CheatRepository(
    this.prefs, {
    http.Client? client,
    this.url = contentUrl,
    this.lang = 'en',
    DateTime Function()? now,
    Future<String> Function()? loadBundled,
  })  : _client = client ?? http.Client(),
        _now = now ?? DateTime.now,
        _loadBundled = loadBundled ?? (() => rootBundle.loadString(bundledContentAsset));

  bool get isConfigured => !url.contains('<');
  bool get schemaTooNew => prefs.getBool(_kSchemaNew) ?? false;

  DateTime? get lastCheckedAt {
    final ms = prefs.getInt(_kLastCheck);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get isCheckDue {
    final last = prefs.getInt(_kLastCheck);
    return last == null || _now().millisecondsSinceEpoch - last >= autoCheckInterval.inMilliseconds;
  }

  /// Fallback chain for offline start: valid cache -> bundled asset -> empty.
  /// If the app ships newer bundled content than the cache, the bundled one wins.
  Future<ContentData> loadLocal() async {
    await prefs.remove(_kLegacyCache);

    ContentData? bundled;
    try {
      bundled = ContentParser.parse(await _loadBundled(), lang: lang);
    } catch (e) {
      debugPrint('[content] bundled content unusable: $e');
    }

    ContentData? cached;
    final raw = prefs.getString(_kCache);
    if (raw != null) {
      try {
        cached = ContentParser.parse(raw, lang: lang);
      } catch (e) {
        debugPrint('[content] dropping bad cache: $e');
        await prefs.remove(_kCache);
        await prefs.remove(_kEtag);
      }
    }

    if (cached != null && (bundled == null || cached.contentVersion >= bundled.contentVersion)) return cached;
    return bundled ?? const ContentData.empty();
  }

  /// One conditional GET. Never throws, never retries. Throttled unless [force].
  Future<SyncOutcome> refresh(int currentVersion, {bool force = false}) async {
    if (!isConfigured) return const SyncOutcome(SyncStatus.notConfigured);
    if (!force && !isCheckDue) return const SyncOutcome(SyncStatus.skippedThrottle);
    await prefs.setInt(_kLastCheck, _now().millisecondsSinceEpoch);

    try {
      final headers = {'Accept': 'application/json'};
      final etag = prefs.getString(_kEtag);
      if (etag != null && prefs.containsKey(_kCache)) headers['If-None-Match'] = etag;

      final res = await _client.get(Uri.parse(url), headers: headers).timeout(fetchTimeout);
      if (res.statusCode == 304) return const SyncOutcome(SyncStatus.notModified);
      if (res.statusCode != 200) return const SyncOutcome(SyncStatus.failed);

      final ContentData remote;
      try {
        remote = ContentParser.parse(utf8.decode(res.bodyBytes), lang: lang);
      } on UnsupportedSchemaException {
        await prefs.setBool(_kSchemaNew, true);
        return const SyncOutcome(SyncStatus.schemaTooNew);
      } on ContentException catch (e) {
        debugPrint('[content] ignoring invalid remote content: $e');
        return const SyncOutcome(SyncStatus.failed);
      }

      await prefs.remove(_kSchemaNew);
      final newEtag = res.headers['etag'];
      if (remote.contentVersion > currentVersion) {
        await prefs.setString(_kCache, remote.rawJson);
        if (newEtag != null) await prefs.setString(_kEtag, newEtag);
        return SyncOutcome(SyncStatus.updated, remote);
      }
      if (newEtag != null && prefs.containsKey(_kCache)) await prefs.setString(_kEtag, newEtag);
      return const SyncOutcome(SyncStatus.notModified);
    } catch (e) {
      debugPrint('[content] refresh failed: $e');
      return const SyncOutcome(SyncStatus.failed);
    }
  }

  UserState loadUserState() {
    var seen = <String, String>{};
    try {
      final raw = prefs.getString(_kSeen);
      if (raw != null) seen = (jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', '$v'));
    } catch (_) {}
    return UserState(
      unlockedIds: (prefs.getStringList(_kUnlocked) ?? []).toSet(),
      favoriteIds: (prefs.getStringList(_kFavs) ?? []).toSet(),
      platform: prefs.getString(_kPlatform) ?? 'ps5',
      bannerDismissed: prefs.getBool(_kBanner) ?? false,
      seen: seen,
      seenInitialized: prefs.containsKey(_kSeen),
      dismissedAnnouncementId: prefs.getString(_kAnnouncement),
      withCodeOnly: prefs.getBool(_kWithCode) ?? true,
      platformChosen: prefs.getBool(_kPlatformChosen) ?? false,
      recentIds: prefs.getStringList(_kRecent) ?? const [],
    );
  }

  Future<void> saveUnlocked(Set<String> s) => prefs.setStringList(_kUnlocked, s.toList());
  Future<void> saveFavorites(Set<String> s) => prefs.setStringList(_kFavs, s.toList());
  Future<void> savePlatform(String p) => prefs.setString(_kPlatform, p);
  Future<void> saveBannerDismissed(bool v) => prefs.setBool(_kBanner, v);
  Future<void> saveSeen(Map<String, String> m) => prefs.setString(_kSeen, jsonEncode(m));
  Future<void> saveDismissedAnnouncement(String id) => prefs.setString(_kAnnouncement, id);
  Future<void> saveWithCodeOnly(bool v) => prefs.setBool(_kWithCode, v);
  Future<void> savePlatformChosen() => prefs.setBool(_kPlatformChosen, true);
  Future<void> saveRecent(List<String> ids) => prefs.setStringList(_kRecent, ids);
  Future<void> resetProgress() async {
    await prefs.remove(_kUnlocked);
    await prefs.remove(_kFavs);
    await prefs.remove(_kRecent);
  }
}
