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
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Vice.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Vice.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Data', style: TextStyle(color: Vice.text, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('data_version: ${s.data.dataVersion}\nlast_updated: ${s.data.lastUpdated}\ncheats loaded: ${s.total}',
              style: const TextStyle(color: Vice.muted)),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Vice.pink),
            onPressed: s.syncing
                ? null
                : () async {
                    final r = await s.sync();
                    if (!context.mounted) return;
                    final msg = switch (r) {
                      SyncResult.updated => 'Updated to data version ${s.data.dataVersion}.',
                      SyncResult.upToDate => 'Already up to date.',
                      SyncResult.failed => 'Could not reach the server. Using saved data.',
                    };
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  },
            icon: s.syncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            label: const Text('Force Sync Data'),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: Vice.pink, side: const BorderSide(color: Vice.pink)),
        onPressed: () => _confirmReset(context, s),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Reset Progress'),
      ),
      const SizedBox(height: 24),
      const Text(
        'Unofficial fan-made companion app. Not affiliated with, endorsed, or sponsored by Rockstar Games or Take-Two Interactive.',
        style: TextStyle(color: Vice.muted, fontSize: 12, height: 1.4),
      ),
    ]);
  }

  Future<void> _confirmReset(BuildContext context, AppState s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Vice.card,
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
