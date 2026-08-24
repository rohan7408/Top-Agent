import 'dart:math';

import '../models/game_state.dart';
import '../models/player.dart';
import '../models/transfer_record.dart';

class PlayerMoveAdjustment {
  const PlayerMoveAdjustment();

  static const int rapidMoveWindowWeeks = 75;

  Player applyRapidMoveRisk(GameState game, Player player) {
    final previous = game.transfers
        .where(
          (transfer) =>
              transfer.playerId == player.id &&
              transfer.type == TransferMoveType.permanent,
        )
        .toList(growable: true)
      ..sort((first, second) {
        final firstWeek = ((first.season - 1) * 50) + first.week;
        final secondWeek = ((second.season - 1) * 50) + second.week;
        return secondWeek.compareTo(firstWeek);
      });
    if (previous.isEmpty) return player;
    final last = previous.first;
    final lastWeek = ((last.season - 1) * 50) + last.week;
    if (game.currentAbsoluteWeek - lastWeek > rapidMoveWindowWeeks) {
      return player;
    }
    final roll = _stableHash(
          '${player.id}-${game.currentSeason}-${game.currentWeek}',
        ) %
        100;
    if (roll >= 45) return player;
    final decline = roll < 12 ? -2 : -1;
    final attributes = player.attributes.evolve(
      technicalDelta: decline,
      mentalDelta: decline,
      physicalDelta: decline,
    );
    final oldAbility = max(1, player.ability);
    final newAbility = Player.calculateOverall(player.position, attributes);
    return player.copyWith(
      attributes: attributes,
      value: player.value * (newAbility / oldAbility),
    );
  }

  int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7FFFFFFF;
    }
    return hash;
  }
}
