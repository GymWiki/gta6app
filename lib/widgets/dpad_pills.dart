import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/content.dart';
import 'theme.dart';

const _arrows = {
  'UP': Icons.arrow_upward_rounded,
  'RIGHT': Icons.arrow_forward_rounded,
  'DOWN': Icons.arrow_downward_rounded,
  'LEFT': Icons.arrow_back_rounded,
};

/// Renders a cheat code: big neon arrow keys, a typed string, or the TBA badge.
class DpadPills extends StatelessWidget {
  final CheatCode? code;
  final Strings t;
  const DpadPills({super.key, required this.code, required this.t});

  @override
  Widget build(BuildContext context) {
    final seq = code?.dpad;
    final text = code?.text;
    if (text != null) {
      return Semantics(
        label: t.codeLabel(text),
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Vice.cyan.withValues(alpha: 0.10),
            border: Border.all(color: Vice.cyan, width: 1.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(text,
              style: const TextStyle(color: Vice.cyan, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
      );
    }
    if (seq == null || seq.isEmpty) {
      return Semantics(
        label: t.codeTbaLabel,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Vice.gold.withValues(alpha: 0.08),
            border: Border.all(color: Vice.gold.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.search_rounded, size: 18, color: Vice.gold),
            const SizedBox(width: 8),
            Flexible(
              child: Text(t.codeTba,
                  style: const TextStyle(color: Vice.gold, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.8)),
            ),
          ]),
        ),
      );
    }
    return Semantics(
      label: t.codeLabel(seq.map((e) => e.toLowerCase()).join(', ')),
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, c) {
        const gap = 5.0;
        final n = seq.length;
        // One row if the keys stay comfortably large (>= 38), otherwise balanced rows of 44.
        final fit = (c.maxWidth - (n - 1) * gap) / n;
        late final double size;
        late final int perRow;
        if (fit >= 38) {
          size = fit.clamp(38, 44).toDouble();
          perRow = n;
        } else {
          size = 44;
          var rows = 1;
          while (((n / rows).ceil()) * (size + gap) - gap > c.maxWidth) {
            rows++;
          }
          perRow = (n / rows).ceil();
        }
        final rows = <List<String>>[
          for (var i = 0; i < n; i += perRow) seq.sublist(i, i + perRow > n ? n : i + perRow),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var r = 0; r < rows.length; r++)
              Padding(
                padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < rows[r].length; i++)
                    Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : gap),
                      child: _Key(direction: rows[r][i], size: size),
                    ),
                ]),
              ),
          ],
        );
      }),
    );
  }
}

class _Key extends StatelessWidget {
  final String direction;
  final double size;
  const _Key({required this.direction, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Vice.cyan.withValues(alpha: 0.10),
          border: Border.all(color: Vice.cyan, width: 1.6),
          borderRadius: BorderRadius.circular(size / 3),
          boxShadow: [BoxShadow(color: Vice.cyan.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: -3)],
        ),
        child: Icon(_arrows[direction] ?? Icons.help_outline_rounded, color: Vice.cyan, size: size * 0.64),
      );
}
