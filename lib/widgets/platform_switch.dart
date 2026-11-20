import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Compact PS5 / Xbox segmented pill: 40dp visual, 48dp tap area per segment.
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
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!on) HapticFeedback.selectionClick();
              onChanged(id);
            },
            child: SizedBox(
              height: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: Vice.dur,
                  curve: Curves.easeOut,
                  height: 36,
                  constraints: const BoxConstraints(minWidth: 56),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(gradient: on ? Vice.sunset : null, borderRadius: BorderRadius.circular(18)),
                  child: Text(label,
                      style: TextStyle(color: on ? Colors.white : Vice.muted, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.6)),
                ),
              ),
            ),
          ),
        );
    return Stack(alignment: Alignment.center, children: [
      Positioned(
        left: 0,
        right: 0,
        top: 4,
        bottom: 4,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Vice.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Vice.border)),
        ),
      ),
      Row(mainAxisSize: MainAxisSize.min, children: [seg('PS5', 'ps5', ps5), seg('XBOX', 'xbox', !ps5)]),
    ]);
  }
}
