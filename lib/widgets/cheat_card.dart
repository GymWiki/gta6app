import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../providers/app_state.dart';
import 'cheat_chips.dart';
import 'dpad_pills.dart';
import 'theme.dart';

/// One cheat. Tap the card to expand it: unlock requirement and description.
class CheatCard extends StatelessWidget {
  final Cheat cheat;
  const CheatCard({super.key, required this.cheat});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final fav = s.favoriteIds.contains(cheat.id);
    final unlocked = s.unlockedIds.contains(cheat.id);
    final expanded = s.focusedId == cheat.id;
    final accent = Vice.categoryColor(cheat.categoryId);
    final badge = s.badgeFor(cheat);
    final code = cheat.codeFor(s.platform);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final dur = reduceMotion ? Duration.zero : Vice.dur;

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
          glow: expanded,
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Vice.categoryIcon(cheat.categoryId), size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(cheat.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
              ),
              IconButton(
                tooltip: fav ? t.removeFavorite : t.addFavorite,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  s.toggleFavorite(cheat.id);
                },
                icon: AnimatedSwitcher(
                  duration: dur,
                  child: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey(fav), color: fav ? Vice.gold : Vice.muted, size: 28),
                ),
              ),
              IconButton(
                tooltip: unlocked ? t.markLocked : t.markUnlocked,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  s.toggleUnlocked(cheat.id);
                },
                icon: AnimatedSwitcher(
                  duration: dur,
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
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  StatusChip(status: cheat.status, t: t),
                  if (badge != null) BadgeChip(badge: badge, t: t),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: dur,
                  child: const Icon(Icons.expand_more_rounded, color: Vice.muted),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            DpadPills(code: code, t: t),
            for (final extra in const ['phone', 'pc'])
              if (cheat.codeFor(extra) != null) ...[
                const SizedBox(height: 10),
                Text(extra.toUpperCase(),
                    style: const TextStyle(color: Vice.muted, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 4),
                DpadPills(code: cheat.codeFor(extra), t: t),
              ],
            AnimatedSize(
              duration: dur,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14, right: 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Divider(height: 1, color: Vice.border),
                        const SizedBox(height: 12),
                        Row(children: [
                          Icon(unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 16, color: accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(t.howToUnlock,
                                style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(cheat.unlockRequirement, style: const TextStyle(fontSize: 15, height: 1.4)),
                        if (cheat.description != null) ...[
                          const SizedBox(height: 10),
                          Text(cheat.description!, style: const TextStyle(color: Vice.muted, fontSize: 14, height: 1.4)),
                        ],
                      ]),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ]),
        ),
      ),
    );
  }
}
