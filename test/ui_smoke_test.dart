import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vice_codes/providers/app_state.dart';
import 'package:vice_codes/screens/home_shell.dart';
import 'package:vice_codes/services/cheat_repository.dart';
import 'package:vice_codes/widgets/ad_banner_widget.dart';
import 'package:vice_codes/widgets/cheat_row.dart';
import 'package:vice_codes/widgets/filter_chips_row.dart';
import 'package:vice_codes/widgets/theme.dart';

/// Medium_Phone_API_36.1: 1080x2400 @ 420dpi = 411x914dp, with status bar + gesture bar.
const mediumPhone = Size(411, 914);

Future<AppState> pumpApp(
  WidgetTester tester, {
  String lang = 'en',
  double textScale = 1.0,
  Size size = mediumPhone,
  bool disableAnimations = false,
  Map<String, Object> prefs = const {'platformChosen': true, 'bannerDismissed': true},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 56, bottom: 40);
  tester.view.viewPadding = const FakeViewPadding(top: 56, bottom: 40);
  addTearDown(tester.view.reset);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);

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
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: disableAnimations),
        child: child!,
      ),
      home: const HomeShell(),
    ),
  ));
  await tester.pumpAndSettle();
  return state;
}

/// Like testWidgets, but on a platform without ads (no ad plugin/timers in tests); a 50dp
/// placeholder stands in for the banner strip so the layout is measured honestly.
void uiTest(String description, Future<void> Function(WidgetTester tester) body) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    AdBannerWidget.debugPlaceholderHeight = 50;
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
      AdBannerWidget.debugPlaceholderHeight = null;
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Types into the search field and waits for the debounce.
Future<void> typeQuery(WidgetTester tester, String q) async {
  await tester.enterText(find.byType(TextField), q);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}

Future<void> tapChip(WidgetTester tester, String label) async {
  final scrollable = find.descendant(of: find.byType(FilterChipsRow), matching: find.byType(Scrollable)).first;
  // Swipe the chip row until the chip can actually be tapped (a user does the same).
  for (var i = 0; i < 20 && find.text(label).hitTestable().evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(-150, 0));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(label).hitTestable());
  await tester.pumpAndSettle();
}

/// Scrolls the cheats list until [finder] is built and visible, like a user would.
Future<void> showInList(WidgetTester tester, Finder finder) async {
  final list = find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(finder, 150, scrollable: list, maxScrolls: 200);
  await tester.pumpAndSettle();
}

/// Scroll a row into view (clear of the pinned header) and tap it, like a user.
Future<void> tapRow(WidgetTester tester, String name) async {
  // A title can appear twice (quick strip + row): the row is the one inside the list rows.
  final title = find.descendant(of: find.byType(CheatRow), matching: find.text(name));
  await showInList(tester, title);
  await tester.ensureVisible(title.first);
  await tester.drag(find.byType(CustomScrollView), const Offset(0, 150));
  await tester.pumpAndSettle();
  await tester.tap(title.first);
  await tester.pumpAndSettle();
}

/// The ad strip (placeholder in tests) as a rect.
Rect adRect(WidgetTester tester) => tester.getRect(find.ancestor(of: find.text('AD'), matching: find.byType(Container)).first);

Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, 20000));
  await tester.pumpAndSettle();
}

List<CheatRow> visibleRows(WidgetTester tester, {required double bottom}) {
  final rows = <CheatRow>[];
  for (final e in find.byType(CheatRow).evaluate()) {
    final r = tester.getRect(find.byWidget(e.widget));
    if (r.top >= 0 && r.bottom <= bottom + 0.5) rows.add(e.widget as CheatRow);
  }
  return rows;
}

void main() {
  group('acceptance criteria (Medium_Phone_API_36.1, 411x914dp)', () {
    uiTest('at least 7 cheats are fully visible without scrolling, each with its code', (tester) async {
      await pumpApp(tester);
      final rows = visibleRows(tester, bottom: adRect(tester).top);
      debugPrint('visible rows: ${rows.length}');
      expect(rows.length, greaterThanOrEqualTo(7));
      // Code is in the list itself: every row shows keys (arrow icons) without opening anything.
      for (final r in rows.take(7)) {
        final keys = find.descendant(of: find.byWidget(r), matching: find.byIcon(Icons.arrow_upward_rounded));
        final all = find.descendant(of: find.byWidget(r), matching: find.byType(Icon));
        expect(all.evaluate().length, greaterThan(5), reason: 'category icon, status, star + code keys');
        expect(keys.evaluate().isNotEmpty || find.descendant(of: find.byWidget(r), matching: find.byIcon(Icons.arrow_downward_rounded)).evaluate().isNotEmpty, isTrue);
      }
    });

    uiTest('the sticky zone is small: the first row starts in the top 25% of the screen', (tester) async {
      await pumpApp(tester);
      final firstRowTop = tester.getTopLeft(find.byType(CheatRow).first).dy;
      debugPrint('first row top: $firstRowTop of ${mediumPhone.height}');
      expect(firstRowTop / mediumPhone.height, lessThan(0.25));
    });

    uiTest('header is 56dp, search 48dp, chip row 48dp, nav bar 56dp', (tester) async {
      await pumpApp(tester);
      expect(tester.getSize(find.text('VICE CODES').first).height, lessThan(56));
      final header = find.ancestor(of: find.text('VICE CODES'), matching: find.byType(SizedBox)).first;
      expect(tester.getSize(header).height, 56);
      expect(tester.getSize(find.byType(TextField)).height, 48);
      final chipRow = find.ancestor(of: find.text('All'), matching: find.byType(SizedBox)).first;
      expect(tester.getSize(chipRow).height, 48);
      final nav = tester.getSize(find.byType(NavigationBar)).height;
      expect(nav, 56 + 20, reason: '56dp bar + 20dp gesture inset');
    });

    uiTest('every tappable control is at least 48x48dp', (tester) async {
      await pumpApp(tester);
      Size sizeOf(Finder f) => tester.getSize(f.first);
      // Icon buttons carry the tooltip; their own size is the tap target.
      for (final tip in ['How it works', 'Add to favorites']) {
        final b = find.byWidgetPredicate((w) => w is IconButton && w.tooltip == tip);
        expect(sizeOf(b).height, greaterThanOrEqualTo(48), reason: tip);
        expect(sizeOf(b).width, greaterThanOrEqualTo(48), reason: tip);
      }
      // Custom controls: the GestureDetector around the label is the tap target.
      for (final label in ['PS5', 'XBOX', 'With code', 'All', 'Favorites']) {
        final box = find.ancestor(of: find.text(label), matching: find.byType(GestureDetector)).first;
        expect(tester.getSize(box).height, greaterThanOrEqualTo(48), reason: label);
      }
      // Inside an expanded row: copy + unlock buttons.
      await tester.tap(find.byType(CheatRow).first);
      await tester.pumpAndSettle();
      for (final label in ['Copy code', 'Mark as unlocked']) {
        expect(tester.getSize(find.ancestor(of: find.text(label), matching: find.bySubtype<ButtonStyleButton>()).first).height, greaterThanOrEqualTo(48));
      }
      // Nav destinations.
      expect(tester.getSize(find.byType(NavigationDestination).first).height, greaterThanOrEqualTo(48));
    });

    uiTest('the ad strip is outside the list: no overlap, the last row scrolls clear of it', (tester) async {
      await pumpApp(tester);
      final listBottom = tester.getRect(find.byType(CustomScrollView)).bottom;
      final adTop = adRect(tester).top;
      final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
      expect(listBottom, lessThanOrEqualTo(adTop), reason: 'list viewport ends where the ad starts');
      expect(adTop + 50, lessThanOrEqualTo(navTop + 0.5), reason: 'ad sits directly above the nav bar');
      // Scroll to the very end: the last collapsed section header is fully above the ad.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      expect(find.textContaining('No code known yet'), findsOneWidget);
      expect(tester.getRect(find.textContaining('No code known yet')).bottom, lessThanOrEqualTo(adTop));
    });

    uiTest('finding a common cheat takes at most 2 actions', (tester) async {
      final s = await pumpApp(tester);
      // 1) type: one action, instant results.
      await typeQuery(tester, 'geld');
      expect(s.view.mainCheats.first.id, 'player_250k');
      // 2) favorite once, then it is on top of the list (0 actions to find it afterwards).
      await tester.tap(find.byTooltip('Add to favorites').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(s.showQuickStrip, isTrue);
      expect(find.text('FAVORITES'), findsOneWidget);
    });

    uiTest('scrolling stays smooth: the list is lazy (only a handful of rows are built)', (tester) async {
      await pumpApp(tester);
      s() => find.byType(CheatRow).evaluate().length;
      expect(s(), lessThan(20), reason: '61 cheats but only the visible ones (plus a small cache) exist as widgets');
    });
  });

  group('renders without overflow', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final lang in ['en', 'nl']) {
        uiTest('small phone 360x640, text scale $scale, $lang', (tester) async {
          final s = await pumpApp(tester, lang: lang, textScale: scale, size: const Size(360, 640));
          expect(find.text('VICE CODES'), findsWidgets);
          s.toggleFavorite('player_250k');
          await tester.pumpAndSettle();
          await tester.tap(find.byType(CheatRow).first);
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip(s.t.infoTooltip));
          await tester.pumpAndSettle();
          expect(find.text(s.t.infoTitle), findsOneWidget);
          await tester.binding.handlePopRoute(); // Android back closes the sheet
          await tester.pumpAndSettle();
          expect(find.text(s.t.infoTitle), findsNothing, reason: 'sheet closed');
          await openTab(tester, s.t.tabTracker);
          expect(find.textContaining(' / 61'), findsOneWidget, reason: 'tracker tab is showing');
          await openTab(tester, s.t.tabSettings);
          await openTab(tester, s.t.tabCheats);
          expect(tester.takeException(), isNull);
        });
      }
    }

    uiTest('landscape', (tester) async {
      await pumpApp(tester, size: const Size(740, 360));
      expect(tester.takeException(), isNull);
    });

    uiTest('with "remove animations" on: opening, switching and closing rows does not break layout', (tester) async {
      final s = await pumpApp(tester, disableAnimations: true);
      await tester.tap(find.text('\$250,000'));
      await tester.pumpAndSettle();
      expect(find.text('HOW TO UNLOCK'), findsOneWidget);
      await tapRow(tester, 'Raise Heat Level');
      expect(find.text('HOW TO UNLOCK'), findsOneWidget);
      await tapRow(tester, 'Raise Heat Level');
      expect(find.text('HOW TO UNLOCK'), findsNothing);
      expect(s.focusedId, isNull);
      expect(tester.takeException(), isNull);
    });

    uiTest('empty state at large text', (tester) async {
      await pumpApp(tester, textScale: 2.0, size: const Size(360, 640));
      await typeQuery(tester, 'zzzz-nothing');
      expect(find.textContaining('No result for'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('search', () {
    uiTest('filters while typing (debounced), highlights, and has a clear button', (tester) async {
      final s = await pumpApp(tester);
      await tester.enterText(find.byType(TextField), 'boomazoom');
      expect(s.query, '', reason: 'debounced: not applied on the very first frame');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(s.query, 'boomazoom');
      expect(s.view.all.map((c) => c.name), ['Maibatsu Boomazoom']);
      expect(find.byType(RichText).evaluate().isNotEmpty, isTrue);

      await tester.tap(find.byTooltip(s.t.clearSearch));
      await tester.pumpAndSettle();
      expect(s.query, '');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    });

    uiTest('synonyms and typos work from the UI', (tester) async {
      final s = await pumpApp(tester);
      await typeQuery(tester, 'politie');
      expect(s.view.mainCheats.map((c) => c.id), contains('player_raise_wanted_level'));
      await typeQuery(tester, 'wantd');
      expect(s.view.mainCheats.map((c) => c.id), contains('player_raise_wanted_level'));
    });

    uiTest('results with no code open the "no code yet" section automatically', (tester) async {
      final s = await pumpApp(tester);
      await typeQuery(tester, 'drunk');
      expect(s.view.mainCheats, isEmpty);
      expect(find.text('Drunk'), findsWidgets, reason: 'visible without tapping the section');
    });

    uiTest('empty state: no result for X, clear filters, report a missing cheat', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final s = await pumpApp(tester);
      await typeQuery(tester, 'zzzz-nothing');
      expect(find.text('No result for "zzzz-nothing"'), findsOneWidget);
      expect(find.text('Missing a cheat? Report it'), findsOneWidget);
      // The mail plugin is not available in tests: the address is copied and a message is shown.
      await tester.tap(find.text('Missing a cheat? Report it'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text(s.t.reportCopied), findsOneWidget);
      await tester.tap(find.text(s.t.clearFilters));
      await tester.pumpAndSettle();
      expect(s.query, '');
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
      expect(s.view.mainCheats.length, 18);
    });

    uiTest('the keyboard does not open by itself', (tester) async {
      await pumpApp(tester);
      expect(tester.testTextInput.isVisible, isFalse);
    });
  });

  group('filters', () {
    uiTest('"With code" is on by default; the collapsed section lists the rest and expands', (tester) async {
      final s = await pumpApp(tester);
      expect(s.withCodeOnly, isTrue);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      expect(find.text('No code known yet (43)'), findsOneWidget);
      expect(find.text('Drunk'), findsNothing);
      await tester.tap(find.text('No code known yet (43)'));
      await tester.pumpAndSettle();
      expect(s.noCodeExpanded, isTrue);
      expect(find.text('CODE TBA — COMMUNITY HUNTING'), findsWidgets);
    });

    uiTest('toggling "With code" off shows everything in one list', (tester) async {
      final s = await pumpApp(tester);
      await tapChip(tester, 'With code');
      expect(s.withCodeOnly, isFalse);
      expect(s.view.mainCheats.length, 61);
      expect(find.textContaining('No code known yet'), findsNothing);
    });

    uiTest('category chips filter, favorites chip shows an empty hint', (tester) async {
      final s = await pumpApp(tester);
      await tapChip(tester, 'Combat');
      expect(s.category, 'combat');
      expect(s.view.all.every((c) => c.categoryId == 'combat'), isTrue);
      await tapChip(tester, 'Favorites');
      expect(s.category, kFavoritesScope);
      expect(find.text(s.t.noFavorites), findsOneWidget);
    });

    uiTest('sticky category headers appear when the filter is All', (tester) async {
      await pumpApp(tester);
      expect(find.text('PLAYER · 5'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(find.textContaining(' · '), findsWidgets, reason: 'a pinned category header stays on screen while scrolling');
    });
  });

  group('rows', () {
    uiTest('tap expands inline: description, big code, copy + unlock; only one open at a time', (tester) async {
      final s = await pumpApp(tester);
      final first = s.view.mainCheats[0];
      final second = s.view.mainCheats[1];
      expect(find.text(first.unlockRequirement), findsNothing);
      await tester.tap(find.text(first.name));
      await tester.pumpAndSettle();
      expect(find.text(first.unlockRequirement), findsOneWidget);
      expect(find.text('Copy code'), findsOneWidget);
      expect(find.text('Mark as unlocked'), findsOneWidget);
      expect(find.text('HOW TO UNLOCK'), findsOneWidget);

      await tapRow(tester, second.name); // the open row is tall: scroll like a user
      expect(find.text('HOW TO UNLOCK'), findsOneWidget, reason: 'the first row closed when the second opened');
      expect(find.text(first.unlockRequirement), findsNothing);
      expect(find.text(second.unlockRequirement), findsOneWidget);
    });

    uiTest('expanded row shows the exact console buttons, and they follow the platform', (tester) async {
      final s = await pumpApp(tester);
      await tester.tap(find.text('\$250,000'));
      await tester.pumpAndSettle();
      expect(find.text('Hold L1, then press R1'), findsOneWidget);
      expect(find.text('L1'), findsOneWidget);
      expect(find.text('R1'), findsOneWidget);
      await tester.tap(find.text('XBOX'));
      await tester.pumpAndSettle();
      expect(s.platform, 'xbox');
      expect(find.text('Hold LB, then press RB'), findsOneWidget);
      expect(find.text('LB'), findsOneWidget);
      expect(find.text('L1'), findsNothing);
    });

    uiTest('closing a tall row above the tapped one does not make the list jump', (tester) async {
      final s = await pumpApp(tester);
      await tester.tap(find.text(s.view.mainCheats[0].name));
      await tester.pumpAndSettle();
      final target = s.view.mainCheats[4].name; // far enough down to have room above after collapsing
      final title = find.descendant(of: find.byType(CheatRow), matching: find.text(target));
      await showInList(tester, title);
      await tester.ensureVisible(title.first);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 150));
      await tester.pumpAndSettle();
      final yBefore = tester.getTopLeft(title.first).dy;
      await tester.tap(title.first);
      await tester.pump(); // the very next frame: the other row already collapsed, no flash
      expect(title, findsWidgets, reason: 'the tapped row is still on screen in that frame');
      expect(tester.getTopLeft(title.first).dy, closeTo(yBefore, 2), reason: 'the tapped row stays where the finger is');
      await tester.pumpAndSettle();
      expect(s.focusedId, s.view.mainCheats[4].id);
      expect(find.text('HOW TO UNLOCK'), findsOneWidget);
    });

    uiTest('copy code puts the code on the clipboard with haptics and a snackbar', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final s = await pumpApp(tester);
      await tester.tap(find.text('\$250,000'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy code'));
      await tester.pumpAndSettle();
      expect(copied, '↑ → ↓ ← ↑ ← ↓ →');
      expect(find.text(s.t.codeCopied), findsOneWidget);
    });

    uiTest('unlock lives in the expanded part and syncs with the tracker', (tester) async {
      final s = await pumpApp(tester);
      await tester.tap(find.text('\$250,000'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as unlocked'));
      await tester.pumpAndSettle();
      expect(s.unlockedIds, {'player_250k'});
      expect(find.text('Unlocked'), findsOneWidget, reason: 'the button now says Unlocked');
      await openTab(tester, s.t.tabTracker);
      expect(find.text('1 / 61'), findsOneWidget);
      expect(find.text('To-Do (60)'), findsOneWidget);
    });

    uiTest('favorite star stays in the row and pins the cheat in the quick strip', (tester) async {
      final s = await pumpApp(tester);
      expect(s.showQuickStrip, isFalse);
      await tester.tap(find.byTooltip('Add to favorites').first);
      await tester.pumpAndSettle();
      expect(s.favoriteIds.length, 1);
      expect(find.text('FAVORITES'), findsOneWidget);
      await typeQuery(tester, 'boomazoom');
      expect(find.text('FAVORITES'), findsNothing, reason: 'the strip hides while searching');
    });

    uiTest('opening a cheat records it under RECENT', (tester) async {
      final s = await pumpApp(tester);
      await tester.tap(find.text('Max Ammo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Max Ammo')); // collapse
      await tester.pumpAndSettle();
      expect(s.recentIds, ['combat_max_ammo']);
      await scrollToTop(tester);
      expect(find.text('RECENT'), findsOneWidget);
    });

    uiTest('status is a small icon, explained in the info sheet', (tester) async {
      final s = await pumpApp(tester);
      expect(find.byIcon(Icons.help_outline_rounded), findsWidgets);
      expect(find.text('UNVERIFIED'), findsNothing, reason: 'no big badge in the list');
      await tester.tap(find.byTooltip(s.t.infoTooltip));
      await tester.pumpAndSettle();
      expect(find.text(s.t.legend), findsOneWidget);
      expect(find.textContaining(s.t.statusVerifiedInfo, findRichText: true), findsOneWidget);
    });
  });

  group('first start and platform', () {
    uiTest('asks once which console you play on and remembers the answer', (tester) async {
      final s = await pumpApp(tester, prefs: const {});
      expect(find.text('Which console do you play on?'), findsOneWidget);
      await tester.tap(find.text('XBOX').last);
      await tester.pumpAndSettle();
      expect(s.platform, 'xbox');
      expect(find.text('Which console do you play on?'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selectedPlatform'), 'xbox');
      expect(prefs.getBool('platformChosen'), isTrue);
    });

    uiTest('dismissing the question keeps PS5 and does not ask again', (tester) async {
      final s = await pumpApp(tester, prefs: const {});
      await tester.tapAt(const Offset(10, 100));
      await tester.pumpAndSettle();
      expect(s.platform, 'ps5');
      expect(s.platformChosen, isTrue);
    });

    uiTest('first-start phone hint banner is dismissible and gone for good', (tester) async {
      final s = await pumpApp(tester, prefs: const {'platformChosen': true});
      expect(find.text('Open Phone (↑) + Hold L1 & R1'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Open Phone (↑) + Hold L1 & R1'), findsNothing);
      expect(s.bannerDismissed, isTrue);
      expect(s.repo.loadUserState().bannerDismissed, isTrue);
    });

    uiTest('info sheet explains both platforms and holds the story note', (tester) async {
      final s = await pumpApp(tester);
      await tester.tap(find.byTooltip(s.t.infoTooltip));
      await tester.pumpAndSettle();
      expect(find.textContaining('hold L1'), findsOneWidget);
      expect(find.textContaining('hold LB'), findsOneWidget);
      expect(find.textContaining('Activating cheats disables Trophies/Achievements'), findsOneWidget);
    });

    uiTest('platform switch changes the platform and the hint, and survives a restart', (tester) async {
      final s = await pumpApp(tester, prefs: const {'platformChosen': true});
      await tester.tap(find.text('XBOX'));
      await tester.pumpAndSettle();
      expect(s.platform, 'xbox');
      expect(find.text('Open Phone (↑) + Hold LB & RB'), findsOneWidget);
      final again = AppState(s.repo, s.data);
      expect(again.platform, 'xbox');
    });
  });

  group('tabs and navigation', () {
    uiTest('filter state and scroll position survive switching tabs', (tester) async {
      final s = await pumpApp(tester);
      await tapChip(tester, 'Combat');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
      await tester.pumpAndSettle();
      final before = tester.state<ScrollableState>(find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first).position.pixels;
      await openTab(tester, s.t.tabTracker);
      await openTab(tester, s.t.tabCheats);
      final after = tester.state<ScrollableState>(find.descendant(of: find.byType(CustomScrollView), matching: find.byType(Scrollable)).first).position.pixels;
      expect(s.category, 'combat');
      expect(after, before);
    });

    uiTest('system back returns to the first tab before leaving the app', (tester) async {
      final s = await pumpApp(tester);
      await openTab(tester, s.t.tabSettings);
      expect(find.text(s.t.refreshNow), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('With code'), findsOneWidget, reason: 'back from settings lands on the cheats tab');
    });

    uiTest('settings: the "collapse cheats without a code" switch controls the list', (tester) async {
      final s = await pumpApp(tester);
      await openTab(tester, s.t.tabSettings);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(s.withCodeOnly, isFalse);
      await openTab(tester, s.t.tabCheats);
      expect(s.view.noCode, isEmpty);
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

    uiTest('refresh without a configured URL explains itself and does not crash', (tester) async {
      final s = await pumpApp(tester);
      await openTab(tester, s.t.tabSettings);
      await tester.tap(find.text(s.t.refreshNow));
      await tester.pumpAndSettle();
      expect(find.text(s.t.notConfigured), findsOneWidget);
    });

    uiTest('progress and favorites survive a restart', (tester) async {
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
  });

  group('language', () {
    uiTest('Dutch UI follows the device language', (tester) async {
      await pumpApp(tester, lang: 'nl', prefs: const {'platformChosen': true});
      expect(find.text('Open telefoon (↑) + houd L1 & R1 ingedrukt'), findsOneWidget);
      expect(find.text('VOORTGANG'), findsOneWidget);
      expect(find.text('Met code'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pumpAndSettle();
      expect(find.text('Nog geen code bekend (43)'), findsOneWidget);
    });
  });
}
