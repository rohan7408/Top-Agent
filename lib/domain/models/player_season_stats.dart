import 'player_match_performance.dart';

class PlayerSeasonStats {
  const PlayerSeasonStats({
    required this.playerId,
    required this.clubId,
    required this.leagueId,
    required this.season,
    this.appearances = 0,
    this.starts = 0,
    this.minutes = 0,
    this.goals = 0,
    this.assists = 0,
    this.cleanSheets = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.playerOfTheMatchAwards = 0,
    this.totalRating = 0,
  });

  final String playerId;
  final String clubId;
  final String leagueId;
  final int season;
  final int appearances;
  final int starts;
  final int minutes;
  final int goals;
  final int assists;
  final int cleanSheets;
  final int yellowCards;
  final int redCards;
  final int playerOfTheMatchAwards;
  final double totalRating;

  double get averageRating => appearances == 0 ? 0 : totalRating / appearances;

  PlayerSeasonStats applyPerformance(PlayerMatchPerformance performance) {
    return PlayerSeasonStats(
      playerId: playerId,
      clubId: clubId,
      leagueId: leagueId,
      season: season,
      appearances: appearances + (performance.minutes > 0 ? 1 : 0),
      starts: starts + (performance.started ? 1 : 0),
      minutes: minutes + performance.minutes,
      goals: goals + performance.goals,
      assists: assists + performance.assists,
      cleanSheets: cleanSheets + (performance.cleanSheet ? 1 : 0),
      yellowCards: yellowCards + performance.yellowCards,
      redCards: redCards + performance.redCards,
      playerOfTheMatchAwards:
          playerOfTheMatchAwards + (performance.playerOfTheMatch ? 1 : 0),
      totalRating: totalRating + performance.rating,
    );
  }

  Map<String, Object> toJson() => {
        'playerId': playerId,
        'clubId': clubId,
        'leagueId': leagueId,
        'season': season,
        'appearances': appearances,
        'starts': starts,
        'minutes': minutes,
        'goals': goals,
        'assists': assists,
        'cleanSheets': cleanSheets,
        'yellowCards': yellowCards,
        'redCards': redCards,
        'playerOfTheMatchAwards': playerOfTheMatchAwards,
        'totalRating': totalRating,
      };

  factory PlayerSeasonStats.fromJson(Map<String, Object?> json) {
    return PlayerSeasonStats(
      playerId: json['playerId']! as String,
      clubId: json['clubId']! as String,
      leagueId: json['leagueId']! as String,
      season: json['season']! as int,
      appearances: json['appearances']! as int,
      starts: json['starts']! as int,
      minutes: json['minutes']! as int,
      goals: json['goals']! as int,
      assists: json['assists']! as int,
      cleanSheets: json['cleanSheets']! as int,
      yellowCards: json['yellowCards']! as int,
      redCards: json['redCards']! as int,
      playerOfTheMatchAwards: json['playerOfTheMatchAwards']! as int,
      totalRating: (json['totalRating']! as num).toDouble(),
    );
  }
}
