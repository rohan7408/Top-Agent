class PlayerInjury {
  const PlayerInjury({
    required this.id,
    required this.playerId,
    required this.name,
    required this.startSeason,
    required this.startWeek,
    required this.totalWeeks,
    required this.weeksRemaining,
  });

  final String id;
  final String playerId;
  final String name;
  final int startSeason;
  final int startWeek;
  final int totalWeeks;
  final int weeksRemaining;

  bool get isActive => weeksRemaining > 0;

  PlayerInjury advanceWeek() => PlayerInjury(
        id: id,
        playerId: playerId,
        name: name,
        startSeason: startSeason,
        startWeek: startWeek,
        totalWeeks: totalWeeks,
        weeksRemaining: (weeksRemaining - 1).clamp(0, totalWeeks),
      );

  Map<String, Object> toJson() => {
        'id': id,
        'playerId': playerId,
        'name': name,
        'startSeason': startSeason,
        'startWeek': startWeek,
        'totalWeeks': totalWeeks,
        'weeksRemaining': weeksRemaining,
      };

  factory PlayerInjury.fromJson(Map<String, Object?> json) => PlayerInjury(
        id: json['id']! as String,
        playerId: json['playerId']! as String,
        name: json['name']! as String,
        startSeason: json['startSeason']! as int,
        startWeek: json['startWeek']! as int,
        totalWeeks: json['totalWeeks']! as int,
        weeksRemaining: json['weeksRemaining']! as int,
      );
}
