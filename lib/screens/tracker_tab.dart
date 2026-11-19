import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
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
      onRefresh: () async { await s.sync(); },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Vice.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Vice.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.unlockedCount} / ${s.total} Cheats Unlocked',
                  style: const TextStyle(color: Vice.text, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: pct, minHeight: 12, color: Vice.cyan, backgroundColor: Vice.border),
              ),
              const SizedBox(height: 6),
              Text('${(pct * 100).round()}%', style: const TextStyle(color: Vice.cyan, fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final e in {
              TrackerFilter.all: 'All',
              TrackerFilter.todo: 'To-Do (Locked)',
              TrackerFilter.unlocked: 'Unlocked',
            }.entries)
              ChoiceChip(
                label: Text(e.value),
                selected: s.trackerFilter == e.key,
                onSelected: (_) => s.setTrackerFilter(e.key),
                selectedColor: Vice.pink,
                backgroundColor: Vice.card,
                side: const BorderSide(color: Vice.border),
                labelStyle: const TextStyle(color: Vice.text, fontWeight: FontWeight.w700),
              ),
          ]),
          const SizedBox(height: 8),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Nothing here.', style: TextStyle(color: Vice.muted))),
            ),
          for (final c in list)
            CheckboxListTile(
              value: s.unlockedIds.contains(c.id),
              onChanged: (_) => s.toggleUnlocked(c.id),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(c.name, style: const TextStyle(color: Vice.text, fontWeight: FontWeight.w700)),
              subtitle: Text(c.unlockRequirement, style: const TextStyle(color: Vice.muted)),
            ),
        ],
      ),
    );
  }
}
