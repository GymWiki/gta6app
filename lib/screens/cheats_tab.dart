import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/cheat_card.dart';
import '../widgets/theme.dart';

class CheatsTab extends StatelessWidget {
  const CheatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.cheatsTabList;
    final favs = s.favorites;
    return RefreshIndicator(
      color: Vice.pink,
      onRefresh: () async { await s.sync(); },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (favs.isNotEmpty) ...[
            _label('★ PINNED'),
            SliverList.builder(itemCount: favs.length, itemBuilder: (_, i) => CheatCard(cheat: favs[i])),
          ],
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  for (final c in ['All', ...s.categories])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text('$c (${s.countFor(c)})'),
                        selected: s.category == c,
                        onSelected: (_) => s.setCategory(c),
                        selectedColor: Vice.pink,
                        backgroundColor: Vice.card,
                        side: const BorderSide(color: Vice.border),
                        labelStyle: const TextStyle(color: Vice.text, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No cheats match.', style: TextStyle(color: Vice.muted))),
            )
          else
            SliverList.builder(itemCount: list.length, itemBuilder: (_, i) => CheatCard(cheat: list[i])),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _label(String t) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
          child: Text(t, style: const TextStyle(color: Vice.pink, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      );
}
