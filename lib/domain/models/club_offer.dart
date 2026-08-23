enum ClubOfferStatus {
  pending,
  accepted,
  declined,
  expired,
}

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
    this.salaryCommissionRate = 0,
    this.status = ClubOfferStatus.pending,
  });

  final String id;
  final String playerId;
  final String clubId;
  final double weeklySalary;
  final double agentFee;
  final int contractLength;
  final int createdWeek;
  final int createdSeason;
  final double salaryCommissionRate;
  final ClubOfferStatus status;

  ClubOffer copyWith({ClubOfferStatus? status}) {
    return ClubOffer(
      id: id,
      playerId: playerId,
      clubId: clubId,
      weeklySalary: weeklySalary,
      agentFee: agentFee,
      contractLength: contractLength,
      createdWeek: createdWeek,
      createdSeason: createdSeason,
      salaryCommissionRate: salaryCommissionRate,
      status: status ?? this.status,
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'playerId': playerId,
        'clubId': clubId,
        'weeklySalary': weeklySalary,
        'agentFee': agentFee,
        'contractLength': contractLength,
        'createdWeek': createdWeek,
        'createdSeason': createdSeason,
        'salaryCommissionRate': salaryCommissionRate,
        'status': status.name,
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
      salaryCommissionRate:
          ((json['salaryCommissionRate'] as num?) ?? 0).toDouble(),
      status: ClubOfferStatus.values.byName(json['status']! as String),
    );
  }
}
