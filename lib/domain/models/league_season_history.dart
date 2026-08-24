class LeaguePlayerHonour {
  const LeaguePlayerHonour({
    required this.playerId,
    required this.clubId,
    required this.value,
  });

  final String playerId;
  final String clubId;
  final int value;

  Map<String, Object> toJson() => {
        'playerId': playerId,
        'clubId': clubId,
        'value': value,
      };

  factory LeaguePlayerHonour.fromJson(Map<String, Object?> json) =>
      LeaguePlayerHonour(
        playerId: json['playerId']! as String,
        clubId: json['clubId']! as String,
        value: (json['value']! as num).toInt(),
      );
}

class LeagueSeasonHistory {
  const LeagueSeasonHistory({
    required this.leagueId,
    required this.season,
    required this.championClubId,
    required this.runnerUpClubId,
    this.topScorer,
    this.topAssister,
    this.cleanSheetLeader,
  });

  final String leagueId;
  final int season;
  final String championClubId;
  final String runnerUpClubId;
  final LeaguePlayerHonour? topScorer;
  final LeaguePlayerHonour? topAssister;
  final LeaguePlayerHonour? cleanSheetLeader;

  Map<String, Object?> toJson() => {
        'leagueId': leagueId,
        'season': season,
        'championClubId': championClubId,
        'runnerUpClubId': runnerUpClubId,
        'topScorer': topScorer?.toJson(),
        'topAssister': topAssister?.toJson(),
        'cleanSheetLeader': cleanSheetLeader?.toJson(),
      };

  factory LeagueSeasonHistory.fromJson(Map<String, Object?> json) =>
      LeagueSeasonHistory(
        leagueId: json['leagueId']! as String,
        season: (json['season']! as num).toInt(),
        championClubId: json['championClubId']! as String,
        runnerUpClubId: json['runnerUpClubId']! as String,
        topScorer: _honourFromJson(json['topScorer']),
        topAssister: _honourFromJson(json['topAssister']),
        cleanSheetLeader: _honourFromJson(json['cleanSheetLeader']),
      );

  static LeaguePlayerHonour? _honourFromJson(Object? value) {
    if (value is! Map) return null;
    return LeaguePlayerHonour.fromJson(value.cast<String, Object?>());
  }
}
