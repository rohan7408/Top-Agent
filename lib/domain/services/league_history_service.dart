import '../models/game_state.dart';
import '../models/league.dart';
import '../models/league_season_history.dart';
import '../models/player.dart';
import '../models/player_season_stats.dart';
import 'league_statistics_service.dart';

class LeagueHistoryService {
  const LeagueHistoryService({
    this.statisticsService = const LeagueStatisticsService(),
  });

  final LeagueStatisticsService statisticsService;

  GameState captureCompletedSeason(GameState game) {
    final additions = <LeagueSeasonHistory>[];
    for (final league in game.leagues) {
      final alreadyCaptured = game.leagueHistory.any(
        (item) =>
            item.leagueId == league.id && item.season == game.currentSeason,
      );
      if (alreadyCaptured) continue;

      final history = _buildHistory(game, league);
      if (history != null) additions.add(history);
    }
    if (additions.isEmpty) return game;
    return game.copyWith(leagueHistory: [...game.leagueHistory, ...additions]);
  }

  LeagueSeasonHistory? _buildHistory(GameState game, League league) {
    final table = game.standings
        .where(
          (record) =>
              record.season == game.currentSeason &&
              league.clubIds.contains(record.clubId),
        )
        .toList(growable: true)
      ..sort((first, second) {
        final points = second.points.compareTo(first.points);
        if (points != 0) return points;
        final difference =
            second.goalDifference.compareTo(first.goalDifference);
        if (difference != 0) return difference;
        return second.goalsFor.compareTo(first.goalsFor);
      });

    if (table.length < 2 || table.every((record) => record.played == 0)) {
      return null;
    }

    final goalkeepers = game.players
        .where((player) => player.position == PlayerPosition.goalkeeper)
        .map((player) => player.id)
        .toSet();
    final leagueStats = game.playerSeasonStats.where(
      (stats) =>
          stats.leagueId == league.id && stats.season == game.currentSeason,
    );

    return LeagueSeasonHistory(
      leagueId: league.id,
      season: game.currentSeason,
      championClubId: table[0].clubId,
      runnerUpClubId: table[1].clubId,
      topScorer: _leader(
        leagueStats,
        league.id,
        game.currentSeason,
        LeagueLeaderboardMetric.goals,
      ),
      topAssister: _leader(
        leagueStats,
        league.id,
        game.currentSeason,
        LeagueLeaderboardMetric.assists,
      ),
      cleanSheetLeader: _leader(
        leagueStats.where((stats) => goalkeepers.contains(stats.playerId)),
        league.id,
        game.currentSeason,
        LeagueLeaderboardMetric.cleanSheets,
      ),
    );
  }

  LeaguePlayerHonour? _leader(
    Iterable<PlayerSeasonStats> stats,
    String leagueId,
    int season,
    LeagueLeaderboardMetric metric,
  ) {
    final items = stats.toList(growable: false);
    final rankings = statisticsService.rankPlayers(
      stats: items,
      leagueId: leagueId,
      season: season,
      metric: metric,
      limit: 1,
    );
    if (rankings.isEmpty) return null;

    final ranking = rankings.first;
    final playerStats = items
        .where((item) => item.playerId == ranking.playerId)
        .toList(growable: true)
      ..sort((first, second) {
        final metricValue =
            _metricValue(second, metric).compareTo(_metricValue(first, metric));
        return metricValue != 0
            ? metricValue
            : second.appearances.compareTo(first.appearances);
      });
    if (playerStats.isEmpty) return null;

    return LeaguePlayerHonour(
      playerId: ranking.playerId,
      clubId: playerStats.first.clubId,
      value: ranking.valueFor(metric).round(),
    );
  }

  int _metricValue(
    PlayerSeasonStats stats,
    LeagueLeaderboardMetric metric,
  ) =>
      switch (metric) {
        LeagueLeaderboardMetric.goals => stats.goals,
        LeagueLeaderboardMetric.assists => stats.assists,
        LeagueLeaderboardMetric.cleanSheets => stats.cleanSheets,
        LeagueLeaderboardMetric.playerOfTheMatch =>
          stats.playerOfTheMatchAwards,
        LeagueLeaderboardMetric.averageRating =>
          (stats.averageRating * 100).round(),
      };
}
