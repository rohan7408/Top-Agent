import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/simulation/engines/training_ground_engine.dart';

void main() {
  test('training ground creates an internal prospect without a scout', () {
    final game = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final initialCount = game.players.length;

    final early = const TrainingGroundEngine().processWeek(
      game,
      nextSeason: 1,
      nextWeek: 12,
      seed: 7,
    );
    expect(early.talentsDeveloped, 0);

    final intake = const TrainingGroundEngine().processWeek(
      game,
      nextSeason: 1,
      nextWeek: 13,
      seed: 7,
    );
    expect(intake.talentsDeveloped, 1);
    expect(intake.state.players, hasLength(initialCount + 1));
    final prospect = intake.state.players.last;
    expect(prospect.ability, inInclusiveRange(32, 48));
    expect(prospect.age, inInclusiveRange(16, 20));
    expect(intake.state.hiredScouts, isEmpty);
    expect(intake.state.trainingGround.lastIntakeAbsoluteWeek, 13);
  });
}
