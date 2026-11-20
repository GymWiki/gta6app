import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/cheat_repository.dart';
import '../widgets/theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      NeonCard(
        accent: Vice.cyan,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Data', style: TextStyle(color: Vice.text, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
              'Laatst bijgewerkt: ${s.data.updatedAt.isEmpty ? '-' : s.data.updatedAt}\n'
              'Contentversie: ${s.data.contentVersion}  ·  ${s.total} cheats\n'
              'Laatst gecontroleerd: ${_fmt(s.lastChecked)}',
              style: const TextStyle(color: Vice.muted, fontSize: 15, height: 1.5)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: Vice.pink, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: s.syncing
                ? null
                : () async {
                    final r = await s.refresh(force: true);
                    if (!context.mounted) return;
                    final msg = switch (r.status) {
                      SyncStatus.updated => 'Bijgewerkt naar contentversie ${s.data.contentVersion}.',
                      SyncStatus.notModified || SyncStatus.skippedThrottle || SyncStatus.busy => 'Je hebt al de nieuwste content.',
                      SyncStatus.schemaTooNew => 'Update de app voor nieuwe functies.',
                      SyncStatus.notConfigured => 'Geen content-URL ingesteld. Gebundelde content wordt gebruikt.',
                      SyncStatus.failed => 'Geen verbinding. Opgeslagen content wordt gebruikt.',
                    };
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  },
            icon: s.syncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            label: const Text('Nu verversen'),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
            foregroundColor: Vice.pink,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: Vice.pink),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: () => _confirmReset(context, s),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Reset Progress'),
      ),
      const SizedBox(height: 24),
      const Text(
        'Unofficial fan-made companion app. Not affiliated with, endorsed, or sponsored by Rockstar Games or Take-Two Interactive.',
        style: TextStyle(color: Vice.muted, fontSize: 13, height: 1.5),
      ),
    ]);
  }

  static String _fmt(DateTime? d) {
    if (d == null) return 'nog niet';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _confirmReset(BuildContext context, AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Vice.surfaceHi,
        title: const Text('Reset progress?'),
        content: const Text('This clears all unlocked checkmarks and favorites. It cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) await s.resetProgress();
  }
}
