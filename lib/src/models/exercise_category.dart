import 'package:flutter/foundation.dart';

@immutable
class ExerciseCategory {
  final String id;
  final String name;
  final String? description;

  const ExerciseCategory({
    required this.id,
    required this.name,
    this.description,
  });

  ExerciseCategory copyWith({String? id, String? name, String? description}) =>
      ExerciseCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
  };

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) =>
      ExerciseCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ExerciseCategory($id, $name)';
}
