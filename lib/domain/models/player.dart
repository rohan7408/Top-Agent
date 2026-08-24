import 'player_attributes.dart';
import 'player_personality.dart';

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
    this.personality = const PlayerPersonality(),
    this.agentTrust = 100,
    this.agencyRelationshipWeeks = 0,
    this.clubId,
    this.agentId,
    this.contractEndSeason,
    this.isRetired = false,
    this.retirementSeason,
    this.fatigue = 0,
    this.consecutiveStarts = 0,
    this.isTransferListed = false,
    this.isLoanListed = false,
    this.loanParentClubId,
    this.loanEndSeason,
    this.loanEndWeek,
    this.loanOriginalSalary,
    this.scoutedByScoutId,
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
  final PlayerPersonality personality;
  final int agentTrust;
  final int agencyRelationshipWeeks;
  final bool isRetired;
  final int? retirementSeason;
  final double fatigue;
  final int consecutiveStarts;
  final bool isTransferListed;
  final bool isLoanListed;
  final String? loanParentClubId;
  final int? loanEndSeason;
  final int? loanEndWeek;
  final double? loanOriginalSalary;
  final String? scoutedByScoutId;

  bool get isOnLoan => loanParentClubId != null;

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
    PlayerPersonality? personality,
    int? agentTrust,
    int? agencyRelationshipWeeks,
    bool? isRetired,
    int? retirementSeason,
    double? fatigue,
    int? consecutiveStarts,
    bool? isTransferListed,
    bool? isLoanListed,
    String? loanParentClubId,
    bool clearLoanParentClubId = false,
    int? loanEndSeason,
    bool clearLoanEndSeason = false,
    int? loanEndWeek,
    bool clearLoanEndWeek = false,
    double? loanOriginalSalary,
    bool clearLoanOriginalSalary = false,
    String? scoutedByScoutId,
    bool clearScoutedByScoutId = false,
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
      personality: personality ?? this.personality,
      agentTrust: (agentTrust ?? this.agentTrust).clamp(0, 300),
      agencyRelationshipWeeks:
          (agencyRelationshipWeeks ?? this.agencyRelationshipWeeks)
              .clamp(0, 9999),
      isRetired: isRetired ?? this.isRetired,
      retirementSeason: retirementSeason ?? this.retirementSeason,
      fatigue: fatigue ?? this.fatigue,
      consecutiveStarts: consecutiveStarts ?? this.consecutiveStarts,
      isTransferListed: isTransferListed ?? this.isTransferListed,
      isLoanListed: isLoanListed ?? this.isLoanListed,
      loanParentClubId: clearLoanParentClubId
          ? null
          : loanParentClubId ?? this.loanParentClubId,
      loanEndSeason:
          clearLoanEndSeason ? null : loanEndSeason ?? this.loanEndSeason,
      loanEndWeek: clearLoanEndWeek ? null : loanEndWeek ?? this.loanEndWeek,
      loanOriginalSalary: clearLoanOriginalSalary
          ? null
          : loanOriginalSalary ?? this.loanOriginalSalary,
      scoutedByScoutId: clearScoutedByScoutId
          ? null
          : scoutedByScoutId ?? this.scoutedByScoutId,
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
        'personality': personality.toJson(),
        'agentTrust': agentTrust,
        'agencyRelationshipWeeks': agencyRelationshipWeeks,
        'isRetired': isRetired,
        'retirementSeason': retirementSeason,
        'fatigue': fatigue,
        'consecutiveStarts': consecutiveStarts,
        'isTransferListed': isTransferListed,
        'isLoanListed': isLoanListed,
        'loanParentClubId': loanParentClubId,
        'loanEndSeason': loanEndSeason,
        'loanEndWeek': loanEndWeek,
        'loanOriginalSalary': loanOriginalSalary,
        'scoutedByScoutId': scoutedByScoutId,
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
      personality: json['personality'] == null
          ? const PlayerPersonality()
          : PlayerPersonality.fromJson(
              (json['personality']! as Map).cast<String, Object?>(),
            ),
      agentTrust: ((json['agentTrust'] as int?) ?? 100).clamp(0, 300),
      agencyRelationshipWeeks:
          ((json['agencyRelationshipWeeks'] as int?) ?? 0).clamp(0, 9999),
      isRetired: (json['isRetired'] as bool?) ?? false,
      retirementSeason: json['retirementSeason'] as int?,
      fatigue: ((json['fatigue'] as num?) ?? 0).toDouble(),
      consecutiveStarts: (json['consecutiveStarts'] as int?) ?? 0,
      isTransferListed: (json['isTransferListed'] as bool?) ?? false,
      isLoanListed: (json['isLoanListed'] as bool?) ?? false,
      loanParentClubId: json['loanParentClubId'] as String?,
      loanEndSeason: json['loanEndSeason'] as int?,
      loanEndWeek: json['loanEndWeek'] as int?,
      loanOriginalSalary: (json['loanOriginalSalary'] as num?)?.toDouble(),
      scoutedByScoutId: json['scoutedByScoutId'] as String?,
    );
  }
}
