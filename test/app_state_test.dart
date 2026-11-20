import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vice_codes/providers/app_state.dart';
import 'package:vice_codes/services/cheat_repository.dart';

Map<String, dynamic> ch(String id, String added, {String? updated}) => {
      'id': id,
      'title': {'en': 'Cheat $id'},
      'categoryId': 'player',
      'effect': {'en': 'E'},
      'unlockRequirement': {'en': 'R'},
      'status': 'unverified',
      'addedAt': added,
      'updatedAt': updated ?? added,
    };

String doc(int v, List<Map<String, dynamic>> cheats, {Object? announcement}) => jsonEncode({
      'schemaVersion': 1,
      'contentVersion': v,
      'updatedAt': '2026-11-20',
      'categories': [
        {'id': 'player', 'name': {'en': 'Player'}}
      ],
      'cheats': cheats,
      if (announcement != null) 'announcement': announcement,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('favorites, unlocked and seen state follow the stable id across content updates', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 11, 21);
    final v1 = doc(1, [ch('a', '2026-11-20'), ch('b', '2026-11-20')]);
    final v2 = doc(2, [ch('a', '2026-11-20', updated: '2026-11-21'), ch('c', '2026-11-21')], announcement: {
      'id': 'n1',
      'title': {'en': 'Hello'},
      'message': {'en': 'World'},
      'active': true,
    });
    final repo = CheatRepository(
      await SharedPreferences.getInstance(),
      url: 'https://example.test/content.json',
      client: MockClient((_) async => http.Response(v2, 200)),
      loadBundled: () async => v1,
    );
    final state = AppState(repo, await repo.loadLocal(), now: () => now);

    // First run: everything is already seen.
    expect(state.cheats.map(state.badgeFor), everyElement(isNull));

    state.toggleFavorite('a');
    state.toggleFavorite('b');
    state.toggleUnlocked('a');

    final out = await state.refresh(force: true);
    expect(out.status, SyncStatus.updated);
    expect(state.cheats.map((c) => c.id), ['a', 'c']);

    // Ids survive even when the cheat disappeared from the content.
    expect(state.favoriteIds, {'a', 'b'});
    expect(state.favorites.map((c) => c.id), ['a']);
    expect(state.unlockedCount, 1);

    // Badges: 'a' was updated, 'c' is new; tapping marks them seen.
    final a = state.cheats.firstWhere((c) => c.id == 'a');
    final c = state.cheats.firstWhere((c) => c.id == 'c');
    expect(state.badgeFor(a), CheatBadge.updated);
    expect(state.badgeFor(c), CheatBadge.fresh);
    state.markSeen(a);
    state.markSeen(c);
    expect(state.badgeFor(a), isNull);
    expect(state.badgeFor(c), isNull);

    // Announcement shows until dismissed, and the dismissal sticks.
    expect(state.activeAnnouncement?.title, 'Hello');
    state.dismissAnnouncement();
    expect(state.activeAnnouncement, isNull);
    final again = AppState(repo, state.data, now: () => now);
    expect(again.activeAnnouncement, isNull);
    expect(again.favoriteIds, {'a', 'b'});
  });

  test('old cheats get no badge even if never seen; search covers tags and description', () async {
    SharedPreferences.setMockInitialValues({'seenCheats': '{}'});
    final raw = doc(1, [
      {
        ...ch('old', '2026-01-01'),
        'tags': ['money'],
        'description': {'en': 'Long text zebra'},
      },
      ch('fresh', '2026-11-20'),
    ]);
    final repo = CheatRepository(await SharedPreferences.getInstance(), loadBundled: () async => raw);
    final state = AppState(repo, await repo.loadLocal(), now: () => DateTime(2026, 11, 21));
    expect(state.badgeFor(state.cheats[0]), isNull);
    expect(state.badgeFor(state.cheats[1]), CheatBadge.fresh);
    state.setQuery('money');
    expect(state.cheatsTabList.map((c) => c.id), ['old']);
    state.setQuery('zebra');
    expect(state.cheatsTabList.map((c) => c.id), ['old']);
  });
}
