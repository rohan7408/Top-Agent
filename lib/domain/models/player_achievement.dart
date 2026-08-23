enum PlayerAchievementType {
  leagueTitle,
  goldenBoot,
  leagueMvp,
  matchMvp,
}

class PlayerAchievement {
  const PlayerAchievement({
    required this.type,
    required this.title,
    required this.detail,
    this.count = 1,
    this.season,
  });

  final PlayerAchievementType type;
  final String title;
  final String detail;
  final int count;
  final int? season;
}
