import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vice_codes/services/content_parser.dart';

void main() {
  final raw = File('content.json').readAsStringSync();

  for (final lang in ['en', 'nl']) {
    test('bundled content.json parses cleanly ($lang)', () {
      final skipped = <String>[];
      final d = ContentParser.parse(raw, lang: lang, onSkip: skipped.add);
      expect(skipped, isEmpty);
      expect(d.cheats.length, 61);
      expect(d.categories.map((c) => c.id), ['player', 'combat', 'vehicles', 'environment', 'filters']);
      final counts = <String, int>{};
      for (final c in d.cheats) {
        counts[c.categoryId] = (counts[c.categoryId] ?? 0) + 1;
      }
      expect(counts, {'player': 10, 'combat': 11, 'vehicles': 21, 'environment': 3, 'filters': 16});
      expect(d.cheats.map((c) => c.id).toSet().length, 61);
    });
  }

  test('known codes survive the conversion', () {
    final d = ContentParser.parse(raw);
    final c = d.cheats.firstWhere((c) => c.id == 'player_250k');
    expect(c.codeFor('ps5')!.dpad, ['UP', 'RIGHT', 'DOWN', 'LEFT', 'UP', 'LEFT', 'DOWN', 'RIGHT']);
    expect(c.codeFor('xbox')!.dpad, c.codeFor('ps5')!.dpad);
    expect(d.cheats.where((c) => c.codeFor('ps5') != null).length, 18);
  });
}
