import 'dart:math';

import '../../domain/models/game_email.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_attributes.dart';
import '../../domain/models/player_training_plan.dart';
import '../../domain/services/game_balance.dart';

class TrainingWeekResult {
  const TrainingWeekResult({
    required this.state,
    required this.attributesImproved,
    required this.overallsImproved,
  });

  final GameState state;
  final int attributesImproved;
  final int overallsImproved;
}

class TrainingEngine {
  const TrainingEngine({this.balance = const GameBalance()});

  final GameBalance balance;

  TrainingWeekResult processWeek(
    GameState game, {
    required int nextSeason,
    required int nextWeek,
  }) {
    final plans = {
      for (final plan in game.trainingPlans) plan.playerId: plan,
    };
    for (final player in game.representedPlayers) {
      plans.putIfAbsent(
        player.id,
        () => PlayerTrainingPlan(playerId: player.id),
      );
    }

    const coachAbility = 0;
    var attributesImproved = 0;
    var overallsImproved = 0;
    var emails = game.emails;

    final players = game.players.map((player) {
      final plan = plans[player.id];
      if (plan == null ||
          player.agentId != game.agent.id ||
          player.isRetired ||
          game.activeInjuryForPlayer(player.id) != null ||
          player.ability >= player.potential) {
        return player;
      }

      final gain = projectedWeeklyProgress(
        player: player,
        plan: plan,
        coachAbility: coachAbility,
      );
      var progress = plan.progress + gain;
      var attributes = player.attributes;
      var effectiveFocus = plan.focus;

      if (progress >= 100) {
        effectiveFocus = plan.focus == TrainingFocus.balanced
            ? _weakestFocus(player)
            : plan.focus;
        final trained = _trainAttributes(
          player: player,
          focus: effectiveFocus,
        );
        final newOverall = Player.calculateOverall(player.position, trained);
        if (newOverall <= player.potential &&
            _focusRating(player, trained, effectiveFocus) >
                _focusRating(player, attributes, effectiveFocus)) {
          final oldOverall = player.ability;
          final oldFocus = _focusRating(player, attributes, effectiveFocus);
          attributes = trained;
          progress -= 100;
          attributesImproved++;
          if (newOverall > oldOverall) overallsImproved++;
          emails = [
            GameEmail(
              id: 'email-training-s$nextSeason-w$nextWeek-${player.id}',
              type: GameEmailType.world,
              subject: '${player.name} completes a training block',
              body:
                  '${effectiveFocus.label} improved from $oldFocus to ${_focusRating(player, trained, effectiveFocus)}. Overall is now $newOverall.',
              season: nextSeason,
              week: nextWeek,
              playerId: player.id,
              clubId: player.clubId,
            ),
            ...emails,
          ];
        } else {
          progress = 99;
        }
      }

      plans[player.id] = plan.copyWith(progress: progress.clamp(0, 99));
      return player.copyWith(
        attributes: attributes,
        fatigue: (player.fatigue + plan.intensity.fatigueLoad).clamp(0, 100),
      );
    }).toList(growable: false);

    return TrainingWeekResult(
      state: game.copyWith(
        players: players,
        trainingPlans: plans.values.toList(growable: false),
        emails: emails,
      ),
      attributesImproved: attributesImproved,
      overallsImproved: overallsImproved,
    );
  }

  int projectedWeeklyProgress({
    required Player player,
    required PlayerTrainingPlan plan,
    required int coachAbility,
  }) {
    return balance.weeklyTrainingProgress(
      age: player.age,
      ability: player.ability,
      potential: player.potential,
      coachAbility: coachAbility,
      fatigue: player.fatigue,
      intensity: plan.intensity,
    );
  }

  TrainingFocus _weakestFocus(Player player) {
    final ratings = <TrainingFocus, int>{
      TrainingFocus.attacking: player.attacking,
      TrainingFocus.defending: player.defending,
      TrainingFocus.technical: player.technical,
      TrainingFocus.mental: player.mental,
      TrainingFocus.physical: player.physical,
      TrainingFocus.speed: player.speed,
    };
    return ratings.entries
        .reduce(
          (first, second) => first.value <= second.value ? first : second,
        )
        .key;
  }

  PlayerAttributes _trainAttributes({
    required Player player,
    required TrainingFocus focus,
  }) {
    final attributes = player.attributes;
    int up(int value) => min(99, value + 1);
    return switch (focus) {
      TrainingFocus.attacking => attributes.copyWith(
          finishing: up(attributes.finishing),
          dribbling: up(attributes.dribbling),
          firstTouch: up(attributes.firstTouch),
          composure: up(attributes.composure),
          anticipation: up(attributes.anticipation),
          positioning: up(attributes.positioning),
        ),
      TrainingFocus.defending => attributes.copyWith(
          tackling: up(attributes.tackling),
          positioning: up(attributes.positioning),
          anticipation: up(attributes.anticipation),
          workRate: up(attributes.workRate),
          strength: up(attributes.strength),
          jumping: up(attributes.jumping),
        ),
      TrainingFocus.technical => attributes.copyWith(
          passing: up(attributes.passing),
          dribbling: up(attributes.dribbling),
          firstTouch: up(attributes.firstTouch),
          finishing: up(attributes.finishing),
          vision: up(attributes.vision),
          goalkeeping: player.position == PlayerPosition.goalkeeper
              ? up(attributes.goalkeeping)
              : attributes.goalkeeping,
        ),
      TrainingFocus.mental => attributes.copyWith(
          decisions: up(attributes.decisions),
          composure: up(attributes.composure),
          anticipation: up(attributes.anticipation),
          positioning: up(attributes.positioning),
          vision: up(attributes.vision),
          workRate: up(attributes.workRate),
        ),
      TrainingFocus.physical => attributes.copyWith(
          agility: up(attributes.agility),
          stamina: up(attributes.stamina),
          strength: up(attributes.strength),
          jumping: up(attributes.jumping),
        ),
      TrainingFocus.speed => attributes.copyWith(
          pace: up(attributes.pace),
          acceleration: up(attributes.acceleration),
          agility: up(attributes.agility),
        ),
      TrainingFocus.balanced => attributes,
    };
  }

  int _focusRating(
    Player player,
    PlayerAttributes attributes,
    TrainingFocus focus,
  ) {
    final temporary = player.copyWith(attributes: attributes);
    return switch (focus) {
      TrainingFocus.attacking => temporary.attacking,
      TrainingFocus.defending => temporary.defending,
      TrainingFocus.technical => temporary.technical,
      TrainingFocus.mental => temporary.mental,
      TrainingFocus.physical => temporary.physical,
      TrainingFocus.speed => temporary.speed,
      TrainingFocus.balanced => temporary.ability,
    };
  }
}
