import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../widgets/sync_feedback.dart';
import '../widgets/theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final t = s.t;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
      NeonCard(
        accent: Vice.cyan,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.contentTitle, style: const TextStyle(color: Vice.text, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _row(t.lastUpdated, s.data.updatedAt.isEmpty ? '-' : s.data.updatedAt),
          _row(t.contentVersion, '${s.data.contentVersion}  ·  ${s.total} ${t.cheatsWord}'),
          _row(t.lastChecked, _fmt(s.lastChecked, t.never)),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Vice.pink,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: s.syncing ? null : () => refreshWithFeedback(context, s),
            icon: s.syncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.sync_rounded),
            label: Text(t.refreshNow),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Vice.pink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: Vice.pink),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _confirmReset(context, s),
        icon: const Icon(Icons.delete_outline_rounded),
        label: Text(t.resetProgress),
      ),
      const SizedBox(height: 24),
      Text(t.disclaimer, style: const TextStyle(color: Vice.muted, fontSize: 13, height: 1.5)),
    ]);
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Wrap(spacing: 8, children: [
          Text('$label:', style: const TextStyle(color: Vice.muted, fontSize: 15, height: 1.4)),
          Text(value, style: const TextStyle(color: Vice.text, fontSize: 15, height: 1.4, fontWeight: FontWeight.w700)),
        ]),
      );

  static String _fmt(DateTime? d, String never) {
    if (d == null) return never;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _confirmReset(BuildContext context, AppState s) async {
    final t = s.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.resetTitle),
        content: Text(t.resetBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Vice.pink),
            child: Text(t.reset),
          ),
        ],
      ),
    );
    if (ok == true) {
      await s.resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(t.resetDone)));
      }
    }
  }
}
