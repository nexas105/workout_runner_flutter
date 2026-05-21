enum EquipmentItem {
  barbell,
  dumbbell,
  kettlebell,
  machine,
  cable,
  bodyweight,
  bands,
  plates,
  bench,
  rack,
  pullupBar,
  treadmill,
  rower,
  stationaryBike,
  jumpRope,
  medball,
}

extension EquipmentItemId on EquipmentItem {
  String get id => name;
}

class EquipmentProfile {
  final Set<EquipmentItem> items;
  final String? name;

  EquipmentProfile({Set<EquipmentItem>? items, this.name})
    : items = Set.unmodifiable(items ?? const <EquipmentItem>{});

  EquipmentProfile.bodyweightOnly({this.name = 'Bodyweight Only'})
    : items = Set.unmodifiable(<EquipmentItem>{
        EquipmentItem.bodyweight,
        EquipmentItem.pullupBar,
      });

  EquipmentProfile.homeGymBasic({this.name = 'Home Gym'})
    : items = Set.unmodifiable(<EquipmentItem>{
        EquipmentItem.barbell,
        EquipmentItem.dumbbell,
        EquipmentItem.bench,
        EquipmentItem.rack,
        EquipmentItem.plates,
        EquipmentItem.bodyweight,
        EquipmentItem.pullupBar,
      });

  EquipmentProfile.commercialGym({this.name = 'Commercial Gym'})
    : items = Set.unmodifiable(EquipmentItem.values.toSet());

  EquipmentProfile.cardioStudio({this.name = 'Cardio Studio'})
    : items = Set.unmodifiable(<EquipmentItem>{
        EquipmentItem.treadmill,
        EquipmentItem.rower,
        EquipmentItem.stationaryBike,
        EquipmentItem.jumpRope,
        EquipmentItem.bodyweight,
      });

  bool get isEmpty => items.isEmpty;

  bool has(EquipmentItem item) => items.contains(item);

  Set<String> get idSet => items.map((i) => i.id).toSet();

  EquipmentProfile copyWith({Set<EquipmentItem>? items, String? name}) =>
      EquipmentProfile(items: items ?? this.items, name: name ?? this.name);

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.id).toList(),
    if (name != null) 'name': name,
  };

  factory EquipmentProfile.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final parsed = <EquipmentItem>{};
    if (raw is List) {
      for (final entry in raw) {
        if (entry is String) {
          for (final item in EquipmentItem.values) {
            if (item.id == entry) {
              parsed.add(item);
              break;
            }
          }
        }
      }
    }
    return EquipmentProfile(items: parsed, name: json['name'] as String?);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquipmentProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          items.length == other.items.length &&
          items.containsAll(other.items);

  @override
  int get hashCode => Object.hash(name, Object.hashAllUnordered(items));
}
