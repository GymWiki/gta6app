import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'theme.dart';

/// Remote announcement + soft "update the app" notice, shown above the tab content.
class NoticeBanners extends StatelessWidget {
  const NoticeBanners({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = s.activeAnnouncement;
    final showSchema = s.schemaTooNew && !s.schemaNoticeDismissed;
    if (a == null && !showSchema) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(children: [
        if (a != null)
          _Banner(
            icon: Icons.campaign_rounded,
            color: Vice.pink,
            title: a.title,
            message: a.message,
            onClose: s.dismissAnnouncement,
          ),
        if (showSchema)
          _Banner(
            icon: Icons.system_update_rounded,
            color: Vice.cyan,
            title: 'Update de app voor nieuwe functies',
            message: 'Er is nieuwe content beschikbaar die deze versie nog niet ondersteunt.',
            onClose: s.dismissSchemaNotice,
          ),
      ]),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final VoidCallback onClose;
  const _Banner({required this.icon, required this.color, required this.title, required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.7)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 20, color: color)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
              const SizedBox(height: 2),
              Text(message, style: const TextStyle(color: Vice.muted, fontSize: 13, height: 1.35)),
            ]),
          ),
          IconButton(tooltip: 'Sluiten', onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 20, color: Vice.muted)),
        ]),
      );
}
