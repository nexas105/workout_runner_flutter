import 'package:flutter/material.dart';

import '../models/set_type.dart';

/// Per-[SetType] accent colour used for badges and set-row tinting in the
/// bundled widgets. Plain `Color` so consumers can wire any palette; the
/// foreground/background contrast pair is built by widgets at paint time
/// (using [WorkoutRunnerThemeData.onAccent] for solid badges).
typedef SetTypeAccents = Map<SetType, Color>;

/// Design tokens for the workout-runner widgets. Override fields on
/// [WorkoutRunnerThemeData] and wrap your subtree in [WorkoutRunnerTheme] to
/// re-style the bundled widgets.
@immutable
class WorkoutRunnerThemeData {
  // Colors
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color accent;
  final Color accentMuted;
  final Color hot;
  final Color hotMuted;
  final Color success;
  final Color danger;
  final Color textPrimary;
  final Color textMuted;
  final Color textDim;
  final Color onAccent;

  // Typography
  final TextStyle heroNumber;
  final TextStyle titleLarge;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodyMuted;
  final TextStyle caption;
  final TextStyle eyebrow;

  // Shape
  final BorderRadius radiusSmall;
  final BorderRadius radiusMedium;
  final BorderRadius radiusLarge;
  final BorderRadius radiusHero;
  final BorderRadius radiusPill;

  // Spacing scale (4, 8, 12, 16, 20, 24, 32)
  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space5;
  final double space6;
  final double space7;

  // Effects
  final List<BoxShadow> shadowCard;
  final List<BoxShadow> shadowGlow;
  final Duration motionFast;
  final Duration motionMedium;

  // Set-type styling — used by `set_view` and any consumer that wants to
  // distinguish warm-ups, drop sets, AMRAP and timed work.
  final SetTypeAccents setTypeAccents;

  // Timer / countdown styles — used by AMRAP / timed-set countdowns.
  final TextStyle timerDefault;
  final TextStyle timerWarning;
  final TextStyle timerSuccess;

  // Rest overlay tokens — colors / opacities for the bundled rest countdown.
  final Color restProgressColor;
  final Color restProgressTrackColor;
  final Color restBackdrop;

  const WorkoutRunnerThemeData({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.accent,
    required this.accentMuted,
    required this.hot,
    required this.hotMuted,
    required this.success,
    required this.danger,
    required this.textPrimary,
    required this.textMuted,
    required this.textDim,
    required this.onAccent,
    required this.heroNumber,
    required this.titleLarge,
    required this.title,
    required this.body,
    required this.bodyMuted,
    required this.caption,
    required this.eyebrow,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusHero,
    required this.radiusPill,
    required this.space1,
    required this.space2,
    required this.space3,
    required this.space4,
    required this.space5,
    required this.space6,
    required this.space7,
    required this.shadowCard,
    required this.shadowGlow,
    required this.motionFast,
    required this.motionMedium,
    required this.setTypeAccents,
    required this.timerDefault,
    required this.timerWarning,
    required this.timerSuccess,
    required this.restProgressColor,
    required this.restProgressTrackColor,
    required this.restBackdrop,
  });

  /// Default dark-first fitness look. Lime accent, deep neutral surfaces.
  factory WorkoutRunnerThemeData.dark() {
    const bg = Color(0xFF0B0C0F);
    const surface = Color(0xFF15171C);
    const surfaceEl = Color(0xFF1C1F25);
    const border = Color(0x142DE8B0); // lime tinted at 8%
    const accent = Color(0xFFC8F44A); // lime
    const accentMuted = Color(0x33C8F44A);
    const hot = Color(0xFFFF6A1A); // orange
    const hotMuted = Color(0x33FF6A1A);
    const success = Color(0xFF7CE2A8);
    const danger = Color(0xFFFF5A5F);
    const textPrimary = Color(0xFFF3F5F7);
    const textMuted = Color(0xFF9BA3AE);
    const textDim = Color(0xFF5C636E);

    return WorkoutRunnerThemeData(
      background: bg,
      surface: surface,
      surfaceElevated: surfaceEl,
      border: border,
      accent: accent,
      accentMuted: accentMuted,
      hot: hot,
      hotMuted: hotMuted,
      success: success,
      danger: danger,
      textPrimary: textPrimary,
      textMuted: textMuted,
      textDim: textDim,
      onAccent: const Color(0xFF0B0C0F),
      heroNumber: const TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        height: 1.0,
        letterSpacing: -1.5,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        height: 1.1,
        letterSpacing: -0.4,
      ),
      title: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.2,
      ),
      body: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.35,
      ),
      bodyMuted: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textMuted,
        height: 1.35,
      ),
      caption: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textMuted,
        height: 1.3,
      ),
      eyebrow: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textMuted,
        height: 1.0,
        letterSpacing: 1.2,
      ),
      radiusSmall: const BorderRadius.all(Radius.circular(10)),
      radiusMedium: const BorderRadius.all(Radius.circular(16)),
      radiusLarge: const BorderRadius.all(Radius.circular(22)),
      radiusHero: const BorderRadius.all(Radius.circular(28)),
      radiusPill: const BorderRadius.all(Radius.circular(999)),
      space1: 4,
      space2: 8,
      space3: 12,
      space4: 16,
      space5: 20,
      space6: 24,
      space7: 32,
      shadowCard: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
      shadowGlow: const [
        BoxShadow(color: Color(0x55C8F44A), blurRadius: 28, spreadRadius: -4),
      ],
      motionFast: const Duration(milliseconds: 180),
      motionMedium: const Duration(milliseconds: 320),
      setTypeAccents: const {
        SetType.working: accent,
        SetType.warmup: Color(0xFF8BB4FF), // cool blue
        SetType.drop: hot, // orange
        SetType.failure: danger, // red
        SetType.amrap: success, // mint
        SetType.timed: Color(0xFFB39DFF), // violet
      },
      timerDefault: const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        height: 1.0,
        letterSpacing: -1.0,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      timerWarning: const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: hot,
        height: 1.0,
        letterSpacing: -1.0,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      timerSuccess: const TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: success,
        height: 1.0,
        letterSpacing: -1.0,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      restProgressColor: accent,
      restProgressTrackColor: const Color(0x14F3F5F7),
      restBackdrop: const Color(0xCC0B0C0F),
    );
  }

  /// Light variant for apps that follow system theme.
  factory WorkoutRunnerThemeData.light() {
    const bg = Color(0xFFF5F6F8);
    const surface = Color(0xFFFFFFFF);
    const surfaceEl = Color(0xFFF9FAFB);
    const border = Color(0x14000000);
    const accent = Color(0xFF6E8F00);
    const accentMuted = Color(0x336E8F00);
    const hot = Color(0xFFE85B12);
    const hotMuted = Color(0x33E85B12);
    const success = Color(0xFF1E9D5B);
    const danger = Color(0xFFE5484D);
    const textPrimary = Color(0xFF15171C);
    const textMuted = Color(0xFF5C636E);
    const textDim = Color(0xFF9BA3AE);

    final dark = WorkoutRunnerThemeData.dark();
    return WorkoutRunnerThemeData(
      background: bg,
      surface: surface,
      surfaceElevated: surfaceEl,
      border: border,
      accent: accent,
      accentMuted: accentMuted,
      hot: hot,
      hotMuted: hotMuted,
      success: success,
      danger: danger,
      textPrimary: textPrimary,
      textMuted: textMuted,
      textDim: textDim,
      onAccent: const Color(0xFFFFFFFF),
      heroNumber: dark.heroNumber.copyWith(color: textPrimary),
      titleLarge: dark.titleLarge.copyWith(color: textPrimary),
      title: dark.title.copyWith(color: textPrimary),
      body: dark.body.copyWith(color: textPrimary),
      bodyMuted: dark.bodyMuted.copyWith(color: textMuted),
      caption: dark.caption.copyWith(color: textMuted),
      eyebrow: dark.eyebrow.copyWith(color: textMuted),
      radiusSmall: dark.radiusSmall,
      radiusMedium: dark.radiusMedium,
      radiusLarge: dark.radiusLarge,
      radiusHero: dark.radiusHero,
      radiusPill: dark.radiusPill,
      space1: dark.space1,
      space2: dark.space2,
      space3: dark.space3,
      space4: dark.space4,
      space5: dark.space5,
      space6: dark.space6,
      space7: dark.space7,
      shadowCard: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
      shadowGlow: const [
        BoxShadow(color: Color(0x336E8F00), blurRadius: 24, spreadRadius: -4),
      ],
      motionFast: dark.motionFast,
      motionMedium: dark.motionMedium,
      setTypeAccents: {
        SetType.working: accent,
        SetType.warmup: const Color(0xFF3D6BD9),
        SetType.drop: hot,
        SetType.failure: danger,
        SetType.amrap: success,
        SetType.timed: const Color(0xFF6E4FE0),
      },
      timerDefault: dark.timerDefault.copyWith(color: textPrimary),
      timerWarning: dark.timerWarning.copyWith(color: hot),
      timerSuccess: dark.timerSuccess.copyWith(color: success),
      restProgressColor: accent,
      restProgressTrackColor: const Color(0x14000000),
      restBackdrop: const Color(0xCC0B0C0F),
    );
  }

  /// Build a theme by mapping a Material [ColorScheme] onto the package
  /// design tokens. Convenient when your app already drives all colours from
  /// `Theme.of(context).colorScheme` and you want the workout runner to
  /// inherit that palette instead of using its own dark/light defaults.
  ///
  /// The mapping is opinionated — override individual fields via [copyWith]
  /// if the result doesn't match your brand exactly.
  factory WorkoutRunnerThemeData.fromColorScheme(ColorScheme scheme) {
    final base =
        scheme.brightness == Brightness.light
            ? WorkoutRunnerThemeData.light()
            : WorkoutRunnerThemeData.dark();
    final accent = scheme.primary;
    final hot = scheme.tertiary;
    final danger = scheme.error;
    final success =
        scheme.brightness == Brightness.light
            ? const Color(0xFF1E9D5B)
            : const Color(0xFF7CE2A8);

    return base.copyWith(
      background: scheme.surface,
      surface: scheme.surfaceContainerHighest,
      surfaceElevated: scheme.surfaceContainerHigh,
      border: scheme.outlineVariant,
      accent: accent,
      accentMuted: accent.withValues(alpha: 0.2),
      hot: hot,
      hotMuted: hot.withValues(alpha: 0.2),
      success: success,
      danger: danger,
      textPrimary: scheme.onSurface,
      textMuted: scheme.onSurfaceVariant,
      textDim: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      onAccent: scheme.onPrimary,
      heroNumber: base.heroNumber.copyWith(color: scheme.onSurface),
      titleLarge: base.titleLarge.copyWith(color: scheme.onSurface),
      title: base.title.copyWith(color: scheme.onSurface),
      body: base.body.copyWith(color: scheme.onSurface),
      bodyMuted: base.bodyMuted.copyWith(color: scheme.onSurfaceVariant),
      caption: base.caption.copyWith(color: scheme.onSurfaceVariant),
      eyebrow: base.eyebrow.copyWith(color: scheme.onSurfaceVariant),
      setTypeAccents: {
        SetType.working: accent,
        SetType.warmup: scheme.secondary,
        SetType.drop: hot,
        SetType.failure: danger,
        SetType.amrap: success,
        SetType.timed: scheme.tertiary,
      },
      timerDefault: base.timerDefault.copyWith(color: scheme.onSurface),
      timerWarning: base.timerWarning.copyWith(color: hot),
      timerSuccess: base.timerSuccess.copyWith(color: success),
      restProgressColor: accent,
      restProgressTrackColor: scheme.surfaceContainerLow,
      restBackdrop: scheme.scrim.withValues(alpha: 0.8),
    );
  }

  WorkoutRunnerThemeData copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? accent,
    Color? accentMuted,
    Color? hot,
    Color? hotMuted,
    Color? success,
    Color? danger,
    Color? textPrimary,
    Color? textMuted,
    Color? textDim,
    Color? onAccent,
    TextStyle? heroNumber,
    TextStyle? titleLarge,
    TextStyle? title,
    TextStyle? body,
    TextStyle? bodyMuted,
    TextStyle? caption,
    TextStyle? eyebrow,
    BorderRadius? radiusSmall,
    BorderRadius? radiusMedium,
    BorderRadius? radiusLarge,
    BorderRadius? radiusHero,
    BorderRadius? radiusPill,
    double? space1,
    double? space2,
    double? space3,
    double? space4,
    double? space5,
    double? space6,
    double? space7,
    List<BoxShadow>? shadowCard,
    List<BoxShadow>? shadowGlow,
    Duration? motionFast,
    Duration? motionMedium,
    SetTypeAccents? setTypeAccents,
    TextStyle? timerDefault,
    TextStyle? timerWarning,
    TextStyle? timerSuccess,
    Color? restProgressColor,
    Color? restProgressTrackColor,
    Color? restBackdrop,
  }) => WorkoutRunnerThemeData(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    border: border ?? this.border,
    accent: accent ?? this.accent,
    accentMuted: accentMuted ?? this.accentMuted,
    hot: hot ?? this.hot,
    hotMuted: hotMuted ?? this.hotMuted,
    success: success ?? this.success,
    danger: danger ?? this.danger,
    textPrimary: textPrimary ?? this.textPrimary,
    textMuted: textMuted ?? this.textMuted,
    textDim: textDim ?? this.textDim,
    onAccent: onAccent ?? this.onAccent,
    heroNumber: heroNumber ?? this.heroNumber,
    titleLarge: titleLarge ?? this.titleLarge,
    title: title ?? this.title,
    body: body ?? this.body,
    bodyMuted: bodyMuted ?? this.bodyMuted,
    caption: caption ?? this.caption,
    eyebrow: eyebrow ?? this.eyebrow,
    radiusSmall: radiusSmall ?? this.radiusSmall,
    radiusMedium: radiusMedium ?? this.radiusMedium,
    radiusLarge: radiusLarge ?? this.radiusLarge,
    radiusHero: radiusHero ?? this.radiusHero,
    radiusPill: radiusPill ?? this.radiusPill,
    space1: space1 ?? this.space1,
    space2: space2 ?? this.space2,
    space3: space3 ?? this.space3,
    space4: space4 ?? this.space4,
    space5: space5 ?? this.space5,
    space6: space6 ?? this.space6,
    space7: space7 ?? this.space7,
    shadowCard: shadowCard ?? this.shadowCard,
    shadowGlow: shadowGlow ?? this.shadowGlow,
    motionFast: motionFast ?? this.motionFast,
    motionMedium: motionMedium ?? this.motionMedium,
    setTypeAccents: setTypeAccents ?? this.setTypeAccents,
    timerDefault: timerDefault ?? this.timerDefault,
    timerWarning: timerWarning ?? this.timerWarning,
    timerSuccess: timerSuccess ?? this.timerSuccess,
    restProgressColor: restProgressColor ?? this.restProgressColor,
    restProgressTrackColor:
        restProgressTrackColor ?? this.restProgressTrackColor,
    restBackdrop: restBackdrop ?? this.restBackdrop,
  );

  /// Convenience accessor for [setTypeAccents] with a guaranteed fallback to
  /// the regular [accent] colour.
  Color accentFor(SetType type) => setTypeAccents[type] ?? accent;
}

/// Wrap any subtree in this widget to provide a [WorkoutRunnerThemeData].
/// Defaults to the dark fitness preset when no ancestor exists.
class WorkoutRunnerTheme extends InheritedTheme {
  final WorkoutRunnerThemeData data;

  const WorkoutRunnerTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static WorkoutRunnerThemeData of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<WorkoutRunnerTheme>();
    return inherited?.data ?? WorkoutRunnerThemeData.dark();
  }

  @override
  bool updateShouldNotify(WorkoutRunnerTheme oldWidget) =>
      data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      WorkoutRunnerTheme(data: data, child: child);
}
