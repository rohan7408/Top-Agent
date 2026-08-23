import '../models/game_state.dart';
import '../models/match_result.dart';
import '../models/player_match_performance.dart';

class TeamMatchReport {
  const TeamMatchReport({
    required this.clubId,
    required this.performances,
    required this.averageRating,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
  });

  final String clubId;
  final List<PlayerMatchPerformance> performances;
  final double averageRating;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
}

class MatchReport {
  const MatchReport({
    required this.result,
    required this.home,
    required this.away,
    required this.playerOfTheMatch,
  });

  final MatchResult result;
  final TeamMatchReport home;
  final TeamMatchReport away;
  final PlayerMatchPerformance? playerOfTheMatch;
}

class MatchReportService {
  const MatchReportService();

  MatchReport? build(GameState game, String matchId) {
    final result = game.matchResultById(matchId);
    if (result == null) return null;
    final performances = game.performancesForMatch(matchId);
    final home = _teamReport(
      result.homeClubId,
      performances.where((item) => item.clubId == result.homeClubId),
    );
    final away = _teamReport(
      result.awayClubId,
      performances.where((item) => item.clubId == result.awayClubId),
    );
    return MatchReport(
      result: result,
      home: home,
      away: away,
      playerOfTheMatch:
          performances.where((item) => item.playerOfTheMatch).firstOrNull,
    );
  }

  TeamMatchReport _teamReport(
    String clubId,
    Iterable<PlayerMatchPerformance> source,
  ) {
    final performances = source.toList(growable: true)
      ..sort((first, second) => second.rating.compareTo(first.rating));
    final totalRating = performances.fold<double>(
      0,
      (total, item) => total + item.rating,
    );
    return TeamMatchReport(
      clubId: clubId,
      performances: List.unmodifiable(performances),
      averageRating:
          performances.isEmpty ? 0 : totalRating / performances.length,
      goals: performances.fold<int>(0, (total, item) => total + item.goals),
      assists: performances.fold<int>(0, (total, item) => total + item.assists),
      yellowCards:
          performances.fold<int>(0, (total, item) => total + item.yellowCards),
      redCards:
          performances.fold<int>(0, (total, item) => total + item.redCards),
    );
  }
}
