import 'package:flutter/foundation.dart';

import '../models/cheat.dart';
import '../services/cheat_repository.dart';

enum TrackerFilter { all, todo, unlocked }

class AppState extends ChangeNotifier {
  final CheatRepository repo;
  AppState(this.repo, CheatData data)
      : _data = data {
    final u = repo.loadUserState();
    unlockedIds = u.unlockedIds;
    favoriteIds = u.favoriteIds;
    platform = u.platform;
    bannerDismissed = u.bannerDismissed;
  }

  CheatData _data;
  late Set<String> unlockedIds;
  late Set<String> favoriteIds;
  late String platform;
  late bool bannerDismissed;

  String query = '';
  String category = 'All';
  TrackerFilter trackerFilter = TrackerFilter.all;
  String? focusedId;
  bool syncing = false;

  CheatData get data => _data;
  List<Cheat> get cheats => _data.cheats;
  int get total => cheats.length;
  int get unlockedCount => cheats.where((c) => unlockedIds.contains(c.id)).length;

  /// Categories in first-seen order, with live counts.
  List<String> get categories {
    final seen = <String>[];
    for (final c in cheats) {
      if (!seen.contains(c.category)) seen.add(c.category);
    }
    return seen;
  }

  int countFor(String cat) => cat == 'All' ? total : cheats.where((c) => c.category == cat).length;

  bool matches(Cheat c) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return c.name.toLowerCase().contains(q) ||
        c.effect.toLowerCase().contains(q) ||
        c.unlockRequirement.toLowerCase().contains(q);
  }

  List<Cheat> get cheatsTabList =>
      cheats.where((c) => (category == 'All' || c.category == category) && matches(c)).toList();

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

  void _apply(CheatData d) {
    _data = d;
    if (category != 'All' && !categories.contains(category)) category = 'All';
    notifyListeners();
  }

  Future<SyncResult> sync() async {
    syncing = true;
    notifyListeners();
    final r = await repo.sync(_data.dataVersion, _apply);
    syncing = false;
    notifyListeners();
    return r;
  }
}
