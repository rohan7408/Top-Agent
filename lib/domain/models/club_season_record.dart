import 'match_result.dart';

class ClubSeasonRecord {
  const ClubSeasonRecord({
    required this.clubId,
    required this.season,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
    this.cleanSheets = 0,
  });

  final String clubId;
  final int season;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final int cleanSheets;

  int get goalDifference => goalsFor - goalsAgainst;

  ClubSeasonRecord applyResult(MatchResult result) {
    final isHome = result.homeClubId == clubId;
    final scored = isHome ? result.homeGoals : result.awayGoals;
    final conceded = isHome ? result.awayGoals : result.homeGoals;
    final didWin = scored > conceded;
    final didDraw = scored == conceded;

    return ClubSeasonRecord(
      clubId: clubId,
      season: season,
      played: played + 1,
      won: won + (didWin ? 1 : 0),
      drawn: drawn + (didDraw ? 1 : 0),
      lost: lost + (!didWin && !didDraw ? 1 : 0),
      goalsFor: goalsFor + scored,
      goalsAgainst: goalsAgainst + conceded,
      points: points +
          (didWin
              ? 3
              : didDraw
                  ? 1
                  : 0),
      cleanSheets: cleanSheets + (conceded == 0 ? 1 : 0),
    );
  }

  Map<String, Object> toJson() => {
        'clubId': clubId,
        'season': season,
        'played': played,
        'won': won,
        'drawn': drawn,
        'lost': lost,
        'goalsFor': goalsFor,
        'goalsAgainst': goalsAgainst,
        'points': points,
        'cleanSheets': cleanSheets,
      };

  factory ClubSeasonRecord.fromJson(Map<String, Object?> json) {
    return ClubSeasonRecord(
      clubId: json['clubId']! as String,
      season: json['season']! as int,
      played: json['played']! as int,
      won: json['won']! as int,
      drawn: json['drawn']! as int,
      lost: json['lost']! as int,
      goalsFor: json['goalsFor']! as int,
      goalsAgainst: json['goalsAgainst']! as int,
      points: json['points']! as int,
      cleanSheets: (json['cleanSheets'] as int?) ?? 0,
    );
  }
}
