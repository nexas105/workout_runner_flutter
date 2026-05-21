import 'package:flutter/foundation.dart';

@immutable
class Muscle {
  final String id;
  final String name;
  final String? group;

  const Muscle({required this.id, required this.name, this.group});

  Muscle copyWith({String? id, String? name, String? group}) => Muscle(
    id: id ?? this.id,
    name: name ?? this.name,
    group: group ?? this.group,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (group != null) 'group': group,
  };

  factory Muscle.fromJson(Map<String, dynamic> json) => Muscle(
    id: json['id'] as String,
    name: json['name'] as String,
    group: json['group'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Muscle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Muscle($id, $name)';
}
