import 'dart:convert';

import '../internal/schema.dart';
import '../models/cardio/cardio_plan.dart';
import '../models/cardio/cardio_result.dart';
import '../models/workout_plan.dart';
import '../models/workout_result.dart';

class DataBundle {
  final int schemaVersion;
  final DateTime exportedAt;
  final List<WorkoutResult> workoutResults;
  final List<CardioResult> cardioResults;
  final List<WorkoutPlan> workoutPlans;
  final List<CardioPlan> cardioPlans;

  const DataBundle({
    required this.schemaVersion,
    required this.exportedAt,
    this.workoutResults = const [],
    this.cardioResults = const [],
    this.workoutPlans = const [],
    this.cardioPlans = const [],
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'workoutResults': workoutResults.map((e) => e.toJson()).toList(),
    'cardioResults': cardioResults.map((e) => e.toJson()).toList(),
    'workoutPlans': workoutPlans.map((e) => e.toJson()).toList(),
    'cardioPlans': cardioPlans.map((e) => e.toJson()).toList(),
  };

  factory DataBundle.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['schemaVersion'];
    final version =
        rawVersion is num ? rawVersion.toInt() : kPluginSchemaVersion;
    final rawExportedAt = json['exportedAt'];
    final exportedAt =
        rawExportedAt is String
            ? DateTime.parse(rawExportedAt)
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return DataBundle(
      schemaVersion: version,
      exportedAt: exportedAt,
      workoutResults: _decodeList(
        json['workoutResults'],
        WorkoutResult.fromJson,
      ),
      cardioResults: _decodeList(json['cardioResults'], CardioResult.fromJson),
      workoutPlans: _decodeList(json['workoutPlans'], WorkoutPlan.fromJson),
      cardioPlans: _decodeList(json['cardioPlans'], CardioPlan.fromJson),
    );
  }

  static List<T> _decodeList<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}

abstract class DataExport {
  static DataBundle bundle({
    List<WorkoutResult> workoutResults = const [],
    List<CardioResult> cardioResults = const [],
    List<WorkoutPlan> workoutPlans = const [],
    List<CardioPlan> cardioPlans = const [],
    DateTime? exportedAt,
  }) => DataBundle(
    schemaVersion: kPluginSchemaVersion,
    exportedAt: exportedAt ?? DateTime.now().toUtc(),
    workoutResults: workoutResults,
    cardioResults: cardioResults,
    workoutPlans: workoutPlans,
    cardioPlans: cardioPlans,
  );

  static String toJsonString(DataBundle b) =>
      const JsonEncoder.withIndent('  ').convert(b.toJson());
}
