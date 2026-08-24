import 'dart:math';

import '../../domain/models/game_state.dart';
import '../../domain/services/talent_generator.dart';

class TrainingGroundWeekResult {
  const TrainingGroundWeekResult({
    required this.state,
    required this.talentsDeveloped,
  });

  final GameState state;
  final int talentsDeveloped;
}

class TrainingGroundEngine {
  const TrainingGroundEngine({
    this.talentGenerator = const TalentGenerator(),
  });

  final TalentGenerator talentGenerator;

  TrainingGroundWeekResult processWeek(
    GameState game, {
    required int nextSeason,
    required int nextWeek,
    required int seed,
  }) {
    final absoluteWeek = ((nextSeason - 1) * 50) + nextWeek;
    final ground = game.trainingGround;
    final maximumTalentPool = max(2, game.office.clientCapacity);
    if (game.availableTalents.length >= maximumTalentPool) {
      return TrainingGroundWeekResult(state: game, talentsDeveloped: 0);
    }
    if (ground.weeksUntilIntake(absoluteWeek) > 0) {
      return TrainingGroundWeekResult(state: game, talentsDeveloped: 0);
    }

    final talent = talentGenerator
        .generateForTrainingGround(
          count: 1,
          minimumAbility: ground.minimumAbility,
          maximumAbility: ground.maximumAbility,
          seed: seed ^ (ground.level * 0x711),
          idPrefix: 'academy-s$nextSeason-w$nextWeek-l${ground.level}',
        )
        .single;
    return TrainingGroundWeekResult(
      state: game.copyWith(
        trainingGround: ground.recordIntake(absoluteWeek),
        players: [...game.players, talent],
      ),
      talentsDeveloped: 1,
    );
  }
}
