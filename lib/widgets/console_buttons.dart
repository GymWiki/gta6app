import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'theme.dart';

const _armColor = Color(0xFF2C3156);
const _discColor = Color(0xFF181B33);
const _idleMark = Color(0xFF8A90B8);

/// The physical D-pad with one direction highlighted. PS5: four separate arms with
/// triangles. Xbox: one cross inside a round disc.
class DpadGlyph extends StatelessWidget {
  final String direction; // UP / RIGHT / DOWN / LEFT
  final bool ps5;
  final double size;
  const DpadGlyph({super.key, required this.direction, required this.ps5, this.size = 40});

  @override
  Widget build(BuildContext context) => Semantics(
        label: direction.toLowerCase(),
        excludeSemantics: true,
        child: SizedBox.square(dimension: size, child: CustomPaint(painter: _DpadPainter(direction, ps5))),
      );
}

class _DpadPainter extends CustomPainter {
  final String dir;
  final bool ps5;
  _DpadPainter(this.dir, this.ps5);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final arm = s * 0.32;
    final inset = ps5 ? 0.0 : s * 0.12; // Xbox: the disc shows around the cross
    final gap = ps5 ? s * 0.07 : 0.0; // PS5: arms do not touch in the middle
    final radius = Radius.circular(s * 0.09);

    Rect rect(String d) => switch (d) {
          'UP' => Rect.fromLTRB(c.dx - arm / 2, inset, c.dx + arm / 2, c.dy - gap + (ps5 ? 0 : arm / 2)),
          'DOWN' => Rect.fromLTRB(c.dx - arm / 2, c.dy + gap - (ps5 ? 0 : arm / 2), c.dx + arm / 2, s - inset),
          'LEFT' => Rect.fromLTRB(inset, c.dy - arm / 2, c.dx - gap + (ps5 ? 0 : arm / 2), c.dy + arm / 2),
          _ => Rect.fromLTRB(c.dx + gap - (ps5 ? 0 : arm / 2), c.dy - arm / 2, s - inset, c.dy + arm / 2),
        };

    if (!ps5) {
      canvas.drawCircle(c, s / 2 - s * 0.02, Paint()..color = _discColor);
      canvas.drawCircle(
        c,
        s / 2 - s * 0.02,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.04
          ..color = Vice.muted.withValues(alpha: 0.5),
      );
    }

    final base = Paint()..color = _armColor;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..color = Vice.muted.withValues(alpha: 0.55);
    final hot = Paint()..color = Vice.cyan;
    const dirs = ['UP', 'RIGHT', 'DOWN', 'LEFT'];

    for (final d in dirs) {
      final rr = RRect.fromRectAndRadius(rect(d), radius);
      canvas.drawRRect(rr, base);
      canvas.drawRRect(rr, edge);
    }
    final pressed = RRect.fromRectAndRadius(rect(dir), radius);
    canvas.drawRRect(pressed, hot);

    // Triangle on every arm, pointing outwards.
    for (final d in dirs) {
      final r = rect(d);
      final t = s * 0.085;
      final p = r.center + switch (d) {
        'UP' => Offset(0, -(r.height * 0.5 - t * 1.6).clamp(0.0, s)),
        'DOWN' => Offset(0, (r.height * 0.5 - t * 1.6).clamp(0.0, s)),
        'LEFT' => Offset(-(r.width * 0.5 - t * 1.6).clamp(0.0, s), 0),
        _ => Offset((r.width * 0.5 - t * 1.6).clamp(0.0, s), 0),
      };
      final path = Path();
      switch (d) {
        case 'UP':
          path
            ..moveTo(p.dx, p.dy - t)
            ..lineTo(p.dx - t, p.dy + t * 0.7)
            ..lineTo(p.dx + t, p.dy + t * 0.7);
        case 'DOWN':
          path
            ..moveTo(p.dx, p.dy + t)
            ..lineTo(p.dx - t, p.dy - t * 0.7)
            ..lineTo(p.dx + t, p.dy - t * 0.7);
        case 'LEFT':
          path
            ..moveTo(p.dx - t, p.dy)
            ..lineTo(p.dx + t * 0.7, p.dy - t)
            ..lineTo(p.dx + t * 0.7, p.dy + t);
        default:
          path
            ..moveTo(p.dx + t, p.dy)
            ..lineTo(p.dx - t * 0.7, p.dy - t)
            ..lineTo(p.dx - t * 0.7, p.dy + t);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = d == dir ? const Color(0xFF071018) : _idleMark);
    }
  }

  @override
  bool shouldRepaint(covariant _DpadPainter old) => old.dir != dir || old.ps5 != ps5;
}

/// A shoulder button: L1/R1 on PlayStation, LB/RB on Xbox.
class BumperGlyph extends StatelessWidget {
  final String label;
  final bool ps5;
  final double size;
  const BumperGlyph({super.key, required this.label, required this.ps5, this.size = 40});

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        excludeSemantics: true,
        child: Container(
          width: size * 1.45,
          height: size * 0.82,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _armColor,
            borderRadius: BorderRadius.circular(ps5 ? size * 0.16 : size * 0.41),
            border: Border.all(color: Vice.cyan, width: 1.6),
          ),
          child: Text(label, style: TextStyle(color: Vice.text, fontWeight: FontWeight.w900, fontSize: size * 0.4, letterSpacing: 0.5)),
        ),
      );
}

/// The complete input for a cheat on one console, in the order it is pressed:
/// 1) open the phone, 2) hold the left shoulder button and press the right one,
/// 3) the code itself as D-pad buttons.
class ConsoleSequence extends StatelessWidget {
  final List<String> dpad;
  final bool ps5;
  final Strings t;
  final double keySize;
  const ConsoleSequence({super.key, required this.dpad, required this.ps5, required this.t, this.keySize = 36});

  @override
  Widget build(BuildContext context) {
    final left = ps5 ? 'L1' : 'LB';
    final right = ps5 ? 'R1' : 'RB';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Steps 1 and 2 are short: side by side, wrapping onto two lines on a narrow screen.
      Wrap(spacing: 24, runSpacing: 10, children: [
        _Step(
          number: 1,
          title: t.stepOpenPhone,
          child: DpadGlyph(direction: 'UP', ps5: ps5, size: keySize),
        ),
        _Step(
          number: 2,
          title: ps5 ? t.stepHoldPs5 : t.stepHoldXbox,
          // Fixed-size button icons: their labels keep a bounded text scale at huge system fonts.
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _Labeled(label: t.hold, child: BumperGlyph(label: left, ps5: ps5, size: keySize)),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
                child: Text('+', style: TextStyle(color: Vice.muted, fontSize: keySize * 0.5, fontWeight: FontWeight.w900)),
              ),
              _Labeled(label: t.press, child: BumperGlyph(label: right, ps5: ps5, size: keySize)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      _Step(
        number: 3,
        title: t.stepEnterCode(dpad.length),
        child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2, child: _CodeButtons(dpad: dpad, ps5: ps5, size: keySize)),
      ),
    ]);
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(color: Vice.muted, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 3),
        child,
      ]);
}

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final Widget child;
  const _Step({required this.number, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Vice.pink.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: Vice.pink)),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Text('$number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ),
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Vice.muted, fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              child,
            ]),
          ),
        ]);
}

/// The code buttons, numbered, in balanced rows (never one orphan button on the last row).
class _CodeButtons extends StatelessWidget {
  final List<String> dpad;
  final bool ps5;
  final double size;
  const _CodeButtons({required this.dpad, required this.ps5, required this.size});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const gap = 6.0;
        final n = dpad.length;
        final maxPerRow = ((c.maxWidth + gap) / (size + gap)).floor().clamp(1, n);
        final rows = (n / maxPerRow).ceil();
        final perRow = (n / rows).ceil();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var start = 0; start < n; start += perRow)
            Padding(
              padding: EdgeInsets.only(top: start == 0 ? 0 : 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = start; i < start + perRow && i < n; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == start ? 0 : gap),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      DpadGlyph(direction: dpad[i], ps5: ps5, size: size),
                      const SizedBox(height: 2),
                      Text('${i + 1}', style: const TextStyle(color: Vice.muted, fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
              ]),
            ),
        ]);
      });
}
