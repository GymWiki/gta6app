import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/cheat.dart';
import '../providers/app_state.dart';
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
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); s.focus(cheat.id); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Vice.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: focused ? Vice.pink : Vice.border, width: focused ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(cheat.name,
                  style: const TextStyle(color: Vice.text, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              tooltip: fav ? 'Unfavorite' : 'Favorite',
              onPressed: () => s.toggleFavorite(cheat.id),
              icon: Icon(fav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: fav ? Vice.pink : Vice.muted, size: 28),
            ),
            IconButton(
              tooltip: unlocked ? 'Mark locked' : 'Mark unlocked',
              onPressed: () => s.toggleUnlocked(cheat.id),
              icon: Icon(unlocked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: unlocked ? Vice.cyan : Vice.muted, size: 28),
            ),
          ]),
          Text(cheat.effect, style: const TextStyle(color: Vice.muted, fontSize: 14, height: 1.3)),
          const SizedBox(height: 12),
          DpadPills(sequence: cheat.dpadSequence),
        ]),
      ),
    );
  }
}
