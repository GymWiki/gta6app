import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/neon_chip.dart';
import '../widgets/theme.dart';

class TrackerTab extends StatelessWidget {
  const TrackerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.trackerList;
    final pct = s.total == 0 ? 0.0 : s.unlockedCount / s.total;
    return RefreshIndicator(
      color: Vice.pink,
      backgroundColor: Vice.surfaceHi,
      onRefresh: () async {
        await s.sync();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          NeonCard(
            accent: Vice.cyan,
            child: Row(children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(alignment: Alignment.center, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: pct),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => SizedBox.expand(
                      child: CircularProgressIndicator(
                          value: v, strokeWidth: 8, color: Vice.cyan, backgroundColor: Vice.border),
                    ),
                  ),
                  Text('${(pct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.unlockedCount} / ${s.total}',
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Vice.cyan)),
                  const Text('Cheats Unlocked', style: TextStyle(color: Vice.muted, fontSize: 15)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final e in {
                TrackerFilter.all: 'All',
                TrackerFilter.todo: 'To-Do (Locked)',
                TrackerFilter.unlocked: 'Unlocked',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: NeonChip(
                      label: e.value, selected: s.trackerFilter == e.key, onTap: () => s.setTrackerFilter(e.key)),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Nothing here yet.', style: TextStyle(color: Vice.muted, fontSize: 16))),
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
                    accent: Vice.categoryColor(c.category),
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
                            Text(c.unlockRequirement,
                                style: const TextStyle(color: Vice.muted, fontSize: 14.5, height: 1.4)),
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
