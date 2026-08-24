import 'dart:math';

import '../models/club.dart';
import '../models/club_offer.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'squad_analysis_service.dart';

class TransferValuation {
  const TransferValuation({
    required this.marketValue,
    required this.askingPrice,
    required this.importance,
    required this.wonderkidValue,
    required this.scarcity,
    required this.financialPressure,
  });

  final double marketValue;
  final double askingPrice;
  final double importance;
  final double wonderkidValue;
  final double scarcity;
  final double financialPressure;
}

/// Shared football-market maths used by club AI and player-offer generation.
///
/// Market value is an estimate, not a release clause. A club's reservation
/// price changes with squad importance, positional depth, age/upside,
/// performance, contract security, listing status, and financial pressure.
class TransferValuationService {
  const TransferValuationService();

  TransferValuation valueForSeller(
    GameState game,
    Player player, {
    double sellerAmbition = 0.5,
  }) {
    final sellerId = player.clubId;
    final seller = sellerId == null ? null : game.clubById(sellerId);
    if (seller == null) {
      return TransferValuation(
        marketValue: player.value,
        askingPrice: player.value,
        importance: 0,
        wonderkidValue: _wonderkidValue(player),
        scarcity: 0,
        financialPressure: 0,
      );
    }

    final squad = game.playersForClub(seller.id);
    final rolePlayers = squad
        .where((member) => member.position == player.position)
        .toList(growable: true)
      ..sort((a, b) => b.ability.compareTo(a.ability));
    final roleIndex =
        rolePlayers.indexWhere((member) => member.id == player.id);
    final roleRank = roleIndex < 0 ? rolePlayers.length : roleIndex;
    final roleStatus = roleRank == 0
        ? 1.0
        : roleRank == 1
            ? 0.78
            : roleRank == 2
                ? 0.52
                : 0.24;
    final squadAverage = squad.isEmpty
        ? player.ability.toDouble()
        : squad.fold<int>(0, (sum, member) => sum + member.ability) /
            squad.length;
    final qualityLead = ((player.ability - squadAverage + 8) / 22).clamp(0, 1);
    final currentStats = game
        .statsForPlayer(player.id)
        .where((stats) => stats.season == game.currentSeason)
        .firstOrNull;
    final usage = ((currentStats?.appearances ?? 0) / 30).clamp(0, 1);
    final rating = currentStats == null || currentStats.appearances == 0
        ? 0.45
        : ((currentStats.averageRating - 5.8) / 2.2).clamp(0, 1);
    final scarcity = _scarcity(rolePlayers.length, player.position);
    final importance = (roleStatus * 0.34 +
            qualityLead * 0.24 +
            usage * 0.20 +
            rating * 0.10 +
            scarcity * 0.12)
        .clamp(0, 1)
        .toDouble();
    final wonderkidValue = _wonderkidValue(player);
    final contractYears = max(
      0,
      (player.contractEndSeason ?? game.currentSeason) - game.currentSeason,
    );
    final contractSecurity = (contractYears / 4).clamp(0, 1);
    final financialPressure = _financialPressure(seller);
    final listedDiscount = player.isTransferListed ? 0.22 : 0.0;

    final premium = (0.06 +
            importance * 0.48 +
            wonderkidValue * 0.46 +
            scarcity * 0.12 +
            contractSecurity * 0.11 +
            rating * 0.08 -
            financialPressure * 0.20 -
            listedDiscount +
            sellerAmbition.clamp(0, 1) * importance * 0.10)
        .clamp(-0.20, 1.25);
    final askingPrice = player.value * (1 + premium);

    return TransferValuation(
      marketValue: player.value,
      askingPrice: askingPrice,
      importance: importance,
      wonderkidValue: wonderkidValue,
      scarcity: scarcity,
      financialPressure: financialPressure,
    );
  }

  /// Continuous willingness curve. Even a vital wonderkid can be sold when a
  /// sufficiently strong offer meets the club's circumstances.
  double saleProbability({
    required TransferValuation valuation,
    required double offer,
    required bool isTransferListed,
    double negotiationEdge = 0,
  }) {
    final ratio = offer / max(1, valuation.askingPrice);
    final priceResponse = 1 / (1 + exp(-7.2 * (ratio - 0.98)));
    final contextAdjustment = valuation.financialPressure * 0.18 +
        (isTransferListed ? 0.16 : 0) -
        valuation.importance * 0.08 -
        valuation.wonderkidValue * 0.06 +
        negotiationEdge;
    return (priceResponse + contextAdjustment).clamp(0.03, 0.97);
  }

  /// Destination fit is deliberately club-specific so one weak club does not
  /// absorb every similar prospect.
  double buyerFit({
    required GameState game,
    required Club club,
    required Player player,
  }) {
    final squad = game.playersForClub(club.id);
    final rolePlayers = squad
        .where((member) => member.position == player.position)
        .toList(growable: false);
    final targetDepth = SquadAnalysisService.targetDepth[player.position]!;
    final shortage = (targetDepth - rolePlayers.length).clamp(-2, targetDepth);
    final roleAverage = rolePlayers.isEmpty
        ? 45.0
        : rolePlayers.fold<int>(0, (sum, member) => sum + member.ability) /
            rolePlayers.length;
    final squadAverage = squad.isEmpty
        ? 50.0
        : squad.fold<int>(0, (sum, member) => sum + member.ability) /
            squad.length;
    final abilityFit = 18 - (player.ability - roleAverage).abs() * 0.75;
    final upgrade = (player.ability - roleAverage).clamp(-12, 18) * 0.85;
    final development = max(0, player.potential - player.ability) *
        ((game.managerForClub(club.id)?.youthDevelopment ?? 55) / 100) *
        0.48;
    final clubLevelFit = 12 - (player.ability - squadAverage).abs() * 0.35;
    final availableFunds = min(club.budget, club.balance);
    final affordability = availableFunds / max(1, player.value);
    final budgetFit = (log(max(0.1, affordability)) * 7).clamp(-18, 16);
    final representedAtClub = game.representedPlayers
        .where((client) => client.clubId == club.id)
        .length;
    final pendingToClub = game.offers
        .where(
          (offer) =>
              offer.clubId == club.id &&
              offer.status == ClubOfferStatus.pending,
        )
        .length;
    final recentArrivals = game.transfers.where((move) {
      if (move.toClubId != club.id) return false;
      final now = (game.currentSeason - 1) * 50 + game.currentWeek;
      final then = (move.season - 1) * 50 + move.week;
      return now - then <= 10;
    }).length;
    final congestion = representedAtClub * 14 +
        pendingToClub * 7 +
        recentArrivals * 6 +
        max(0, squad.length - 23) * 3;

    return shortage * 14 +
        abilityFit +
        upgrade +
        development +
        clubLevelFit +
        budgetFit -
        congestion;
  }

  double _wonderkidValue(Player player) {
    if (player.age > 24) return 0;
    final ageFactor = ((25 - player.age) / 9).clamp(0, 1);
    final ceiling = ((player.potential - 68) / 27).clamp(0, 1);
    final growthGap = ((player.potential - player.ability) / 24).clamp(0, 1);
    return (ageFactor * 0.30 + ceiling * 0.42 + growthGap * 0.28).clamp(0, 1);
  }

  double _scarcity(int roleCount, PlayerPosition position) {
    final target = SquadAnalysisService.targetDepth[position]!;
    return ((target + 1 - roleCount) / target).clamp(0, 1);
  }

  double _financialPressure(Club club) {
    final salaryRunway = club.balance / max(1, club.totalSalary);
    final runwayPressure = ((14 - salaryRunway) / 14).clamp(0, 1);
    final budgetPressure = club.budget <= 0
        ? 1.0
        : ((club.squadValue * 0.05 - club.budget) /
                max(1, club.squadValue * 0.05))
            .clamp(0, 1);
    return (runwayPressure * 0.65 + budgetPressure * 0.35).clamp(0, 1);
  }
}
