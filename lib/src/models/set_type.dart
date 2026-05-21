/// Semantic flavour of a set inside a [WorkoutPlan].
///
/// * [working] — the default; a regular straight set against the target.
/// * [warmup] — preparatory set, usually lighter, not counted toward PRs.
/// * [drop] — a drop set continuation: weight reduced, taken to failure.
/// * [failure] — set explicitly taken to muscular failure.
/// * [amrap] — "as many reps as possible" inside a fixed time window.
/// * [timed] — duration-bound effort (planks, isometric holds).
enum SetType { working, warmup, drop, failure, amrap, timed }

extension SetTypeSerializer on SetType {
  String get id => name;

  static SetType fromId(String? raw) {
    if (raw == null) return SetType.working;
    return SetType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => SetType.working,
    );
  }
}
