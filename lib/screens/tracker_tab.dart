import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/neon_chip.dart';
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
    return RefreshIndicator(
      color: Vice.pink,
      backgroundColor: Vice.surfaceHi,
      onRefresh: () => refreshWithFeedback(context, s),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const NoticeBanners(),
          NeonCard(
            accent: Vice.cyan,
            child: Row(children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(alignment: Alignment.center, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: pct),
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => SizedBox.expand(
                      child: CircularProgressIndicator(value: v, strokeWidth: 8, color: Vice.cyan, backgroundColor: Vice.border),
                    ),
                  ),
                  Text('${(pct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
                      child: Text('${s.unlockedCount} / ${s.total}',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Vice.cyan)),
                    ),
                    Text(t.cheatsUnlocked, style: const TextStyle(color: Vice.muted, fontSize: 15)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final e in {
                TrackerFilter.all: '${t.filterAll} (${s.total})',
                TrackerFilter.todo: '${t.filterTodo} ($todo)',
                TrackerFilter.unlocked: '${t.filterUnlocked} (${s.unlockedCount})',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: NeonChip(label: e.value, selected: s.trackerFilter == e.key, onTap: () => s.setTrackerFilter(e.key)),
                ),
            ]),
          ),
          const SizedBox(height: 8),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: PressScale(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  s.toggleUnlocked(c.id);
                },
                child: Semantics(
                  checked: s.unlockedIds.contains(c.id),
                  label: '${c.name}. ${c.unlockRequirement}',
                  excludeSemantics: true,
                  child: NeonCard(
                    accent: Vice.categoryColor(c.categoryId),
                    padding: const EdgeInsets.fromLTRB(8, 10, 14, 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Checkbox(value: s.unlockedIds.contains(c.id), onChanged: (_) => s.toggleUnlocked(c.id)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                            const SizedBox(height: 4),
                            Text(c.unlockRequirement, style: const TextStyle(color: Vice.muted, fontSize: 15, height: 1.4)),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
