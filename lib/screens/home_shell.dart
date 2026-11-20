import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/app_state.dart';
import '../widgets/ad_banner_widget.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/info_sheet.dart';
import '../widgets/platform_switch.dart';
import '../widgets/search_field.dart';
import '../widgets/theme.dart';
import 'cheats_tab.dart';
import 'settings_tab.dart';
import 'tracker_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // One-time "which console?" question on first start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.read<AppState>().platformChosen) showPlatformPicker(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Throttled inside AppState/repository (max once per few hours).
    if (state == AppLifecycleState.resumed) context.read<AppState>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.select<AppState, Strings>((s) => s.t);
    return PopScope(
      // Back goes to the first tab before it leaves the app.
      canPop: _tab == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _tab = 0);
      },
      child: Scaffold(
        backgroundColor: Vice.bg,
        // Layout, top to bottom: sticky zone | list (own scroll viewport) | fixed ad strip | nav.
        // The ad is never drawn over the list, so the last row can always be scrolled clear of it.
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _Header(onInfo: () => showInfoSheet(context)),
            if (_tab != 2) const Padding(padding: EdgeInsets.fromLTRB(12, 0, 12, 4), child: SearchField()),
            if (_tab == 0) const FilterChipsRow(),
            Expanded(
              child: IndexedStack(index: _tab, children: const [CheatsTab(), TrackerTab(), SettingsTab()]),
            ),
            const AdBannerWidget(),
          ]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.gamepad_outlined), selectedIcon: const Icon(Icons.gamepad_rounded), label: t.tabCheats),
            NavigationDestination(icon: const Icon(Icons.checklist_rounded), selectedIcon: const Icon(Icons.checklist_rtl_rounded), label: t.tabTracker),
            NavigationDestination(icon: const Icon(Icons.tune_rounded), selectedIcon: const Icon(Icons.tune_rounded), label: t.tabSettings),
          ],
        ),
      ),
    );
  }
}

/// Compact header (56dp): small brand left, info + platform switch right.
class _Header extends StatelessWidget {
  final VoidCallback onInfo;
  const _Header({required this.onInfo});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 8),
        child: Row(children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(fit: BoxFit.scaleDown, child: SunsetText('VICE CODES', size: 20)),
            ),
          ),
          IconButton(
            tooltip: s.t.infoTooltip,
            onPressed: onInfo,
            icon: const Icon(Icons.info_outline_rounded, color: Vice.muted),
          ),
          PlatformSwitch(ps5: s.platform == 'ps5', onChanged: s.setPlatform),
        ]),
      ),
    );
  }
}
