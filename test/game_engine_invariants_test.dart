import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/match_result.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/simulation/game_engine.dart';

void main() {
  const factory = GameFactory();
  const engine = GameEngine();

  test('a duplicated fixture is simulated only once', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final firstFixture = game.fixturesForWeek(1, 1).first;
    final result = engine.simulateOneWeek(
      game.copyWith(fixtures: [...game.fixtures, firstFixture]),
    );

    expect(result.summary.matchesPlayed, 10);
    expect(result.state.matchResults, hasLength(10));
    expect(
      result.state.matchResults.map((match) => match.id).toSet(),
      hasLength(10),
    );
  });

  test('an already completed week cannot append the same matches again', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final once = engine.simulateOneWeek(game).state;
    final replay = engine.simulateOneWeek(
      once.copyWith(agent: once.agent.copyWith(currentWeek: 1)),
    );

    expect(replay.summary.matchesPlayed, 0);
    expect(replay.state.matchResults, hasLength(10));
    expect(
      replay.state.matchResults.map((match) => match.id).toSet(),
      hasLength(10),
    );
    expect(replay.state.currentStandings.every((record) => record.played == 1),
        isTrue);
  });

  test('club result queries can isolate one season', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final club = game.clubs.first;
    final opponent = game.clubs[1];
    final withHistory = game.copyWith(
      matchResults: [
        MatchResult(
          id: 'old-result',
          leagueId: club.leagueId,
          homeClubId: club.id,
          awayClubId: opponent.id,
          homeGoals: 1,
          awayGoals: 0,
          week: 1,
          season: 1,
        ),
        MatchResult(
          id: 'current-result',
          leagueId: club.leagueId,
          homeClubId: club.id,
          awayClubId: opponent.id,
          homeGoals: 2,
          awayGoals: 0,
          week: 1,
          season: 2,
        ),
      ],
    );

    expect(withHistory.resultsForClub(club.id), hasLength(2));
    expect(
      withHistory.resultsForClubInSeason(club.id, 2).single.id,
      'current-result',
    );
  });

  test('three seasons preserve world, schedule, roster, and history integrity',
      () {
    var game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24, 18),
    );

    for (var week = 0; week < 150; week++) {
      game = engine.simulateOneWeek(game).state;
    }

    expect(game.currentSeason, 4);
    expect(game.currentWeek, 1);
    expect(game.leagueHistory, hasLength(3));
    expect(
      game.leagueHistory.map((history) => history.season).toSet(),
      {1, 2, 3},
    );
    expect(
      game.matchResults.map((match) => match.id).toSet().length,
      game.matchResults.length,
    );
    expect(
      game.fixtures.map((fixture) => fixture.id).toSet().length,
      game.fixtures.length,
    );

    for (var season = 1; season <= 3; season++) {
      final seasonTable =
          game.standings.where((record) => record.season == season).toList();
      expect(seasonTable, hasLength(game.clubs.length));
      expect(
        seasonTable.every((record) => record.played == 38),
        isTrue,
        reason:
            'Season $season played counts: ${seasonTable.map((record) => record.played).toList()}',
      );
      for (final club in game.clubs) {
        expect(game.resultsForClubInSeason(club.id, season), hasLength(38));
      }
    }

    final rosteredPlayerIds = <String>{};
    for (final club in game.clubs) {
      final expectedRoster =
          game.playersForClub(club.id).map((player) => player.id).toSet();
      expect(club.playerIds.toSet(), expectedRoster);
      expect(rosteredPlayerIds.intersection(expectedRoster), isEmpty);
      rosteredPlayerIds.addAll(expectedRoster);
      expect(club.squadValue.isFinite, isTrue);
      expect(club.totalSalary.isFinite, isTrue);
      expect(club.balance.isFinite, isTrue);
      expect(club.budget.isFinite, isTrue);
      expect(club.squadValue, greaterThanOrEqualTo(0));
      expect(club.totalSalary, greaterThanOrEqualTo(0));
      expect(club.budget, greaterThanOrEqualTo(0));
    }
  });
}
