import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/content.dart';
import '../providers/app_state.dart';
import 'platform_switch.dart';
import 'status_icon.dart';
import 'theme.dart';

/// "How it works": per-platform entry instructions, the story note and the status legend.
Future<void> showInfoSheet(BuildContext context) {
  final s = context.read<AppState>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Vice.surfaceHi,
    builder: (ctx) => ChangeNotifierProvider.value(value: s, child: const _InfoBody()),
  );
}

class _InfoBody extends StatelessWidget {
  const _InfoBody();

  @override
  Widget build(BuildContext context) {
    final t = context.select<AppState, Strings>((s) => s.t);
    final ps5 = context.select<AppState, bool>((s) => s.platform == 'ps5');
    Widget heading(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Row(children: [
            Icon(icon, size: 18, color: Vice.cyan),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
          ]),
        );
    Widget body(String text, {bool strong = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text,
              style: TextStyle(fontSize: 14.5, height: 1.45, color: strong ? Vice.text : Vice.muted, fontWeight: strong ? FontWeight.w700 : FontWeight.w400)),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(t.infoTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          heading(Icons.phone_iphone_rounded, t.infoEnter),
          body(t.infoPs5, strong: ps5),
          body(t.infoXbox, strong: !ps5),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: PlatformSwitch(ps5: ps5, onChanged: context.read<AppState>().setPlatform),
          ),
          heading(Icons.info_outline_rounded, t.infoMore),
          body(t.note),
          heading(Icons.verified_rounded, t.legend),
          for (final st in CheatStatus.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                StatusIcon(status: st, t: t, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${StatusIcon.spec(st, t).$1}  ', style: TextStyle(fontWeight: FontWeight.w900, color: StatusIcon.spec(st, t).$3, fontSize: 13)),
                    TextSpan(
                        text: switch (st) {
                          CheatStatus.verified => t.statusVerifiedInfo,
                          CheatStatus.unverified => t.statusUnverifiedInfo,
                          CheatStatus.rumor => t.statusRumorInfo,
                        },
                        style: const TextStyle(color: Vice.muted, fontSize: 13.5)),
                  ])),
                ),
              ]),
            ),
          const SizedBox(height: 14),
          Text(t.disclaimer, style: const TextStyle(color: Vice.muted, fontSize: 12, height: 1.4)),
        ]),
      ),
    );
  }
}

/// One-time "which console?" question on first start.
Future<void> showPlatformPicker(BuildContext context) async {
  final s = context.read<AppState>();
  final t = s.t;
  await showModalBottomSheet<String>(
    context: context,
    isDismissible: true,
    showDragHandle: true,
    backgroundColor: Vice.surfaceHi,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(t.pickPlatformTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(t.pickPlatformBody, style: const TextStyle(color: Vice.muted, fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _PlatformButton(label: 'PS5', onTap: () => Navigator.pop(ctx, 'ps5'))),
            const SizedBox(width: 12),
            Expanded(child: _PlatformButton(label: 'XBOX', onTap: () => Navigator.pop(ctx, 'xbox'))),
          ]),
        ]),
      ),
    ),
  ).then((choice) {
    if (choice != null) {
      s.setPlatform(choice);
    } else {
      s.confirmPlatformChoice(); // dismissed: keep the default, don't ask again
    }
  });
}

class _PlatformButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PlatformButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: Vice.surface,
          foregroundColor: Vice.text,
          side: const BorderSide(color: Vice.pink, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
      );
}
