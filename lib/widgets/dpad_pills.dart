import 'package:flutter/material.dart';

import '../models/content.dart';
import 'theme.dart';

const _arrows = {'UP': '↑', 'RIGHT': '→', 'DOWN': '↓', 'LEFT': '←'};

/// Renders a cheat code: big neon arrow keys, a typed string, or the TBA badge.
class DpadPills extends StatelessWidget {
  final CheatCode? code;
  const DpadPills({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final seq = code?.dpad;
    final text = code?.text;
    if (text != null) {
      return Semantics(
        label: 'Code: $text',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Vice.cyan.withValues(alpha: 0.10),
            border: Border.all(color: Vice.cyan, width: 1.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: Vice.cyan, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
      );
    }
    if (seq == null || seq.isEmpty) {
      return Semantics(
        label: 'Code to be announced, community hunting',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Vice.gold.withValues(alpha: 0.08),
            border: Border.all(color: Vice.gold.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.search_rounded, size: 18, color: Vice.gold),
            SizedBox(width: 8),
            Flexible(
              child: Text('CODE TBA — COMMUNITY HUNTING',
                  style: TextStyle(color: Vice.gold, fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.8)),
            ),
          ]),
        ),
      );
    }
    return Semantics(
      label: 'Code: ${seq.map((e) => e.toLowerCase()).join(', ')}',
      excludeSemantics: true,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final d in seq)
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Vice.cyan.withValues(alpha: 0.10),
                border: Border.all(color: Vice.cyan, width: 1.6),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Vice.cyan.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: -3)],
              ),
              child: Text(_arrows[d] ?? '?',
                  style: const TextStyle(color: Vice.cyan, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
            ),
        ],
      ),
    );
  }
}
