enum RestGoal { strength, hypertrophy, endurance, mobility, hiit }

class RestPreset {
  final Duration duration;
  final RestGoal goal;
  final String label;

  const RestPreset({
    required this.duration,
    required this.goal,
    required this.label,
  });
}

const Map<RestGoal, RestPreset> kDefaultRestPresets = {
  RestGoal.strength: RestPreset(
    duration: Duration(seconds: 180),
    goal: RestGoal.strength,
    label: 'Strength',
  ),
  RestGoal.hypertrophy: RestPreset(
    duration: Duration(seconds: 90),
    goal: RestGoal.hypertrophy,
    label: 'Hypertrophy',
  ),
  RestGoal.endurance: RestPreset(
    duration: Duration(seconds: 45),
    goal: RestGoal.endurance,
    label: 'Endurance',
  ),
  RestGoal.mobility: RestPreset(
    duration: Duration(seconds: 30),
    goal: RestGoal.mobility,
    label: 'Mobility',
  ),
  RestGoal.hiit: RestPreset(
    duration: Duration(seconds: 20),
    goal: RestGoal.hiit,
    label: 'HIIT',
  ),
};

abstract class RestPresetResolver {
  static const Duration _fallback = Duration(seconds: 90);

  static Duration resolve({
    Duration? planDefault,
    Duration? exerciseDefault,
    Duration? setDefault,
    RestGoal? planGoal,
  }) {
    if (setDefault != null) return setDefault;
    if (exerciseDefault != null) return exerciseDefault;
    if (planDefault != null) return planDefault;
    if (planGoal != null) {
      final preset = kDefaultRestPresets[planGoal];
      if (preset != null) return preset.duration;
    }
    return _fallback;
  }
}
