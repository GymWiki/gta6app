import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vice_codes/l10n/strings.dart';
import 'package:vice_codes/widgets/console_buttons.dart';
import 'package:vice_codes/widgets/theme.dart';

Future<void> pump(WidgetTester t, {required bool ps5, required List<String> code, String lang = 'en', double width = 360, double scale = 1}) async {
  await t.pumpWidget(MaterialApp(
    theme: Vice.theme(),
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 800), textScaler: TextScaler.linear(scale)),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: width - 32, child: ConsoleSequence(dpad: code, ps5: ps5, t: Strings(lang))),
          ),
        ),
      ),
    ),
  ));
}

const _code = ['UP', 'RIGHT', 'DOWN', 'LEFT', 'UP', 'LEFT', 'DOWN', 'RIGHT'];

void main() {
  testWidgets('PS5: open phone (D-pad up), hold L1 + press R1, then the code buttons', (t) async {
    await pump(t, ps5: true, code: _code);
    expect(find.text('Open the phone'), findsOneWidget);
    expect(find.text('Hold L1, then press R1'), findsOneWidget);
    expect(find.text('Enter the code (8 buttons)'), findsOneWidget);
    expect(find.text('L1'), findsOneWidget);
    expect(find.text('R1'), findsOneWidget);
    expect(find.text('LB'), findsNothing);
    // 1 D-pad for "open the phone" + one per code button, in order.
    expect(find.byType(DpadGlyph), findsNWidgets(1 + _code.length));
    final dirs = t.widgetList<DpadGlyph>(find.byType(DpadGlyph)).map((g) => g.direction).toList();
    expect(dirs, ['UP', ..._code]);
    expect(t.widgetList<DpadGlyph>(find.byType(DpadGlyph)).every((g) => g.ps5), isTrue);
    for (var i = 1; i <= _code.length; i++) {
      expect(find.text('$i'), findsWidgets, reason: 'button $i is numbered');
    }
  });

  testWidgets('Xbox: LB + RB and the Xbox-style D-pad', (t) async {
    await pump(t, ps5: false, code: _code);
    expect(find.text('Hold LB, then press RB'), findsOneWidget);
    expect(find.text('LB'), findsOneWidget);
    expect(find.text('RB'), findsOneWidget);
    expect(find.text('L1'), findsNothing);
    expect(t.widgetList<DpadGlyph>(find.byType(DpadGlyph)).every((g) => !g.ps5), isTrue);
  });

  testWidgets('Dutch labels', (t) async {
    await pump(t, ps5: true, code: _code, lang: 'nl');
    expect(find.text('Open de telefoon'), findsOneWidget);
    expect(find.text('Houd L1 vast en druk op R1'), findsOneWidget);
    expect(find.text('Voer de code in (8 knoppen)'), findsOneWidget);
    expect(find.text('HOUD VAST'), findsOneWidget);
    expect(find.text('DRUK'), findsOneWidget);
  });

  testWidgets('long codes are split in balanced rows, nothing overflows (narrow + huge text)', (t) async {
    const ten = ['DOWN', 'UP', 'LEFT', 'UP', 'UP', 'UP', 'UP', 'UP', 'DOWN', 'DOWN'];
    for (final width in [320.0, 360.0, 411.0]) {
      for (final scale in [1.0, 2.0]) {
        await pump(t, ps5: false, code: ten, width: width, scale: scale);
        expect(t.takeException(), isNull, reason: 'width $width scale $scale');
        // The numbers 1..10 are all present; the last row is never a lone button.
        final tens = t.getTopLeft(find.text('10').last).dy;
        final ones = t.getTopLeft(find.text('1').last).dy;
        expect(tens >= ones, isTrue);
      }
    }
  });

  testWidgets('each direction is drawn (all four, both consoles) without errors', (t) async {
    for (final ps5 in [true, false]) {
      await pump(t, ps5: ps5, code: const ['UP', 'RIGHT', 'DOWN', 'LEFT']);
      expect(t.takeException(), isNull);
    }
  });
}
