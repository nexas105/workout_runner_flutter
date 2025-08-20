import 'package:flutter/material.dart';
import 'package:fitness_workout/fitness_workout.dart';

class SetView extends StatefulWidget {
  final WorkoutRunnerController controller;
  final TextStyle? titleStyle;
  final TextStyle? inputStyle;
  final Color? activeCardColor;
  final Color? inactiveCardColor;
  final Color? doneCardColor;

  const SetView({
    super.key,
    required this.controller,
    this.titleStyle,
    this.inputStyle,
    this.activeCardColor,
    this.inactiveCardColor,
    this.doneCardColor,
  });

  @override
  State<SetView> createState() => _SetViewState();
}

class _SetViewState extends State<SetView> {
  late final PageController _pageController;

  // Eingabepuffer je Satz
  final Map<String, double> _weight = {};
  final Map<String, int> _reps = {};
  final Map<String, int> _rir = {};

  String? _restKey;
  DateTime? _restStartedAt;
  final Map<String, Duration> _lastSetDuration = {};
  final Map<String, Duration> _lastRestDuration = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _k(int ex, int si) => '$ex-$si';

  void _invalidateLocal(int ex, int si) {
    final key = _k(ex, si);
    _weight.remove(key);
    _reps.remove(key);
    _rir.remove(key);
  }

  PerformedSet? _performedSet(int exerciseIndex, int setIndex) {
    final st = widget.controller.state;
    if (st == null) return null;
    final ex = st.performed.firstWhere(
      (e) => e.exerciseIndex == exerciseIndex,
      orElse:
          () => PerformedExercise(
            exerciseIndex: exerciseIndex,
            exerciseName: '',
            sets: const [],
          ),
    );
    try {
      return ex.sets.firstWhere((s) => s.setIndex == setIndex);
    } catch (_) {
      return null;
    }
  }

  (double, int, int) _performedValuesOrFallback(
    int ex,
    int si,
    double w,
    int r,
    int rir,
  ) {
    final p = _performedSet(ex, si);
    if (p != null) {
      final pw = p.actualWeight ?? w;
      final pr = p.actualReps;
      final prir = p.rir ?? rir;
      return (pw, pr, prir);
    }
    return (w, r, rir);
  }

  double _initWeight(int ex, int si) {
    final key = _k(ex, si);
    if (_weight.containsKey(key)) return _weight[key]!;
    final p = _performedSet(ex, si);
    if (p != null && p.actualWeight != null) {
      return _weight[key] = p.actualWeight!;
    }
    final t = widget.controller.exercises[ex].sets[si].targetWeight ?? 0;
    return _weight[key] = t.toDouble();
  }

  int _initReps(int ex, int si) {
    final key = _k(ex, si);
    if (_reps.containsKey(key)) return _reps[key]!;
    final p = _performedSet(ex, si);
    if (p != null) return _reps[key] = p.actualReps;
    final t = widget.controller.exercises[ex].sets[si].targetReps;
    return _reps[key] = t;
  }

  int _initRir(int ex, int si) {
    final key = _k(ex, si);
    if (_rir.containsKey(key)) return _rir[key]!;
    final p = _performedSet(ex, si);
    if (p != null && p.rir != null) return _rir[key] = p.rir!;
    return _rir[key] = 2;
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _goToNextSet(int currentIndex, int total) {
    final next = (currentIndex + 1).clamp(0, total - 1);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ex = widget.controller.currentExercise;
        if (ex == null) {
          return Center(
            child: Text(
              'Keine aktive Übung',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        final exerciseIdx = widget.controller.currentExerciseIndex;
        final isActiveExercise =
            widget.controller.hasActiveExercise &&
            widget.controller.activeExerciseIndex == exerciseIdx;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Satzanzahl)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Sätze: ${ex.sets.length}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Globales Pause-Banner (optional – du kannst es entfernen, wenn nur Inline-Timer gewünscht sind)
            if (widget.controller.isResting && _restKey == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Chip(
                      label: Text(
                        'Pause ${widget.controller.restRemaining.inSeconds}s',
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.controller.skipRest,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),

            // Set-Karten
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _pageController,
                padEnds: false,
                itemCount: ex.sets.length,
                itemBuilder: (context, setIdx) {
                  final totalSets = ex.sets.length;
                  final key = _k(exerciseIdx, setIdx);

                  final performed = _performedSet(exerciseIdx, setIdx);
                  final wasPerformed = performed != null;

                  if (_restKey == key &&
                      !widget.controller.isResting &&
                      _restStartedAt != null) {
                    final restDur = DateTime.now().difference(_restStartedAt!);
                    _lastRestDuration[key] = restDur;

                    // Fallback: Werte aus performed (oder lokale Slider)
                    final wValTmp = _initWeight(exerciseIdx, setIdx);
                    final rValTmp = _initReps(exerciseIdx, setIdx);
                    final rirValTmp = _initRir(exerciseIdx, setIdx);
                    final (_pw, _pr, _prir) = _performedValuesOrFallback(
                      exerciseIdx,
                      setIdx,
                      wValTmp,
                      rValTmp,
                      rirValTmp,
                    );

                    widget.controller.updatePerformedSet(
                      exerciseIndex: exerciseIdx,
                      setIndex: setIdx,
                      weight: _pw,
                      reps: _pr,
                      rir: _prir,
                    );

                    _invalidateLocal(exerciseIdx, setIdx);

                    _restKey = null;
                    _restStartedAt = null;
                    _goToNextSet(setIdx, totalSets);
                  }

                  final isThisActiveSet =
                      widget.controller.activeSetExerciseIndex == exerciseIdx &&
                      widget.controller.activeSetIndex == setIdx;
                  final canStart =
                      isActiveExercise &&
                      widget.controller.activeSetIndex == null;

                  final cardColor =
                      wasPerformed
                          ? (widget.doneCardColor ??
                              theme.colorScheme.tertiaryContainer.withOpacity(
                                0.25,
                              ))
                          : isThisActiveSet
                          ? (widget.activeCardColor ??
                              theme.colorScheme.primaryContainer.withOpacity(
                                0.25,
                              ))
                          : (widget.inactiveCardColor ??
                              theme.colorScheme.surface);

                  final wVal = _initWeight(exerciseIdx, setIdx);
                  final rVal = _initReps(exerciseIdx, setIdx);
                  final rirVal = _initRir(exerciseIdx, setIdx);

                  final showInlineRest =
                      widget.controller.isResting && _restKey == key;

                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 8,
                    ),
                    child: Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Satz ${setIdx + 1}/$totalSets',
                                  style:
                                      widget.titleStyle ??
                                      theme.textTheme.titleMedium,
                                ),
                                const Spacer(),
                                if (isThisActiveSet)
                                  Row(
                                    children: [
                                      const Icon(Icons.timer, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        _fmt(
                                          widget.controller.currentSetElapsed,
                                        ),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  )
                                else if (_lastSetDuration.containsKey(key))
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_off, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        _fmt(_lastSetDuration[key]!),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                              ],
                            ),

                            if (!isThisActiveSet && wasPerformed) ...[
                              const SizedBox(height: 4),
                              if (_lastSetDuration[key] != null)
                                Text(
                                  'Satzzeit: ${_fmt(_lastSetDuration[key]!)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (_lastRestDuration[key] != null)
                                Text(
                                  'Pause: ${_fmt(_lastRestDuration[key]!)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                            ],

                            const SizedBox(height: 8),

                            if (showInlineRest) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.hourglass_bottom),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pause läuft',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleSmall,
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${widget.controller.restRemaining.inSeconds}s',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (_) {
                                        final total = widget
                                            .controller
                                            .defaultSetRest
                                            .inSeconds
                                            .clamp(1, 3600);
                                        final left = widget
                                            .controller
                                            .restRemaining
                                            .inSeconds
                                            .clamp(0, total);
                                        final progress = 1.0 - (left / total);
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: LinearProgressIndicator(
                                            value:
                                                progress.isNaN
                                                    ? null
                                                    : progress,
                                            minHeight: 8,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          widget.controller.skipRest();
                                          final started = _restStartedAt;
                                          if (started != null) {
                                            _lastRestDuration[key] =
                                                DateTime.now().difference(
                                                  started,
                                                );
                                          }
                                          setState(() {
                                            _restKey = null;
                                            _restStartedAt = null;
                                          });
                                          _goToNextSet(setIdx, totalSets);
                                        },
                                        icon: const Icon(Icons.skip_next),
                                        label: const Text('Timer überspringen'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            if (!showInlineRest)
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gewicht: ${wVal.toStringAsFixed(1)} kg',
                                          style:
                                              widget.inputStyle ??
                                              theme.textTheme.bodyMedium,
                                        ),
                                        Slider(
                                          value: wVal,
                                          min: 0,
                                          max: 300,
                                          divisions: 120,
                                          label: wVal.toStringAsFixed(1),
                                          onChanged:
                                              isThisActiveSet
                                                  ? (v) => setState(
                                                    () => _weight[key] = v,
                                                  )
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            if (!showInlineRest)
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Wdh: $rVal',
                                          style:
                                              widget.inputStyle ??
                                              theme.textTheme.bodyMedium,
                                        ),
                                        Slider(
                                          value: rVal.toDouble(),
                                          min: 1,
                                          max: 30,
                                          divisions: 29,
                                          label: '$rVal',
                                          onChanged:
                                              isThisActiveSet
                                                  ? (v) => setState(
                                                    () =>
                                                        _reps[key] = v.round(),
                                                  )
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'RIR: $rirVal',
                                          style:
                                              widget.inputStyle ??
                                              theme.textTheme.bodyMedium,
                                        ),
                                        Slider(
                                          value: rirVal.toDouble(),
                                          min: 0,
                                          max: 5,
                                          divisions: 5,
                                          label: '$rirVal',
                                          onChanged:
                                              isThisActiveSet
                                                  ? (v) => setState(
                                                    () => _rir[key] = v.round(),
                                                  )
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                            const Spacer(),

                            Row(
                              children: [
                                if (!isThisActiveSet && !wasPerformed)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          (canStart)
                                              ? () => widget.controller
                                                  .startSet(exerciseIdx, setIdx)
                                              : null,
                                      icon: const Icon(Icons.play_arrow),
                                      label: const Text('Start'),
                                    ),
                                  )
                                else if (isThisActiveSet)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final endW = _weight[key] ?? wVal;
                                        final endR = _reps[key] ?? rVal;
                                        final endRir = _rir[key] ?? rirVal;

                                        // Satzdauer merken (vom laufenden Timer)
                                        _lastSetDuration[key] =
                                            widget.controller.currentSetElapsed;

                                        final ok = await widget.controller
                                            .finishActiveSet(
                                              weight: endW,
                                              reps: endR,
                                              rir: endRir,
                                              setDuration:
                                                  widget
                                                      .controller
                                                      .currentSetElapsed,
                                            );
                                        if (!mounted || !ok) return;

                                        setState(() {
                                          _restKey = key;
                                          _restStartedAt = DateTime.now();
                                        });
                                      },
                                      icon: const Icon(Icons.stop),
                                      label: const Text('Speichern'),
                                    ),
                                  )
                                else if (!showInlineRest)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        await showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (ctx) {
                                            double w = _weight[key] ?? wVal;
                                            int reps = _reps[key] ?? rVal;
                                            int rir = _rir[key] ?? rirVal;

                                            return StatefulBuilder(
                                              builder: (ctx2, setLocal) {
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom:
                                                        MediaQuery.of(
                                                          ctx2,
                                                        ).viewInsets.bottom +
                                                        16,
                                                    left: 16,
                                                    right: 16,
                                                    top: 16,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Eintrag bearbeiten',
                                                        style:
                                                            theme
                                                                .textTheme
                                                                .titleMedium,
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),

                                                      Text(
                                                        'Gewicht: ${w.toStringAsFixed(1)} kg',
                                                      ),
                                                      Slider(
                                                        value: w,
                                                        min: 0,
                                                        max: 300,
                                                        divisions: 120,
                                                        onChanged:
                                                            (v) => setLocal(
                                                              () => w = v,
                                                            ),
                                                      ),

                                                      Text('Wdh: $reps'),
                                                      Slider(
                                                        value: reps.toDouble(),
                                                        min: 1,
                                                        max: 30,
                                                        divisions: 29,
                                                        onChanged:
                                                            (v) => setLocal(
                                                              () =>
                                                                  reps =
                                                                      v.round(),
                                                            ),
                                                      ),

                                                      Text('RIR: $rir'),
                                                      Slider(
                                                        value: rir.toDouble(),
                                                        min: 0,
                                                        max: 5,
                                                        divisions: 5,
                                                        onChanged:
                                                            (v) => setLocal(
                                                              () =>
                                                                  rir =
                                                                      v.round(),
                                                            ),
                                                      ),

                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Spacer(),
                                                          ElevatedButton.icon(
                                                            onPressed: () async {
                                                              await widget
                                                                  .controller
                                                                  .updatePerformedSet(
                                                                    exerciseIndex:
                                                                        exerciseIdx,
                                                                    setIndex:
                                                                        setIdx,
                                                                    weight: w,
                                                                    reps: reps,
                                                                    rir: rir,
                                                                  );
                                                              if (mounted) {
                                                                setState(() {
                                                                  _invalidateLocal(
                                                                    exerciseIdx,
                                                                    setIdx,
                                                                  );
                                                                });
                                                                Navigator.of(
                                                                  ctx2,
                                                                ).pop();
                                                              }
                                                            },
                                                            icon: const Icon(
                                                              Icons.save,
                                                            ),
                                                            label: const Text(
                                                              'Speichern',
                                                            ),
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
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Bearbeiten'),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
