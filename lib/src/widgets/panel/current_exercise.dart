import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter/material.dart';

class CurrentExercise extends StatefulWidget {
  final WorkoutRunnerController controller;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color? activeBorderColor;
  final Color? inactiveBorderColor;
  final Color? activeCardColor;
  final Color? inactiveCardColor;
  final Color? activeIconColor;
  final Color? inactiveIconColor;

  const CurrentExercise({
    super.key,
    required this.controller,
    this.titleStyle,
    this.subtitleStyle,
    this.activeBorderColor,
    this.inactiveBorderColor,
    this.activeCardColor,
    this.inactiveCardColor,
    this.activeIconColor,
    this.inactiveIconColor,
  });

  @override
  State<CurrentExercise> createState() => _CurrentExerciseState();
}

class _CurrentExerciseState extends State<CurrentExercise> {
  late final PageController _pageController;
  bool _isUserScrolling = false;

  int _doneSetsFor(int exerciseIndex) {
    final st = widget.controller.state;
    if (st == null) return 0;
    final ex = st.performed.firstWhere(
      (e) => e.exerciseIndex == exerciseIndex,
      orElse:
          () => PerformedExercise(
            exerciseIndex: exerciseIndex,
            exerciseName: '',
            sets: const [],
          ),
    );
    return ex.sets.length;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: widget.controller.currentExerciseIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 168,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final items = widget.controller.exercises;
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Keine Übungen',
                style: widget.subtitleStyle ?? theme.textTheme.bodyMedium,
              ),
            );
          }

          final activePageIndex = widget.controller.currentExerciseIndex;

          if (!_isUserScrolling &&
              _pageController.hasClients &&
              (_pageController.page?.round() ?? _pageController.initialPage) !=
                  activePageIndex) {
            _pageController.animateToPage(
              activePageIndex,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification) _isUserScrolling = true;
              if (n is ScrollEndNotification) _isUserScrolling = false;
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              onPageChanged: (index) {
                if (index != widget.controller.currentExerciseIndex) {
                  widget.controller.changeExerciseIndex(index);
                }
              },
              itemCount: items.length,
              itemBuilder: (context, index) {
                final ex = items[index];
                final isPageActive = widget.controller.isExerciseActive(index);
                final pinned = widget.controller.state?.activeExerciseIndex;
                final isPinnedHere = pinned != null && pinned == index;
                final canStart = pinned == null;

                final totalSets = ex.sets.length;
                final doneSets = _doneSetsFor(index);
                final progress = totalSets == 0 ? 0.0 : doneSets / totalSets;
                final nextSetNr =
                    (doneSets < totalSets) ? (doneSets + 1) : totalSets;

                final borderColor =
                    isPageActive
                        ? (widget.activeBorderColor ??
                            theme.colorScheme.primary)
                        : (widget.inactiveBorderColor ??
                            theme.colorScheme.outlineVariant.withOpacity(0.6));

                final cardColor =
                    isPageActive
                        ? (widget.activeCardColor ??
                            theme.colorScheme.primaryContainer.withOpacity(
                              0.25,
                            ))
                        : (widget.inactiveCardColor ??
                            theme.colorScheme.surface);

                final iconColor =
                    isPageActive
                        ? (widget.activeIconColor ?? theme.colorScheme.primary)
                        : (widget.inactiveIconColor ?? theme.iconTheme.color);

                final titleStyle =
                    widget.titleStyle ??
                    theme.textTheme.titleMedium?.copyWith(
                      fontWeight:
                          isPageActive ? FontWeight.w600 : FontWeight.w500,
                    );

                final subtitleStyle =
                    widget.subtitleStyle ??
                    theme.textTheme.bodySmall?.copyWith(
                      color:
                          isPageActive
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                    );

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (!isPageActive) {
                        widget.controller.changeExerciseIndex(index);
                      }
                    },
                    child: Card(
                      elevation: isPageActive ? 2 : 0,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: borderColor,
                          width: isPageActive ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      isPageActive
                                          ? (widget.activeCardColor ??
                                              theme.colorScheme.primary
                                                  .withOpacity(0.15))
                                          : (widget.inactiveCardColor ??
                                              theme.colorScheme.surfaceVariant),
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: iconColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ex.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: titleStyle,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Übung ${index + 1} von ${items.length} • $doneSets/$totalSets Sätze'
                                        '${doneSets < totalSets ? ' • Nächster: Satz $nextSetNr' : ''}',
                                        style: subtitleStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isPinnedHere)
                                  IconButton(
                                    onPressed:
                                        () =>
                                            widget.controller
                                                .clearActiveExercise(),
                                    icon: const Icon(Icons.pause_circle_filled),
                                    tooltip: 'Pause',
                                  )
                                else
                                  IconButton(
                                    onPressed:
                                        canStart
                                            ? () => widget.controller
                                                .setActiveExercise(index)
                                            : null,
                                    icon: const Icon(Icons.play_circle_fill),
                                    tooltip:
                                        canStart ? 'Starten' : 'Bereits aktiv',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Fortschrittsleiste für erledigte Sätze
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress.isNaN ? 0.0 : progress,
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Kleine Legende rechtsbündig
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '$doneSets / $totalSets erledigt',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
