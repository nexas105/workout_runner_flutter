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
export 'src/models/exercise_metadata.dart';
export 'src/models/muscle.dart';
export 'src/models/performed_exercise.dart';
export 'src/models/performed_set.dart';
export 'src/models/set_type.dart';
export 'src/models/workout_block.dart';
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
export 'src/data/cardio_templates.dart';
export 'src/data/catalog.dart';
export 'src/data/default_cardio_plans.dart';
export 'src/data/default_categories.dart';
export 'src/data/default_exercises.dart';
export 'src/data/default_muscles.dart';
export 'src/data/default_plans.dart';
export 'src/data/strength_templates.dart';

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

// Feedback (haptics / audio / voice / rating) -------------------------------
export 'src/feedback/runner_audio.dart';
export 'src/feedback/runner_audio_bridge.dart';
export 'src/feedback/runner_haptics.dart';
export 'src/feedback/runner_haptics_bridge.dart';
export 'src/feedback/runner_voice.dart';
export 'src/feedback/session_rating.dart';

// Notes ----------------------------------------------------------------------
export 'src/notes/notes_timeline.dart';
export 'src/notes/workout_notes.dart';

// Scheduling -----------------------------------------------------------------
export 'src/scheduling/scheduled_workout.dart';

// Error model ----------------------------------------------------------------
export 'src/error/error_messages.dart';
export 'src/error/runner_action_result.dart';

// Intelligence (overload / recommendations / rest / plan gen / readiness) ---
export 'src/intelligence/deload.dart';
export 'src/intelligence/equipment_profile.dart';
export 'src/intelligence/exercise_picker.dart';
export 'src/intelligence/overload.dart';
export 'src/intelligence/plan_generator.dart';
export 'src/intelligence/readiness.dart';
export 'src/intelligence/recommendations.dart';
export 'src/intelligence/rest_preset.dart';

// Stats & PR detection -------------------------------------------------------
export 'src/stats/personal_records.dart';
export 'src/stats/streaming_stats.dart';
export 'src/stats/weekly_workout_summary.dart';
export 'src/stats/workout_stats.dart';

// Search ---------------------------------------------------------------------
export 'src/search/exercise_alternatives.dart';
export 'src/search/exercise_index.dart';
export 'src/search/exercise_search.dart';

// Tags -----------------------------------------------------------------------
export 'src/tags/tag_filter.dart';
export 'src/tags/workout_tags.dart';

// Completion rules ----------------------------------------------------------
export 'src/completion/completion_rules.dart';

// Sync DTOs ------------------------------------------------------------------
export 'src/sync/sync_envelope.dart';
export 'src/sync/sync_merge.dart';

// Privacy --------------------------------------------------------------------
export 'src/privacy/audit.dart';
export 'src/privacy/consent.dart';
export 'src/privacy/data_export.dart';
export 'src/privacy/redaction.dart';

// Form cues ------------------------------------------------------------------
export 'src/cues/form_cues.dart';

// Coach mode -----------------------------------------------------------------
export 'src/coach/coach_engine.dart';
export 'src/coach/coach_signal.dart';
export 'src/coach/coaching_message.dart';

// Program blocks -------------------------------------------------------------
export 'src/program/program_progress.dart';
export 'src/program/program_templates.dart';
export 'src/program/training_program.dart';

// Import / export helpers ----------------------------------------------------
export 'src/export/share_helpers.dart';
export 'src/import/workout_import.dart';

// Units & formatting ---------------------------------------------------------
export 'src/units/measurement_system.dart';
export 'src/units/plate_calculator.dart';
export 'src/units/unit_conversions.dart';
export 'src/units/unit_formatters.dart';
export 'src/units/warmup_generator.dart';

// Storage --------------------------------------------------------------------
export 'src/storage/custom_entity_registry.dart';
export 'src/storage/exercise_favorites_storage.dart';
export 'src/storage/in_memory_custom_entity_registry.dart';
export 'src/storage/in_memory_exercise_favorites_storage.dart';
export 'src/storage/in_memory_paged_history_storage.dart';
export 'src/storage/in_memory_runner_storage.dart';
export 'src/storage/in_memory_workout_history_storage.dart';
export 'src/storage/paged_history_storage.dart';
export 'src/storage/plan_draft_controller.dart';
export 'src/storage/plan_draft_storage.dart';
export 'src/storage/prefs_runner_storage.dart';
export 'src/storage/runner_storage.dart';
export 'src/storage/scheduled_workout_storage.dart';
export 'src/storage/session_rating_storage.dart';
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

// Dashboard widgets ----------------------------------------------------------
export 'src/widgets/dashboard/pr_highlights_card.dart';
export 'src/widgets/dashboard/recent_sessions_list.dart';
export 'src/widgets/dashboard/volume_trend_chart.dart';
export 'src/widgets/dashboard/weekly_summary_card.dart';

// Onboarding widgets ---------------------------------------------------------
export 'src/widgets/onboarding/equipment_picker_sheet.dart';
export 'src/widgets/onboarding/experience_level_picker.dart';
export 'src/widgets/onboarding/goal_picker_sheet.dart';
export 'src/widgets/onboarding/plan_generation_profile_sheet.dart';

// Focus runner UI (Phase 2.8) ------------------------------------------------
export 'src/widgets/focus/exercise_focus_card.dart';
export 'src/widgets/focus/focus_action_bar.dart';
export 'src/widgets/focus/next_up_strip.dart';
export 'src/widgets/focus/runner_focus_panel.dart';
export 'src/widgets/focus/session_header.dart';
export 'src/widgets/focus/set_timeline.dart';

// Editors --------------------------------------------------------------------
export 'src/widgets/editors/cardio_plan_editor_screen.dart';
export 'src/widgets/editors/catalog_picker_sheet.dart';
export 'src/widgets/editors/category_editor_sheet.dart';
export 'src/widgets/editors/exercise_editor_sheet.dart';
export 'src/widgets/editors/meta_field_row.dart';
export 'src/widgets/editors/muscle_editor_sheet.dart';
export 'src/widgets/editors/plan_editor_screen.dart';

// Cardio widgets -------------------------------------------------------------
export 'src/widgets/cardio_quick_runner.dart';
export 'src/widgets/cardio_results_view.dart';
export 'src/widgets/cardio_runner_panel.dart';
export 'src/widgets/cardio_runner_scope.dart';
export 'src/widgets/cardio_runner_status.dart';

// Screens --------------------------------------------------------------------
export 'src/screens/cardio_runner_screen.dart';
export 'src/screens/runner_screen.dart';
