import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../providers/app_state.dart';
import '../widgets/cheat_card.dart';
import '../widgets/neon_chip.dart';
import '../widgets/notice_banners.dart';
import '../widgets/sync_feedback.dart';
import '../widgets/theme.dart';

class CheatsTab extends StatelessWidget {
  const CheatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final list = s.cheatsTabList;
    final favs = s.favorites;
    return RefreshIndicator(
      color: Vice.pink,
      backgroundColor: Vice.surfaceHi,
      onRefresh: () => refreshWithFeedback(context, s),
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: NoticeBanners())),
          const SliverToBoxAdapter(child: _GuideCard()),
          if (favs.isNotEmpty) ...[
            _label('${t.pinned} (${favs.length})', Vice.gold, icon: Icons.star_rounded),
            SliverList.builder(itemCount: favs.length, itemBuilder: (_, i) => CheatCard(cheat: favs[i])),
          ],
          SliverPersistentHeader(pinned: true, delegate: _ChipsHeader(s)),
          if (favs.isNotEmpty) _label('${t.allCheats} (${list.length})', Vice.muted),
          if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search_off_rounded, size: 48, color: Vice.muted),
                    const SizedBox(height: 8),
                    Text(t.noMatch, style: const TextStyle(color: Vice.muted, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        s.setQuery('');
                        s.setCategory(kAllCategories);
                      },
                      child: Text(t.clearFilters),
                    ),
                  ]),
                ),
              ),
            )
          else
            SliverList.builder(itemCount: list.length, itemBuilder: (_, i) => CheatCard(cheat: list[i])),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _label(String text, Color c, {IconData? icon}) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 2),
          child: Row(children: [
            if (icon != null) ...[Icon(icon, size: 16, color: c), const SizedBox(width: 6)],
            Flexible(
              child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
            ),
          ]),
        ),
      );
}

/// How to enter a code on the selected console + the collapsible story note.
class _GuideCard extends StatelessWidget {
  const _GuideCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Vice.cyan.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Vice.cyan.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.phone_iphone_rounded, size: 20, color: Vice.cyan),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduce ? Duration.zero : Vice.dur,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, if (current != null) current],
                ),
                child: Text(
                  t.phoneHint(s.platform == 'ps5'),
                  key: ValueKey(s.platform),
                  style: const TextStyle(color: Vice.cyan, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ]),
        ),
        AnimatedSize(
          duration: reduce ? Duration.zero : Vice.dur,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: s.bannerDismissed
              ? Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => s.dismissBanner(false),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: Text(t.showNote),
                    style: TextButton.styleFrom(foregroundColor: Vice.muted, minimumSize: const Size(48, 48)),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
                  decoration: BoxDecoration(
                    color: Vice.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Vice.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_rounded, size: 18, color: Vice.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(t.note, style: const TextStyle(color: Vice.muted, fontSize: 13.5, height: 1.4)),
                      ),
                    ),
                    IconButton(
                      tooltip: t.hideNote,
                      onPressed: () => s.dismissBanner(true),
                      icon: const Icon(Icons.close_rounded, size: 20, color: Vice.muted),
                    ),
                  ]),
                ),
        ),
      ]),
    );
  }
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
        color: Vice.bg.withValues(alpha: 0.96),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            for (final c in [CheatCategory(kAllCategories, s.t.filterAll), ...s.categories])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NeonChip(
                  label: '${c.name} (${s.countFor(c.id)})',
                  selected: s.category == c.id,
                  color: c.id == kAllCategories ? Vice.pink : Vice.categoryColor(c.id),
                  onTap: () => s.setCategory(c.id),
                ),
              ),
          ],
        ),
      );

  @override
  bool shouldRebuild(covariant _ChipsHeader old) => true;
}
