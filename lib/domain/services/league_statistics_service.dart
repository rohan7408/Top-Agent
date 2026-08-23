import '../models/player_season_stats.dart';

enum LeagueLeaderboardMetric {
  goals,
  assists,
  averageRating,
  cleanSheets,
  playerOfTheMatch,
}

extension LeagueLeaderboardMetricLabel on LeagueLeaderboardMetric {
  String get label => switch (this) {
        LeagueLeaderboardMetric.goals => 'Top scorers',
        LeagueLeaderboardMetric.assists => 'Most assists',
        LeagueLeaderboardMetric.averageRating => 'Best rating',
        LeagueLeaderboardMetric.cleanSheets => 'Clean sheets',
        LeagueLeaderboardMetric.playerOfTheMatch => 'Player of match',
      };

  String get shortLabel => switch (this) {
        LeagueLeaderboardMetric.goals => 'G',
        LeagueLeaderboardMetric.assists => 'A',
        LeagueLeaderboardMetric.averageRating => 'RTG',
        LeagueLeaderboardMetric.cleanSheets => 'CS',
        LeagueLeaderboardMetric.playerOfTheMatch => 'POTM',
      };
}

class LeaguePlayerRanking {
  const LeaguePlayerRanking({
    required this.playerId,
    required this.appearances,
    required this.goals,
    required this.assists,
    required this.cleanSheets,
    required this.playerOfTheMatchAwards,
    required this.totalRating,
  });

  final String playerId;
  final int appearances;
  final int goals;
  final int assists;
  final int cleanSheets;
  final int playerOfTheMatchAwards;
  final double totalRating;

  double get averageRating => appearances == 0 ? 0 : totalRating / appearances;

  double valueFor(LeagueLeaderboardMetric metric) => switch (metric) {
        LeagueLeaderboardMetric.goals => goals.toDouble(),
        LeagueLeaderboardMetric.assists => assists.toDouble(),
        LeagueLeaderboardMetric.averageRating => averageRating,
        LeagueLeaderboardMetric.cleanSheets => cleanSheets.toDouble(),
        LeagueLeaderboardMetric.playerOfTheMatch =>
          playerOfTheMatchAwards.toDouble(),
      };
}

class LeagueStatisticsService {
  const LeagueStatisticsService();

  List<LeaguePlayerRanking> rankPlayers({
    required Iterable<PlayerSeasonStats> stats,
    required String leagueId,
    required int season,
    required LeagueLeaderboardMetric metric,
    int limit = 20,
    int minimumAppearances = 1,
  }) {
    final totals = <String, _MutablePlayerTotals>{};
    for (final item in stats) {
      if (item.leagueId != leagueId || item.season != season) continue;
      totals.putIfAbsent(item.playerId, _MutablePlayerTotals.new).add(item);
    }

    final rankings = totals.entries
        .map((entry) => entry.value.freeze(entry.key))
        .where((item) => item.appearances >= minimumAppearances)
        .toList(growable: true)
      ..sort((first, second) {
        final value = second.valueFor(metric).compareTo(first.valueFor(metric));
        if (value != 0) return value;
        final appearances = second.appearances.compareTo(first.appearances);
        if (appearances != 0) return appearances;
        return second.averageRating.compareTo(first.averageRating);
      });

    return List.unmodifiable(rankings.take(limit));
  }
}

class _MutablePlayerTotals {
  int appearances = 0;
  int goals = 0;
  int assists = 0;
  int cleanSheets = 0;
  int playerOfTheMatchAwards = 0;
  double totalRating = 0;

  void add(PlayerSeasonStats stats) {
    appearances += stats.appearances;
    goals += stats.goals;
    assists += stats.assists;
    cleanSheets += stats.cleanSheets;
    playerOfTheMatchAwards += stats.playerOfTheMatchAwards;
    totalRating += stats.totalRating;
  }

  LeaguePlayerRanking freeze(String playerId) => LeaguePlayerRanking(
        playerId: playerId,
        appearances: appearances,
        goals: goals,
        assists: assists,
        cleanSheets: cleanSheets,
        playerOfTheMatchAwards: playerOfTheMatchAwards,
        totalRating: totalRating,
      );
}
