import 'package:flutter/material.dart';
import 'theme.dart';

const _arrows = {'UP': '↑', 'RIGHT': '→', 'DOWN': '↓', 'LEFT': '←'};

/// Big neon arrow keys — readable from across the room.
class DpadPills extends StatelessWidget {
  final List<String>? sequence;
  const DpadPills({super.key, required this.sequence});

  @override
  Widget build(BuildContext context) {
    final seq = sequence;
    if (seq == null || seq.isEmpty) {
      return Semantics(
        label: 'Code to be announced, community hunting',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Vice.gold.withOpacity(0.08),
            border: Border.all(color: Vice.gold.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
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
                color: Vice.cyan.withOpacity(0.10),
                border: Border.all(color: Vice.cyan, width: 1.6),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Vice.cyan.withOpacity(0.3), blurRadius: 10, spreadRadius: -3)],
              ),
              child: Text(_arrows[d] ?? '?',
                  style: const TextStyle(color: Vice.cyan, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
            ),
        ],
      ),
    );
  }
}
