import 'dart:math';

import '../../domain/models/game_state.dart';
import '../../domain/models/player_injury.dart';
import '../../domain/services/game_balance.dart';

class WeeklyInjuryEngine {
  const WeeklyInjuryEngine({this.balance = const GameBalance()});

  final GameBalance balance;

  List<PlayerInjury> createIncidentalInjuries({
    required GameState game,
    required Set<String> excludedPlayerIds,
    required int seed,
  }) {
    final random = Random(seed ^ 0x494E4A);
    final activeInjuryIds = game.injuries
        .where((injury) => injury.isActive)
        .map((injury) => injury.playerId)
        .toSet();
    final injuries = <PlayerInjury>[];

    for (final player in game.players) {
      if (player.isRetired ||
          activeInjuryIds.contains(player.id) ||
          excludedPlayerIds.contains(player.id)) {
        continue;
      }
      final injuryChance = balance.incidentalInjuryChance(
        hasClub: player.clubId != null,
        age: player.age,
        fatigue: player.fatigue,
        consecutiveStarts: player.consecutiveStarts,
      );
      if (random.nextDouble() >= injuryChance) continue;

      final roll = random.nextDouble();
      final (name, duration) = switch (roll) {
        < 0.35 => ('Training knock', 1),
        < 0.70 => ('Training strain', 2 + random.nextInt(3)),
        < 0.90 => ('Ankle injury', 3 + random.nextInt(4)),
        _ => ('Back injury', 5 + random.nextInt(6)),
      };
      injuries.add(
        PlayerInjury(
          id: 'injury-weekly-s${game.currentSeason}-w${game.currentWeek}-${player.id}',
          playerId: player.id,
          name: name,
          startSeason: game.currentSeason,
          startWeek: game.currentWeek,
          totalWeeks: duration,
          weeksRemaining: duration,
        ),
      );
    }
    return List.unmodifiable(injuries);
  }
}
