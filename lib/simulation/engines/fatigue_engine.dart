import '../../domain/models/club_manager.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player_match_performance.dart';
import '../../domain/services/game_balance.dart';

class FatigueEngine {
  const FatigueEngine({this.balance = const GameBalance()});

  final GameBalance balance;

  GameState recoverBeforeWeek(GameState game) {
    return game.copyWith(
      players: game.players.map((player) {
        if (player.isRetired) return player;
        final recovery =
            balance.weeklyFatigueRecovery(player.attributes.stamina);
        return player.copyWith(
          fatigue: (player.fatigue - recovery).clamp(0, 100),
        );
      }).toList(growable: false),
    );
  }

  GameState applyMatchLoad(
    GameState game,
    List<PlayerMatchPerformance> performances,
  ) {
    final performanceByPlayer = {
      for (final performance in performances) performance.playerId: performance,
    };
    final managers = {
      for (final manager in game.clubManagers) manager.clubId: manager,
    };
    return game.copyWith(
      players: game.players.map((player) {
        final performance = performanceByPlayer[player.id];
        if (performance == null) {
          return player.copyWith(consecutiveStarts: 0);
        }
        final manager = managers[performance.clubId];
        final styleLoad = switch (manager?.tacticalStyle) {
          TacticalStyle.highPress => 6.0,
          TacticalStyle.possession => 2.0,
          TacticalStyle.counterAttack => 1.0,
          TacticalStyle.defensive => -1.0,
          TacticalStyle.balanced || null => 0.0,
        };
        final matchLoad = balance.matchFatigueLoad(
          minutes: performance.minutes,
          stamina: player.attributes.stamina,
          consecutiveStarts: player.consecutiveStarts,
          tacticalLoad: styleLoad,
        );
        return player.copyWith(
          fatigue: (player.fatigue + matchLoad).clamp(0, 100),
          consecutiveStarts:
              performance.started ? player.consecutiveStarts + 1 : 0,
        );
      }).toList(growable: false),
    );
  }
}
