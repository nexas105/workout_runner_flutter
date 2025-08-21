import 'package:fitness_workout/fitness_workout.dart';
import 'package:fitness_workout/src/widgets/panel/current_exercise.dart';
import 'package:flutter/material.dart';

/// Kompakter Card-Banner, der entweder den CurrentExercise-Pager einblendet
/// (wenn keine aktive Übung existiert) oder – bei aktiver Übung – die Sätze
/// der aktuellen Übung mit Start/Stop/Edit-Logik zeigt.
/// Controller bitte mit übergeben
class QuickRunner extends StatefulWidget {
  final List<WorkoutPlan>? plans;
  final WorkoutRunnerController controller;
  final void Function(WorkoutResult?)? onFinished;
  final Route<void> Function(BuildContext context, WorkoutPlan plan)?
  runnerRouteBuilder;
  const QuickRunner({
    super.key,
    required this.controller,
    this.plans,
    this.onFinished,
    this.runnerRouteBuilder,
  });

  @override
  State<QuickRunner> createState() => _QuickRunnerState();
}

class _QuickRunnerState extends State<QuickRunner> {
  // NEU: Controller für den PageView
  late final PageController _pageController;
  int _selectedPlanIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialisiert den PageController
    _pageController = PageController();
  }

  @override
  void dispose() {
    // Gibt den Controller frei, um Speicherlecks zu vermeiden
    _pageController.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  PerformedSet? _performed(int exerciseIndex, int setIndex) {
    return widget.controller.getPerformedSet(exerciseIndex, setIndex);
  }

  (double, int, int) _initialValues({
    required int exerciseIndex,
    required int setIndex,
  }) {
    // 1) bereits performed?
    final p = _performed(exerciseIndex, setIndex);
    if (p != null) {
      final w = (p.actualWeight ?? 0).toDouble();
      final r = p.actualReps;
      final rir = p.rir ?? 2;
      return (w, r, rir);
    }
    // 2) sonst Targets
    final set = widget.controller.exercises[exerciseIndex].sets[setIndex];
    final w = (set.targetWeight ?? 0).toDouble();
    final r = set.targetReps;
    const rir = 2;
    return (w, r, rir);
  }

  void _openRunnerScreen(BuildContext context) {
    final plan = widget.controller.plan;
    if (plan == null) return;
    final builder = widget.runnerRouteBuilder;
    if (builder != null) {
      Navigator.of(context).push(builder(context, plan));
      return;
    }
    // Fallback: einfacher Default-Screen mit RunnerPanel
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(title: const Text('Runner')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: RunnerPanel(
                  controller: widget.controller,
                  plan: plan,
                  onFinished: widget.onFinished,
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _openEditSheet({
    required int exerciseIndex,
    required int setIndex,
    required bool finishingActiveSet,
  }) async {
    double w;
    int reps;
    int rir;

    final init = _initialValues(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
    );
    w = init.$1;
    reps = init.$2;
    rir = init.$3;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx2).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    finishingActiveSet
                        ? 'Satz speichern'
                        : 'Eintrag bearbeiten',
                    style: Theme.of(ctx2).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text('Gewicht: ${w.toStringAsFixed(1)} kg'),
                  Slider(
                    value: w,
                    min: 0,
                    max: 300,
                    divisions: 120,
                    onChanged: (v) => setLocal(() => w = v),
                  ),
                  Text('Wiederholungen: $reps'),
                  Slider(
                    value: reps.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    onChanged: (v) => setLocal(() => reps = v.round()),
                  ),
                  Text('RIR: $rir'),
                  Slider(
                    value: rir.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    onChanged: (v) => setLocal(() => rir = v.round()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(
                          finishingActiveSet ? 'Speichern' : 'Aktualisieren',
                        ),
                        onPressed: () async {
                          if (finishingActiveSet) {
                            await runner.finishActiveSet(
                              weight: w,
                              reps: reps,
                              rir: rir,
                            );
                          } else {
                            await runner.updatePerformedSet(
                              exerciseIndex: exerciseIndex,
                              setIndex: setIndex,
                              weight: w,
                              reps: reps,
                              rir: rir,
                            );
                          }
                          if (mounted) Navigator.of(ctx2).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    int _nextOpenSetIndex(int exIdx) {
      for (int i = 0; i < runner.exercises[exIdx].sets.length; i++) {
        if (runner.getPerformedSet(exIdx, i) == null) return i;
      }
      return -1;
    }

    return AnimatedBuilder(
      animation: runner,
      builder: (context, _) {
        // Keine Daten/Plan? – Plan-Übersicht oder Platzhalter
        if (runner.plan == null || runner.state == null) {
          final available = widget.plans ?? const <WorkoutPlan>[];
          if (available.isNotEmpty) {
            // ALT: War vorher eine ListView
            // NEU: Ist jetzt ein PageView mit Indikatoren
            return Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Wähle einen Plan',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    // Der PageView für horizontales Sliden
                    SizedBox(
                      height: 120, // Feste Höhe für den Pager
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: available.length,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedPlanIndex = index;
                          });
                        },
                        itemBuilder: (ctx, i) {
                          final p = available[i];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.name, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                '${p.exercises.length} Übungen',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  await runner.start(
                                    p,
                                    resumeIfPossible: false,
                                  );
                                },
                                child: const Text('Starten'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Die Indikator-Punkte
                    if (available.length > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(available.length, (index) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(
                              vertical: 10.0,
                              horizontal: 4.0,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _selectedPlanIndex == index
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface.withOpacity(
                                        0.24,
                                      ),
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              ),
            );
          }
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Workout wird initialisiert …',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }

        // Keine aktive Übung → den CurrentExercise-Pager zeigen
        if (!runner.hasActiveExercise) {
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Plan-Header + Finish-Button
                  Row(
                    children: [
                      // NEU: InkWell macht den Namen klickbar
                      Expanded(
                        child: InkWell(
                          onTap: () => _openRunnerScreen(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              runner.plan?.name ?? 'Aktueller Plan',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Workout beenden',
                        onPressed: () async {
                          final res = await runner.finish();
                          if (widget.onFinished != null) {
                            widget.onFinished!(res);
                          }
                        },
                        icon: const Icon(Icons.stop_circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Wähle eine Übung und starte sie',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  CurrentExercise(controller: widget.controller),
                  const SizedBox(height: 8),
                  Text(
                    'Tippe auf den Play/Pin-Button bei einer Übung um sie zu aktivieren.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Es existiert eine aktive Übung → deren Sätze anzeigen
        final activeExerciseIdx = runner.activeExerciseIndex;
        final activeExercise = runner.exercises[activeExerciseIdx];
        final isSetRunning = runner.isSetRunning;
        final activeSetExerciseIdx = runner.activeSetExerciseIndex;
        final activeSetIdx = runner.activeSetIndex;

        final totalSets = activeExercise.sets.length;
        int displayedSetIndex;
        if (isSetRunning &&
            activeSetExerciseIdx == activeExerciseIdx &&
            activeSetIdx != null) {
          displayedSetIndex = activeSetIdx;
        } else {
          final nextIdx = _nextOpenSetIndex(activeExerciseIdx);
          displayedSetIndex = nextIdx == -1 ? totalSets - 1 : nextIdx;
        }
        final performed = runner.getPerformedSet(
          activeExerciseIdx,
          displayedSetIndex,
        );
        final isThisRunning =
            isSetRunning &&
            activeSetExerciseIdx == activeExerciseIdx &&
            activeSetIdx == displayedSetIndex;
        final canStartThis =
            runner.canActivateSet(activeExerciseIdx) &&
            !isSetRunning &&
            performed == null &&
            !runner.isResting;

        return Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header mit Übungsname
                Row(
                  children: [
                    // NEU: InkWell macht den Namen klickbar
                    Expanded(
                      child: InkWell(
                        onTap: () => _openRunnerScreen(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            activeExercise.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    if (runner.isResting) ...[
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('Pause ${runner.restRemaining.inSeconds}s'),
                      ),
                      TextButton(
                        onPressed: runner.skipRest,
                        child: const Text('Skip'),
                      ),
                    ],
                    IconButton(
                      tooltip: 'Übung wechseln',
                      onPressed: () {
                        runner.clearActiveExercise();
                      },
                      icon: const Icon(Icons.swap_horiz),
                    ),
                    IconButton(
                      tooltip: 'Workout beenden',
                      onPressed: () async {
                        final res = await runner.finish();
                        if (widget.onFinished != null) widget.onFinished!(res);
                      },
                      icon: const Icon(Icons.stop_circle),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Laufender Set Timer
                if (isSetRunning &&
                    activeSetExerciseIdx == activeExerciseIdx &&
                    activeSetIdx != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Satz ${activeSetIdx + 1} läuft • ${_fmt(runner.currentSetElapsed)}',
                        ),
                      ],
                    ),
                  ),

                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      child: Text('${displayedSetIndex + 1}'),
                    ),
                    title: Text(
                      performed == null
                          ? 'Ziel: ${activeExercise.sets[displayedSetIndex].targetReps} Wdh' +
                              (activeExercise
                                          .sets[displayedSetIndex]
                                          .targetWeight !=
                                      null
                                  ? ' @ ${activeExercise.sets[displayedSetIndex].targetWeight!.toStringAsFixed(1)} kg'
                                  : '')
                          : 'Ergebnis: ${performed.actualReps} Wdh' +
                              (performed.actualWeight != null
                                  ? ' @ ${performed.actualWeight!.toStringAsFixed(1)} kg'
                                  : '') +
                              (performed.rir != null
                                  ? ' • RIR ${performed.rir}'
                                  : ''),
                    ),
                    subtitle:
                        performed == null
                            ? null
                            : (performed.duration != null
                                ? Text(
                                  'Satzdauer: ${_fmt(performed.duration!)}',
                                )
                                : null),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Satz starten',
                          onPressed:
                              canStartThis
                                  ? () {
                                    runner.startSet(
                                      activeExerciseIdx,
                                      displayedSetIndex,
                                    );
                                  }
                                  : null,
                          icon: const Icon(Icons.play_arrow),
                        ),
                        if (isThisRunning)
                          IconButton(
                            tooltip: 'Satz speichern',
                            onPressed: () {
                              _openEditSheet(
                                exerciseIndex: activeExerciseIdx,
                                setIndex: displayedSetIndex,
                                finishingActiveSet: true,
                              );
                            },
                            icon: const Icon(Icons.stop_circle),
                          )
                        else
                          IconButton(
                            tooltip:
                                performed == null
                                    ? 'Noch kein Eintrag'
                                    : 'Bearbeiten',
                            onPressed:
                                performed == null
                                    ? null
                                    : () {
                                      _openEditSheet(
                                        exerciseIndex: activeExerciseIdx,
                                        setIndex: displayedSetIndex,
                                        finishingActiveSet: false,
                                      );
                                    },
                            icon: const Icon(Icons.edit),
                          ),
                      ],
                    ),
                  ),
                ),

                if (!isSetRunning &&
                    runner.getPerformedSet(activeExerciseIdx, totalSets - 1) !=
                        null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Alle Sätze erledigt. Du kannst die Übung beenden.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),

                // ENTFERNT: Der Button zum Öffnen der Runner-Seite wurde entfernt.
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
