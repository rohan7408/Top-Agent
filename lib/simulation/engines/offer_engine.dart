import 'dart:math';

import '../../domain/models/club.dart';
import '../../domain/models/club_offer.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/services/game_balance.dart';
import '../../domain/services/squad_analysis_service.dart';
import '../../domain/services/transfer_valuation_service.dart';

class OfferEngine {
  const OfferEngine({
    this.balance = const GameBalance(),
    this.transferValuation = const TransferValuationService(),
  });

  final GameBalance balance;
  final TransferValuationService transferValuation;

  List<ClubOffer> generateOffers({
    required GameState game,
    required Player player,
  }) {
    final offerType = player.clubId == null
        ? ClubOfferType.freeAgent
        : player.isTransferListed
            ? ClubOfferType.transfer
            : player.isLoanListed
                ? ClubOfferType.loan
                : null;
    if (offerType == null || player.isOnLoan) return const [];
    final seed = _stableHash(
      offerType == ClubOfferType.freeAgent
          ? '${player.id}-${game.currentSeason}-${game.currentWeek}'
          : '${player.id}-${game.currentSeason}-${game.currentWeek}-${offerType.name}',
    );
    final random = Random(seed);
    final sellerValuation = transferValuation.valueForSeller(game, player);
    final candidates = game.clubs
        .where(
          (club) =>
              club.id != player.clubId &&
              club.budget > 0 &&
              club.balance > 0 &&
              _isPlausibleDestination(
                game: game,
                club: club,
                player: player,
                offerType: offerType,
              ),
        )
        .map(
          (club) => (
            club: club,
            fit: _clubFit(game: game, club: club, player: player),
          ),
        )
        .toList(growable: true)
      ..sort((first, second) => second.fit.compareTo(first.fit));

    if (candidates.isEmpty) return const [];
    final offerCount = switch (offerType) {
      ClubOfferType.loan => min(candidates.length, 1),
      ClubOfferType.transfer => min(candidates.length, 1 + random.nextInt(2)),
      ClubOfferType.freeAgent => min(candidates.length, 1 + random.nextInt(3)),
    };

    final selectedClubs = _weightedDestinations(
      candidates: candidates,
      count: offerCount,
      random: random,
    );

    return List.generate(offerCount, (index) {
      final club = selectedClubs[index];
      final weeklySalary = balance.weeklyWage(
        ability: player.ability,
        potential: player.potential,
        age: player.age,
        marketMultiplier: 0.94 + (random.nextDouble() * 0.20),
      );
      final contractLength =
          offerType == ClubOfferType.loan ? 1 : 2 + random.nextInt(4);
      final seller =
          player.clubId == null ? null : game.clubById(player.clubId!);
      final buyerManager = game.managerForClub(club.id);
      final sellerManager =
          seller == null ? null : game.managerForClub(seller.id);
      final negotiationDelta = ((sellerManager?.transferNegotiation ?? 60) -
              (buyerManager?.transferNegotiation ?? 60)) /
          500;
      final transferFee = switch (offerType) {
        ClubOfferType.freeAgent => 0.0,
        ClubOfferType.transfer => min(
            sellerValuation.askingPrice *
                (0.94 + random.nextDouble() * 0.14 - negotiationDelta * 0.35),
            min(club.budget, club.balance) * 0.98,
          ).toDouble(),
        ClubOfferType.loan => min(
            player.value * (0.025 + random.nextDouble() * 0.025),
            min(club.budget, club.balance) * 0.25,
          ).toDouble(),
      };
      final agentFee = balance.agentSigningFee(
        weeklyWage: weeklySalary,
        clubBudget: club.budget,
        contractLength: contractLength,
        feeRate: game.office.agentFeeRate,
      );

      return ClubOffer(
        id: offerType == ClubOfferType.freeAgent
            ? 'offer-${player.id}-${game.currentSeason}-${game.currentWeek}-${club.id}'
            : 'offer-${offerType.name}-${player.id}-${game.currentSeason}-${game.currentWeek}-${club.id}',
        playerId: player.id,
        clubId: club.id,
        weeklySalary: weeklySalary,
        agentFee: agentFee,
        contractLength: contractLength,
        createdWeek: game.currentWeek,
        createdSeason: game.currentSeason,
        type: offerType,
        fromClubId: player.clubId,
        transferFee: transferFee,
        salaryCommissionRate: game.office.salaryCommissionRate,
      );
    }, growable: false);
  }

  double _clubFit({
    required GameState game,
    required Club club,
    required Player player,
  }) {
    final reputation = game.agent.reputation;
    final reputationTrust = reputation >= 0
        ? log(reputation + 1) * 2
        : -log(reputation.abs() + 1) * 2.5;
    final relationship = game.clubAgencyRelationshipScore(club.id);
    return transferValuation.buyerFit(
          game: game,
          club: club,
          player: player,
        ) +
        reputationTrust +
        relationship * 0.08;
  }

  bool _isPlausibleDestination({
    required GameState game,
    required Club club,
    required Player player,
    required ClubOfferType offerType,
  }) {
    final squad = game.playersForClub(club.id);
    final rolePlayers = squad
        .where((member) => member.position == player.position)
        .toList(growable: false);
    final averageRoleAbility = rolePlayers.isEmpty
        ? 50.0
        : rolePlayers.fold<int>(0, (sum, member) => sum + member.ability) /
            rolePlayers.length;
    final roleTarget = SquadAnalysisService.targetDepth[player.position]!;
    final sellerValuation = transferValuation.valueForSeller(game, player);
    return switch (offerType) {
      ClubOfferType.loan => player.age <= 23 &&
          player.potential >= player.ability + 4 &&
          squad.length < 25 &&
          rolePlayers.length <= roleTarget + 1 &&
          player.ability >= averageRoleAbility - 9,
      ClubOfferType.transfer => squad.length < 27 &&
          (player.ability >= averageRoleAbility - 6 ||
              player.potential >= averageRoleAbility + 3) &&
          min(club.budget, club.balance) >= sellerValuation.askingPrice,
      ClubOfferType.freeAgent => squad.length < 27 &&
          (rolePlayers.length <= roleTarget + 2 ||
              player.ability >= averageRoleAbility),
    };
  }

  List<Club> _weightedDestinations({
    required List<({Club club, double fit})> candidates,
    required int count,
    required Random random,
  }) {
    final pool = [...candidates];
    final selected = <Club>[];
    while (selected.length < count && pool.isNotEmpty) {
      final highestFit = pool.map((candidate) => candidate.fit).reduce(max);
      final weights = pool
          .map((candidate) => exp((candidate.fit - highestFit) / 18))
          .toList(growable: false);
      final totalWeight = weights.fold<double>(0, (sum, item) => sum + item);
      var draw = random.nextDouble() * totalWeight;
      var selectedIndex = pool.length - 1;
      for (var index = 0; index < pool.length; index++) {
        draw -= weights[index];
        if (draw <= 0) {
          selectedIndex = index;
          break;
        }
      }
      selected.add(pool.removeAt(selectedIndex).club);
    }
    return selected;
  }

  static int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7FFFFFFF;
    }
    return hash;
  }
}
