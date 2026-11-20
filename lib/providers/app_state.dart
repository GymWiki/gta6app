import 'package:flutter/foundation.dart';

import '../models/content.dart';
import '../services/cheat_repository.dart';

enum TrackerFilter { all, todo, unlocked }

enum CheatBadge { fresh, updated }

const String kAllCategories = 'all';

/// Cheats added/updated within this window can show a Nieuw/Bijgewerkt badge.
const Duration badgeWindow = Duration(days: 14);

class AppState extends ChangeNotifier {
  final CheatRepository repo;
  final DateTime Function() _now;

  AppState(this.repo, ContentData data, {DateTime Function()? now})
      : _data = data,
        _now = now ?? DateTime.now {
    final u = repo.loadUserState();
    unlockedIds = u.unlockedIds;
    favoriteIds = u.favoriteIds;
    platform = u.platform;
    bannerDismissed = u.bannerDismissed;
    dismissedAnnouncementId = u.dismissedAnnouncementId;
    seen = {...u.seen};
    // First run: everything already in the content counts as seen, so only
    // later additions/updates get a badge.
    if (!u.seenInitialized && data.cheats.isNotEmpty) {
      seen = {for (final c in data.cheats) c.id: _stamp(c)};
      repo.saveSeen(seen);
    }
  }

  ContentData _data;
  late Set<String> unlockedIds;
  late Set<String> favoriteIds;
  late String platform;
  late bool bannerDismissed;
  late Map<String, String> seen;
  String? dismissedAnnouncementId;
  bool schemaNoticeDismissed = false;

  String query = '';
  String category = kAllCategories;
  TrackerFilter trackerFilter = TrackerFilter.all;
  String? focusedId;
  bool syncing = false;

  ContentData get data => _data;
  List<Cheat> get cheats => _data.cheats;
  List<CheatCategory> get categories => _data.categories;
  int get total => cheats.length;
  int get unlockedCount => cheats.where((c) => unlockedIds.contains(c.id)).length;
  bool get schemaTooNew => repo.schemaTooNew;
  DateTime? get lastChecked => repo.lastCheckedAt;

  int countFor(String categoryId) =>
      categoryId == kAllCategories ? total : cheats.where((c) => c.categoryId == categoryId).length;

  bool matches(Cheat c) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return c.name.toLowerCase().contains(q) ||
        c.effect.toLowerCase().contains(q) ||
        c.unlockRequirement.toLowerCase().contains(q) ||
        (c.description?.toLowerCase().contains(q) ?? false) ||
        c.tags.any((t) => t.toLowerCase().contains(q));
  }

  List<Cheat> get cheatsTabList =>
      cheats.where((c) => (category == kAllCategories || c.categoryId == category) && matches(c)).toList();

  List<Cheat> get favorites => cheats.where((c) => favoriteIds.contains(c.id) && matches(c)).toList();

  List<Cheat> get trackerList => cheats.where((c) {
        final u = unlockedIds.contains(c.id);
        final ok = switch (trackerFilter) {
          TrackerFilter.all => true,
          TrackerFilter.todo => !u,
          TrackerFilter.unlocked => u,
        };
        return ok && matches(c);
      }).toList();

  // --- New / updated badges (keyed by stable cheat id) ---

  String _stamp(Cheat c) => c.updatedAt.millisecondsSinceEpoch.toString();

  bool _recent(DateTime d) => _now().difference(d) <= badgeWindow;

  CheatBadge? badgeFor(Cheat c) {
    final seenStamp = seen[c.id];
    if (seenStamp == _stamp(c)) return null;
    if (seenStamp == null) return (c.isNew || _recent(c.addedAt)) ? CheatBadge.fresh : null;
    return _recent(c.updatedAt) ? CheatBadge.updated : null;
  }

  void markSeen(Cheat c) {
    if (seen[c.id] == _stamp(c)) return;
    seen = {...seen, c.id: _stamp(c)};
    repo.saveSeen(seen);
    notifyListeners();
  }

  // --- Announcement ---

  Announcement? get activeAnnouncement {
    final a = _data.announcement;
    if (a == null || !a.active || a.id == dismissedAnnouncementId) return null;
    return a;
  }

  void dismissAnnouncement() {
    final a = _data.announcement;
    if (a == null) return;
    dismissedAnnouncementId = a.id;
    repo.saveDismissedAnnouncement(a.id);
    notifyListeners();
  }

  void dismissSchemaNotice() {
    schemaNoticeDismissed = true;
    notifyListeners();
  }

  // --- UI state ---

  void setQuery(String v) { query = v; notifyListeners(); }
  void setCategory(String v) { category = v; notifyListeners(); }
  void setTrackerFilter(TrackerFilter f) { trackerFilter = f; notifyListeners(); }
  void focus(String id) { focusedId = focusedId == id ? null : id; notifyListeners(); }

  void setPlatform(String p) { platform = p; repo.savePlatform(p); notifyListeners(); }

  void toggleUnlocked(String id) {
    unlockedIds = {...unlockedIds};
    if (!unlockedIds.remove(id)) unlockedIds.add(id);
    repo.saveUnlocked(unlockedIds);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    favoriteIds = {...favoriteIds};
    if (!favoriteIds.remove(id)) favoriteIds.add(id);
    repo.saveFavorites(favoriteIds);
    notifyListeners();
  }

  void dismissBanner(bool v) { bannerDismissed = v; repo.saveBannerDismissed(v); notifyListeners(); }

  Future<void> resetProgress() async {
    unlockedIds = {};
    favoriteIds = {};
    await repo.resetProgress();
    notifyListeners();
  }

  // --- Remote content ---

  /// Background refresh: throttled unless [force]. Shows cached content immediately;
  /// the UI only rebuilds if new content arrived.
  Future<SyncOutcome> refresh({bool force = false}) async {
    if (syncing) return const SyncOutcome(SyncStatus.busy);
    if (!force && !repo.isCheckDue) return const SyncOutcome(SyncStatus.skippedThrottle);
    syncing = true;
    notifyListeners();
    final r = await repo.refresh(_data.contentVersion, force: force);
    syncing = false;
    final d = r.data;
    if (r.status == SyncStatus.updated && d != null) {
      _data = d;
      if (category != kAllCategories && !d.categories.any((c) => c.id == category)) category = kAllCategories;
    }
    notifyListeners();
    return r;
  }
}
