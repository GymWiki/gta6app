import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vice_codes/services/cheat_repository.dart';

void main() {
  test('bundled cheats.json has all 61 cheats with the expected split', () {
    final d = CheatRepository.parse(File('assets/cheats.json').readAsStringSync());
    final counts = <String, int>{};
    for (final c in d.cheats) {
      counts[c.category] = (counts[c.category] ?? 0) + 1;
    }
    expect(d.cheats.length, 61);
    expect(counts, {'Player': 10, 'Combat': 11, 'Vehicles': 21, 'Environment': 3, 'Filters': 16});
    expect(d.cheats.map((c) => c.id).toSet().length, 61);
  });
}
