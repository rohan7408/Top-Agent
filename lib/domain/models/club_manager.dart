enum TacticalStyle {
  balanced,
  possession,
  highPress,
  counterAttack,
  defensive,
}

extension TacticalStyleLabel on TacticalStyle {
  String get label => switch (this) {
        TacticalStyle.balanced => 'Balanced',
        TacticalStyle.possession => 'Possession',
        TacticalStyle.highPress => 'High press',
        TacticalStyle.counterAttack => 'Counter attack',
        TacticalStyle.defensive => 'Defensive',
      };
}

class ClubManager {
  const ClubManager({
    required this.id,
    required this.clubId,
    required this.name,
    required this.age,
    required this.ability,
    required this.youthDevelopment,
    required this.transferNegotiation,
    required this.tacticalStyle,
    required this.contractEndSeason,
    required this.rotation,
  });

  final String id;
  final String clubId;
  final String name;
  final int age;
  final int ability;
  final int youthDevelopment;
  final int transferNegotiation;
  final TacticalStyle tacticalStyle;
  final int contractEndSeason;
  final int rotation;

  Map<String, Object> toJson() => {
        'id': id,
        'clubId': clubId,
        'name': name,
        'age': age,
        'ability': ability,
        'youthDevelopment': youthDevelopment,
        'transferNegotiation': transferNegotiation,
        'tacticalStyle': tacticalStyle.name,
        'contractEndSeason': contractEndSeason,
        'rotation': rotation,
      };

  factory ClubManager.fromJson(Map<String, Object?> json) => ClubManager(
        id: json['id']! as String,
        clubId: json['clubId']! as String,
        name: json['name']! as String,
        age: json['age']! as int,
        ability: json['ability']! as int,
        youthDevelopment: json['youthDevelopment']! as int,
        transferNegotiation: json['transferNegotiation']! as int,
        tacticalStyle:
            TacticalStyle.values.byName(json['tacticalStyle']! as String),
        contractEndSeason: json['contractEndSeason']! as int,
        rotation: (json['rotation'] as int?) ?? 60,
      );
}
