import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cheat.dart';

/// Point this at your hosted cheats.json (GitHub Raw, Vercel, ...).
const String REMOTE_JSON_URL =
    'https://raw.githubusercontent.com/gymwiki/gta6app/main/assets/cheats.json';

enum SyncResult { updated, upToDate, failed }

class UserState {
  final Set<String> unlockedIds;
  final Set<String> favoriteIds;
  final String platform;
  final bool bannerDismissed;
  const UserState(this.unlockedIds, this.favoriteIds, this.platform, this.bannerDismissed);
}

class CheatRepository {
  static const _kCache = 'cheats_cache';
  static const _kUnlocked = 'unlockedIds';
  static const _kFavs = 'favoriteIds';
  static const _kPlatform = 'selectedPlatform';
  static const _kBanner = 'bannerDismissed';

  final SharedPreferences prefs;
  final http.Client _client;
  CheatRepository(this.prefs, {http.Client? client}) : _client = client ?? http.Client();

  static CheatData parse(String raw) {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final list = (m['cheats'] as List).map((e) => Cheat.fromJson(e as Map<String, dynamic>)).toList();
    return CheatData(
      dataVersion: m['data_version'] as int,
      lastUpdated: (m['last_updated'] as String?) ?? '',
      cheats: list,
      rawJson: raw,
    );
  }

  /// Newest of bundled vs cached. Never throws for a bad cache.
  Future<CheatData> loadLocal() async {
    final bundled = parse(await rootBundle.loadString('assets/cheats.json'));
    final cached = prefs.getString(_kCache);
    if (cached != null) {
      try {
        final c = parse(cached);
        if (c.dataVersion > bundled.dataVersion) return c;
      } catch (_) {
        await prefs.remove(_kCache);
      }
    }
    return bundled;
  }

  /// Returns the new data via [onUpdate] only if the remote is newer.
  Future<SyncResult> sync(int currentVersion, void Function(CheatData) onUpdate) async {
    try {
      final res = await _client.get(Uri.parse(REMOTE_JSON_URL)).timeout(const Duration(seconds: 4));
      if (res.statusCode != 200) return SyncResult.failed;
      final remote = parse(utf8.decode(res.bodyBytes));
      if (remote.dataVersion <= currentVersion || remote.cheats.isEmpty) return SyncResult.upToDate;
      await prefs.setString(_kCache, remote.rawJson);
      onUpdate(remote);
      return SyncResult.updated;
    } catch (_) {
      return SyncResult.failed; // silent fallback
    }
  }

  UserState loadUserState() => UserState(
        (prefs.getStringList(_kUnlocked) ?? []).toSet(),
        (prefs.getStringList(_kFavs) ?? []).toSet(),
        prefs.getString(_kPlatform) ?? 'ps5',
        prefs.getBool(_kBanner) ?? false,
      );

  Future<void> saveUnlocked(Set<String> s) => prefs.setStringList(_kUnlocked, s.toList());
  Future<void> saveFavorites(Set<String> s) => prefs.setStringList(_kFavs, s.toList());
  Future<void> savePlatform(String p) => prefs.setString(_kPlatform, p);
  Future<void> saveBannerDismissed(bool v) => prefs.setBool(_kBanner, v);
  Future<void> resetProgress() async {
    await prefs.remove(_kUnlocked);
    await prefs.remove(_kFavs);
  }
}
