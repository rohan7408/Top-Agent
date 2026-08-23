import '../../domain/models/game_email.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
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
    final email = GameEmail(
      id: 'email-academy-s$nextSeason-w$nextWeek-${talent.id}',
      type: GameEmailType.world,
      subject: 'Training Ground prospect: ${talent.name}',
      body:
          'Your Level ${ground.level} Training Ground developed a ${talent.age}-year-old ${talent.position.label.toLowerCase()} rated ${talent.ability} with ${talent.potential} potential. No scout was required.',
      season: nextSeason,
      week: nextWeek,
      playerId: talent.id,
    );

    return TrainingGroundWeekResult(
      state: game.copyWith(
        trainingGround: ground.recordIntake(absoluteWeek),
        players: [...game.players, talent],
        emails: [email, ...game.emails],
      ),
      talentsDeveloped: 1,
    );
  }
}
