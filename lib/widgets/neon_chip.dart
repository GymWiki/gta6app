import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class NeonChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const NeonChip({super.key, required this.label, required this.selected, required this.onTap, this.color = Vice.pink});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: Vice.dur,
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.2) : Vice.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? color : Vice.border, width: selected ? 1.6 : 1),
            ),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Vice.text : Vice.muted, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      );
}
