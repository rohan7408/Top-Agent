class LeagueFixture {
  const LeagueFixture({
    required this.id,
    required this.leagueId,
    required this.homeClubId,
    required this.awayClubId,
    required this.round,
    required this.week,
    required this.season,
  });

  final String id;
  final String leagueId;
  final String homeClubId;
  final String awayClubId;
  final int round;
  final int week;
  final int season;

  Map<String, Object> toJson() => {
        'id': id,
        'leagueId': leagueId,
        'homeClubId': homeClubId,
        'awayClubId': awayClubId,
        'round': round,
        'week': week,
        'season': season,
      };

  factory LeagueFixture.fromJson(Map<String, Object?> json) {
    return LeagueFixture(
      id: json['id']! as String,
      leagueId: json['leagueId']! as String,
      homeClubId: json['homeClubId']! as String,
      awayClubId: json['awayClubId']! as String,
      round: json['round']! as int,
      week: json['week']! as int,
      season: json['season']! as int,
    );
  }
}
