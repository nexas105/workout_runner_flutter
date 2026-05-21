import '../internal/schema.dart';

enum ProgramDayKind { strength, cardio, rest, mobility }

class ProgramDay {
  final String id;
  final String label;
  final ProgramDayKind kind;
  final String? planId;
  final String? notes;
  final Map<String, dynamic>? meta;

  const ProgramDay({
    required this.id,
    required this.label,
    required this.kind,
    this.planId,
    this.notes,
    this.meta,
  });

  ProgramDay copyWith({
    String? id,
    String? label,
    ProgramDayKind? kind,
    String? planId,
    String? notes,
    Map<String, dynamic>? meta,
  }) => ProgramDay(
    id: id ?? this.id,
    label: label ?? this.label,
    kind: kind ?? this.kind,
    planId: planId ?? this.planId,
    notes: notes ?? this.notes,
    meta: meta ?? this.meta,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'kind': kind.name,
    if (planId != null) 'planId': planId,
    if (notes != null) 'notes': notes,
    if (meta != null) 'meta': meta,
  };

  factory ProgramDay.fromJson(Map<String, dynamic> json) => ProgramDay(
    id: json['id'] as String,
    label: json['label'] as String,
    kind: ProgramDayKind.values.firstWhere(
      (k) => k.name == json['kind'] as String,
      orElse: () => ProgramDayKind.rest,
    ),
    planId: json['planId'] as String?,
    notes: json['notes'] as String?,
    meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
  );
}

class ProgramWeek {
  final int index;
  final List<ProgramDay> days;
  final String? notes;

  const ProgramWeek({
    required this.index,
    required this.days,
    this.notes,
  });

  ProgramWeek copyWith({
    int? index,
    List<ProgramDay>? days,
    String? notes,
  }) => ProgramWeek(
    index: index ?? this.index,
    days: days ?? this.days,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => {
    'index': index,
    'days': days.map((d) => d.toJson()).toList(),
    if (notes != null) 'notes': notes,
  };

  factory ProgramWeek.fromJson(Map<String, dynamic> json) => ProgramWeek(
    index: (json['index'] as num).toInt(),
    days: (json['days'] as List<dynamic>)
        .map((d) => ProgramDay.fromJson(d as Map<String, dynamic>))
        .toList(),
    notes: json['notes'] as String?,
  );
}

class TrainingProgram {
  final String id;
  final String name;
  final String? description;
  final List<ProgramWeek> weeks;
  final Map<String, dynamic>? meta;

  const TrainingProgram({
    required this.id,
    required this.name,
    required this.weeks,
    this.description,
    this.meta,
  });

  TrainingProgram copyWith({
    String? id,
    String? name,
    String? description,
    List<ProgramWeek>? weeks,
    Map<String, dynamic>? meta,
  }) => TrainingProgram(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    weeks: weeks ?? this.weeks,
    meta: meta ?? this.meta,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': kPluginSchemaVersion,
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'weeks': weeks.map((w) => w.toJson()).toList(),
    if (meta != null) 'meta': meta,
  };

  factory TrainingProgram.fromJson(Map<String, dynamic> json) =>
      TrainingProgram(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        weeks: (json['weeks'] as List<dynamic>)
            .map((w) => ProgramWeek.fromJson(w as Map<String, dynamic>))
            .toList(),
        meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
      );

  int get totalDays =>
      weeks.fold(0, (sum, w) => sum + w.days.length);

  int get totalStrengthDays => weeks.fold(
    0,
    (sum, w) =>
        sum + w.days.where((d) => d.kind == ProgramDayKind.strength).length,
  );

  int get totalCardioDays => weeks.fold(
    0,
    (sum, w) =>
        sum + w.days.where((d) => d.kind == ProgramDayKind.cardio).length,
  );

  ProgramDay? dayAt(int week, int day) {
    final w = weeks.firstWhere(
      (x) => x.index == week,
      orElse: () => const ProgramWeek(index: -1, days: []),
    );
    if (w.index == -1) return null;
    if (day < 0 || day >= w.days.length) return null;
    return w.days[day];
  }
}
