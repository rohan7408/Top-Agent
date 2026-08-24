import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/application/game_controller.dart';
import 'package:football_agent/application/persistence_providers.dart';
import 'package:football_agent/domain/services/league_statistics_service.dart';
import 'package:football_agent/domain/services/match_report_service.dart';

import 'helpers/in_memory_game_save_repository.dart';

void main() {
  test('league leaderboards rank stored season statistics', () {
    final container = ProviderContainer(
      overrides: [
        gameSaveRepositoryProvider.overrideWithValue(
          InMemoryGameSaveRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );
    controller.simulateNextWeek();
    final game = container.read(gameControllerProvider)!;
    const service = LeagueStatisticsService();

    for (final metric in LeagueLeaderboardMetric.values) {
      final rankings = service.rankPlayers(
        stats: game.playerSeasonStats,
        leagueId: game.leagues.single.id,
        season: game.currentSeason,
        metric: metric,
      );
      expect(rankings, isNotEmpty);
      expect(rankings.length, lessThanOrEqualTo(20));
      for (var index = 1; index < rankings.length; index++) {
        expect(
          rankings[index - 1].valueFor(metric),
          greaterThanOrEqualTo(rankings[index].valueFor(metric)),
        );
      }
    }
  });

  test('match report connects result, team totals, ratings and player of match',
      () {
    final container = ProviderContainer(
      overrides: [
        gameSaveRepositoryProvider.overrideWithValue(
          InMemoryGameSaveRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );
    controller.simulateNextWeek();
    final game = container.read(gameControllerProvider)!;
    final result = game.matchResults.first;
    final report = const MatchReportService().build(game, result.id)!;

    expect(report.home.performances.length, greaterThan(11));
    expect(report.away.performances.length, greaterThan(11));
    expect(
      report.home.performances.where((performance) => performance.started),
      hasLength(11),
    );
    expect(
      report.away.performances.where((performance) => performance.started),
      hasLength(11),
    );
    expect(report.home.goals, result.homeGoals);
    expect(report.away.goals, result.awayGoals);
    expect(report.playerOfTheMatch, isNotNull);
    expect(report.home.averageRating, inInclusiveRange(3, 10));
    expect(report.away.averageRating, inInclusiveRange(3, 10));
    expect(game.performancesForMatch(result.id).length, greaterThan(22));
    expect(game.matchResultById(result.id), same(result));
  });
}
