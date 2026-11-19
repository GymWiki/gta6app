import 'package:flutter_test/flutter_test.dart';
import 'package:vice_codes/models/cheat.dart';
import 'package:vice_codes/services/cheat_repository.dart';

void main() {
  test('parses cheat JSON incl. null dpad', () {
    final d = CheatRepository.parse(
        '{"data_version":2,"last_updated":"x","cheats":[{"id":"a","name":"A","category":"Player","effect":"e","dpad_sequence":null,"unlock_requirement":"u"},'
        '{"id":"b","name":"B","category":"Combat","effect":"e","dpad_sequence":["UP","left"],"unlock_requirement":"u"}]}');
    expect(d.dataVersion, 2);
    expect(d.cheats[0].dpadSequence, isNull);
    expect(d.cheats[1].dpadSequence, ['UP', 'LEFT']);
    expect(d.cheats, isA<List<Cheat>>());
  });
}
