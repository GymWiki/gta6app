import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vice_codes/models/content.dart';
import 'package:vice_codes/services/cheat_search.dart';
import 'package:vice_codes/services/content_parser.dart';

void main() {
  final data = ContentParser.parse(File('content.json').readAsStringSync());
  final nl = ContentParser.parse(File('content.json').readAsStringSync(), lang: 'nl');
  final search = CheatSearch(data.cheats);
  final searchNl = CheatSearch(nl.cheats);
  List<String> ids(CheatSearch s, String q, ContentData d) => s.rank(q, d.cheats).map((c) => c.id).toList();

  group('basics', () {
    test('empty or 1-letter query returns everything unchanged', () {
      expect(search.rank('', data.cheats).length, 61);
      expect(search.rank('   ', data.cheats).length, 61);
      expect(search.rank('a', data.cheats).length, 61);
    });

    test('prefix and contains on the title', () {
      expect(ids(search, 'boomaz', data).first, 'vehicle_maibatsu_boomazoom');
      expect(ids(search, 'dozer', data), contains('vehicle_hvy_bulldozer'));
    });

    test('all words must match (AND)', () {
      expect(ids(search, 'raise wanted', data).first, 'player_raise_wanted_level');
      expect(ids(search, 'raise banana', data), isEmpty);
    });

    test('diacritics and punctuation are ignored', () {
      expect(ids(search, r'$250,000', data), contains('player_250k'));
      expect(ids(search, '250k', data).first, 'player_250k');
    });
  });

  group('synonyms in Dutch and English', () {
    test('politie / cops / police / wanted all find the wanted-level cheats', () {
      for (final q in ['politie', 'cops', 'police', 'wanted']) {
        final r = ids(search, q, data);
        expect(r, containsAll(['player_raise_heat_level', 'player_raise_wanted_level']), reason: q);
      }
    });

    test('geld / money / cash find the money cheat first', () {
      for (final q in ['geld', 'money', 'cash']) {
        expect(ids(search, q, data).first, 'player_250k', reason: q);
      }
    });

    test('auto / vehicle find vehicle cheats', () {
      for (final q in ['auto', 'vehicle', 'voertuig']) {
        final r = ids(search, q, data);
        expect(r.where((i) => i.startsWith('vehicle_')).length, greaterThan(10), reason: q);
      }
    });

    test('weer / weather find Cycle Weather; tijd finds the time cheats', () {
      expect(ids(search, 'weer', data), contains('env_cycle_weather'));
      expect(ids(search, 'weather', data), contains('env_cycle_weather'));
      expect(ids(search, 'tijd', data), containsAll(['env_move_time_forward', 'env_pause_time_of_day']));
    });

    test('munitie / ammo find the ammo cheats', () {
      for (final q in ['munitie', 'ammo']) {
        expect(ids(search, q, data), containsAll(['combat_max_ammo', 'combat_infinite_ammo', 'combat_no_reload']), reason: q);
      }
    });

    test('works against the Dutch-language content too', () {
      expect(ids(searchNl, 'geld', nl).first, 'player_250k');
      expect(ids(searchNl, 'dronken', nl), contains('player_drunk'));
    });

    test('expand() groups words', () {
      expect(CheatSearch.expand('politie'), containsAll(['cops', 'wanted', 'police']));
      expect(CheatSearch.expand('xx'), {'xx'});
    });
  });

  group('typos', () {
    test('one wrong letter still finds the cheat', () {
      expect(ids(search, 'boomazom', data).first, 'vehicle_maibatsu_boomazoom');
      expect(ids(search, 'wantd', data), contains('player_raise_wanted_level'));
      expect(ids(search, 'polite', data), contains('player_raise_wanted_level'));
      expect(ids(search, 'bulldoser', data), contains('vehicle_hvy_bulldozer'));
    });

    test('no noise: synonyms are not fuzzy and short words do not match running text', () {
      // "politie" must not drag in every cheat whose requirement says "Complete ...".
      final r = ids(search, 'politie', data);
      expect(r.toSet(), {'player_raise_heat_level', 'player_raise_wanted_level', 'filter_migraine', 'filter_hellscape'});
      expect(r.take(2).toSet(), {'player_raise_heat_level', 'player_raise_wanted_level'}, reason: 'aliases/titles rank first');
      // "geld" is not "gold medals".
      expect(ids(search, 'geld', data), ['player_250k']);
    });

    test('short words are not fuzzy (no noise)', () {
      expect(ids(search, 'xyz', data), isEmpty);
      expect(ids(search, 'zzzz-nothing', data), isEmpty);
    });
  });

  group('ranking', () {
    test('title matches outrank text matches', () {
      final r = ids(search, 'ammo', data);
      // "Max/Infinite Ammo" have it in the title, others only via text/synonyms.
      expect(r.take(2).toSet(), {'combat_max_ammo', 'combat_infinite_ammo'});
    });

    test('keeps candidate order for equal scores and only searches the given candidates', () {
      final subset = data.cheats.where((c) => c.categoryId == 'vehicles').toList();
      final r = search.rank('spawn', subset);
      expect(r.every((c) => c.categoryId == 'vehicles'), isTrue);
    });
  });

  group('highlight', () {
    String mark(String text, String q) {
      final rs = CheatSearch.highlight(text, q);
      final b = StringBuffer();
      var pos = 0;
      for (final r in rs) {
        b.write(text.substring(pos, r.start));
        b.write('[${text.substring(r.start, r.end)}]');
        pos = r.end;
      }
      b.write(text.substring(pos));
      return b.toString();
    }

    test('marks matched parts', () {
      expect(mark('Raise Wanted Level', 'wanted'), 'Raise [Wanted] Level');
      expect(mark('Maibatsu Boomazoom', 'boom'), 'Maibatsu [Boom]azoom');
    });

    test('marks synonym hits and typo words, merges overlaps', () {
      expect(mark('Raise Wanted Level', 'politie'), 'Raise [Wanted] Level');
      expect(mark('Raise Wanted Level', 'wantd'), 'Raise [Wanted] Level');
      // A typed prefix of a known word highlights the whole word.
      expect(mark('Raise Wanted Level', 'raise wan'), '[Raise] [Wanted] Level');
    });

    test('empty query highlights nothing', () {
      expect(CheatSearch.highlight('Raise Wanted Level', ''), isEmpty);
    });
  });
}
