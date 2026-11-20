import 'package:flutter/material.dart';

/// Semantic design tokens — "Vice City sunset" palette.
class Vice {
  // Surfaces
  static const bg = Color(0xFF0A0A14);
  static const surface = Color(0xFF14152A);
  static const surfaceHi = Color(0xFF1C1E3A);
  static const border = Color(0xFF2B2F52);

  // Accents
  static const pink = Color(0xFFFF2E93);
  static const orange = Color(0xFFFF8A3D);
  static const purple = Color(0xFF8B5CFF);
  static const cyan = Color(0xFF19F0FF);
  static const gold = Color(0xFFFFC857);

  // Text (all ≥4.5:1 on surface)
  static const text = Color(0xFFF5F5FF);
  static const muted = Color(0xFFA9AFD0);

  static const card = surface; // legacy alias

  static const sunset = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [pink, orange],
  );
  static const dusk = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A1148), Color(0xFF14102B), bg],
  );

  // 8dp rhythm
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s24 = 24.0;
  static const dur = Duration(milliseconds: 200);

  static Color categoryColor(String c) => switch (c) {
        'Player' => cyan,
        'Combat' => const Color(0xFFFF4D5E),
        'Vehicles' => orange,
        'Environment' => const Color(0xFF3DFFB0),
        'Filters' => purple,
        _ => pink,
      };

  static IconData categoryIcon(String c) => switch (c) {
        'Player' => Icons.person_rounded,
        'Combat' => Icons.gps_fixed_rounded,
        'Vehicles' => Icons.directions_car_rounded,
        'Environment' => Icons.wb_twilight_rounded,
        'Filters' => Icons.filter_vintage_rounded,
        _ => Icons.bolt_rounded,
      };

  static ThemeData theme() {
    const scheme = ColorScheme.dark(
      primary: pink,
      secondary: cyan,
      tertiary: orange,
      surface: surface,
      onSurface: text,
      outline: border,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: ThemeData.dark().textTheme.apply(bodyColor: text, displayColor: text),
      splashFactory: InkSparkle.splashFactory,
      focusColor: cyan.withValues(alpha: 0.3),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? cyan : null),
        checkColor: const WidgetStatePropertyAll(bg),
        side: const BorderSide(color: muted, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: pink.withValues(alpha: 0.22),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: s.contains(WidgetState.selected) ? text : muted,
            )),
        iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(color: s.contains(WidgetState.selected) ? pink : muted, size: 26)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHi,
        contentTextStyle: const TextStyle(color: text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceHi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Text painted with the sunset gradient.
class SunsetText extends StatelessWidget {
  final String text;
  final double size;
  const SunsetText(this.text, {super.key, this.size = 24});
  @override
  Widget build(BuildContext context) => ShaderMask(
        shaderCallback: (r) => Vice.sunset.createShader(r),
        blendMode: BlendMode.srcIn,
        child: Text(text,
            style: TextStyle(
                fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 2.5, fontStyle: FontStyle.italic)),
      );
}

/// Standard neon-bordered surface used by every card.
class NeonCard extends StatelessWidget {
  final Widget child;
  final Color? accent;
  final bool glow;
  final EdgeInsets padding;
  const NeonCard({
    super.key,
    required this.child,
    this.accent,
    this.glow = false,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? Vice.pink;
    return AnimatedContainer(
      duration: Vice.dur,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Vice.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glow ? a : Vice.border, width: glow ? 1.6 : 1),
        boxShadow: glow ? [BoxShadow(color: a.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: -2)] : const [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(children: [
          Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: a)),
          Padding(padding: padding.copyWith(left: padding.left + 4), child: child),
        ]),
      ),
    );
  }
}

/// Scale-on-press wrapper: transform only, so layout never shifts.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PressScale({super.key, required this.child, this.onTap});
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down && !reduce ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
