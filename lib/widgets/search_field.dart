import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import 'theme.dart';

/// Search box (48dp). Filters while typing (debounced ~120ms), has a clear button and
/// stays in sync when the query is reset from elsewhere ("Clear filters").
class SearchField extends StatefulWidget {
  const SearchField({super.key});
  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  static const _debounce = Duration(milliseconds: 120);
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(AppState s, String v) {
    _timer?.cancel();
    if (v.isEmpty) {
      s.setQuery('');
      return;
    }
    _timer = Timer(_debounce, () => s.setQuery(v));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // Follow external resets (not while a debounced edit is pending).
    if (!(_timer?.isActive ?? false) && _controller.text != s.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !(_timer?.isActive ?? false) && _controller.text != s.query) {
          _controller.value = TextEditingValue(text: s.query, selection: TextSelection.collapsed(offset: s.query.length));
        }
      });
    }
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return SizedBox(
      height: 48,
      child: TextField(
        controller: _controller,
        onChanged: (v) => _onChanged(s, v),
        textInputAction: TextInputAction.search,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        style: const TextStyle(color: Vice.text, fontSize: 16),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: s.t.searchHint,
          hintStyle: const TextStyle(color: Vice.muted),
          prefixIcon: const Icon(Icons.search_rounded, color: Vice.muted),
          suffixIcon: ListenableBuilder(
            listenable: _controller,
            builder: (_, __) => _controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: s.t.clearSearch,
                    icon: const Icon(Icons.close_rounded, color: Vice.muted),
                    onPressed: () {
                      _timer?.cancel();
                      _controller.clear();
                      s.setQuery('');
                    },
                  ),
          ),
          filled: true,
          fillColor: Vice.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: border(Vice.border),
          enabledBorder: border(Vice.border),
          focusedBorder: border(Vice.pink, 1.6),
        ),
      ),
    );
  }
}
