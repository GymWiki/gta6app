import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../providers/app_state.dart';
import '../services/feedback.dart';
import '../widgets/cheat_row.dart';
import '../widgets/notice_banners.dart';
import '../widgets/quick_strip.dart';
import '../widgets/sync_feedback.dart';
import '../widgets/theme.dart';

class CheatsTab extends StatelessWidget {
  const CheatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    final view = s.view;
    // When nothing is left in the main list, show the "no code yet" results right away.
    final noCodeOpen = s.noCodeExpanded || (view.mainCheats.isEmpty && view.noCode.isNotEmpty);

    return RefreshIndicator(
      color: Vice.pink,
      backgroundColor: Vice.surfaceHi,
      onRefresh: () => refreshWithFeedback(context, s),
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: NoticeBanners()),
          // The strip slides in/out (instead of popping in and shoving the list down under the finger).
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: MediaQuery.of(context).disableAnimations ? const Duration(milliseconds: 1) : Vice.dur,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: s.showQuickStrip ? const QuickStrip() : const SizedBox(width: double.infinity),
            ),
          ),
          if (view.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _EmptyState(state: s))
          else ...[
            for (final g in view.groups)
              if (g.cheats.isNotEmpty)
                if (view.grouped && g.category != null)
                  SliverMainAxisGroup(slivers: [
                    SliverPersistentHeader(pinned: true, delegate: _GroupHeader(g.category!, g.cheats.length, t.groupHeader)),
                    SliverList.builder(itemCount: g.cheats.length, itemBuilder: (_, i) => CheatRow(cheat: g.cheats[i])),
                  ])
                else
                  SliverList.builder(itemCount: g.cheats.length, itemBuilder: (_, i) => CheatRow(cheat: g.cheats[i])),
            if (view.noCode.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _NoCodeHeader(
                  label: t.noCodeSection(view.noCode.length),
                  open: noCodeOpen,
                  onTap: s.toggleNoCodeExpanded,
                ),
              ),
              if (noCodeOpen) SliverList.builder(itemCount: view.noCode.length, itemBuilder: (_, i) => CheatRow(cheat: view.noCode[i])),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _GroupHeader extends SliverPersistentHeaderDelegate {
  final CheatCategory category;
  final int count;
  final String Function(String, int) format;
  _GroupHeader(this.category, this.count, this.format);

  @override
  double get minExtent => 36;
  @override
  double get maxExtent => 36;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final color = Vice.categoryColor(category.id);
    return Container(
      color: Vice.bg, // solid: nothing shows through behind a pinned header
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      child: Row(children: [
        Icon(Vice.categoryIcon(category.id), size: 16, color: color),
        const SizedBox(width: 8),
        Text(format(category.name.toUpperCase(), count),
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 1.2)),
      ]),
    );
  }

  @override
  bool shouldRebuild(covariant _GroupHeader old) => old.category.id != category.id || old.count != count;
}

class _NoCodeHeader extends StatelessWidget {
  final String label;
  final bool open;
  final VoidCallback onTap;
  const _NoCodeHeader({required this.label, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        expanded: open,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 52,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Vice.border), bottom: BorderSide(color: Vice.border))),
            child: Row(children: [
              const Icon(Icons.search_rounded, size: 18, color: Vice.gold),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: const TextStyle(color: Vice.gold, fontWeight: FontWeight.w800, fontSize: 14))),
              Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Vice.muted),
            ]),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final AppState state;
  const _EmptyState({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = state.t;
    final favoritesEmpty = state.category == kFavoritesScope && state.query.trim().isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(favoritesEmpty ? Icons.star_outline_rounded : Icons.search_off_rounded, size: 44, color: Vice.muted),
          const SizedBox(height: 10),
          Text(
            favoritesEmpty ? t.noFavorites : (state.query.trim().isEmpty ? t.noMatch : t.noResultFor(state.query.trim())),
            style: const TextStyle(color: Vice.text, fontSize: 16, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          if (!favoritesEmpty) ...[
            FilledButton.tonal(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () {
                state.setQuery('');
                state.setCategory(kAllCategories);
              },
              child: Text(t.clearFilters),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: Vice.cyan),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final opened = await reportMissingCheat(state.query.trim());
                if (!opened) {
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(t.reportCopied)));
                }
              },
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: Text(t.reportMissing),
            ),
          ],
        ]),
      ),
    );
  }
}
