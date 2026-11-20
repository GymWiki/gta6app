import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vice_codes/providers/app_state.dart';
import 'package:vice_codes/screens/home_shell.dart';
import 'package:vice_codes/services/cheat_repository.dart';
import 'package:vice_codes/widgets/theme.dart';

Future<AppState> pumpApp(
  WidgetTester tester, {
  String lang = 'en',
  double textScale = 1.0,
  Size size = const Size(360, 740),
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final repo = CheatRepository(
    await SharedPreferences.getInstance(),
    lang: lang,
    loadBundled: () async => File('content.json').readAsStringSync(),
  );
  final state = AppState(repo, await repo.loadLocal());
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: state,
    child: MaterialApp(
      theme: Vice.theme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const HomeShell(),
    ),
  ));
  await tester.pump();
  return state;
}

Finder get _cheatList =>
    find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;

/// Scrolls the cheats list until [finder] is built and visible, like a user would.
Future<void> showInList(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 150, scrollable: _cheatList, maxScrolls: 200);
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Like testWidgets, but on a platform without ads (no ad timers/plugins in tests).
void uiTest(String description, Future<void> Function(WidgetTester tester) body) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    final previous = FlutterError.onError;
    // Print the full report (which widget, which constraints) when layout breaks.
    FlutterError.onError = (details) {
      debugPrint(details.exception.toString());
      debugPrint(details.toString(minLevel: DiagnosticLevel.info));
      previous?.call(details);
    };
    try {
      await body(tester);
    } finally {
      FlutterError.onError = previous;
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  group('renders without overflow on a small phone', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final lang in ['en', 'nl']) {
        uiTest('all tabs, text scale $scale, $lang', (tester) async {
          final s = await pumpApp(tester, lang: lang, textScale: scale, size: const Size(360, 640));
          expect(find.text('VICE CODES'), findsWidgets);
          // Expand one card, favorite one, then visit every tab.
          s.toggleFavorite(s.cheats.first.id);
          await tester.pumpAndSettle();
          await showInList(tester, find.text(s.cheats.first.name));
          await tester.tap(find.text(s.cheats.first.name).first);
          await tester.pumpAndSettle();
          await openTab(tester, s.t.tabTracker);
          await openTab(tester, s.t.tabSettings);
          await openTab(tester, s.t.tabCheats);
          expect(tester.takeException(), isNull);
        });
      }
    }

    uiTest('landscape', (tester) async {
      await pumpApp(tester, size: const Size(740, 360));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  uiTest('search filters, clear button and empty state', (tester) async {
    final s = await pumpApp(tester);
    await tester.enterText(find.byType(TextField), 'Boomazoom');
    await tester.pumpAndSettle();
    expect(s.cheatsTabList.map((c) => c.name), ['Maibatsu Boomazoom']);

    await tester.tap(find.byTooltip(s.t.clearSearch));
    await tester.pumpAndSettle();
    expect(s.query, '');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');

    await tester.enterText(find.byType(TextField), 'zzzz-nothing');
    await tester.pumpAndSettle();
    expect(find.text(s.t.noMatch), findsOneWidget);
    await tester.tap(find.text(s.t.clearFilters));
    await tester.pumpAndSettle();
    expect(s.query, '');
    expect(s.cheatsTabList.length, 61);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '', reason: 'field follows the reset');
  });

  uiTest('category chips show live counts and filter', (tester) async {
    final s = await pumpApp(tester);
    expect(find.text('All (61)'), findsOneWidget);
    expect(find.text('Player (10)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Vehicles (21)'), 100,
        scrollable: find.descendant(of: find.byType(SliverPersistentHeader), matching: find.byType(Scrollable)));
    expect(find.text('Vehicles (21)'), findsOneWidget);
    final chips = find.descendant(of: find.byType(SliverPersistentHeader), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('Combat (11)'), 100, scrollable: chips);
    await tester.tap(find.text('Combat (11)'));
    await tester.pumpAndSettle();
    expect(s.cheatsTabList.length, 11);
  });

  uiTest('platform toggle swaps the phone instruction', (tester) async {
    final s = await pumpApp(tester);
    expect(find.text('Open Phone (↑) + Hold L1 & R1'), findsOneWidget);
    await tester.tap(find.text('XBOX'));
    await tester.pumpAndSettle();
    expect(s.platform, 'xbox');
    expect(find.text('Open Phone (↑) + Hold LB & RB'), findsOneWidget);
  });

  uiTest('tapping a card reveals how to unlock it', (tester) async {
    final s = await pumpApp(tester);
    final first = s.cheats.first;
    expect(find.text(first.unlockRequirement), findsNothing);
    await tester.tap(find.text(first.name).first);
    await tester.pumpAndSettle();
    expect(find.text(first.unlockRequirement), findsOneWidget);
    expect(find.text(s.t.howToUnlock), findsOneWidget);
  });

  uiTest('favorite pins a card, unlocking updates the tracker', (tester) async {
    final s = await pumpApp(tester);
    final first = s.cheats.first;
    await tester.tap(find.byTooltip(s.t.addFavorite).first);
    await tester.pumpAndSettle();
    expect(s.favoriteIds, {first.id});
    expect(find.textContaining(s.t.pinned), findsOneWidget);

    await tester.tap(find.byTooltip(s.t.markUnlocked).first);
    await tester.pumpAndSettle();
    expect(s.unlockedIds, {first.id});
    await openTab(tester, s.t.tabTracker);
    expect(find.text('1 / 61'), findsOneWidget);
    expect(find.text('To-Do (60)'), findsOneWidget);
  });

  uiTest('progress survives a restart', (tester) async {
    final s = await pumpApp(tester);
    s.toggleUnlocked('player_250k');
    s.toggleFavorite('player_250k');
    s.setPlatform('xbox');
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final again = AppState(CheatRepository(prefs, loadBundled: () async => File('content.json').readAsStringSync()), s.data);
    expect(again.unlockedIds, {'player_250k'});
    expect(again.favoriteIds, {'player_250k'});
    expect(again.platform, 'xbox');
  });

  uiTest('system back returns to the first tab before leaving the app', (tester) async {
    final s = await pumpApp(tester);
    await openTab(tester, s.t.tabSettings);
    expect(find.text(s.t.refreshNow), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('All (61)'), findsOneWidget, reason: 'back from settings lands on the cheats tab');
  });

  uiTest('reset progress asks for confirmation', (tester) async {
    final s = await pumpApp(tester);
    s.toggleUnlocked('player_250k');
    await openTab(tester, s.t.tabSettings);
    await tester.tap(find.text(s.t.resetProgress));
    await tester.pumpAndSettle();
    expect(find.text(s.t.resetTitle), findsOneWidget);
    await tester.tap(find.text(s.t.cancel));
    await tester.pumpAndSettle();
    expect(s.unlockedIds, isNotEmpty);

    await tester.tap(find.text(s.t.resetProgress));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.t.reset));
    await tester.pumpAndSettle();
    expect(s.unlockedIds, isEmpty);
  });

  uiTest('settings refresh without a configured URL explains itself and does not crash', (tester) async {
    final s = await pumpApp(tester);
    await openTab(tester, s.t.tabSettings);
    await tester.tap(find.text(s.t.refreshNow));
    await tester.pumpAndSettle();
    expect(find.text(s.t.notConfigured), findsOneWidget);
  });

  uiTest('Dutch UI follows the device language', (tester) async {
    await pumpApp(tester, lang: 'nl');
    expect(find.text('Open telefoon (↑) + houd L1 & R1 ingedrukt'), findsOneWidget);
    expect(find.text('VOORTGANG'), findsOneWidget);
    expect(find.text('Speler (10)'), findsOneWidget);
  });
}
