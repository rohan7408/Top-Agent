import 'dart:math';

import '../models/club.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'club_transfer_strategy.dart';
import 'transfer_eligibility.dart';

class PlayerTransferDecisionService {
  const PlayerTransferDecisionService({
    this.transferEligibility = const TransferEligibility(),
  });

  final TransferEligibility transferEligibility;

  double acceptanceProbability({
    required GameState game,
    required Player player,
    required Club seller,
    required Club buyer,
    required ClubTransferStrategy buyerStrategy,
    required double weeklySalary,
  }) {
    final salaryRatio = weeklySalary / max(1, player.salary);
    final salaryAppeal =
        (log(max(0.35, salaryRatio)) / log(1.5)).clamp(-1.5, 1.6);
    final prestigeDelta =
        (log(max(0.1, buyer.clubValue / seller.clubValue)) / log(3))
            .clamp(-1.2, 1.2);
    final rolePlayers = game
        .playersForClub(buyer.id)
        .where((member) => member.position == player.position)
        .toList(growable: false);
    final roleAverage = rolePlayers.isEmpty
        ? 45.0
        : rolePlayers.fold<int>(0, (sum, member) => sum + member.ability) /
            rolePlayers.length;
    final roleOpportunity =
        ((player.ability - roleAverage + 5) / 14).clamp(-0.7, 1.0).toDouble();
    final weeksAtClub = transferEligibility.weeksAtOwningClub(game, player);
    final stabilityPenalty = ((90 - weeksAtClub) / 40).clamp(0.0, 1.0);
    final personalAmbition = player.personality.ambition / 100;
    final professionalism = player.personality.professionalism / 100;
    final listedBoost = player.isTransferListed ? 0.55 : 0.0;
    final utility = -0.18 +
        salaryAppeal * 1.18 +
        prestigeDelta * (0.48 + personalAmbition * 0.42) +
        buyerStrategy.ambition * (0.34 + personalAmbition * 0.34) +
        roleOpportunity * 0.64 +
        listedBoost -
        stabilityPenalty * (0.34 + professionalism * 0.28);
    final probability = 1 / (1 + exp(-utility));
    return probability.clamp(0.05, 0.97);
  }
}
