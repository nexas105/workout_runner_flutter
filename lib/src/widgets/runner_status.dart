import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

// Assuming these are the correct paths for your project

typedef DurationFormatter = String Function(Duration);

/// ===========================================================================
/// Shared Utils (jetzt Controller-basiert)
/// ===========================================================================
class _RunnerStatusUtils {
  static String defaultFmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static bool hasActiveRun(WorkoutRunnerController controller) =>
      controller.isRunning &&
      controller.state != null &&
      controller.plan != null;

  static List<String> parts({
    required WorkoutRunnerController controller,
    required DurationFormatter fmt,
    required bool showExerciseTimer,
    required bool showSetTimer,
  }) {
    final st = controller.state!;
    final p = controller.plan!;
    final list = <String>[
      p.name,
      '${st.exerciseIndex + 1}/${p.exercises.length}',
      fmt(controller.elapsed),
    ];
    if (showSetTimer && controller.isSetRunning) {
      list.add('S:${fmt(controller.currentSetElapsed)}');
    }
    return list;
  }

  // KORRIGIERT: Nimmt den Controller entgegen, um den aktiven Plan zu erhalten
  static void navigateToRunner(
    BuildContext context,
    WorkoutRunnerController controller,
  ) {
    // Nur navigieren, wenn ein Plan aktiv ist
    final activePlan = controller.plan;
    if (activePlan == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        // 'const' entfernt, da 'activePlan' eine Variable ist
        builder: (ctx) => RunnerDefaultScreen(plan: activePlan),
      ),
    );
  }

  static Widget buildInlineLabel(
    BuildContext context, {
    required List<String> parts,
    bool dense = true,
  }) {
    final style = (dense
            ? Theme.of(context).textTheme.labelSmall
            : Theme.of(context).textTheme.labelMedium)
        ?.copyWith(height: 1.1);
    return Text(
      parts.join(' • '),
      style: style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      softWrap: false,
    );
  }

  static Widget icon(BuildContext context, {double size = 16}) {
    return Icon(
      Icons.fitness_center,
      size: size,
      color: Theme.of(context).iconTheme.color,
    );
  }
}

/// ===========================================================================
/// RunnerStatusChip
/// ===========================================================================
class RunnerStatusChip extends StatelessWidget {
  final WorkoutRunnerController controller;
  final DurationFormatter? format;
  final bool showExerciseTimer;
  final bool showSetTimer;
  final bool dense;
  final EdgeInsetsGeometry padding;
  final bool showIcon;
  final String? tooltip;

  const RunnerStatusChip({
    super.key,
    required this.controller,
    this.format,
    this.showExerciseTimer = true,
    this.showSetTimer = false,
    this.dense = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.showIcon = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = format ?? _RunnerStatusUtils.defaultFmt;
    final chipTheme = ChipTheme.of(context);
    return Padding(
      padding: padding,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (!_RunnerStatusUtils.hasActiveRun(controller)) {
            return const SizedBox.shrink();
          }

          final parts = _RunnerStatusUtils.parts(
            controller: controller,
            fmt: fmt,
            showExerciseTimer: showExerciseTimer,
            showSetTimer: showSetTimer,
          );

          final content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                _RunnerStatusUtils.icon(context, size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: _RunnerStatusUtils.buildInlineLabel(
                  context,
                  parts: parts,
                  dense: dense,
                ),
              ),
            ],
          );

          final chip = Chip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: chipTheme.backgroundColor,
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 0,
            ),
            label: content,
          );

          // KORRIGIERT: Übergibt den Controller an die Navigationsfunktion
          final tappable = InkWell(
            onTap:
                () => _RunnerStatusUtils.navigateToRunner(context, controller),
            borderRadius: BorderRadius.circular(16),
            child: chip,
          );

          return tooltip == null
              ? tappable
              : Tooltip(message: tooltip!, child: tappable);
        },
      ),
    );
  }
}

/// ===========================================================================
/// RunnerStatusBanner (full-width Card/Banner)
/// ===========================================================================
class RunnerStatusBanner extends StatelessWidget {
  final WorkoutRunnerController controller;
  final DurationFormatter? format;
  final bool showExerciseTimer;
  final bool showSetTimer;
  final bool showIcon;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? background;
  final BorderRadiusGeometry borderRadius;
  final double elevation;
  final TextStyle? textStyle;
  final String? tooltip;

  const RunnerStatusBanner({
    super.key,
    required this.controller,
    this.format,
    this.showExerciseTimer = true,
    this.showSetTimer = false,
    this.showIcon = true,
    this.padding = const EdgeInsets.all(12),
    this.margin = const EdgeInsets.all(12),
    this.background,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.elevation = 1.0,
    this.textStyle,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = format ?? _RunnerStatusUtils.defaultFmt;
    final theme = Theme.of(context);
    final bg = background ?? theme.colorScheme.surface;

    final card = AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!_RunnerStatusUtils.hasActiveRun(controller)) {
          return const SizedBox.shrink();
        }

        final parts = _RunnerStatusUtils.parts(
          controller: controller,
          fmt: fmt,
          showExerciseTimer: showExerciseTimer,
          showSetTimer: showSetTimer,
        );

        final label = Text(
          parts.join(' • '),
          style: textStyle ?? theme.textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );

        final row = Row(
          children: [
            if (showIcon) ...[
              _RunnerStatusUtils.icon(context, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(child: label),
            Icon(Icons.chevron_right, color: theme.iconTheme.color),
          ],
        );

        final material = Material(
          elevation: elevation,
          color: bg,
          borderRadius: borderRadius,
          child: InkWell(
            onTap:
                () => _RunnerStatusUtils.navigateToRunner(context, controller),
            borderRadius:
                borderRadius is BorderRadius
                    ? borderRadius as BorderRadius
                    : null,
            child: Padding(padding: padding, child: row),
          ),
        );

        return Padding(padding: margin, child: material);
      },
    );

    return tooltip == null ? card : Tooltip(message: tooltip!, child: card);
  }
}

/// ===========================================================================
/// RunnerStatusBottomBar (für Scaffold.bottomNavigationBar)
/// ===========================================================================
class RunnerStatusBottomBar extends StatelessWidget {
  final WorkoutRunnerController controller;
  final DurationFormatter? format;
  final bool showExerciseTimer;
  final bool showSetTimer;
  final bool showIcon;
  final double height;
  final String? tooltip;

  const RunnerStatusBottomBar({
    super.key,
    required this.controller,
    this.format,
    this.showExerciseTimer = true,
    this.showSetTimer = false,
    this.showIcon = true,
    this.height = 56,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = format ?? _RunnerStatusUtils.defaultFmt;
    final theme = Theme.of(context);

    final bar = AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!_RunnerStatusUtils.hasActiveRun(controller)) {
          return const SizedBox.shrink();
        }

        final parts = _RunnerStatusUtils.parts(
          controller: controller,
          fmt: fmt,
          showExerciseTimer: showExerciseTimer,
          showSetTimer: showSetTimer,
        );

        return Material(
          color: theme.colorScheme.surface,
          elevation: 8,
          child: InkWell(
            onTap:
                () => _RunnerStatusUtils.navigateToRunner(context, controller),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (showIcon) ...[
                      _RunnerStatusUtils.icon(context),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        parts.join(' • '),
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.iconTheme.color),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return tooltip == null ? bar : Tooltip(message: tooltip!, child: bar);
  }
}

/// ===========================================================================
/// RunnerStatusAppBar (drop-in AppBar)
/// ===========================================================================
class RunnerStatusAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final WorkoutRunnerController controller;
  final DurationFormatter? format;
  final bool showExerciseTimer;
  final bool showSetTimer;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final String? fallbackTitle;

  const RunnerStatusAppBar({
    super.key,
    required this.controller,
    this.format,
    this.showExerciseTimer = true,
    this.showSetTimer = false,
    this.centerTitle = false,
    this.actions,
    this.leading,
    this.height = kToolbarHeight,
    this.fallbackTitle = 'Workouts',
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final fmt = format ?? _RunnerStatusUtils.defaultFmt;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasRun = _RunnerStatusUtils.hasActiveRun(controller);
        final theme = Theme.of(context);

        Widget title;
        if (hasRun) {
          final st = controller.state!;
          final p = controller.plan!;
          title = Column(
            crossAxisAlignment:
                centerTitle
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${p.name} • ${st.exerciseIndex + 1}/${p.exercises.length}',
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'W: ${fmt(controller.elapsed)}',
                    style: theme.textTheme.labelSmall,
                  ),
                  if (showSetTimer && controller.isSetRunning) ...[
                    const SizedBox(width: 8),
                    Text(
                      'S: ${fmt(controller.currentSetElapsed)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ],
          );
        } else {
          title = Text(fallbackTitle ?? '', style: theme.textTheme.titleLarge);
        }

        return AppBar(
          title: title,
          centerTitle: centerTitle,
          leading: leading,
          actions: actions,
        );
      },
    );
  }
}
