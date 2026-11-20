import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/app_state.dart';
import '../widgets/ad_banner_widget.dart';
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
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: Vice.dusk),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              _tab == 2 ? const _TitleBar() : const _StickyHeader(),
              Expanded(
                child: IndexedStack(index: _tab, children: const [CheatsTab(), TrackerTab(), SettingsTab()]),
              ),
            ]),
          ),
        ),
        // The ad sits directly above the nav bar and collapses to 0px when unavailable.
        bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
          const AdBannerWidget(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              NavigationDestination(
                  icon: const Icon(Icons.gamepad_outlined),
                  selectedIcon: const Icon(Icons.gamepad_rounded),
                  label: t.tabCheats),
              NavigationDestination(
                  icon: const Icon(Icons.checklist_rounded),
                  selectedIcon: const Icon(Icons.checklist_rtl_rounded),
                  label: t.tabTracker),
              NavigationDestination(
                  icon: const Icon(Icons.tune_rounded),
                  selectedIcon: const Icon(Icons.tune_rounded),
                  label: t.tabSettings),
            ],
          ),
        ]),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Align(alignment: Alignment.centerLeft, child: SunsetText('VICE CODES', size: 24)),
      );
}

/// Compact sticky header: brand + platform switch + search. The phone instruction
/// and the note scroll away with the list so the cheats get the screen.
class _StickyHeader extends StatelessWidget {
  const _StickyHeader();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Expanded(
            child: Align(alignment: Alignment.centerLeft, child: FittedBox(fit: BoxFit.scaleDown, child: SunsetText('VICE CODES', size: 22))),
          ),
          const SizedBox(width: 8),
          PlatformSwitch(ps5: s.platform == 'ps5', onChanged: s.setPlatform),
        ]),
        const SizedBox(height: 8),
        const SearchField(),
      ]),
    );
  }
}
