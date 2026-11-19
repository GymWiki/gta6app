import 'package:flutter/material.dart';
import 'theme.dart';

const _arrows = {'UP': '↑', 'RIGHT': '→', 'DOWN': '↓', 'LEFT': '←'};

class DpadPills extends StatelessWidget {
  final List<String>? sequence;
  const DpadPills({super.key, required this.sequence});

  @override
  Widget build(BuildContext context) {
    final seq = sequence;
    if (seq == null || seq.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Vice.muted),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('CODE TBA — COMMUNITY HUNTING',
            style: TextStyle(color: Vice.muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8)),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final d in seq)
          Semantics(
            label: d.toLowerCase(),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Vice.cyan.withOpacity(0.12),
                border: Border.all(color: Vice.cyan, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_arrows[d] ?? '?',
                  style: const TextStyle(color: Vice.cyan, fontSize: 24, fontWeight: FontWeight.w900, height: 1)),
            ),
          ),
      ],
    );
  }
}
