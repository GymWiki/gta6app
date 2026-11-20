import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/cheat_card.dart';
import '../widgets/neon_chip.dart';
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
      backgroundColor: Vice.surfaceHi,
      onRefresh: () async {
        await s.sync();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (favs.isNotEmpty) ...[
            _label('★  PINNED', Vice.gold),
            SliverList.builder(itemCount: favs.length, itemBuilder: (_, i) => CheatCard(cheat: favs[i])),
          ],
          SliverPersistentHeader(pinned: true, delegate: _ChipsHeader(s)),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.search_off_rounded, size: 48, color: Vice.muted),
                  const SizedBox(height: 8),
                  const Text('No cheats match your search.', style: TextStyle(color: Vice.muted, fontSize: 16)),
                  TextButton(
                    onPressed: () {
                      s.setQuery('');
                      s.setCategory('All');
                    },
                    child: const Text('Clear filters'),
                  ),
                ]),
              ),
            )
          else
            SliverList.builder(itemCount: list.length, itemBuilder: (_, i) => CheatCard(cheat: list[i])),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _label(String t, Color c) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
          child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        ),
      );
}

class _ChipsHeader extends SliverPersistentHeaderDelegate {
  final AppState s;
  _ChipsHeader(this.s);
  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) => Container(
        color: Vice.bg.withOpacity(0.96),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            for (final c in ['All', ...s.categories])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NeonChip(
                  label: '$c (${s.countFor(c)})',
                  selected: s.category == c,
                  color: c == 'All' ? Vice.pink : Vice.categoryColor(c),
                  onTap: () => s.setCategory(c),
                ),
              ),
          ],
        ),
      );

  @override
  bool shouldRebuild(covariant _ChipsHeader old) => true;
}
