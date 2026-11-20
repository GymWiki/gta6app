import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'theme.dart';

/// Remote announcement, the soft "update the app" notice and the first-start phone hint,
/// shown at the top of the list (they scroll away with it).
class NoticeBanners extends StatelessWidget {
  const NoticeBanners({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = s.activeAnnouncement;
    final showSchema = s.schemaTooNew && !s.schemaNoticeDismissed;
    final showHint = !s.bannerDismissed;
    if (a == null && !showSchema && !showHint) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(children: [
        if (a != null)
          _Banner(icon: Icons.campaign_rounded, color: Vice.pink, title: a.title, message: a.message, closeLabel: s.t.close, onClose: s.dismissAnnouncement),
        if (showSchema)
          _Banner(
              icon: Icons.system_update_rounded,
              color: Vice.cyan,
              title: s.t.appUpdateTitle,
              message: s.t.appUpdateBody,
              closeLabel: s.t.close,
              onClose: s.dismissSchemaNotice),
        if (showHint)
          _Banner(
              icon: Icons.phone_iphone_rounded,
              color: Vice.cyan,
              title: s.t.phoneHint(s.platform == 'ps5'),
              message: null,
              closeLabel: s.t.close,
              onClose: () => s.dismissBanner(true)),
      ]),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? message;
  final String closeLabel;
  final VoidCallback onClose;
  const _Banner({required this.icon, required this.color, required this.title, required this.message, required this.closeLabel, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(12, 4, 0, 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: message == null ? color : Vice.text)),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(message!, style: const TextStyle(color: Vice.muted, fontSize: 13, height: 1.35)),
                ],
              ]),
            ),
          ),
          IconButton(tooltip: closeLabel, onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 20, color: Vice.muted)),
        ]),
      );
}
