import '../models/club.dart';
import '../models/player.dart';

class SquadNeed {
  const SquadNeed({
    required this.position,
    required this.playerCount,
    required this.averageAbility,
    required this.priority,
  });

  final PlayerPosition position;
  final int playerCount;
  final double averageAbility;
  final double priority;
}

class SquadAnalysisService {
  const SquadAnalysisService();

  static const targetDepth = {
    PlayerPosition.goalkeeper: 2,
    PlayerPosition.defender: 6,
    PlayerPosition.midfielder: 6,
    PlayerPosition.forward: 4,
  };

  List<SquadNeed> prioritiesForClub(
    Club club,
    Iterable<Player> allPlayers,
  ) {
    final squad = allPlayers.where((player) => player.clubId == club.id);
    final needs = PlayerPosition.values.map((position) {
      final rolePlayers =
          squad.where((player) => player.position == position).toList();
      final average = rolePlayers.isEmpty
          ? 0.0
          : rolePlayers.fold<int>(0, (sum, player) => sum + player.ability) /
              rolePlayers.length;
      final shortage = targetDepth[position]! - rolePlayers.length;
      final priority = (shortage > 0 ? shortage * 100 : 0) + (100 - average);
      return SquadNeed(
        position: position,
        playerCount: rolePlayers.length,
        averageAbility: average,
        priority: priority,
      );
    }).toList(growable: false)
      ..sort((first, second) => second.priority.compareTo(first.priority));
    return List.unmodifiable(needs);
  }
}
