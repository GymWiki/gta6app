import 'package:flutter/foundation.dart';

import '../l10n/strings.dart';
import '../models/content.dart';
import '../services/cheat_repository.dart';
import '../services/cheat_search.dart';

enum TrackerFilter { all, todo, unlocked }

enum CheatBadge { fresh, updated }

/// Scope chips: everything, favorites, or a category id.
const String kAllCategories = 'all';
const String kFavoritesScope = 'favorites';

/// Cheats added/updated within this window can show a New/Updated badge.
const Duration badgeWindow = Duration(days: 14);

const int maxRecent = 5;

class CheatGroup {
  /// Null for a flat (ungrouped) list.
  final CheatCategory? category;
  final List<Cheat> cheats;
  const CheatGroup(this.category, this.cheats);
}

/// Everything the cheats list needs, computed once per input change (memoized).
class CheatsView {
  final List<CheatGroup> groups;

  /// Cheats without a known code, shown in a collapsed section when "with code" is on.
  final List<Cheat> noCode;
  final bool grouped;
  const CheatsView({required this.groups, required this.noCode, required this.grouped});

  List<Cheat> get mainCheats => [for (final g in groups) ...g.cheats];
  List<Cheat> get all => [...mainCheats, ...noCode];
  bool get isEmpty => groups.every((g) => g.cheats.isEmpty) && noCode.isEmpty;
}

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
    platformChosen = u.platformChosen;
    bannerDismissed = u.bannerDismissed;
    dismissedAnnouncementId = u.dismissedAnnouncementId;
    withCodeOnly = u.withCodeOnly;
    recentIds = [...u.recentIds];
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
  late bool platformChosen;

  /// The first-start phone hint banner was dismissed (the same hint lives in the info sheet).
  late bool bannerDismissed;
  late Map<String, String> seen;
  late bool withCodeOnly;
  late List<String> recentIds;
  String? dismissedAnnouncementId;
  bool schemaNoticeDismissed = false;

  String query = '';
  String category = kAllCategories;
  bool noCodeExpanded = false;
  TrackerFilter trackerFilter = TrackerFilter.all;
  String? focusedId;

  /// Height of the currently expanded detail (reported by the row), used to keep the tapped
  /// row in place when a different row above it collapses.
  double expandedHeight = 0;

  /// True while the previously open row collapses because another one was opened:
  /// that collapse is instant, so the scroll position can be corrected in the same frame.
  bool instantCollapse = false;
  bool syncing = false;

  // --- memoized derived data ---
  CheatSearch? _search;
  int _searchVersion = -1;
  CheatsView? _view;
  String _viewKey = '';
  int _favRevision = 0;

  Strings get t => Strings(repo.lang);
  ContentData get data => _data;
  List<Cheat> get cheats => _data.cheats;
  List<CheatCategory> get categories => _data.categories;
  int get total => cheats.length;
  int get unlockedCount => cheats.where((c) => unlockedIds.contains(c.id)).length;
  bool get schemaTooNew => repo.schemaTooNew;
  DateTime? get lastChecked => repo.lastCheckedAt;

  CheatSearch get _engine {
    if (_search == null || _searchVersion != _identityOfData) {
      _search = CheatSearch(_data.cheats);
      _searchVersion = _identityOfData;
    }
    return _search!;
  }

  int get _identityOfData => Object.hash(_data.contentVersion, _data.cheats.length, identityHashCode(_data));

  Cheat? cheatById(String id) {
    for (final c in cheats) {
      if (c.id == id) return c;
    }
    return null;
  }

  bool hasCode(Cheat c) => c.displayCode(platform) != null;

  int countFor(String scope) => switch (scope) {
        kAllCategories => total,
        kFavoritesScope => cheats.where((c) => favoriteIds.contains(c.id)).length,
        _ => cheats.where((c) => c.categoryId == scope).length,
      };

  /// Terms to highlight for the current query.
  String get highlightQuery => query;

  List<Cheat> _scoped() => switch (category) {
        kAllCategories => cheats,
        kFavoritesScope => cheats.where((c) => favoriteIds.contains(c.id)).toList(),
        _ => cheats.where((c) => c.categoryId == category).toList(),
      };

  /// The filtered, ranked, grouped list. Recomputed only when an input changed.
  CheatsView get view {
    final key = '$query|$category|$withCodeOnly|$platform|$_favRevision|$_identityOfData';
    if (_view != null && key == _viewKey) return _view!;
    final base = _engine.rank(query, _scoped());
    final split = withCodeOnly && category != kFavoritesScope;
    final withCode = split ? base.where(hasCode).toList() : base;
    final noCode = split ? base.where((c) => !hasCode(c)).toList() : <Cheat>[];
    final searching = query.trim().isNotEmpty;
    final grouped = category == kAllCategories && !searching;
    final List<CheatGroup> groups;
    if (grouped) {
      groups = [
        for (final cat in categories)
          if (withCode.any((c) => c.categoryId == cat.id))
            CheatGroup(cat, withCode.where((c) => c.categoryId == cat.id).toList()),
      ];
    } else {
      groups = [CheatGroup(null, withCode)];
    }
    _viewKey = key;
    return _view = CheatsView(groups: groups, noCode: noCode, grouped: grouped);
  }

  /// Every cheat currently listed (main list + "no code yet" section).
  List<Cheat> get visibleCheats => view.all;

  /// Tracker list: status filter + the same search engine.
  List<Cheat> get trackerList {
    final byStatus = cheats.where((c) {
      final u = unlockedIds.contains(c.id);
      return switch (trackerFilter) {
        TrackerFilter.all => true,
        TrackerFilter.todo => !u,
        TrackerFilter.unlocked => u,
      };
    });
    return _engine.rank(query, byStatus);
  }

  /// Quick access: favorites then recently opened, deduped. Hidden while searching/filtering.
  List<Cheat> get quickFavorites => [for (final id in favoriteIds) if (cheatById(id) != null) cheatById(id)!];
  List<Cheat> get quickRecent => [
        for (final id in recentIds)
          if (cheatById(id) != null && !favoriteIds.contains(id)) cheatById(id)!,
      ];
  bool get showQuickStrip =>
      query.trim().isEmpty && category == kAllCategories && (quickFavorites.isNotEmpty || quickRecent.isNotEmpty);

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

  void setQuery(String v) {
    if (v == query) return;
    query = v;
    notifyListeners();
  }

  void setCategory(String v) {
    category = v;
    noCodeExpanded = false;
    notifyListeners();
  }

  void setTrackerFilter(TrackerFilter f) {
    trackerFilter = f;
    notifyListeners();
  }

  void setWithCodeOnly(bool v) {
    withCodeOnly = v;
    repo.saveWithCodeOnly(v);
    notifyListeners();
  }

  void toggleNoCodeExpanded() {
    noCodeExpanded = !noCodeExpanded;
    notifyListeners();
  }

  /// Only one row is expanded at a time; opening one records it as "recently viewed".
  void focus(String id) {
    instantCollapse = focusedId != null && focusedId != id;
    focusedId = focusedId == id ? null : id;
    if (focusedId != null) {
      recentIds = [id, ...recentIds.where((x) => x != id)].take(maxRecent).toList();
      repo.saveRecent(recentIds);
      final c = cheatById(id);
      if (c != null) markSeen(c);
    }
    notifyListeners();
  }

  void collapse() {
    if (focusedId == null) return;
    instantCollapse = false;
    focusedId = null;
    notifyListeners();
  }

  void setPlatform(String p) {
    platform = p;
    platformChosen = true;
    repo.savePlatform(p);
    repo.savePlatformChosen();
    notifyListeners();
  }

  /// First-start question answered (or dismissed): remember that we asked.
  void confirmPlatformChoice() {
    if (platformChosen) return;
    platformChosen = true;
    repo.savePlatform(platform);
    repo.savePlatformChosen();
    notifyListeners();
  }

  void toggleUnlocked(String id) {
    unlockedIds = {...unlockedIds};
    if (!unlockedIds.remove(id)) unlockedIds.add(id);
    repo.saveUnlocked(unlockedIds);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    favoriteIds = {...favoriteIds};
    if (!favoriteIds.remove(id)) favoriteIds.add(id);
    _favRevision++;
    repo.saveFavorites(favoriteIds);
    notifyListeners();
  }

  void dismissBanner(bool v) {
    bannerDismissed = v;
    repo.saveBannerDismissed(v);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    unlockedIds = {};
    favoriteIds = {};
    recentIds = [];
    _favRevision++;
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
      if (category != kAllCategories && category != kFavoritesScope && !d.categories.any((c) => c.id == category)) {
        category = kAllCategories;
      }
    }
    notifyListeners();
    return r;
  }
}
