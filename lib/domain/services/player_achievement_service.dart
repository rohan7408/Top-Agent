import '../models/game_state.dart';
import '../models/club_season_record.dart';
import '../models/player_achievement.dart';
import 'league_statistics_service.dart';

class PlayerAchievementService {
  const PlayerAchievementService({
    this.statisticsService = const LeagueStatisticsService(),
  });

  final LeagueStatisticsService statisticsService;

  List<PlayerAchievement> achievementsFor(
    GameState game,
    String playerId,
  ) {
    final completedStats = game.playerSeasonStats
        .where(
          (stats) =>
              stats.playerId == playerId &&
              stats.season < game.currentSeason &&
              stats.appearances > 0,
        )
        .toList(growable: false);
    final completedLeagueSeasons = {
      for (final stats in completedStats) '${stats.leagueId}|${stats.season}',
    };
    final leagueTitles = <PlayerAchievement>[];
    final goldenBoots = <PlayerAchievement>[];
    final leagueMvps = <PlayerAchievement>[];

    for (final key in completedLeagueSeasons) {
      final parts = key.split('|');
      final leagueId = parts.first;
      final season = int.parse(parts.last);
      final league = game.leagues
          .where((candidate) => candidate.id == leagueId)
          .firstOrNull;
      final leagueName = league?.name ?? 'League';
      final seasonLabel = game.seasonLabel(season);
      final playerStints = completedStats.where(
        (stats) => stats.leagueId == leagueId && stats.season == season,
      );

      final table = game.standings
          .where(
            (record) =>
                record.season == season &&
                (league?.clubIds.contains(record.clubId) ?? true),
          )
          .toList(growable: true)
        ..sort(_compareTableRecords);
      if (table.isNotEmpty &&
          playerStints.any((stats) => stats.clubId == table.first.clubId)) {
        leagueTitles.add(
          PlayerAchievement(
            type: PlayerAchievementType.leagueTitle,
            title: 'League title',
            detail: '$leagueName · $seasonLabel',
            season: season,
          ),
        );
      }

      final scorers = statisticsService.rankPlayers(
        stats: game.playerSeasonStats,
        leagueId: leagueId,
        season: season,
        metric: LeagueLeaderboardMetric.goals,
      );
      if (scorers.isNotEmpty &&
          scorers.first.playerId == playerId &&
          scorers.first.goals > 0) {
        goldenBoots.add(
          PlayerAchievement(
            type: PlayerAchievementType.goldenBoot,
            title: 'Golden Boot',
            detail: '$leagueName · $seasonLabel',
            season: season,
          ),
        );
      }

      final minimumAppearances = _minimumMvpAppearances(game, leagueId, season);
      final mvpRanking = statisticsService.rankPlayers(
        stats: game.playerSeasonStats,
        leagueId: leagueId,
        season: season,
        metric: LeagueLeaderboardMetric.averageRating,
        minimumAppearances: minimumAppearances,
      );
      if (mvpRanking.isNotEmpty && mvpRanking.first.playerId == playerId) {
        leagueMvps.add(
          PlayerAchievement(
            type: PlayerAchievementType.leagueMvp,
            title: 'League MVP',
            detail: '$leagueName · $seasonLabel',
            season: season,
          ),
        );
      }
    }

    final matchMvpCount = game.playerSeasonStats
        .where((stats) => stats.playerId == playerId)
        .fold<int>(
          0,
          (total, stats) => total + stats.playerOfTheMatchAwards,
        );
    final achievements = <PlayerAchievement>[
      if (leagueTitles.isNotEmpty) _combine(leagueTitles),
      if (goldenBoots.isNotEmpty) _combine(goldenBoots),
      if (leagueMvps.isNotEmpty) _combine(leagueMvps),
      if (matchMvpCount > 0)
        PlayerAchievement(
          type: PlayerAchievementType.matchMvp,
          title: 'Match MVP',
          detail:
              '$matchMvpCount player-of-the-match award${matchMvpCount == 1 ? '' : 's'}',
          count: matchMvpCount,
        ),
    ];
    return List.unmodifiable(achievements);
  }

  PlayerAchievement _combine(List<PlayerAchievement> achievements) {
    final latest = [...achievements]..sort(
        (first, second) => (second.season ?? 0).compareTo(first.season ?? 0));
    return PlayerAchievement(
      type: latest.first.type,
      title: latest.first.title,
      detail: latest.first.detail,
      count: achievements.length,
      season: latest.first.season,
    );
  }

  int _minimumMvpAppearances(GameState game, String leagueId, int season) {
    final mostAppearances = game.playerSeasonStats
        .where(
          (stats) => stats.leagueId == leagueId && stats.season == season,
        )
        .fold<int>(
          0,
          (maximum, stats) =>
              stats.appearances > maximum ? stats.appearances : maximum,
        );
    return mostAppearances < 10 ? 1 : 10;
  }

  int _compareTableRecords(
    ClubSeasonRecord first,
    ClubSeasonRecord second,
  ) {
    final points = second.points.compareTo(first.points);
    if (points != 0) return points;
    final difference = second.goalDifference.compareTo(first.goalDifference);
    if (difference != 0) return difference;
    return second.goalsFor.compareTo(first.goalsFor);
  }
}
