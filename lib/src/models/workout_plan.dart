import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'workout_exercise.dart';

@immutable
class WorkoutPlan {
  final String id;
  final String name;
  final String? description;
  final List<WorkoutExercise> exercises;
  final Map<String, dynamic>? meta;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.exercises,
    this.description,
    this.meta,
  });

  WorkoutPlan copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkoutExercise>? exercises,
    Map<String, dynamic>? meta,
  }) =>
      WorkoutPlan(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        exercises: exercises ?? this.exercises,
        meta: meta ?? this.meta,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        if (meta != null) 'meta': meta,
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        exercises: (json['exercises'] as List<dynamic>)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
      );

  String toJsonString() => jsonEncode(toJson());
  factory WorkoutPlan.fromJsonString(String s) =>
      WorkoutPlan.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutPlan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
