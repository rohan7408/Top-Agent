import 'dart:math';

import '../../domain/models/club.dart';
import '../../domain/models/club_offer.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/services/game_balance.dart';

class OfferEngine {
  const OfferEngine({this.balance = const GameBalance()});

  final GameBalance balance;

  List<ClubOffer> generateOffers({
    required GameState game,
    required Player player,
  }) {
    final seed = _stableHash(
      '${player.id}-${game.currentSeason}-${game.currentWeek}',
    );
    final random = Random(seed);
    final candidates = game.clubs
        .where((club) => club.id != player.clubId && club.budget > 0)
        .map(
          (club) => (
            club: club,
            fit: _clubFit(game: game, club: club, player: player) +
                random.nextDouble() * 10,
          ),
        )
        .toList(growable: true)
      ..sort((first, second) => second.fit.compareTo(first.fit));

    if (candidates.isEmpty) return const [];
    final offerCount = min(candidates.length, 1 + random.nextInt(3));

    return List.generate(offerCount, (index) {
      final club = candidates[index].club;
      final weeklySalary = balance.weeklyWage(
        ability: player.ability,
        potential: player.potential,
        age: player.age,
        marketMultiplier: 0.94 + (random.nextDouble() * 0.20),
      );
      final contractLength = 2 + random.nextInt(4);
      final agentFee = balance.agentSigningFee(
        weeklyWage: weeklySalary,
        clubBudget: club.budget,
        contractLength: contractLength,
        feeRate: game.office.agentFeeRate,
      );

      return ClubOffer(
        id: 'offer-${player.id}-${game.currentSeason}-${game.currentWeek}-${club.id}',
        playerId: player.id,
        clubId: club.id,
        weeklySalary: weeklySalary,
        agentFee: agentFee,
        contractLength: contractLength,
        createdWeek: game.currentWeek,
        createdSeason: game.currentSeason,
        salaryCommissionRate: game.office.salaryCommissionRate,
      );
    }, growable: false);
  }

  double _clubFit({
    required GameState game,
    required Club club,
    required Player player,
  }) {
    final squad = game.playersForClub(club.id);
    final positionPlayers = squad
        .where((member) => member.position == player.position)
        .toList(growable: false);
    final comparisonGroup = positionPlayers.isEmpty ? squad : positionPlayers;
    final averageAbility = comparisonGroup.isEmpty
        ? 50.0
        : comparisonGroup
                .map((member) => member.ability)
                .reduce((first, second) => first + second) /
            comparisonGroup.length;
    final developmentValue = (player.potential - player.ability) * 0.7;
    final squadOpportunity = 16 - (player.ability - averageAbility).abs();
    final youthDevelopment =
        ((game.managerForClub(club.id)?.youthDevelopment ?? 55) - 50) * 0.12;
    final reputation = game.agent.reputation;
    final reputationTrust = reputation >= 0
        ? log(reputation + 1) * 2
        : -log(reputation.abs() + 1) * 2.5;
    return squadOpportunity +
        developmentValue +
        youthDevelopment +
        reputationTrust;
  }

  static int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7FFFFFFF;
    }
    return hash;
  }
}
