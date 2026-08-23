class PlayerMatchPerformance {
  const PlayerMatchPerformance({
    required this.id,
    required this.matchId,
    required this.leagueId,
    required this.playerId,
    required this.clubId,
    required this.week,
    required this.season,
    required this.started,
    required this.minutes,
    required this.goals,
    required this.assists,
    required this.cleanSheet,
    required this.yellowCards,
    required this.redCards,
    required this.rating,
    this.playerOfTheMatch = false,
  });

  final String id;
  final String matchId;
  final String leagueId;
  final String playerId;
  final String clubId;
  final int week;
  final int season;
  final bool started;
  final int minutes;
  final int goals;
  final int assists;
  final bool cleanSheet;
  final int yellowCards;
  final int redCards;
  final double rating;
  final bool playerOfTheMatch;

  PlayerMatchPerformance copyWith({bool? playerOfTheMatch}) {
    return PlayerMatchPerformance(
      id: id,
      matchId: matchId,
      leagueId: leagueId,
      playerId: playerId,
      clubId: clubId,
      week: week,
      season: season,
      started: started,
      minutes: minutes,
      goals: goals,
      assists: assists,
      cleanSheet: cleanSheet,
      yellowCards: yellowCards,
      redCards: redCards,
      rating: rating,
      playerOfTheMatch: playerOfTheMatch ?? this.playerOfTheMatch,
    );
  }

  Map<String, Object> toJson() => {
        'id': id,
        'matchId': matchId,
        'leagueId': leagueId,
        'playerId': playerId,
        'clubId': clubId,
        'week': week,
        'season': season,
        'started': started,
        'minutes': minutes,
        'goals': goals,
        'assists': assists,
        'cleanSheet': cleanSheet,
        'yellowCards': yellowCards,
        'redCards': redCards,
        'rating': rating,
        'playerOfTheMatch': playerOfTheMatch,
      };

  factory PlayerMatchPerformance.fromJson(Map<String, Object?> json) {
    return PlayerMatchPerformance(
      id: json['id']! as String,
      matchId: json['matchId']! as String,
      leagueId: json['leagueId']! as String,
      playerId: json['playerId']! as String,
      clubId: json['clubId']! as String,
      week: json['week']! as int,
      season: json['season']! as int,
      started: json['started']! as bool,
      minutes: json['minutes']! as int,
      goals: json['goals']! as int,
      assists: json['assists']! as int,
      cleanSheet: json['cleanSheet']! as bool,
      yellowCards: json['yellowCards']! as int,
      redCards: json['redCards']! as int,
      rating: (json['rating']! as num).toDouble(),
      playerOfTheMatch: json['playerOfTheMatch']! as bool,
    );
  }
}
