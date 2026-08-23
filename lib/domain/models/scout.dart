class Scout {
  const Scout({
    required this.id,
    required this.name,
    required this.ability,
    required this.salary,
    required this.agencyId,
  });

  static const String candidatePoolAgencyId = 'scout-candidate-pool';

  final String id;
  final String name;
  final int ability;
  final double salary;
  final String agencyId;

  bool get isCandidate => agencyId == candidatePoolAgencyId;
  double get signingCost => salary * 4;

  int get requiredReputation => switch (ability) {
        <= 49 => -999999,
        <= 59 => 5,
        <= 69 => 15,
        <= 79 => 40,
        <= 89 => 100,
        _ => 250,
      };

  Scout copyWith({String? agencyId}) => Scout(
        id: id,
        name: name,
        ability: ability,
        salary: salary,
        agencyId: agencyId ?? this.agencyId,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'ability': ability,
        'salary': salary,
        'agencyId': agencyId,
      };

  factory Scout.fromJson(Map<String, Object?> json) => Scout(
        id: json['id']! as String,
        name: json['name']! as String,
        ability: json['ability']! as int,
        salary: (json['salary']! as num).toDouble(),
        agencyId: json['agencyId']! as String,
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
