import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vice_codes/services/cheat_repository.dart';
import 'package:vice_codes/services/content_parser.dart';

String content({int version = 1, int schema = 1, String id = 'a'}) => jsonEncode({
      'schemaVersion': schema,
      'contentVersion': version,
      'updatedAt': '2026-11-20',
      'categories': [
        {'id': 'player', 'name': {'en': 'Player'}}
      ],
      'cheats': [
        {
          'id': id,
          'title': {'en': 'T $id'},
          'categoryId': 'player',
          'effect': {'en': 'E'},
          'unlockRequirement': {'en': 'R'},
          'status': 'verified',
          'addedAt': '2026-11-20',
          'updatedAt': '2026-11-20',
        }
      ],
    });

const url = 'https://example.test/content.json';

Future<CheatRepository> repo({
  Map<String, Object> prefs = const {},
  MockClientHandler? handler,
  String? bundled,
  DateTime Function()? now,
  String theUrl = url,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  return CheatRepository(
    await SharedPreferences.getInstance(),
    client: MockClient(handler ?? (_) async => throw http.ClientException('offline')),
    url: theUrl,
    now: now,
    loadBundled: () async => bundled ?? content(version: 1, id: 'bundled'),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('loadLocal fallback order', () {
    test('no cache -> bundled', () async {
      final r = await repo();
      expect((await r.loadLocal()).cheats.single.id, 'bundled');
    });

    test('valid newer cache wins over bundled', () async {
      final r = await repo(prefs: {'content_cache': content(version: 5, id: 'cached')});
      expect((await r.loadLocal()).cheats.single.id, 'cached');
    });

    test('bundled wins when the app ships newer content than the cache', () async {
      final r = await repo(
        prefs: {'content_cache': content(version: 2, id: 'cached')},
        bundled: content(version: 9, id: 'bundled'),
      );
      expect((await r.loadLocal()).cheats.single.id, 'bundled');
    });

    test('corrupt cache is dropped -> bundled', () async {
      final r = await repo(prefs: {'content_cache': '{broken', 'content_etag': '"x"'});
      expect((await r.loadLocal()).cheats.single.id, 'bundled');
      expect(r.prefs.containsKey('content_cache'), isFalse);
      expect(r.prefs.containsKey('content_etag'), isFalse);
    });

    test('broken bundled and no cache -> empty content, no crash', () async {
      final r = await repo(bundled: '{nope');
      final d = await r.loadLocal();
      expect(d.cheats, isEmpty);
    });
  });

  group('refresh', () {
    test('newer remote -> updated, cached with etag, and used on next start', () async {
      final r = await repo(
          handler: (_) async => http.Response(content(version: 3, id: 'remote'), 200, headers: {'etag': '"abc"'}));
      final out = await r.refresh(1);
      expect(out.status, SyncStatus.updated);
      expect(out.data!.cheats.single.id, 'remote');
      expect(r.prefs.getString('content_etag'), '"abc"');
      expect((await r.loadLocal()).contentVersion, 3);
    });

    test('same or older contentVersion -> notModified, cache untouched', () async {
      final r = await repo(handler: (_) async => http.Response(content(version: 2), 200));
      expect((await r.refresh(2)).status, SyncStatus.notModified);
      expect((await r.refresh(5, force: true)).status, SyncStatus.notModified);
      expect(r.prefs.containsKey('content_cache'), isFalse);
    });

    test('sends If-None-Match only with a cache, and 304 means notModified', () async {
      final seen = <String?>[];
      final r = await repo(
        prefs: {'content_cache': content(version: 2), 'content_etag': '"v2"'},
        handler: (req) async {
          seen.add(req.headers['If-None-Match']);
          return http.Response('', 304);
        },
      );
      expect((await r.refresh(2)).status, SyncStatus.notModified);
      expect(seen, ['"v2"']);

      final r2 = await repo(prefs: {'content_etag': '"orphan"'}, handler: (req) async {
        seen.add(req.headers['If-None-Match']);
        return http.Response('', 304);
      });
      await r2.refresh(1);
      expect(seen.last, isNull);
    });

    test('broken JSON, empty body, HTTP error and offline all -> failed and keep cache', () async {
      for (final h in <MockClientHandler>[
        (_) async => http.Response('{broken', 200),
        (_) async => http.Response('', 200),
        (_) async => http.Response('oops', 500),
        (_) async => throw http.ClientException('offline'),
      ]) {
        final r = await repo(prefs: {'content_cache': content(version: 2, id: 'cached')}, handler: h);
        expect((await r.refresh(2)).status, SyncStatus.failed);
        expect((await r.loadLocal()).cheats.single.id, 'cached');
      }
    });

    test('higher schemaVersion -> schemaTooNew, cache kept, flag cleared by a later valid response', () async {
      var body = content(schema: supportedSchemaVersion + 1, version: 99);
      final r = await repo(
        prefs: {'content_cache': content(version: 2, id: 'cached')},
        handler: (_) async => http.Response(body, 200),
      );
      expect((await r.refresh(2)).status, SyncStatus.schemaTooNew);
      expect(r.schemaTooNew, isTrue);
      expect((await r.loadLocal()).cheats.single.id, 'cached');
      body = content(version: 2);
      await r.refresh(2, force: true);
      expect(r.schemaTooNew, isFalse);
    });

    test('auto checks are throttled to once per interval; force bypasses', () async {
      var calls = 0;
      var now = DateTime(2026, 11, 20, 12);
      final r = await repo(now: () => now, handler: (_) async {
        calls++;
        return http.Response(content(version: 1), 200);
      });
      expect((await r.refresh(1)).status, SyncStatus.notModified);
      expect((await r.refresh(1)).status, SyncStatus.skippedThrottle);
      now = now.add(autoCheckInterval - const Duration(minutes: 1));
      expect((await r.refresh(1)).status, SyncStatus.skippedThrottle);
      expect((await r.refresh(1, force: true)).status, SyncStatus.notModified);
      now = now.add(autoCheckInterval + const Duration(minutes: 1));
      expect((await r.refresh(1)).status, SyncStatus.notModified);
      expect(calls, 3);
    });

    test('a failed check also counts for the throttle (no retry loops)', () async {
      var calls = 0;
      final r = await repo(handler: (_) async {
        calls++;
        throw http.ClientException('offline');
      });
      await r.refresh(1);
      await r.refresh(1);
      expect(calls, 1);
    });

    test('placeholder URL never hits the network', () async {
      var calls = 0;
      final r = await repo(theUrl: contentUrl, handler: (_) async {
        calls++;
        return http.Response('', 200);
      });
      expect((await r.refresh(1, force: true)).status, SyncStatus.notConfigured);
      expect(calls, 0);
    });
  });
}
