import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/content.dart';
import '../providers/app_state.dart';
import 'theme.dart';

/// Status label: icon + text + color, so it never relies on color alone.
class StatusChip extends StatelessWidget {
  final CheatStatus status;
  final Strings t;
  const StatusChip({super.key, required this.status, required this.t});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      CheatStatus.verified => (t.statusVerified, Icons.verified_rounded, Vice.cyan),
      CheatStatus.unverified => (t.statusUnverified, Icons.help_outline_rounded, Vice.gold),
      CheatStatus.rumor => (t.statusRumor, Icons.hearing_rounded, Vice.purple),
    };
    return _Pill(label: label, icon: icon, color: color);
  }
}

class BadgeChip extends StatelessWidget {
  final CheatBadge badge;
  final Strings t;
  const BadgeChip({super.key, required this.badge, required this.t});

  @override
  Widget build(BuildContext context) => badge == CheatBadge.fresh
      ? _Pill(label: t.badgeNew, icon: Icons.auto_awesome_rounded, color: Vice.pink, filled: true)
      : _Pill(label: t.badgeUpdated, icon: Icons.update_rounded, color: Vice.orange, filled: true);
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  const _Pill({required this.label, required this.icon, required this.color, this.filled = false});

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        // Compact labels stay readable but never blow up the card at huge text sizes.
        maxScaleFactor: 1.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            // Filled pills use a dark enough background for white text (>= 4.5:1).
            color: filled ? Color.alphaBlend(Colors.black.withValues(alpha: 0.45), color) : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: filled ? 0.9 : 0.7)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      color: filled ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            ),
          ]),
        ),
      );
}
