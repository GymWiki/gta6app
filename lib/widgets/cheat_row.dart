import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../providers/app_state.dart';
import 'code_keys.dart';
import 'highlight_text.dart';
import 'status_icon.dart';
import 'theme.dart';

/// Compact list row (~72dp): category icon, title + one-line effect, favorite star, and the
/// code itself as keys. Tap to expand inline (one row at a time).
class CheatRow extends StatelessWidget {
  final Cheat cheat;
  const CheatRow({super.key, required this.cheat});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final fav = s.favoriteIds.contains(cheat.id);
    final unlocked = s.unlockedIds.contains(cheat.id);
    final expanded = s.focusedId == cheat.id;
    final accent = Vice.categoryColor(cheat.categoryId);
    final badge = s.badgeFor(cheat);
    final code = cheat.displayCode(s.platform);
    final reduce = MediaQuery.of(context).disableAnimations;
    final dur = reduce ? Duration.zero : Vice.dur;

    return Semantics(
      container: true,
      expanded: expanded,
      child: Material(
        color: expanded ? Vice.surface : Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            s.focus(cheat.id);
            if (s.focusedId == cheat.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Scrollable.ensureVisible(context, alignment: 0.1, duration: dur, curve: Curves.easeOut);
                }
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: expanded ? accent : Colors.transparent, width: 3),
                bottom: BorderSide(color: Vice.border.withValues(alpha: 0.6)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 5, 0, 5),
            child: Stack(children: [
              // Content leaves room on the right for the 48dp star target.
              Padding(
                padding: const EdgeInsets.only(right: 48),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Icon(Vice.categoryIcon(cheat.categoryId), size: 18, color: accent),
                    const SizedBox(width: 8),
                    Flexible(
                      child: HighlightText(cheat.name,
                          query: s.query, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.25)),
                    ),
                    const SizedBox(width: 6),
                    StatusIcon(status: cheat.status, t: t, size: 14),
                    if (unlocked) ...[
                      const SizedBox(width: 6),
                      Semantics(
                        label: t.unlockedTag,
                        child: const Icon(Icons.check_circle_rounded, size: 14, color: Vice.cyan),
                      ),
                    ],
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      _NewDot(label: badge == CheatBadge.fresh ? t.badgeNew : t.badgeUpdated),
                    ],
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: HighlightText(cheat.effect,
                        query: s.query, style: const TextStyle(color: Vice.muted, fontSize: 13, height: 1.3)),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: CodeKeys(code: code, t: t, size: 22),
                  ),
                ]),
              ),
              Positioned(
                top: -5,
                right: 0,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    tooltip: fav ? t.removeFavorite : t.addFavorite,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      s.toggleFavorite(cheat.id);
                    },
                    icon: Icon(fav ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: fav ? Vice.gold : Vice.muted, size: 24),
                  ),
                ),
              ),
            ]),
          ),
        ),
        // Expanded part lives outside the InkWell row padding so it can use the full width.
      ),
    ).withExpansion(expanded: expanded, cheat: cheat, accent: accent);
  }
}

extension on Widget {
  Widget withExpansion({required bool expanded, required Cheat cheat, required Color accent}) => Builder(builder: (context) {
        final reduce = MediaQuery.of(context).disableAnimations;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          this,
          AnimatedSize(
            duration: reduce ? Duration.zero : Vice.dur,
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? ColoredBox(color: Vice.surface, child: CheatDetail(cheat: cheat, accent: accent))
                : const SizedBox(width: double.infinity),
          ),
        ]);
      });
}

class _NewDot extends StatelessWidget {
  final String label;
  const _NewDot({required this.label});

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: Vice.pink.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(6)),
          child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.4)),
        ),
      );
}

/// The expanded body of a cheat: description, big code, copy + unlock actions, status.
/// Used inline in the list and in the bottom sheet opened from the quick strip.
class CheatDetail extends StatelessWidget {
  final Cheat cheat;
  final Color accent;
  const CheatDetail({super.key, required this.cheat, required this.accent});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final code = cheat.displayCode(s.platform);
    final unlocked = s.unlockedIds.contains(cheat.id);
    final (statusLabel, _, statusColor) = StatusIcon.spec(cheat.status, t);
    final statusInfo = switch (cheat.status) {
      CheatStatus.verified => t.statusVerifiedInfo,
      CheatStatus.unverified => t.statusUnverifiedInfo,
      CheatStatus.rumor => t.statusRumorInfo,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (cheat.description != null) ...[
          Text(cheat.description!, style: const TextStyle(fontSize: 14, height: 1.4, color: Vice.muted)),
          const SizedBox(height: 10),
        ],
        Row(children: [
          Icon(unlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 15, color: accent),
          const SizedBox(width: 6),
          Flexible(child: Text(t.howToUnlock, style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1))),
        ]),
        const SizedBox(height: 4),
        Text(cheat.unlockRequirement, style: const TextStyle(fontSize: 14.5, height: 1.4)),
        const SizedBox(height: 12),
        CodeKeys(code: code, t: t, size: 40),
        for (final extra in const ['phone', 'pc'])
          if (cheat.codeFor(extra) != null) ...[
            const SizedBox(height: 10),
            Text(extra.toUpperCase(), style: const TextStyle(color: Vice.muted, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 4),
            CodeKeys(code: cheat.codeFor(extra), t: t, size: 30),
          ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (code != null)
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: codeAsText(code)));
                HapticFeedback.mediumImpact();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(t.codeCopied), duration: const Duration(seconds: 2)));
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(t.copyCode),
            ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: unlocked ? Vice.cyan : Vice.text,
              side: BorderSide(color: unlocked ? Vice.cyan : Vice.border),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              s.toggleUnlocked(cheat.id);
            },
            icon: Icon(unlocked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18),
            label: Text(unlocked ? t.unmarkUsed : t.markUsed),
          ),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: StatusIcon(status: cheat.status, t: t)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$statusLabel  ', style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12.5)),
              TextSpan(text: statusInfo, style: const TextStyle(color: Vice.muted, fontSize: 12.5)),
            ])),
          ),
        ]),
      ]),
    );
  }
}
