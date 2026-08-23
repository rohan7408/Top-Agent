enum AgencyTransactionType {
  agentFee,
  salaryCommission,
  scoutSigning,
  scoutPayroll,
  officeUpgrade,
  trainingGroundUpgrade,
  representationTermination,
  agencyEvent,
}

extension AgencyTransactionTypeLabel on AgencyTransactionType {
  String get label => switch (this) {
        AgencyTransactionType.agentFee => 'Agent fee',
        AgencyTransactionType.salaryCommission => 'Salary commission',
        AgencyTransactionType.scoutSigning => 'Scout signing',
        AgencyTransactionType.scoutPayroll => 'Scout payroll',
        AgencyTransactionType.officeUpgrade => 'Office upgrade',
        AgencyTransactionType.trainingGroundUpgrade =>
          'Training ground upgrade',
        AgencyTransactionType.representationTermination =>
          'Representation ended',
        AgencyTransactionType.agencyEvent => 'Agency event',
      };
}

class AgencyTransaction {
  const AgencyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.season,
    required this.week,
  });

  final String id;
  final AgencyTransactionType type;
  final double amount;
  final String description;
  final int season;
  final int week;

  Map<String, Object> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'description': description,
        'season': season,
        'week': week,
      };

  factory AgencyTransaction.fromJson(Map<String, Object?> json) =>
      AgencyTransaction(
        id: json['id']! as String,
        type: AgencyTransactionType.values.byName(json['type']! as String),
        amount: (json['amount']! as num).toDouble(),
        description: json['description']! as String,
        season: json['season']! as int,
        week: json['week']! as int,
      );
}
