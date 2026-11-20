import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../providers/app_state.dart';
import 'cheat_chips.dart';
import 'dpad_pills.dart';
import 'theme.dart';

class CheatCard extends StatelessWidget {
  final Cheat cheat;
  const CheatCard({super.key, required this.cheat});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final fav = s.favoriteIds.contains(cheat.id);
    final unlocked = s.unlockedIds.contains(cheat.id);
    final focused = s.focusedId == cheat.id;
    final accent = Vice.categoryColor(cheat.categoryId);
    final badge = s.badgeFor(cheat);
    final code = cheat.codeFor(s.platform);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: PressScale(
        onTap: () {
          HapticFeedback.selectionClick();
          s.focus(cheat.id);
          s.markSeen(cheat);
        },
        child: NeonCard(
          accent: accent,
          glow: focused,
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Vice.categoryIcon(cheat.categoryId), size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(cheat.name,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
              ),
              IconButton(
                tooltip: fav ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  s.toggleFavorite(cheat.id);
                },
                icon: AnimatedSwitcher(
                  duration: Vice.dur,
                  child: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey(fav), color: fav ? Vice.gold : Vice.muted, size: 28),
                ),
              ),
              IconButton(
                tooltip: unlocked ? 'Mark as locked' : 'Mark as unlocked',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  s.toggleUnlocked(cheat.id);
                },
                icon: AnimatedSwitcher(
                  duration: Vice.dur,
                  child: Icon(unlocked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      key: ValueKey(unlocked), color: unlocked ? Vice.cyan : Vice.muted, size: 28),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(cheat.effect, style: const TextStyle(color: Vice.muted, fontSize: 15, height: 1.4)),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              StatusChip(status: cheat.status),
              if (badge != null) BadgeChip(badge: badge),
            ]),
            const SizedBox(height: 12),
            DpadPills(code: code),
            for (final extra in const ['phone', 'pc'])
              if (cheat.codeFor(extra) != null) ...[
                const SizedBox(height: 10),
                Text(extra.toUpperCase(),
                    style: const TextStyle(color: Vice.muted, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 4),
                DpadPills(code: cheat.codeFor(extra)),
              ],
          ]),
        ),
      ),
    );
  }
}
