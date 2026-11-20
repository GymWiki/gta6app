import 'package:flutter/material.dart';

import '../services/cheat_search.dart';
import 'theme.dart';

/// Text with the parts that match the search query highlighted.
class HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final int maxLines;
  const HighlightText(this.text, {super.key, required this.query, required this.style, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final ranges = query.trim().isEmpty ? const <({int start, int end})>[] : CheatSearch.highlight(text, query);
    if (ranges.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final spans = <TextSpan>[];
    var pos = 0;
    for (final r in ranges) {
      if (r.start > pos) spans.add(TextSpan(text: text.substring(pos, r.start)));
      spans.add(TextSpan(
        text: text.substring(r.start, r.end),
        style: TextStyle(color: Vice.text, backgroundColor: Vice.pink.withValues(alpha: 0.45), fontWeight: FontWeight.w900),
      ));
      pos = r.end;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
    return Text.rich(TextSpan(style: style, children: spans), maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
}
