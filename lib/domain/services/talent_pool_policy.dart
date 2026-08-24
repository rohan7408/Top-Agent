import 'dart:math';

import '../models/game_state.dart';

class TalentPoolPolicy {
  const TalentPoolPolicy();

  static const int maximumTalentAge = 21;

  int capacityFor(GameState game) => max(2, game.office.clientCapacity);

  GameState clean(GameState game) {
    final available = game.availableTalents.toList(growable: true)
      ..sort((a, b) {
        final byAge = a.age.compareTo(b.age);
        if (byAge != 0) return byAge;
        final byPotential = b.potential.compareTo(a.potential);
        return byPotential != 0 ? byPotential : b.ability.compareTo(a.ability);
      });
    final retainedIds = available
        .where(
          (player) =>
              player.age <= maximumTalentAge &&
              player.ability <=
                  max(
                    game.office.scoutingRatingCap,
                    game.trainingGround.maximumAbility,
                  ),
        )
        .take(capacityFor(game))
        .map((player) => player.id)
        .toSet();
    final removedIds = available
        .where((player) => !retainedIds.contains(player.id))
        .map((player) => player.id)
        .toSet();
    if (removedIds.isEmpty) return game;
    return game.copyWith(
      players: game.players
          .where((player) => !removedIds.contains(player.id))
          .toList(growable: false),
      emails: game.emails
          .where((email) => !removedIds.contains(email.playerId))
          .toList(growable: false),
    );
  }
}
