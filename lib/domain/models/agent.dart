class Agent {
  const Agent({
    required this.id,
    required this.name,
    required this.agencyName,
    required this.age,
    required this.money,
    required this.reputation,
    required this.currentWeek,
    required this.currentSeason,
  });

  final String id;
  final String name;
  final String agencyName;
  final int age;
  final double money;
  final int reputation;
  final int currentWeek;
  final int currentSeason;

  Agent copyWith({
    String? id,
    String? name,
    String? agencyName,
    int? age,
    double? money,
    int? reputation,
    int? currentWeek,
    int? currentSeason,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      agencyName: agencyName ?? this.agencyName,
      age: age ?? this.age,
      money: money ?? this.money,
      reputation: reputation ?? this.reputation,
      currentWeek: currentWeek ?? this.currentWeek,
      currentSeason: currentSeason ?? this.currentSeason,
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'agencyName': agencyName,
        'age': age,
        'money': money,
        'reputation': reputation,
        'currentWeek': currentWeek,
        'currentSeason': currentSeason,
      };

  factory Agent.fromJson(Map<String, Object?> json) {
    return Agent(
      id: json['id']! as String,
      name: json['name']! as String,
      agencyName: json['agencyName']! as String,
      age: json['age']! as int,
      money: (json['money']! as num).toDouble(),
      reputation: json['reputation']! as int,
      currentWeek: json['currentWeek']! as int,
      currentSeason: json['currentSeason']! as int,
    );
  }
}
