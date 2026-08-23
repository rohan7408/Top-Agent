import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/contract.dart';
import 'package:football_agent/domain/models/player.dart';
import 'package:football_agent/domain/models/player_injury.dart';
import 'package:football_agent/domain/models/player_season_stats.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/simulation/engines/player_lifecycle_engine.dart';
import 'package:football_agent/simulation/engines/weekly_injury_engine.dart';
import 'package:football_agent/simulation/game_engine.dart';

void main() {
  final factory = const GameFactory();

  test('an injured player misses the week and recovery counts down once', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final player = game.playersForClub(game.clubs.first.id).first;
    final injury = PlayerInjury(
      id: 'test-injury',
      playerId: player.id,
      name: 'Muscle strain',
      startSeason: 1,
      startWeek: 1,
      totalWeeks: 2,
      weeksRemaining: 2,
    );

    final result = const GameEngine().simulateOneWeek(
      game.copyWith(injuries: [injury]),
    );

    expect(
      result.state.playerPerformances
          .where((performance) => performance.playerId == player.id),
      isEmpty,
    );
    expect(
      result.state.injuries
          .firstWhere((item) => item.id == injury.id)
          .weeksRemaining,
      1,
    );
    expect(
      result.state.injuryAvailabilityLabel(
        result.state.injuries.firstWhere((item) => item.id == injury.id),
      ),
      'Injury till Week 2',
    );
  });

  test('players can suffer incidental injuries outside a match', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final fatigued = game.copyWith(
      players: game.players
          .map((player) => player.copyWith(fatigue: 100))
          .toList(growable: false),
    );
    const engine = WeeklyInjuryEngine();
    final injuries = <PlayerInjury>[];
    for (var seed = 0; seed < 100 && injuries.isEmpty; seed++) {
      injuries.addAll(
        engine.createIncidentalInjuries(
          game: fatigued,
          excludedPlayerIds: const {},
          seed: seed,
        ),
      );
    }

    expect(injuries, isNotEmpty);
    expect(injuries.every((injury) => injury.totalWeeks > 0), isTrue);
  });

  test('young high-performing player improves at the season change', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final original = game.players.firstWhere(
      (player) => player.position == PlayerPosition.forward,
    );
    final players = [...game.players];
    final index = players.indexWhere((player) => player.id == original.id);
    players[index] = original.copyWith(
      age: 19,
      potential: (original.ability + 12).clamp(1, 99),
    );
    final stats = PlayerSeasonStats(
      playerId: original.id,
      clubId: original.clubId!,
      leagueId: game.clubs.first.leagueId,
      season: 1,
      appearances: 30,
      starts: 30,
      minutes: 2700,
      goals: 18,
      assists: 8,
      playerOfTheMatchAwards: 5,
      totalRating: 225,
    );

    final result = const PlayerLifecycleEngine().processSeasonEnd(
      game.copyWith(players: players, playerSeasonStats: [stats]),
      nextSeason: 2,
      seed: 7,
    );
    final developed =
        result.state.players.firstWhere((player) => player.id == original.id);

    expect(developed.age, 20);
    expect(developed.ability, greaterThan(original.ability));
    expect(developed.potential, greaterThanOrEqualTo(developed.ability));
    expect(result.playersImproved, greaterThan(0));
  });

  test('a player at the retirement ceiling leaves squad and contract', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final original = game.players.firstWhere(
      (player) => player.position != PlayerPosition.goalkeeper,
    );
    final players = [...game.players];
    final index = players.indexWhere((player) => player.id == original.id);
    players[index] = original.copyWith(age: 41);
    final contract = Contract(
      id: 'retirement-contract',
      playerId: original.id,
      clubId: original.clubId!,
      salary: original.salary,
      agentFee: 0,
      contractLength: 2,
      startSeason: 1,
      endSeason: 3,
    );

    final result = const PlayerLifecycleEngine().processSeasonEnd(
      game.copyWith(players: players, contracts: [contract]),
      nextSeason: 2,
      seed: 11,
    );
    final retired =
        result.state.players.firstWhere((player) => player.id == original.id);

    expect(retired.age, 42);
    expect(retired.isRetired, isTrue);
    expect(retired.retirementSeason, 2);
    expect(retired.clubId, isNull);
    expect(retired.salary, 0);
    expect(result.state.clubById(original.clubId!)!.playerIds,
        isNot(contains(original.id)));
    expect(result.state.contracts.where((item) => item.playerId == original.id),
        isEmpty);
    expect(result.playersRetired, 1);
  });

  test('an unrenewed expired contract releases the player and records it', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final original = game.players.first;
    final players = [...game.players];
    final index = players.indexWhere((player) => player.id == original.id);
    players[index] = original.copyWith(
      age: 25,
      contractEndSeason: 1,
    );

    final result = const PlayerLifecycleEngine().processSeasonEnd(
      game.copyWith(players: players),
      nextSeason: 2,
      seed: 17,
    );
    final released =
        result.state.players.firstWhere((player) => player.id == original.id);

    expect(released.isRetired, isFalse);
    expect(released.clubId, isNull);
    expect(released.contractEndSeason, isNull);
    expect(result.contractsExpired, 1);
    expect(
      result.state.contractEvents.single.playerId,
      original.id,
    );
    expect(
      result.state.contractEvents.single.clubId,
      original.clubId,
    );
  });
}
