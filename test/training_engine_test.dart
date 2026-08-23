import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/player_injury.dart';
import 'package:football_agent/domain/models/player_training_plan.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/simulation/engines/training_engine.dart';

void main() {
  test('weekly training improves its focus and applies intensity fatigue', () {
    final game = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final talent = game.availableTalents.first.copyWith(
      agentId: game.agent.id,
      isRecruited: true,
      fatigue: 10,
    );
    final prepared = game.copyWith(
      players: [
        talent,
        ...game.players.where((player) => player.id != talent.id),
      ],
      trainingPlans: [
        PlayerTrainingPlan(
          playerId: talent.id,
          focus: TrainingFocus.speed,
          intensity: TrainingIntensity.normal,
          progress: 95,
        ),
      ],
    );

    final result = const TrainingEngine().processWeek(
      prepared,
      nextSeason: 1,
      nextWeek: 2,
    );
    final trained =
        result.state.players.singleWhere((player) => player.id == talent.id);
    final plan = result.state.trainingPlanForPlayer(talent.id);

    expect(result.attributesImproved, 1);
    expect(trained.speed, greaterThan(talent.speed));
    expect(trained.fatigue, 13);
    expect(plan.progress, lessThan(30));
    expect(result.state.emails, isEmpty);
  });

  test('injury pauses both training progress and training fatigue', () {
    final game = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final talent = game.availableTalents.first.copyWith(
      agentId: game.agent.id,
      isRecruited: true,
      fatigue: 25,
    );
    final prepared = game.copyWith(
      players: [
        talent,
        ...game.players.where((player) => player.id != talent.id),
      ],
      trainingPlans: [
        PlayerTrainingPlan(
          playerId: talent.id,
          focus: TrainingFocus.technical,
          intensity: TrainingIntensity.intense,
          progress: 40,
        ),
      ],
      injuries: [
        PlayerInjury(
          id: 'training-injury',
          playerId: talent.id,
          name: 'Ankle sprain',
          startSeason: 1,
          startWeek: 1,
          totalWeeks: 3,
          weeksRemaining: 2,
        ),
      ],
    );

    final result = const TrainingEngine().processWeek(
      prepared,
      nextSeason: 1,
      nextWeek: 2,
    );
    final paused =
        result.state.players.singleWhere((player) => player.id == talent.id);

    expect(result.state.trainingPlanForPlayer(talent.id).progress, 40);
    expect(paused.fatigue, 25);
    expect(result.attributesImproved, 0);
  });

  test('intense training projects more progress than light training', () {
    final game = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final talent = game.availableTalents.first;
    const engine = TrainingEngine();

    final light = engine.projectedWeeklyProgress(
      player: talent,
      plan: PlayerTrainingPlan(
        playerId: 'player',
        intensity: TrainingIntensity.light,
      ),
      coachAbility: 0,
    );
    final intense = engine.projectedWeeklyProgress(
      player: talent,
      plan: PlayerTrainingPlan(
        playerId: 'player',
        intensity: TrainingIntensity.intense,
      ),
      coachAbility: 0,
    );

    expect(intense, greaterThan(light));
  });
}
