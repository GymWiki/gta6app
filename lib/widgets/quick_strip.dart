import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../providers/app_state.dart';
import 'cheat_row.dart';
import 'code_keys.dart';
import 'theme.dart';

/// One horizontal strip at the top of the list: favorites, then recently viewed (max 5).
/// Each mini card shows the code, so the common ones are readable without opening.
class QuickStrip extends StatelessWidget {
  const QuickStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final favs = s.quickFavorites;
    final recent = s.quickRecent;
    // Compact element: text scaling is capped so the cards keep their size at huge system fonts.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: 84,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          children: [
            if (favs.isNotEmpty) ...[
              _Label(
                  text: t.quickFavorites,
                  icon: Icons.star_rounded,
                  color: Vice.gold),
              for (final c in favs) _Mini(cheat: c),
            ],
            if (recent.isNotEmpty) ...[
              _Label(
                  text: t.quickRecent,
                  icon: Icons.history_rounded,
                  color: Vice.muted),
              for (final c in recent) _Mini(cheat: c),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Label({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8, left: 2),
        child: SizedBox(
          width: 64,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                      letterSpacing: 0.8)),
            ),
          ]),
        ),
      );
}

class _Mini extends StatelessWidget {
  final Cheat cheat;
  const _Mini({required this.cheat});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final accent = Vice.categoryColor(cheat.categoryId);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Vice.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            s.focus(cheat.id);
            s.collapse(); // the sheet shows the detail; keep the list itself unexpanded
            _openDetail(context, cheat, accent);
          },
          child: Container(
            width: 176,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Vice.border)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(children: [
                    Icon(Vice.categoryIcon(cheat.categoryId),
                        size: 15, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(cheat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  CodeKeys(
                      code: cheat.displayCode(s.platform), t: s.t, size: 20),
                ]),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Cheat cheat, Color accent) {
    final s = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Vice.surfaceHi,
      showDragHandle: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: s,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Row(children: [
                      Icon(Vice.categoryIcon(cheat.categoryId), color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(cheat.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w900))),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(cheat.effect,
                        style: const TextStyle(
                            color: Vice.muted, fontSize: 14, height: 1.4)),
                  ),
                  CheatDetail(cheat: cheat, accent: accent),
                ]),
          ),
        ),
      ),
    );
  }
}
