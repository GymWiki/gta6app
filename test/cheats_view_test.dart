import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vice_codes/models/content.dart';
import 'package:vice_codes/providers/app_state.dart';
import 'package:vice_codes/services/cheat_repository.dart';
import 'package:vice_codes/services/content_parser.dart';

Future<AppState> make({Map<String, Object> prefs = const {}, String platform = 'ps5'}) async {
  SharedPreferences.setMockInitialValues({'platformChosen': true, 'selectedPlatform': platform, ...prefs});
  final repo = CheatRepository(await SharedPreferences.getInstance(), loadBundled: () async => File('content.json').readAsStringSync());
  return AppState(repo, await repo.loadLocal(), now: () => DateTime(2026, 11, 21));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('default view: "with code" on', () {
    test('cheats with a code are grouped per category, the rest sit in the "no code yet" section', () async {
      final s = await make();
      final v = s.view;
      expect(v.grouped, isTrue);
      expect(v.mainCheats.every(s.hasCode), isTrue);
      expect(v.noCode.every((c) => !s.hasCode(c)), isTrue);
      expect(v.mainCheats.length, 18);
      expect(v.noCode.length, 43);
      expect(v.all.length, 61);
      // Categories follow the content order and only non-empty groups are shown.
      expect(v.groups.map((g) => g.category!.id), ['player', 'combat', 'vehicles', 'environment', 'filters']
          .where((id) => v.mainCheats.any((c) => c.categoryId == id)));
    });

    test('turning "with code" off lists everything, no collapsed section', () async {
      final s = await make();
      s.setWithCodeOnly(false);
      expect(s.view.noCode, isEmpty);
      expect(s.view.mainCheats.length, 61);
      expect(s.repo.loadUserState().withCodeOnly, isFalse, reason: 'persisted (also from Settings)');
    });

    test('the setting is restored on the next start', () async {
      final s = await make(prefs: {'withCodeOnly': false});
      expect(s.withCodeOnly, isFalse);
      expect(s.view.noCode, isEmpty);
    });
  });

  group('scope chips', () {
    test('a category is a flat list (no sticky headers) and still splits out cheats without code', () async {
      final s = await make();
      s.setCategory('vehicles');
      final v = s.view;
      expect(v.grouped, isFalse);
      expect(v.mainCheats.every((c) => c.categoryId == 'vehicles'), isTrue);
      expect(v.mainCheats.length + v.noCode.length, 21);
    });

    test('favorites show every favorite, including ones without a code', () async {
      final s = await make();
      s.toggleFavorite('player_250k'); // has a code
      s.toggleFavorite('player_drunk'); // no code yet
      s.setCategory(kFavoritesScope);
      expect(s.view.mainCheats.map((c) => c.id).toSet(), {'player_250k', 'player_drunk'});
      expect(s.view.noCode, isEmpty);
    });

    test('changing the scope collapses the "no code yet" section again', () async {
      final s = await make();
      s.toggleNoCodeExpanded();
      expect(s.noCodeExpanded, isTrue);
      s.setCategory('combat');
      expect(s.noCodeExpanded, isFalse);
    });
  });

  group('search in the view', () {
    test('a query gives a flat, ranked list; hits without code go to the collapsed section', () async {
      final s = await make();
      s.setQuery('politie');
      final v = s.view;
      expect(v.grouped, isFalse);
      expect(v.mainCheats.map((c) => c.id), ['player_raise_heat_level', 'player_raise_wanted_level']);
      expect(v.noCode.map((c) => c.id).toSet(), {'filter_migraine', 'filter_hellscape'});
    });

    test('search respects the selected category', () async {
      final s = await make();
      s.setCategory('combat');
      s.setQuery('ammo');
      expect(s.view.all.every((c) => c.categoryId == 'combat'), isTrue);
      expect(s.view.all, isNotEmpty);
    });

    test('no match -> empty view', () async {
      final s = await make();
      s.setQuery('zzzz-nothing');
      expect(s.view.isEmpty, isTrue);
    });
  });

  group('memoization', () {
    test('the same inputs return the very same view object; any input change recomputes', () async {
      final s = await make();
      final a = s.view;
      expect(identical(s.view, a), isTrue);
      s.focus('player_250k'); // UI-only state does not invalidate the list
      expect(identical(s.view, a), isTrue);
      s.setQuery('geld');
      final b = s.view;
      expect(identical(b, a), isFalse);
      expect(identical(s.view, b), isTrue);
      s.setQuery('');
      expect(identical(s.view, b), isFalse);
      s.setPlatform('xbox');
      expect(s.view.mainCheats.length, 18);
    });

    test('favorites changes refresh the favorites scope', () async {
      final s = await make();
      s.setCategory(kFavoritesScope);
      expect(s.view.isEmpty, isTrue);
      s.toggleFavorite('player_250k');
      expect(s.view.mainCheats.map((c) => c.id), ['player_250k']);
      s.toggleFavorite('player_250k');
      expect(s.view.isEmpty, isTrue);
    });
  });

  group('performance', () {
    test('ranking + grouping stays far below a frame (16ms) per keystroke', () async {
      final s = await make();
      final queries = ['p', 'po', 'pol', 'poli', 'polit', 'politie', 'geld', 'money', 'auto', 'wantd', 'boomazom', 'ammo'];
      // Warm up the JIT, then time many full recomputations (query change -> view).
      for (final q in queries) {
        s.setQuery(q);
        s.view;
      }
      final sw = Stopwatch()..start();
      const rounds = 50;
      for (var i = 0; i < rounds; i++) {
        for (final q in queries) {
          s.setQuery(i.isEven ? q : '$q ');
          s.view;
        }
      }
      sw.stop();
      final perView = sw.elapsedMicroseconds / (rounds * queries.length) / 1000;
      // ignore: avoid_print
      print('PERF avg ms per query+view: ${perView.toStringAsFixed(3)}');
      expect(perView, lessThan(8), reason: 'well within a 16ms frame, even on a debug VM');
    });
  });

  group('recently viewed and the quick strip', () {
    test('opening a cheat records it; max 5, newest first, no duplicates; persisted', () async {
      final s = await make();
      for (final id in ['player_250k', 'player_drunk', 'combat_max_ammo', 'env_cycle_weather', 'filter_pinhole', 'filter_fisheye']) {
        s.focus(id);
      }
      expect(s.recentIds, ['filter_fisheye', 'filter_pinhole', 'env_cycle_weather', 'combat_max_ammo', 'player_drunk']);
      s.focus('player_drunk'); // collapse
      s.focus('player_drunk'); // reopen -> moves to front, still 5
      expect(s.recentIds.first, 'player_drunk');
      expect(s.recentIds.length, 5);
      expect(s.recentIds.toSet().length, 5);
      expect(s.repo.loadUserState().recentIds, s.recentIds);
    });

    test('only one row is open at a time', () async {
      final s = await make();
      s.focus('player_250k');
      s.focus('player_drunk');
      expect(s.focusedId, 'player_drunk');
      s.focus('player_drunk');
      expect(s.focusedId, isNull);
    });

    test('strip lists favorites, then recents without duplicates; hidden while searching or filtering', () async {
      final s = await make();
      expect(s.showQuickStrip, isFalse, reason: 'no data yet: the list gets the whole screen');
      s.toggleFavorite('player_250k');
      s.focus('player_250k');
      s.focus('combat_max_ammo');
      expect(s.showQuickStrip, isTrue);
      expect(s.quickFavorites.map((c) => c.id), ['player_250k']);
      expect(s.quickRecent.map((c) => c.id), ['combat_max_ammo'], reason: 'the favorite is not repeated under recent');
      s.setQuery('geld');
      expect(s.showQuickStrip, isFalse);
      s.setQuery('');
      s.setCategory('combat');
      expect(s.showQuickStrip, isFalse);
    });

    test('reset progress clears favorites, unlocked and recents', () async {
      final s = await make();
      s.toggleFavorite('player_250k');
      s.focus('player_250k');
      await s.resetProgress();
      expect(s.favoriteIds, isEmpty);
      expect(s.recentIds, isEmpty);
      expect(s.showQuickStrip, isFalse);
    });
  });

  group('platform choice', () {
    test('first start: not chosen yet; choosing or confirming remembers it permanently', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = CheatRepository(await SharedPreferences.getInstance(), loadBundled: () async => File('content.json').readAsStringSync());
      final s = AppState(repo, await repo.loadLocal());
      expect(s.platformChosen, isFalse);
      s.setPlatform('xbox');
      expect(s.platformChosen, isTrue);
      final again = AppState(repo, s.data);
      expect(again.platform, 'xbox');
      expect(again.platformChosen, isTrue);
    });

    test('dismissing the question keeps the default and does not ask again', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = CheatRepository(await SharedPreferences.getInstance(), loadBundled: () async => File('content.json').readAsStringSync());
      final s = AppState(repo, await repo.loadLocal());
      s.confirmPlatformChoice();
      expect(AppState(repo, s.data).platformChosen, isTrue);
      expect(AppState(repo, s.data).platform, 'ps5');
    });
  });

  group('codes per platform', () {
    test('displayCode falls back to the other console, then to phone/pc, then null', () {
      ContentData parse(String codes) => ContentParser.parse('''
        {"schemaVersion":1,"contentVersion":1,"updatedAt":"2026-11-20",
         "categories":[{"id":"player","name":{"en":"Player"}}],
         "cheats":[{"id":"a","title":{"en":"A"},"categoryId":"player","effect":{"en":"e"},"unlockRequirement":{"en":"r"},
         "status":"verified","addedAt":"2026-11-20","updatedAt":"2026-11-20"$codes}]}''');
      final onlyPs5 = parse(',"codes":{"ps5":["UP"]}').cheats.single;
      expect(onlyPs5.displayCode('xbox')!.dpad, ['UP']);
      expect(onlyPs5.codeFor('xbox'), isNull, reason: 'strict lookup stays strict');
      expect(parse(',"codes":{"phone":"555"}').cheats.single.displayCode('ps5')!.text, '555');
      expect(parse('').cheats.single.displayCode('ps5'), isNull);
    });

    test('aliases are optional and parsed', () {
      final c = ContentParser.parse(File('content.json').readAsStringSync()).cheats;
      expect(c.firstWhere((x) => x.id == 'player_250k').aliases, contains('geld'));
      expect(c.firstWhere((x) => x.id == 'player_parachute').aliases, isNotEmpty);
      expect(c.where((x) => x.aliases.isEmpty), isNotEmpty, reason: 'aliases stay optional');
    });
  });
}
