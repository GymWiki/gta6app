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
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: Vice.dusk),
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            if (_tab != 2) const _StickyHeader() else const _TitleBar(),
            Expanded(
              child: IndexedStack(index: _tab, children: const [CheatsTab(), TrackerTab(), SettingsTab()]),
            ),
          ]),
        ),
      ),
      // Ad sits directly above the nav bar and collapses to 0px when unavailable.
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const AdBannerWidget(),
        NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.gamepad_outlined), selectedIcon: Icon(Icons.gamepad_rounded), label: 'CHEATS'),
            NavigationDestination(icon: Icon(Icons.checklist_rounded), selectedIcon: Icon(Icons.checklist_rtl_rounded), label: 'TRACKER'),
            NavigationDestination(icon: Icon(Icons.tune_rounded), selectedIcon: Icon(Icons.tune_rounded), label: 'SETTINGS'),
          ],
        ),
      ]),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Align(alignment: Alignment.centerLeft, child: SunsetText('VICE CODES', size: 26)),
      );
}

class _StickyHeader extends StatelessWidget {
  const _StickyHeader();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ps5 = s.platform == 'ps5';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Expanded(child: Align(alignment: Alignment.centerLeft, child: SunsetText('VICE CODES', size: 24))),
          _PlatformSwitch(ps5: ps5, onChanged: s.setPlatform),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Vice.cyan.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Vice.cyan.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.phone_iphone_rounded, size: 18, color: Vice.cyan),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: Vice.dur,
                child: Text(
                  ps5 ? 'Open Phone (↑) + Hold L1 & R1' : 'Open Phone (↑) + Hold LB & RB',
                  key: ValueKey(ps5),
                  style: const TextStyle(color: Vice.cyan, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        TextField(
          onChanged: s.setQuery,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Vice.text, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search cheats, effects, unlocks…',
            hintStyle: const TextStyle(color: Vice.muted),
            prefixIcon: const Icon(Icons.search_rounded, color: Vice.muted),
            filled: true,
            fillColor: Vice.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Vice.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Vice.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Vice.pink, width: 1.6)),
          ),
        ),
        AnimatedSize(
          duration: Vice.dur,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: s.bannerDismissed
              ? Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => s.dismissBanner(false),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('Show note'),
                    style: TextButton.styleFrom(foregroundColor: Vice.muted, minimumSize: const Size(48, 48)),
                  ),
                )
              : Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
                  decoration: BoxDecoration(
                    color: Vice.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Vice.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_rounded, size: 18, color: Vice.orange),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Note: Cheats unlock in the Pause Menu (Progress > Cheats) only after completing the main story. Activating cheats disables Trophies/Achievements.',
                        style: TextStyle(color: Vice.muted, fontSize: 13, height: 1.35),
                      ),
                    ),
                    IconButton(
                        tooltip: 'Dismiss note',
                        onPressed: () => s.dismissBanner(true),
                        icon: const Icon(Icons.close_rounded, size: 20, color: Vice.muted)),
                  ]),
                ),
        ),
      ]),
    );
  }
}

/// Animated segmented PS5 / Xbox pill.
class _PlatformSwitch extends StatelessWidget {
  final bool ps5;
  final ValueChanged<String> onChanged;
  const _PlatformSwitch({required this.ps5, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, String id, bool on) => Semantics(
          button: true,
          selected: on,
          label: label,
          child: GestureDetector(
            onTap: () => onChanged(id),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: Vice.dur,
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: on ? Vice.sunset : null,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: on ? Colors.white : Vice.muted, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Vice.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Vice.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('PS5', 'ps5', ps5),
        seg('XBOX', 'xbox', !ps5),
      ]),
    );
  }
}
