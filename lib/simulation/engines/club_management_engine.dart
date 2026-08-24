import 'dart:math';

import '../../domain/models/contract.dart';
import '../../domain/models/contract_event.dart';
import '../../domain/models/club.dart';
import '../../domain/models/game_email.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/transfer_record.dart';
import '../../domain/services/game_balance.dart';
import '../../domain/services/squad_analysis_service.dart';
import '../../domain/services/season_calendar.dart';
import '../../domain/services/transfer_eligibility.dart';
import '../../domain/services/player_move_adjustment.dart';
import '../../domain/services/transfer_valuation_service.dart';
import '../../domain/services/club_roster_accounting.dart';
import '../../domain/services/club_transfer_strategy.dart';
import '../../domain/services/club_financial_policy.dart';
import '../../domain/services/player_transfer_decision.dart';

class ClubManagementResult {
  const ClubManagementResult({
    required this.state,
    required this.transfersCompleted,
    required this.contractsRenewed,
  });

  final GameState state;
  final int transfersCompleted;
  final int contractsRenewed;
}

class ClubManagementEngine {
  const ClubManagementEngine({
    this.squadAnalysisService = const SquadAnalysisService(),
    this.balance = const GameBalance(),
    this.seasonCalendar = const SeasonCalendar(),
    this.transferEligibility = const TransferEligibility(),
    this.playerMoveAdjustment = const PlayerMoveAdjustment(),
    this.transferValuation = const TransferValuationService(),
    this.clubRosterAccounting = const ClubRosterAccounting(),
    this.transferStrategy = const ClubTransferStrategyService(),
    this.financialPolicy = const ClubFinancialPolicyService(),
    this.playerDecision = const PlayerTransferDecisionService(),
  });

  final SquadAnalysisService squadAnalysisService;
  final GameBalance balance;
  final SeasonCalendar seasonCalendar;
  final TransferEligibility transferEligibility;
  final PlayerMoveAdjustment playerMoveAdjustment;
  final TransferValuationService transferValuation;
  final ClubRosterAccounting clubRosterAccounting;
  final ClubTransferStrategyService transferStrategy;
  final ClubFinancialPolicyService financialPolicy;
  final PlayerTransferDecisionService playerDecision;

  ClubManagementResult processWeek(GameState game, {required int seed}) {
    var working = game.copyWith(
      clubs: game.clubs
          .map(
            (club) => club.copyWith(
              balance: club.balance - club.totalSalary,
            ),
          )
          .toList(growable: false),
    );

    if (!seasonCalendar.isTransferWindow(game.currentWeek)) {
      return ClubManagementResult(
        state: working,
        transfersCompleted: 0,
        contractsRenewed: 0,
      );
    }

    final random = Random(seed ^ 0x4C5542);
    var transfersCompleted = 0;
    final buyers = working.clubs
        .map((club) {
          final strategy = transferStrategy.forClub(working, club);
          final policy = financialPolicy.forClub(
            game: working,
            club: club,
            strategy: strategy,
          );
          return _BuyerTurn(
            clubId: club.id,
            priority: strategy.recruitmentUrgency +
                random.nextDouble() * 0.30 -
                strategy.recentArrivals * 0.07,
            canRecruit:
                strategy.canRecruit && policy.availableTransferFunds > 0,
          );
        })
        .where((turn) => turn.canRecruit)
        .toList(growable: true)
      ..sort((first, second) => second.priority.compareTo(first.priority));
    for (final buyer in buyers) {
      if (transfersCompleted >= 2) break;
      final transfer = _attemptTransfer(working, buyer.clubId, random);
      if (transfer == null) continue;
      working = transfer;
      transfersCompleted++;
    }

    var contractsRenewed = 0;
    if (game.currentWeek >= 40) {
      final renewal = _renewExpiringContracts(working, random);
      working = renewal.state;
      contractsRenewed = renewal.count;
    }

    return ClubManagementResult(
      state: working,
      transfersCompleted: transfersCompleted,
      contractsRenewed: contractsRenewed,
    );
  }

  GameState? _attemptTransfer(GameState game, String buyerId, Random random) {
    final buyerIndex = game.clubs.indexWhere((club) => club.id == buyerId);
    if (buyerIndex < 0) return null;
    final buyer = game.clubs[buyerIndex];
    final strategy = transferStrategy.forClub(game, buyer);
    if (!strategy.canRecruit) return null;
    final policy = financialPolicy.forClub(
      game: game,
      club: buyer,
      strategy: strategy,
    );
    if (policy.availableTransferFunds <= 0 || policy.maxOfferWage <= 0) {
      return null;
    }
    final need =
        squadAnalysisService.prioritiesForClub(buyer, game.players).first;
    final buyerSquad = game.playersForClub(buyer.id);
    if (buyerSquad.length >= 26) return null;
    final buyerAverage = buyerSquad.isEmpty
        ? 50.0
        : buyerSquad.fold<int>(0, (sum, player) => sum + player.ability) /
            buyerSquad.length;

    final candidates = game.players.where((player) {
      final sellerId = player.clubId;
      if (sellerId == null || sellerId == buyer.id || player.agentId != null) {
        return false;
      }
      if (player.position != need.position || player.age < 18) return false;
      if (player.isLoanListed || player.isOnLoan) return false;
      if (!transferEligibility.canTransferPermanently(game, player)) {
        return false;
      }
      final sellerSquad = game.playersForClub(sellerId);
      if (sellerSquad.length <= 14) return false;
      final abilityFloor = buyerAverage - 5 + strategy.ambition * 5.5;
      final canStrengthen = player.ability >= abilityFloor ||
          (player.age <= 23 && player.potential >= buyerAverage + 3);
      final seller = game.clubById(sellerId);
      if (seller == null) return false;
      final sellerStrategy = transferStrategy.forClub(game, seller);
      final valuation = transferValuation.valueForSeller(
        game,
        player,
        sellerAmbition: sellerStrategy.ambition,
      );
      final affordable =
          policy.availableTransferFunds >= valuation.askingPrice * 0.55;
      return canStrengthen && affordable;
    }).toList(growable: true)
      ..sort((first, second) {
        final firstScore = _transferTargetScore(
          game: game,
          player: first,
          buyer: buyer,
          strategy: strategy,
        );
        final secondScore = _transferTargetScore(
          game: game,
          player: second,
          buyer: buyer,
          strategy: strategy,
        );
        return secondScore.compareTo(firstScore);
      });

    if (candidates.isEmpty) return null;
    final shortlist = candidates.take(min(4, candidates.length)).toList();
    final biasedIndex =
        (random.nextDouble() * random.nextDouble() * shortlist.length).floor();
    final player = shortlist[biasedIndex.clamp(0, shortlist.length - 1)];
    final sellerIndex =
        game.clubs.indexWhere((club) => club.id == player.clubId);
    if (sellerIndex < 0) return null;
    final seller = game.clubs[sellerIndex];
    final buyerManager = game.managerForClub(buyer.id);
    final sellerManager = game.managerForClub(seller.id);
    final buyerNegotiation = buyerManager?.transferNegotiation ?? 60;
    final sellerNegotiation = sellerManager?.transferNegotiation ?? 60;
    final sellerStrategy = transferStrategy.forClub(game, seller);
    final valuation = transferValuation.valueForSeller(
      game,
      player,
      sellerAmbition: sellerStrategy.ambition,
    );
    final bidMultiplier = (0.82 +
            random.nextDouble() * 0.22 +
            strategy.ambition * 0.16 +
            (buyerNegotiation - sellerNegotiation) / 450)
        .clamp(0.76, 1.28);
    final fee = (valuation.askingPrice * bidMultiplier).roundToDouble();
    if (fee > policy.availableTransferFunds) return null;
    final acceptanceChance = transferValuation.saleProbability(
      valuation: valuation,
      offer: fee,
      isTransferListed: player.isTransferListed,
      negotiationEdge: (buyerNegotiation - sellerNegotiation) / 800,
    );
    if (random.nextDouble() > acceptanceChance) return null;

    final marketWage = balance.weeklyWage(
      ability: player.ability,
      potential: player.potential,
      age: player.age,
      marketMultiplier: 1.02,
    );
    final desiredSalary = max(
      player.salary *
          (1.06 + strategy.ambition * 0.18 + random.nextDouble() * 0.10),
      marketWage * (0.94 + strategy.ambition * 0.16 + strategy.prestige * 0.06),
    );
    final salary = min(desiredSalary, policy.maxOfferWage).roundToDouble();
    if (!policy.canFund(club: buyer, fee: fee, weeklyWage: salary)) {
      return null;
    }
    final playerAcceptance = playerDecision.acceptanceProbability(
      game: game,
      player: player,
      seller: seller,
      buyer: buyer,
      buyerStrategy: strategy,
      weeklySalary: salary,
    );
    if (random.nextDouble() > playerAcceptance) return null;
    final contractLength = 3 + random.nextInt(3);
    final players = [...game.players];
    final playerIndex = players.indexWhere((item) => item.id == player.id);
    final adjustedPlayer =
        playerMoveAdjustment.applyRapidMoveRisk(game, player);
    players[playerIndex] = adjustedPlayer.copyWith(
      clubId: buyer.id,
      value: fee,
      salary: salary,
      contractEndSeason: game.currentSeason + contractLength,
      isTransferListed: false,
      isLoanListed: false,
    );

    final clubs = [...game.clubs];
    clubs[sellerIndex] = clubRosterAccounting.synchronize(
      seller.copyWith(
        budget: seller.budget + fee,
        balance: seller.balance + fee,
      ),
      players,
    );
    clubs[buyerIndex] = clubRosterAccounting.synchronize(
      buyer.copyWith(
        budget: buyer.budget - fee,
        balance: buyer.balance - fee,
      ),
      players,
    );

    final transferId =
        'transfer-s${game.currentSeason}-w${game.currentWeek}-${game.transfers.length + 1}';
    final contract = Contract(
      id: 'contract-$transferId',
      playerId: player.id,
      clubId: buyer.id,
      salary: salary,
      agentFee: 0,
      contractLength: contractLength,
      startSeason: game.currentSeason,
      endSeason: game.currentSeason + contractLength,
      startWeek: game.currentWeek,
    );
    final contractEvent = ContractEvent(
      id: 'contract-event-$transferId',
      type: ContractEventType.signed,
      playerId: player.id,
      clubId: buyer.id,
      season: game.currentSeason,
      week: game.currentWeek,
      weeklySalary: salary,
      previousSalary: player.salary,
      endSeason: game.currentSeason + contractLength,
    );
    final transfer = TransferRecord(
      id: transferId,
      playerId: player.id,
      fromClubId: seller.id,
      toClubId: buyer.id,
      fee: fee,
      season: game.currentSeason,
      week: game.currentWeek,
    );
    return game.copyWith(
      players: players,
      clubs: clubs,
      contracts: [
        ...game.contracts.where((item) => item.playerId != player.id),
        contract,
      ],
      contractEvents: [...game.contractEvents, contractEvent],
      transfers: [...game.transfers, transfer],
      emails: player.agentId == game.agent.id
          ? [
              GameEmail(
                id: 'email-$transferId',
                type: GameEmailType.transfer,
                subject: '${player.name} joins ${buyer.name}',
                body:
                    '${buyer.name} completed the signing of ${player.name} from ${seller.name} for ${_money(fee)}.',
                season: game.currentSeason,
                week: game.currentWeek,
                playerId: player.id,
                clubId: buyer.id,
              ),
              ...game.emails,
            ]
          : game.emails,
    );
  }

  double _transferTargetScore({
    required GameState game,
    required Player player,
    required Club buyer,
    required ClubTransferStrategy strategy,
  }) {
    final contract = game.contracts
        .where((contract) => contract.playerId == player.id)
        .lastOrNull;
    final listedBonus = player.isTransferListed ? 35.0 : 0.0;
    final fit = transferValuation.buyerFit(
      game: game,
      club: buyer,
      player: player,
    );
    final ageProfile = player.age <= 23
        ? 8.0
        : player.age >= 31
            ? -8.0
            : 3.0;
    final valueEfficiency = player.ability * 1000000 / max(1, player.value);
    final expiringBonus =
        contract != null && contract.endSeason <= game.currentSeason + 1
            ? 7.0
            : 0.0;
    final immediateQuality = (player.ability - strategy.squadAverage) *
        (0.45 + strategy.ambition * 0.80);
    final futureValue = max(0, player.potential - player.ability) *
        (0.22 + (1 - strategy.ambition) * 0.24);
    final arrivalPenalty = strategy.recentArrivals * 7.0;
    return listedBonus +
        fit +
        ageProfile +
        valueEfficiency +
        expiringBonus +
        immediateQuality +
        futureValue -
        arrivalPenalty;
  }

  ({GameState state, int count}) _renewExpiringContracts(
    GameState game,
    Random random,
  ) {
    var players = [...game.players];
    var clubs = [...game.clubs];
    var contracts = [...game.contracts];
    final contractEvents = [...game.contractEvents];
    final emails = [...game.emails];
    var renewed = 0;

    for (var clubIndex = 0; clubIndex < clubs.length; clubIndex++) {
      if (renewed >= 4) break;
      final club = clubs[clubIndex];
      final squad =
          players.where((player) => player.clubId == club.id).toList();
      if (squad.isEmpty) continue;
      final average =
          squad.fold<int>(0, (sum, player) => sum + player.ability) /
              squad.length;
      final candidates = squad
          .where((player) =>
              player.agentId == null &&
              (player.contractEndSeason ?? 999) <= game.currentSeason &&
              (player.ability >= average || player.age <= 23))
          .toList()
        ..sort((first, second) => second.ability.compareTo(first.ability));
      if (candidates.isEmpty) continue;

      final player = candidates.first;
      final playerIndex = players.indexWhere((item) => item.id == player.id);
      final length = 2 + random.nextInt(3);
      final salary = max(
        player.salary * (1.06 + random.nextDouble() * 0.14),
        balance.weeklyWage(
          ability: player.ability,
          potential: player.potential,
          age: player.age,
          marketMultiplier: 0.98,
        ),
      ).roundToDouble();
      players[playerIndex] = player.copyWith(
        salary: salary,
        contractEndSeason: game.currentSeason + length,
      );
      clubs[clubIndex] = club.copyWith(
        totalSalary: club.totalSalary - player.salary + salary,
      );
      final renewalId =
          'renewal-s${game.currentSeason}-w${game.currentWeek}-${player.id}';
      contracts = [
        ...contracts.where((item) => item.playerId != player.id),
        Contract(
          id: renewalId,
          playerId: player.id,
          clubId: club.id,
          salary: salary,
          agentFee: 0,
          contractLength: length,
          startSeason: game.currentSeason,
          endSeason: game.currentSeason + length,
          startWeek: game.currentWeek,
        ),
      ];
      contractEvents.add(
        ContractEvent(
          id: 'contract-event-$renewalId',
          type: ContractEventType.renewed,
          playerId: player.id,
          clubId: club.id,
          season: game.currentSeason,
          week: game.currentWeek,
          weeklySalary: salary,
          previousSalary: player.salary,
          endSeason: game.currentSeason + length,
        ),
      );
      if (player.agentId == game.agent.id) {
        emails.insert(
          0,
          GameEmail(
            id: 'email-$renewalId',
            type: GameEmailType.contract,
            subject: '${player.name} agrees new deal',
            body:
                '${club.name} renewed ${player.name}\'s contract through ${game.seasonLabel(game.currentSeason + length)}.',
            season: game.currentSeason,
            week: game.currentWeek,
            playerId: player.id,
            clubId: club.id,
          ),
        );
      }
      renewed++;
    }

    return (
      state: game.copyWith(
        players: players,
        clubs: clubs,
        contracts: contracts,
        contractEvents: contractEvents,
        emails: emails,
      ),
      count: renewed,
    );
  }

  String _money(double amount) {
    if (amount >= 1000000) return '£${(amount / 1000000).toStringAsFixed(1)}m';
    if (amount >= 1000) return '£${(amount / 1000).toStringAsFixed(0)}k';
    return '£${amount.toStringAsFixed(0)}';
  }
}

class _BuyerTurn {
  const _BuyerTurn({
    required this.clubId,
    required this.priority,
    required this.canRecruit,
  });

  final String clubId;
  final double priority;
  final bool canRecruit;
}
