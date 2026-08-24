import 'dart:math';

import '../../domain/models/club_offer.dart';
import '../../domain/models/game_state.dart';

enum OfferNegotiationStatus { accepted, rejected, withdrawn, invalid }

class OfferNegotiationResolution {
  const OfferNegotiationResolution({
    required this.state,
    required this.status,
    required this.acceptanceChance,
  });

  final GameState state;
  final OfferNegotiationStatus status;
  final double acceptanceChance;
}

class OfferNegotiationEngine {
  const OfferNegotiationEngine();

  OfferNegotiationResolution evaluate({
    required GameState game,
    required String offerId,
    required double weeklySalary,
    required double agentFee,
    required int contractLength,
  }) {
    final offer = game.offerById(offerId);
    if (offer == null ||
        offer.status != ClubOfferStatus.pending ||
        weeklySalary < 0 ||
        agentFee < 0 ||
        contractLength < 1 ||
        contractLength > 5) {
      return OfferNegotiationResolution(
        state: game,
        status: OfferNegotiationStatus.invalid,
        acceptanceChance: 0,
      );
    }

    final club = game.clubById(offer.clubId);
    if (club == null) {
      return OfferNegotiationResolution(
        state: game,
        status: OfferNegotiationStatus.invalid,
        acceptanceChance: 0,
      );
    }

    final salaryRatio =
        offer.weeklySalary <= 0 ? 1.0 : weeklySalary / offer.weeklySalary;
    final feeRatio = offer.agentFee <= 0 ? 1.0 : agentFee / offer.agentFee;
    final salaryPressure = max(0, salaryRatio - 1) * 0.58;
    final feePressure = max(0, feeRatio - 1) * 0.34;
    final lengthPressure = (contractLength - offer.contractLength).abs() * 0.05;
    final relationshipBonus = game.clubAgencyRelationshipScore(club.id) / 500;
    final reputationBonus = game.agent.reputation.clamp(-200, 400) / 1600;
    final affordability = agentFee + (weeklySalary * 50);
    final budgetPenalty =
        affordability > max(club.budget, club.balance) ? 0.32 : 0.0;
    final unrealisticTerms = salaryRatio > 1.65 ||
        feeRatio > 1.80 ||
        affordability > max(club.budget, club.balance) * 1.1;
    final chance = (unrealisticTerms
            ? 0.0
            : 0.84 -
                salaryPressure -
                feePressure -
                lengthPressure -
                budgetPenalty +
                relationshipBonus +
                reputationBonus)
        .clamp(0.0, 0.97)
        .toDouble();

    final isAtOrBelowOriginal = weeklySalary <= offer.weeklySalary &&
        agentFee <= offer.agentFee &&
        contractLength == offer.contractLength;
    final roll = _stableRoll(
      '$offerId-${offer.negotiationRounds}-$weeklySalary-$agentFee-$contractLength',
    );
    final accepted =
        !unrealisticTerms && (isAtOrBelowOriginal || roll < chance);
    final rounds = offer.negotiationRounds + 1;
    final withdrawn = !accepted && rounds >= 3;

    final offers = game.offers.map((candidate) {
      if (candidate.id != offer.id) return candidate;
      if (accepted) {
        return candidate.copyWith(
          weeklySalary: weeklySalary,
          agentFee: agentFee,
          contractLength: contractLength,
          negotiationRounds: rounds,
        );
      }
      return candidate.copyWith(
        negotiationRounds: rounds,
        status: withdrawn ? ClubOfferStatus.declined : null,
      );
    }).toList(growable: false);

    return OfferNegotiationResolution(
      state: game.copyWith(offers: offers),
      status: accepted
          ? OfferNegotiationStatus.accepted
          : withdrawn
              ? OfferNegotiationStatus.withdrawn
              : OfferNegotiationStatus.rejected,
      acceptanceChance: chance,
    );
  }

  double _stableRoll(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash / 0x7fffffff;
  }
}
