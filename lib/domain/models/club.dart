class Club {
  Club({
    required this.id,
    required this.name,
    required this.leagueId,
    required this.clubValue,
    required this.squadValue,
    required this.totalSalary,
    required this.budget,
    required this.balance,
    List<String> playerIds = const [],
  }) : playerIds = List.unmodifiable(playerIds);

  final String id;
  final String name;
  final String leagueId;
  final double clubValue;
  final double squadValue;
  final double totalSalary;
  final double budget;
  final double balance;
  final List<String> playerIds;

  Club copyWith({
    double? clubValue,
    double? squadValue,
    double? totalSalary,
    double? budget,
    double? balance,
    List<String>? playerIds,
  }) {
    return Club(
      id: id,
      name: name,
      leagueId: leagueId,
      clubValue: clubValue ?? this.clubValue,
      squadValue: squadValue ?? this.squadValue,
      totalSalary: totalSalary ?? this.totalSalary,
      budget: budget ?? this.budget,
      balance: balance ?? this.balance,
      playerIds: playerIds ?? this.playerIds,
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'leagueId': leagueId,
        'clubValue': clubValue,
        'squadValue': squadValue,
        'totalSalary': totalSalary,
        'budget': budget,
        'balance': balance,
        'playerIds': playerIds,
      };

  factory Club.fromJson(Map<String, Object?> json) {
    return Club(
      id: json['id']! as String,
      name: json['name']! as String,
      leagueId: json['leagueId']! as String,
      clubValue: (json['clubValue']! as num).toDouble(),
      squadValue: (json['squadValue']! as num).toDouble(),
      totalSalary: (json['totalSalary']! as num).toDouble(),
      budget: (json['budget']! as num).toDouble(),
      balance:
          ((json['balance'] as num?) ?? json['clubValue']! as num).toDouble(),
      playerIds: (json['playerIds']! as List<Object?>).cast<String>(),
    );
  }
}
