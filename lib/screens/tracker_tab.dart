import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/highlight_text.dart';
import '../widgets/notice_banners.dart';
import '../widgets/sync_feedback.dart';
import '../widgets/theme.dart';

class TrackerTab extends StatelessWidget {
  const TrackerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final list = s.trackerList;
    final pct = s.total == 0 ? 0.0 : s.unlockedCount / s.total;
    final todo = s.total - s.unlockedCount;
    final reduce = MediaQuery.of(context).disableAnimations;

    Widget filterChip(TrackerFilter f, String label) {
      final on = s.trackerFilter == f;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              s.setTrackerFilter(f);
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: Vice.dur,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? Vice.pink.withValues(alpha: 0.18) : Vice.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: on ? Vice.pink : Vice.border),
                ),
                child: Text(label, style: TextStyle(color: on ? Vice.text : Vice.muted, fontWeight: FontWeight.w800, fontSize: 13.5)),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Vice.pink,
      backgroundColor: Vice.surfaceHi,
      onRefresh: () => refreshWithFeedback(context, s),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const NoticeBanners(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(alignment: Alignment.center, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: pct),
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => SizedBox.expand(
                      child: CircularProgressIndicator(value: v, strokeWidth: 7, color: Vice.cyan, backgroundColor: Vice.border),
                    ),
                  ),
                  Text('${(pct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Semantics(
                  label: '${s.unlockedCount} / ${s.total} ${t.cheatsUnlocked}',
                  excludeSemantics: true,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('${s.unlockedCount} / ${s.total}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Vice.cyan)),
                    ),
                    Text(t.cheatsUnlocked, style: const TextStyle(color: Vice.muted, fontSize: 14)),
                  ]),
                ),
              ),
            ]),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                filterChip(TrackerFilter.all, '${t.filterAll} (${s.total})'),
                filterChip(TrackerFilter.todo, '${t.filterTodo} ($todo)'),
                filterChip(TrackerFilter.unlocked, '${t.filterUnlocked} (${s.unlockedCount})'),
              ],
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  s.trackerFilter == TrackerFilter.todo && s.query.isEmpty ? t.trackerEmptyTodo : t.trackerEmpty,
                  style: const TextStyle(color: Vice.muted, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          for (final c in list)
            Semantics(
              checked: s.unlockedIds.contains(c.id),
              label: '${c.name}. ${c.unlockRequirement}',
              excludeSemantics: true,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  s.toggleUnlocked(c.id);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 64),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Vice.border.withValues(alpha: 0.6)))),
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Checkbox(value: s.unlockedIds.contains(c.id), onChanged: (_) => s.toggleUnlocked(c.id)),
                    ),
                    Icon(Vice.categoryIcon(c.categoryId), size: 18, color: Vice.categoryColor(c.categoryId)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        HighlightText(c.name, query: s.query, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        HighlightText(c.unlockRequirement,
                            query: s.query, maxLines: 2, style: const TextStyle(color: Vice.muted, fontSize: 13, height: 1.3)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
