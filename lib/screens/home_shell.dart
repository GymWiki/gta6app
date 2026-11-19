import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/theme.dart';
import 'cheats_tab.dart';
import 'settings_tab.dart';
import 'tracker_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          if (_tab != 2) const _StickyHeader(),
          Expanded(
            child: IndexedStack(index: _tab, children: const [CheatsTab(), TrackerTab(), SettingsTab()]),
          ),
        ]),
      ),
      // Ad sits directly above the nav bar; lists are in Expanded so it never overlaps them.
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const AdBannerWidget(),
        BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.gamepad_rounded), label: 'Cheats'),
            BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'Tracker'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ]),
    );
  }
}

class _StickyHeader extends StatelessWidget {
  const _StickyHeader();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ps5 = s.platform == 'ps5';
    return Container(
      color: Vice.bg,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          _seg('PS5', ps5, () => s.setPlatform('ps5')),
          const SizedBox(width: 8),
          _seg('Xbox', !ps5, () => s.setPlatform('xbox')),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                  color: Vice.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(
                ps5 ? 'Open Phone (↑) + Hold L1 & R1' : 'Open Phone (↑) + Hold LB & RB',
                style: const TextStyle(color: Vice.cyan, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        TextField(
          onChanged: s.setQuery,
          style: const TextStyle(color: Vice.text),
          decoration: InputDecoration(
            hintText: 'Search name, effect or unlock…',
            hintStyle: const TextStyle(color: Vice.muted),
            prefixIcon: const Icon(Icons.search, color: Vice.muted),
            filled: true,
            fillColor: Vice.card,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        if (!s.bannerDismissed)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(
                color: Vice.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: Vice.border)),
            child: Row(children: [
              const Expanded(
                child: Text(
                  'Note: Cheats unlock in the Pause Menu (Progress > Cheats) only after completing the main story. Activating cheats disables Trophies/Achievements.',
                  style: TextStyle(color: Vice.muted, fontSize: 12),
                ),
              ),
              IconButton(
                  tooltip: 'Dismiss',
                  onPressed: () => s.dismissBanner(true),
                  icon: const Icon(Icons.close, size: 18, color: Vice.muted)),
            ]),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => s.dismissBanner(false),
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('Show note', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: Vice.muted, visualDensity: VisualDensity.compact),
            ),
          ),
      ]),
    );
  }

  Widget _seg(String label, bool on, VoidCallback tap) => GestureDetector(
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: on ? Vice.pink : Vice.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? Vice.pink : Vice.border),
          ),
          child: Text(label, style: const TextStyle(color: Vice.text, fontWeight: FontWeight.w800)),
        ),
      );
}
