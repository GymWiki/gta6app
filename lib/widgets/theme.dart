import 'package:flutter/material.dart';

class Vice {
  static const bg = Color(0xFF0B0C14);
  static const card = Color(0xFF151828);
  static const border = Color(0xFF252A42);
  static const pink = Color(0xFFFF2A85);
  static const cyan = Color(0xFF00F0FF);
  static const text = Color(0xFFF2F3FA);
  static const muted = Color(0xFF9AA0BD);

  static ThemeData theme() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.dark(primary: pink, secondary: cyan, surface: card),
        canvasColor: bg,
        useMaterial3: true,
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? cyan : null),
          checkColor: const WidgetStatePropertyAll(bg),
          side: const BorderSide(color: muted, width: 2),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: card,
          selectedItemColor: pink,
          unselectedItemColor: muted,
        ),
      );
}
