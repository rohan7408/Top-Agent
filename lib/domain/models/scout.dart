class Scout {
  const Scout({
    required this.id,
    required this.name,
    required this.ability,
    required this.salary,
    required this.agencyId,
    this.agencyTrust = 100,
    this.weeksWithAgency = 0,
  });

  static const String candidatePoolAgencyId = 'scout-candidate-pool';

  final String id;
  final String name;
  final int ability;
  final double salary;
  final String agencyId;
  final int agencyTrust;
  final int weeksWithAgency;

  bool get isCandidate => agencyId == candidatePoolAgencyId;
  double get signingCost => salary * 4;
  bool get trustsAgencyEnough => agencyTrust >= 80;

  int get requiredReputation => switch (ability) {
        <= 49 => -999999,
        <= 59 => 5,
        <= 69 => 15,
        <= 79 => 40,
        <= 89 => 100,
        _ => 250,
      };

  Scout copyWith({
    String? agencyId,
    int? agencyTrust,
    int? weeksWithAgency,
  }) =>
      Scout(
        id: id,
        name: name,
        ability: ability,
        salary: salary,
        agencyId: agencyId ?? this.agencyId,
        agencyTrust: (agencyTrust ?? this.agencyTrust).clamp(0, 300),
        weeksWithAgency:
            (weeksWithAgency ?? this.weeksWithAgency).clamp(0, 9999),
      );

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'ability': ability,
        'salary': salary,
        'agencyId': agencyId,
        'agencyTrust': agencyTrust,
        'weeksWithAgency': weeksWithAgency,
      };

  factory Scout.fromJson(Map<String, Object?> json) => Scout(
        id: json['id']! as String,
        name: json['name']! as String,
        ability: json['ability']! as int,
        salary: (json['salary']! as num).toDouble(),
        agencyId: json['agencyId']! as String,
        agencyTrust: ((json['agencyTrust'] as int?) ?? 100).clamp(0, 300),
        weeksWithAgency:
            ((json['weeksWithAgency'] as int?) ?? 0).clamp(0, 9999),
      );

  static Scout? fromLegacyStaffJson(Map<String, Object?> json) {
    if (json['role'] != 'scout') return null;
    final legacyAgencyId = json['agencyId']! as String;
    return Scout(
      id: json['id']! as String,
      name: json['name']! as String,
      ability: json['ability']! as int,
      salary: (json['salary']! as num).toDouble(),
      agencyId: legacyAgencyId == 'staff-candidate-pool'
          ? candidatePoolAgencyId
          : legacyAgencyId,
    );
  }
}
