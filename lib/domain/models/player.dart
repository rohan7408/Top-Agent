import 'player_attributes.dart';

enum PlayerPosition {
  goalkeeper,
  defender,
  midfielder,
  forward,
}

extension PlayerPositionLabel on PlayerPosition {
  String get label => switch (this) {
        PlayerPosition.goalkeeper => 'Goalkeeper',
        PlayerPosition.defender => 'Defender',
        PlayerPosition.midfielder => 'Midfielder',
        PlayerPosition.forward => 'Forward',
      };

  String get shortLabel => switch (this) {
        PlayerPosition.goalkeeper => 'GK',
        PlayerPosition.defender => 'DEF',
        PlayerPosition.midfielder => 'MID',
        PlayerPosition.forward => 'FWD',
      };
}

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.position,
    required this.potential,
    required this.attributes,
    required this.value,
    required this.salary,
    required this.isRecruited,
    this.clubId,
    this.agentId,
    this.contractEndSeason,
    this.isRetired = false,
    this.retirementSeason,
    this.fatigue = 0,
    this.consecutiveStarts = 0,
  });

  final String id;
  final String name;
  final int age;
  final int heightCm;
  final int weightKg;
  final PlayerPosition position;
  final int potential;
  final PlayerAttributes attributes;
  final double value;
  final String? clubId;
  final String? agentId;
  final double salary;
  final int? contractEndSeason;
  final bool isRecruited;
  final bool isRetired;
  final int? retirementSeason;
  final double fatigue;
  final int consecutiveStarts;

  int get attacking => attributes.attacking;
  int get defending => attributes.defending;
  int get technical => position == PlayerPosition.goalkeeper
      ? ((attributes.goalkeeping * 0.7) +
              (attributes.passing * 0.1) +
              (attributes.firstTouch * 0.1) +
              (attributes.positioning * 0.1))
          .round()
      : attributes.technical;
  int get mental => attributes.mental;
  int get physical => attributes.physical;
  int get speed => attributes.speed;

  int get ability => calculateOverall(position, attributes);

  static int calculateOverall(
    PlayerPosition position,
    PlayerAttributes attributes,
  ) {
    final attacking = attributes.attacking;
    final defending = attributes.defending;
    final technical = position == PlayerPosition.goalkeeper
        ? ((attributes.goalkeeping * 0.7) +
                (attributes.passing * 0.1) +
                (attributes.firstTouch * 0.1) +
                (attributes.positioning * 0.1))
            .round()
        : attributes.technical;
    final mental = attributes.mental;
    final physical = attributes.physical;
    final speed = attributes.speed;

    final overall = switch (position) {
      PlayerPosition.goalkeeper => (attacking * 0.02) +
          (defending * 0.08) +
          (technical * 0.38) +
          (mental * 0.20) +
          (physical * 0.16) +
          (speed * 0.16),
      PlayerPosition.defender => (attacking * 0.05) +
          (defending * 0.35) +
          (technical * 0.17) +
          (mental * 0.18) +
          (physical * 0.15) +
          (speed * 0.10),
      PlayerPosition.midfielder => (attacking * 0.15) +
          (defending * 0.13) +
          (technical * 0.28) +
          (mental * 0.22) +
          (physical * 0.10) +
          (speed * 0.12),
      PlayerPosition.forward => (attacking * 0.33) +
          (defending * 0.03) +
          (technical * 0.22) +
          (mental * 0.17) +
          (physical * 0.10) +
          (speed * 0.15),
    };
    return overall.round().clamp(1, 99);
  }

  Player copyWith({
    String? name,
    int? age,
    int? heightCm,
    int? weightKg,
    PlayerPosition? position,
    int? potential,
    PlayerAttributes? attributes,
    double? value,
    String? clubId,
    bool clearClubId = false,
    String? agentId,
    bool clearAgentId = false,
    double? salary,
    int? contractEndSeason,
    bool clearContractEndSeason = false,
    bool? isRecruited,
    bool? isRetired,
    int? retirementSeason,
    double? fatigue,
    int? consecutiveStarts,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      position: position ?? this.position,
      potential: potential ?? this.potential,
      attributes: attributes ?? this.attributes,
      value: value ?? this.value,
      clubId: clearClubId ? null : clubId ?? this.clubId,
      agentId: clearAgentId ? null : agentId ?? this.agentId,
      salary: salary ?? this.salary,
      contractEndSeason: clearContractEndSeason
          ? null
          : contractEndSeason ?? this.contractEndSeason,
      isRecruited: isRecruited ?? this.isRecruited,
      isRetired: isRetired ?? this.isRetired,
      retirementSeason: retirementSeason ?? this.retirementSeason,
      fatigue: fatigue ?? this.fatigue,
      consecutiveStarts: consecutiveStarts ?? this.consecutiveStarts,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'position': position.name,
        'ability': ability,
        'potential': potential,
        'attributes': attributes.toJson(),
        'value': value,
        'clubId': clubId,
        'agentId': agentId,
        'salary': salary,
        'contractEndSeason': contractEndSeason,
        'isRecruited': isRecruited,
        'isRetired': isRetired,
        'retirementSeason': retirementSeason,
        'fatigue': fatigue,
        'consecutiveStarts': consecutiveStarts,
      };

  factory Player.fromJson(Map<String, Object?> json) {
    return Player(
      id: json['id']! as String,
      name: json['name']! as String,
      age: json['age']! as int,
      heightCm: (json['heightCm'] as int?) ?? 180,
      weightKg: (json['weightKg'] as int?) ?? 75,
      position: PlayerPosition.values.byName(json['position']! as String),
      potential: json['potential']! as int,
      attributes: json['attributes'] == null
          ? PlayerAttributes.balanced(json['ability']! as int)
          : PlayerAttributes.fromJson(
              (json['attributes']! as Map).cast<String, Object?>(),
            ),
      value: (json['value']! as num).toDouble(),
      clubId: json['clubId'] as String?,
      agentId: json['agentId'] as String?,
      salary: (json['salary']! as num).toDouble(),
      contractEndSeason: json['contractEndSeason'] as int?,
      isRecruited: json['isRecruited']! as bool,
      isRetired: (json['isRetired'] as bool?) ?? false,
      retirementSeason: json['retirementSeason'] as int?,
      fatigue: ((json['fatigue'] as num?) ?? 0).toDouble(),
      consecutiveStarts: (json['consecutiveStarts'] as int?) ?? 0,
    );
  }
}
