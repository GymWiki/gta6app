import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where "missing a cheat? report it" goes. Replace with your own address.
const String feedbackEmail = 'cheats@example.com';

/// Opens the mail app with the search term as context. If no mail app can be opened,
/// the address is copied to the clipboard instead. Returns true when a mail app opened.
Future<bool> reportMissingCheat(String searchTerm) async {
  final uri = Uri(
    scheme: 'mailto',
    path: feedbackEmail,
    query: 'subject=${Uri.encodeComponent('Missing cheat')}&body=${Uri.encodeComponent(searchTerm.isEmpty ? '' : 'Cheat: $searchTerm')}',
  );
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
  } catch (_) {}
  try {
    await Clipboard.setData(const ClipboardData(text: feedbackEmail));
  } catch (_) {
    // No clipboard either: the caller still shows its message, nothing else to do.
  }
  return false;
}
