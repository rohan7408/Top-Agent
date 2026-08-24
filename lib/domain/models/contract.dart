class Contract {
  const Contract({
    required this.id,
    required this.playerId,
    required this.clubId,
    required this.salary,
    required this.agentFee,
    required this.contractLength,
    required this.startSeason,
    required this.endSeason,
    this.startWeek = 1,
    this.salaryCommissionRate = 0,
  });

  final String id;
  final String playerId;
  final String clubId;
  final double salary;
  final double agentFee;
  final int contractLength;
  final int startSeason;
  final int endSeason;
  final int startWeek;
  final double salaryCommissionRate;

  double get weeklySalaryCommission => salary * salaryCommissionRate;

  Map<String, Object> toJson() => {
        'id': id,
        'playerId': playerId,
        'clubId': clubId,
        'salary': salary,
        'agentFee': agentFee,
        'contractLength': contractLength,
        'startSeason': startSeason,
        'endSeason': endSeason,
        'startWeek': startWeek,
        'salaryCommissionRate': salaryCommissionRate,
      };

  factory Contract.fromJson(Map<String, Object?> json) {
    return Contract(
      id: json['id']! as String,
      playerId: json['playerId']! as String,
      clubId: json['clubId']! as String,
      salary: (json['salary']! as num).toDouble(),
      agentFee: (json['agentFee']! as num).toDouble(),
      contractLength: json['contractLength']! as int,
      startSeason: json['startSeason']! as int,
      endSeason: json['endSeason']! as int,
      startWeek: (json['startWeek'] as int?) ?? 1,
      salaryCommissionRate:
          ((json['salaryCommissionRate'] as num?) ?? 0).toDouble(),
    );
  }
}
