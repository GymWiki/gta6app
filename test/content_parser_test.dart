import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vice_codes/services/content_parser.dart';

Map<String, dynamic> cheat(String id, {Map<String, dynamic>? extra, List<String> drop = const []}) {
  final m = <String, dynamic>{
    'id': id,
    'title': {'en': 'Title $id', 'nl': 'Titel $id'},
    'categoryId': 'player',
    'effect': {'en': 'Effect'},
    'unlockRequirement': {'en': 'Req', 'nl': 'Eis'},
    'status': 'unverified',
    'addedAt': '2026-11-20',
    'updatedAt': '2026-11-20',
    ...?extra,
  };
  for (final k in drop) {
    m.remove(k);
  }
  return m;
}

String doc({int schema = 1, int version = 1, List<dynamic>? cheats, List<dynamic>? categories, Object? announcement}) =>
    jsonEncode({
      'schemaVersion': schema,
      'contentVersion': version,
      'updatedAt': '2026-11-20',
      'categories': categories ??
          [
            {'id': 'player', 'name': {'en': 'Player', 'nl': 'Speler'}}
          ],
      'cheats': cheats ?? [cheat('a')],
      if (announcement != null) 'announcement': announcement,
    });

void main() {
  test('parses a valid document', () {
    final d = ContentParser.parse(doc(cheats: [
      cheat('a', extra: {
        'codes': {
          'ps5': ['up', 'DOWN'],
          'phone': '555-0100',
          'xbox': ['SIDEWAYS'],
        },
        'status': 'verified',
        'tags': ['money'],
        'isNew': true,
      })
    ]));
    final c = d.cheats.single;
    expect(d.contentVersion, 1);
    expect(c.status.name, 'verified');
    expect(c.codeFor('ps5')!.dpad, ['UP', 'DOWN']);
    expect(c.codeFor('phone')!.text, '555-0100');
    expect(c.codeFor('xbox'), isNull, reason: 'invalid sequence is ignored, cheat is kept');
    expect(c.isNew, isTrue);
    expect(c.tags, ['money']);
  });

  test('uses requested language and falls back to en', () {
    final nl = ContentParser.parse(doc(), lang: 'nl').cheats.single;
    expect(nl.name, 'Titel a');
    expect(nl.effect, 'Effect', reason: 'no nl effect -> en');
    expect(ContentParser.parse(doc(), lang: 'de').cheats.single.name, 'Title a');
    expect(ContentParser.parse(doc(), lang: 'nl').categories.single.name, 'Speler');
  });

  test('skips a broken cheat but keeps the others', () {
    final skipped = <String>[];
    final d = ContentParser.parse(
      doc(cheats: [
        cheat('good1'),
        cheat('no_title', drop: ['title']),
        cheat('bad_cat', extra: {'categoryId': 'nope'}),
        cheat('bad_date', extra: {'addedAt': 'yesterday'}),
        'not an object',
        cheat('good1'), // duplicate id
        cheat('good2'),
      ]),
      onSkip: skipped.add,
    );
    expect(d.cheats.map((c) => c.id), ['good1', 'good2']);
    expect(skipped.length, 5);
  });

  test('unknown status falls back to unverified', () {
    expect(ContentParser.parse(doc(cheats: [cheat('a', extra: {'status': 'whatever'})])).cheats.single.status.name,
        'unverified');
  });

  test('ignores a broken announcement, keeps a valid one', () {
    expect(ContentParser.parse(doc(announcement: {'id': 'x'})).announcement, isNull);
    final a = ContentParser.parse(
      doc(announcement: {
        'id': 'a1',
        'title': {'en': 'Hi', 'nl': 'Hoi'},
        'message': {'en': 'Msg'},
        'active': true,
      }),
      lang: 'nl',
    ).announcement!;
    expect(a.title, 'Hoi');
    expect(a.message, 'Msg');
    expect(a.active, isTrue);
  });

  test('rejects unusable documents', () {
    for (final raw in ['', '   ', '{not json', '[]', '{}', 'null']) {
      expect(() => ContentParser.parse(raw), throwsA(isA<ContentException>()), reason: raw);
    }
    expect(() => ContentParser.parse(doc(cheats: [])), throwsA(isA<ContentException>()));
    expect(() => ContentParser.parse(doc(cheats: [cheat('x', drop: ['effect'])])), throwsA(isA<ContentException>()),
        reason: 'no valid cheats left');
  });

  test('higher schemaVersion throws UnsupportedSchemaException', () {
    expect(() => ContentParser.parse(doc(schema: supportedSchemaVersion + 1)), throwsA(isA<UnsupportedSchemaException>()));
  });
}
