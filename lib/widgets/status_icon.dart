import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/content.dart';
import 'theme.dart';

/// Small status marker. Shape + color + tooltip, so it never relies on color alone.
class StatusIcon extends StatelessWidget {
  final CheatStatus status;
  final Strings t;
  final double size;
  const StatusIcon({super.key, required this.status, required this.t, this.size = 15});

  static (String, IconData, Color) spec(CheatStatus s, Strings t) => switch (s) {
        CheatStatus.verified => (t.statusVerified, Icons.verified_rounded, Vice.cyan),
        CheatStatus.unverified => (t.statusUnverified, Icons.help_outline_rounded, Vice.gold),
        CheatStatus.rumor => (t.statusRumor, Icons.hearing_rounded, Vice.purple),
      };

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = spec(status, t);
    return Semantics(label: label, child: Tooltip(message: label, child: Icon(icon, size: size, color: color)));
  }
}
