import 'package:flutter/material.dart';

import '../models/content.dart';
import '../providers/app_state.dart';
import 'theme.dart';

/// Status label: icon + text + color, so it never relies on color alone.
class StatusChip extends StatelessWidget {
  final CheatStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      CheatStatus.verified => ('VERIFIED', Icons.verified_rounded, Vice.cyan),
      CheatStatus.unverified => ('UNVERIFIED', Icons.help_outline_rounded, Vice.gold),
      CheatStatus.rumor => ('RUMOR', Icons.hearing_rounded, Vice.purple),
    };
    return _Pill(label: label, icon: icon, color: color);
  }
}

class BadgeChip extends StatelessWidget {
  final CheatBadge badge;
  const BadgeChip({super.key, required this.badge});

  @override
  Widget build(BuildContext context) => badge == CheatBadge.fresh
      ? const _Pill(label: 'NIEUW', icon: Icons.auto_awesome_rounded, color: Vice.pink, filled: true)
      : const _Pill(label: 'BIJGEWERKT', icon: Icons.update_rounded, color: Vice.orange, filled: true);
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  const _Pill({required this.label, required this.icon, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: filled ? 0.9 : 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: filled ? 0 : 0.7)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: filled ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: filled ? Colors.white : color, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
        ]),
      );
}
