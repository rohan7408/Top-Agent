import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/models/player.dart';
import 'package:football_agent/domain/models/player_injury.dart';
import 'package:football_agent/domain/models/player_training_plan.dart';
import 'package:football_agent/domain/services/football_world_factory.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/talent_generator.dart';

void main() {
  test('creates a deterministic initial career state', () {
    final createdAt = DateTime.utc(2026, 8, 23, 12);
    final state = const GameFactory().createNewGame(
      agentName: '  Alex Morgan  ',
      agencyName: '  North Star Sports  ',
      agentAge: 34,
      createdAt: createdAt,
    );

    expect(state.agent.name, 'Alex Morgan');
    expect(state.agent.agencyName, 'North Star Sports');
    expect(state.agent.age, 34);
    expect(state.agent.money, GameFactory.startingMoney);
    expect(state.currentWeek, 1);
    expect(state.currentSeason, 1);
    expect(state.availableTalents, hasLength(2));
    expect(state.scouts.where((scout) => scout.isCandidate), hasLength(4));
    expect(state.hiredScouts, isEmpty);
    expect(state.office.level, 1);
    expect(state.office.clientCapacity, 3);
    expect(state.office.scoutCapacity, 1);
    expect(state.clubs, hasLength(20));
    expect(state.clubManagers, hasLength(20));
    expect(state.clubs.every((club) => club.balance > 0), isTrue);
    expect(
      state.clubs.every((club) => state.managerForClub(club.id) != null),
      isTrue,
    );
    expect(state.leagues, hasLength(1));
    expect(state.leagues.single.name, 'Premier League');
    expect(state.leagues.single.positionPrizeMoney, hasLength(20));
    expect(state.leagues.single.prizeMoneyForPosition(1), 100000000);
    expect(
      state.leagues.single.prizeMoneyForPosition(20),
      lessThan(state.leagues.single.prizeMoneyForPosition(1)),
    );
    expect(
      state.players,
      hasLength((20 * FootballWorldFactory.squadSize) + 2),
    );
    expect(
      state.clubs.every(
        (club) => club.playerIds.length == FootballWorldFactory.squadSize,
      ),
      isTrue,
    );
    expect(
      state.clubs.every((club) {
        final connectedPlayerIds =
            state.playersForClub(club.id).map((player) => player.id).toSet();
        return connectedPlayerIds.length == FootballWorldFactory.squadSize &&
            connectedPlayerIds.containsAll(club.playerIds);
      }),
      isTrue,
    );
    expect(
      state.availableTalents.every(
        (player) => player.age >= 16 && player.age <= 20,
      ),
      isTrue,
    );
    expect(
      state.players.every(
        (player) =>
            player.heightCm >= 168 &&
            player.heightCm <= 201 &&
            player.weightKg >= 58 &&
            player.weightKg <= 105,
      ),
      isTrue,
    );
    expect(
      state.players.every(
        (player) =>
            player.ability ==
            Player.calculateOverall(player.position, player.attributes),
      ),
      isTrue,
    );
    expect(
      state.players.every(
        (player) => [
          player.attacking,
          player.defending,
          player.technical,
          player.mental,
          player.physical,
          player.speed,
        ].every((rating) => rating >= 1 && rating <= 99),
      ),
      isTrue,
    );
  });

  test('game state survives a JSON round trip', () {
    final original = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );

    final withInjury = original.copyWith(
      players: [
        original.players.first.copyWith(fatigue: 54, consecutiveStarts: 3),
        ...original.players.skip(1),
      ],
      injuries: [
        PlayerInjury(
          id: 'injury-round-trip',
          playerId: original.players.first.id,
          name: 'Ankle sprain',
          startSeason: 1,
          startWeek: 1,
          totalWeeks: 3,
          weeksRemaining: 3,
        ),
      ],
      trainingPlans: [
        PlayerTrainingPlan(
          playerId: original.players.first.id,
          focus: TrainingFocus.mental,
          intensity: TrainingIntensity.intense,
          progress: 63,
        ),
      ],
    );
    final restored = GameState.fromJson(withInjury.toJson());

    expect(restored.agent.id, original.agent.id);
    expect(restored.agent.name, original.agent.name);
    expect(restored.createdAt, original.createdAt);
    expect(restored.schemaVersion, GameState.currentSchemaVersion);
    expect(restored.seasonLabel(1), '2025/2026');
    expect(restored.seasonLabel(2), '2026/2027');
    expect(restored.availableTalents, hasLength(2));
    expect(restored.scouts, hasLength(4));
    expect(restored.office.level, 1);
    expect(restored.clubs, hasLength(20));
    expect(restored.fixtures, hasLength(380));
    expect(restored.leagues.single.positionPrizeMoney, hasLength(20));
    expect(restored.players.first.heightCm, original.players.first.heightCm);
    expect(restored.players.first.weightKg, original.players.first.weightKg);
    expect(restored.players.first.attacking, original.players.first.attacking);
    expect(restored.players.first.ability, original.players.first.ability);
    expect(restored.clubManagers, hasLength(20));
    expect(
        restored.clubManagers.every((manager) => manager.rotation > 0), isTrue);
    expect(restored.clubs.first.balance, original.clubs.first.balance);
    expect(restored.injuries.single.name, 'Ankle sprain');
    expect(restored.injuries.single.weeksRemaining, 3);
    expect(restored.players.first.fatigue, 54);
    expect(restored.players.first.consecutiveStarts, 3);
    expect(
      restored.trainingPlanForPlayer(original.players.first.id).focus,
      TrainingFocus.mental,
    );
    expect(
      restored.trainingPlanForPlayer(original.players.first.id).intensity,
      TrainingIntensity.intense,
    );
    expect(
      restored.trainingPlanForPlayer(original.players.first.id).progress,
      63,
    );
  });

  test('higher reputation produces a stronger talent rating band', () {
    const generator = TalentGenerator();

    final newAgentBand = generator.ratingBandForReputation(1);
    final establishedAgentBand = generator.ratingBandForReputation(1000);

    expect(
      establishedAgentBand.minimumAbility,
      greaterThan(newAgentBand.minimumAbility),
    );
    expect(
      establishedAgentBand.maximumAbility,
      greaterThan(newAgentBand.maximumAbility),
    );
  });
}
