import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'theme.dart';

/// Search box bound to AppState.query, with a clear button. Stays in sync when
/// the query is reset from elsewhere (e.g. "Clear filters").
class SearchField extends StatefulWidget {
  const SearchField({super.key});
  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (_controller.text != s.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.text != s.query) {
          _controller.value = TextEditingValue(
            text: s.query,
            selection: TextSelection.collapsed(offset: s.query.length),
          );
        }
      });
    }
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: _controller,
      onChanged: s.setQuery,
      textInputAction: TextInputAction.search,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: const TextStyle(color: Vice.text, fontSize: 16),
      decoration: InputDecoration(
        hintText: s.t.searchHint,
        hintStyle: const TextStyle(color: Vice.muted),
        prefixIcon: const Icon(Icons.search_rounded, color: Vice.muted),
        suffixIcon: s.query.isEmpty
            ? null
            : IconButton(
                tooltip: s.t.clearSearch,
                icon: const Icon(Icons.close_rounded, color: Vice.muted),
                onPressed: () => s.setQuery(''),
              ),
        filled: true,
        fillColor: Vice.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border(Vice.border),
        enabledBorder: border(Vice.border),
        focusedBorder: border(Vice.pink, 1.6),
      ),
    );
  }
}
