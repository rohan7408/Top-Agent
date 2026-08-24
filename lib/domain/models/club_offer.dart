enum ClubOfferStatus {
  pending,
  accepted,
  declined,
  expired,
}

enum ClubOfferType { freeAgent, transfer, loan }

class ClubOffer {
  const ClubOffer({
    required this.id,
    required this.playerId,
    required this.clubId,
    required this.weeklySalary,
    required this.agentFee,
    required this.contractLength,
    required this.createdWeek,
    required this.createdSeason,
    this.type = ClubOfferType.freeAgent,
    this.fromClubId,
    this.transferFee = 0,
    this.salaryCommissionRate = 0,
    this.status = ClubOfferStatus.pending,
    this.negotiationRounds = 0,
  });

  final String id;
  final String playerId;
  final String clubId;
  final double weeklySalary;
  final double agentFee;
  final int contractLength;
  final int createdWeek;
  final int createdSeason;
  final ClubOfferType type;
  final String? fromClubId;
  final double transferFee;
  final double salaryCommissionRate;
  final ClubOfferStatus status;
  final int negotiationRounds;

  bool get isMarketMove => type != ClubOfferType.freeAgent;

  ClubOffer copyWith({
    double? weeklySalary,
    double? agentFee,
    int? contractLength,
    ClubOfferStatus? status,
    int? negotiationRounds,
  }) {
    return ClubOffer(
      id: id,
      playerId: playerId,
      clubId: clubId,
      weeklySalary: weeklySalary ?? this.weeklySalary,
      agentFee: agentFee ?? this.agentFee,
      contractLength: contractLength ?? this.contractLength,
      createdWeek: createdWeek,
      createdSeason: createdSeason,
      type: type,
      fromClubId: fromClubId,
      transferFee: transferFee,
      salaryCommissionRate: salaryCommissionRate,
      status: status ?? this.status,
      negotiationRounds: negotiationRounds ?? this.negotiationRounds,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'playerId': playerId,
        'clubId': clubId,
        'weeklySalary': weeklySalary,
        'agentFee': agentFee,
        'contractLength': contractLength,
        'createdWeek': createdWeek,
        'createdSeason': createdSeason,
        'type': type.name,
        'fromClubId': fromClubId,
        'transferFee': transferFee,
        'salaryCommissionRate': salaryCommissionRate,
        'status': status.name,
        'negotiationRounds': negotiationRounds,
      };

  factory ClubOffer.fromJson(Map<String, Object?> json) {
    return ClubOffer(
      id: json['id']! as String,
      playerId: json['playerId']! as String,
      clubId: json['clubId']! as String,
      weeklySalary: (json['weeklySalary']! as num).toDouble(),
      agentFee: (json['agentFee']! as num).toDouble(),
      contractLength: json['contractLength']! as int,
      createdWeek: json['createdWeek']! as int,
      createdSeason: json['createdSeason']! as int,
      type: ClubOfferType.values.byName(
        (json['type'] as String?) ?? ClubOfferType.freeAgent.name,
      ),
      fromClubId: json['fromClubId'] as String?,
      transferFee: ((json['transferFee'] as num?) ?? 0).toDouble(),
      salaryCommissionRate:
          ((json['salaryCommissionRate'] as num?) ?? 0).toDouble(),
      status: ClubOfferStatus.values.byName(json['status']! as String),
      negotiationRounds: (json['negotiationRounds'] as int?) ?? 0,
    );
  }
}
