/// Public API of the `fitness_workout` package.
///
/// The package ships two complementary runners:
///
/// * [WorkoutRunner] — sets × reps × weight, for strength workouts.
/// * [CardioRunner] — interval / lap based, for running, cycling, rowing,
///   HIIT, jump rope, etc.
///
/// Both are `ChangeNotifier`s and share the same [RunnerStorage] abstraction,
/// so the same app can run a strength and a cardio session side-by-side (each
/// uses its own storage slot).
library;

// Controllers ----------------------------------------------------------------
export 'src/controller/cardio_runner.dart';
export 'src/controller/workout_runner.dart';

// Strength models ------------------------------------------------------------
export 'src/models/exercise_category.dart';
export 'src/models/muscle.dart';
export 'src/models/performed_exercise.dart';
export 'src/models/performed_set.dart';
export 'src/models/set_type.dart';
export 'src/models/workout_exercise.dart';
export 'src/models/workout_plan.dart';
export 'src/models/workout_plan_builder.dart';
export 'src/models/workout_plan_validation.dart';
export 'src/models/workout_result.dart';
export 'src/models/workout_runner_state.dart';
export 'src/models/workout_set.dart';

// Cardio models --------------------------------------------------------------
export 'src/models/cardio/cardio_interval.dart';
export 'src/models/cardio/cardio_lap.dart';
export 'src/models/cardio/cardio_plan.dart';
export 'src/models/cardio/cardio_plan_builder.dart';
export 'src/models/cardio/cardio_result.dart';
export 'src/models/cardio/cardio_runner_state.dart';

// Data catalogues (muscles, categories, exercises, preset plans) ------------
export 'src/data/default_cardio_plans.dart';
export 'src/data/default_categories.dart';
export 'src/data/default_exercises.dart';
export 'src/data/default_muscles.dart';
export 'src/data/default_plans.dart';

// Schema versioning ----------------------------------------------------------
export 'src/internal/schema.dart' show kPluginSchemaVersion;

// Localization ---------------------------------------------------------------
export 'src/l10n/workout_runner_localizations.dart';

// Energy / kcal helpers ------------------------------------------------------
export 'src/internal/energy.dart'
    show
        EnergyEstimator,
        kDefaultMet,
        kDefaultMetByCategoryId,
        kDefaultMetByDiscipline;

// Units & formatting ---------------------------------------------------------
export 'src/units/measurement_system.dart';
export 'src/units/plate_calculator.dart';
export 'src/units/unit_conversions.dart';
export 'src/units/unit_formatters.dart';

// Storage --------------------------------------------------------------------
export 'src/storage/in_memory_runner_storage.dart';
export 'src/storage/in_memory_workout_history_storage.dart';
export 'src/storage/prefs_runner_storage.dart';
export 'src/storage/runner_storage.dart';
export 'src/storage/workout_history_storage.dart';

// Theme ----------------------------------------------------------------------
export 'src/theme/workout_runner_theme.dart';

// Shared widget building blocks ---------------------------------------------
export 'src/widgets/internals/runner_card.dart';
export 'src/widgets/internals/runner_pill_button.dart';
export 'src/widgets/internals/section_label.dart';
export 'src/widgets/internals/timer_text.dart';

// Strength widgets -----------------------------------------------------------
export 'src/widgets/quick_runner.dart';
export 'src/widgets/results_view.dart';
export 'src/widgets/runner_panel.dart';
export 'src/widgets/runner_status.dart';
export 'src/widgets/set_view.dart';
export 'src/widgets/runner_scope.dart';

// Cardio widgets -------------------------------------------------------------
export 'src/widgets/cardio_quick_runner.dart';
export 'src/widgets/cardio_results_view.dart';
export 'src/widgets/cardio_runner_panel.dart';
export 'src/widgets/cardio_runner_scope.dart';
export 'src/widgets/cardio_runner_status.dart';

// Screens --------------------------------------------------------------------
export 'src/screens/cardio_runner_screen.dart';
export 'src/screens/runner_screen.dart';
