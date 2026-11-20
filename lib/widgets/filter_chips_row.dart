import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'theme.dart';

/// One compact horizontal chip row: [With code] toggle | All | Favorites | categories.
/// Visuals are 36dp; the tap area is the full 48dp row height.
class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _Chip(
            label: t.filterWithCode,
            icon: s.withCodeOnly ? Icons.check_rounded : Icons.keyboard_rounded,
            selected: s.withCodeOnly,
            color: Vice.cyan,
            onTap: () => s.setWithCodeOnly(!s.withCodeOnly),
          ),
          Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 14), color: Vice.border),
          _Chip(
            label: t.filterAll,
            selected: s.category == kAllCategories,
            color: Vice.pink,
            onTap: () => s.setCategory(kAllCategories),
          ),
          _Chip(
            label: t.filterFavorites,
            icon: Icons.star_rounded,
            selected: s.category == kFavoritesScope,
            color: Vice.gold,
            onTap: () => s.setCategory(kFavoritesScope),
          ),
          for (final c in s.categories)
            _Chip(
              label: c.name,
              icon: Vice.categoryIcon(c.id),
              selected: s.category == c.id,
              color: Vice.categoryColor(c.id),
              onTap: () => s.setCategory(c.id),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.color, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: 48,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: Vice.dur,
              curve: Curves.easeOut,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.18) : Vice.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: selected ? color : Vice.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 16, color: selected ? color : Vice.muted), const SizedBox(width: 6)],
                Text(label,
                    style: TextStyle(
                        color: selected ? Vice.text : Vice.muted, fontWeight: FontWeight.w800, fontSize: 13.5)),
              ]),
            ),
          ),
        ),
      );
}
