import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Animated PS5 / Xbox segmented pill.
class PlatformSwitch extends StatelessWidget {
  final bool ps5;
  final ValueChanged<String> onChanged;
  const PlatformSwitch({super.key, required this.ps5, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, String id, bool on) => Semantics(
          button: true,
          selected: on,
          label: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!on) HapticFeedback.selectionClick();
              onChanged(id);
            },
            child: AnimatedContainer(
              duration: Vice.dur,
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: on ? Vice.sunset : null,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(label,
                  style: TextStyle(color: on ? Colors.white : Vice.muted, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Vice.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Vice.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('PS5', 'ps5', ps5),
        seg('XBOX', 'xbox', !ps5),
      ]),
    );
  }
}
