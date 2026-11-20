import 'package:flutter/material.dart';

import '../providers/app_state.dart';
import '../services/cheat_repository.dart';

/// Manual refresh (pull-to-refresh or button) with a short result message.
Future<void> refreshWithFeedback(BuildContext context, AppState s) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final r = await s.refresh(force: true);
  final t = s.t;
  final msg = switch (r.status) {
    SyncStatus.updated => t.updatedTo(s.data.contentVersion),
    SyncStatus.notModified || SyncStatus.skippedThrottle || SyncStatus.busy => t.upToDate,
    SyncStatus.schemaTooNew => t.needsAppUpdate,
    SyncStatus.notConfigured => t.notConfigured,
    SyncStatus.failed => t.offline,
  };
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
}
