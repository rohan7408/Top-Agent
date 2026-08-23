class MatchResult {
  const MatchResult({
    required this.id,
    required this.leagueId,
    required this.homeClubId,
    required this.awayClubId,
    required this.homeGoals,
    required this.awayGoals,
    required this.week,
    required this.season,
  });

  final String id;
  final String leagueId;
  final String homeClubId;
  final String awayClubId;
  final int homeGoals;
  final int awayGoals;
  final int week;
  final int season;

  Map<String, Object> toJson() => {
        'id': id,
        'leagueId': leagueId,
        'homeClubId': homeClubId,
        'awayClubId': awayClubId,
        'homeGoals': homeGoals,
        'awayGoals': awayGoals,
        'week': week,
        'season': season,
      };

  factory MatchResult.fromJson(Map<String, Object?> json) {
    return MatchResult(
      id: json['id']! as String,
      leagueId: json['leagueId']! as String,
      homeClubId: json['homeClubId']! as String,
      awayClubId: json['awayClubId']! as String,
      homeGoals: json['homeGoals']! as int,
      awayGoals: json['awayGoals']! as int,
      week: json['week']! as int,
      season: json['season']! as int,
    );
  }
}
