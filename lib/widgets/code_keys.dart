import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/content.dart';
import 'theme.dart';

const _arrowIcons = {
  'UP': Icons.arrow_upward_rounded,
  'RIGHT': Icons.arrow_forward_rounded,
  'DOWN': Icons.arrow_downward_rounded,
  'LEFT': Icons.arrow_back_rounded,
};

const _arrowGlyphs = {'UP': '↑', 'RIGHT': '→', 'DOWN': '↓', 'LEFT': '←'};

/// Plain-text form of a code for the clipboard / screen readers.
String codeAsText(CheatCode code) => code.text ?? code.dpad!.map((d) => _arrowGlyphs[d] ?? d).join(' ');

/// A cheat code drawn as a row of keys. [size] is the key size in dp; keys stay in one
/// row and scale down if the row is too narrow (10-key codes on small phones).
class CodeKeys extends StatelessWidget {
  final CheatCode? code;
  final Strings t;
  final double size;

  /// Show the "CODE TBA" badge when there is no code.
  final bool showTba;
  const CodeKeys({super.key, required this.code, required this.t, this.size = 24, this.showTba = true});

  @override
  Widget build(BuildContext context) {
    final c = code;
    if (c == null) return showTba ? _Tba(t: t, compact: size < 30) : const SizedBox.shrink();
    final label = t.codeLabel(c.text ?? c.dpad!.map((e) => e.toLowerCase()).join(', '));
    if (c.text != null) {
      return Semantics(
        label: label,
        excludeSemantics: true,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: size * 0.5, vertical: size * 0.15),
          decoration: BoxDecoration(color: Vice.cyan.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(c.text!,
              style: TextStyle(
                  color: Vice.cyan, fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: size * 0.6, letterSpacing: 1)),
        ),
      );
    }
    final dirs = c.dpad!;
    const gap = 3.0;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < dirs.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            _Key(direction: dirs[i], size: size),
          ],
        ]),
      ),
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
          color: Vice.cyan.withValues(alpha: 0.14),
          border: Border.all(color: Vice.cyan.withValues(alpha: 0.85), width: 1.2),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Icon(_arrowIcons[direction] ?? Icons.help_outline_rounded, color: Vice.cyan, size: size * 0.7),
      );
}

class _Tba extends StatelessWidget {
  final Strings t;
  final bool compact;
  const _Tba({required this.t, required this.compact});

  @override
  Widget build(BuildContext context) => Semantics(
        label: t.codeTbaLabel,
        excludeSemantics: true,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_rounded, size: compact ? 14 : 18, color: Vice.gold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(t.codeTba,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Vice.gold, fontWeight: FontWeight.w800, fontSize: compact ? 12 : 13.5, letterSpacing: 0.6)),
          ),
        ]),
      );
}
