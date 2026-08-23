import 'dart:math';

import '../../domain/models/contract.dart';
import '../../domain/models/contract_event.dart';
import '../../domain/models/game_email.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/transfer_record.dart';
import '../../domain/services/game_balance.dart';
import '../../domain/services/squad_analysis_service.dart';

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
  });

  final SquadAnalysisService squadAnalysisService;
  final GameBalance balance;

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

    if (!_isTransferWindow(game.currentWeek)) {
      return ClubManagementResult(
        state: working,
        transfersCompleted: 0,
        contractsRenewed: 0,
      );
    }

    final random = Random(seed ^ 0x4C5542);
    var transfersCompleted = 0;
    final buyers = [...working.clubs]..shuffle(random);
    for (final buyer in buyers) {
      if (transfersCompleted >= 2) break;
      final transfer = _attemptTransfer(working, buyer.id, random);
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

  bool _isTransferWindow(int week) => (week >= 20 && week <= 24) || week >= 40;

  GameState? _attemptTransfer(GameState game, String buyerId, Random random) {
    final buyerIndex = game.clubs.indexWhere((club) => club.id == buyerId);
    if (buyerIndex < 0) return null;
    final buyer = game.clubs[buyerIndex];
    final need =
        squadAnalysisService.prioritiesForClub(buyer, game.players).first;
    final buyerSquad = game.playersForClub(buyer.id);
    final buyerAverage = buyerSquad.isEmpty
        ? 50.0
        : buyerSquad.fold<int>(0, (sum, player) => sum + player.ability) /
            buyerSquad.length;

    final candidates = game.players.where((player) {
      final sellerId = player.clubId;
      if (sellerId == null || sellerId == buyer.id || player.agentId != null) {
        return false;
      }
      if (player.position != need.position || player.age < 21) return false;
      final sellerSquad = game.playersForClub(sellerId);
      final roleCount =
          sellerSquad.where((item) => item.position == player.position).length;
      final minimumAfterSale =
          max(1, SquadAnalysisService.targetDepth[player.position]! - 1);
      if (roleCount <= minimumAfterSale || sellerSquad.length <= 16) {
        return false;
      }
      return player.ability >= buyerAverage - 4;
    }).toList(growable: true)
      ..sort((first, second) {
        final firstScore = first.ability * 1000000 / max(1, first.value);
        final secondScore = second.ability * 1000000 / max(1, second.value);
        return secondScore.compareTo(firstScore);
      });

    if (candidates.isEmpty) return null;
    final shortlist = candidates.take(min(8, candidates.length)).toList();
    final player = shortlist[random.nextInt(shortlist.length)];
    final sellerIndex =
        game.clubs.indexWhere((club) => club.id == player.clubId);
    if (sellerIndex < 0) return null;
    final seller = game.clubs[sellerIndex];
    final buyerManager = game.managerForClub(buyer.id);
    final sellerManager = game.managerForClub(seller.id);
    final negotiationDelta = ((sellerManager?.transferNegotiation ?? 60) -
            (buyerManager?.transferNegotiation ?? 60)) /
        500;
    final fee = balance.transferFee(
      marketValue: player.value,
      negotiationDelta: negotiationDelta,
      randomFactor: random.nextDouble(),
    );
    if (fee > buyer.budget || fee > buyer.balance) return null;

    final salary = max(
      player.salary * (1.08 + random.nextDouble() * 0.18),
      balance.weeklyWage(
        ability: player.ability,
        potential: player.potential,
        age: player.age,
        marketMultiplier: 1.02,
      ),
    ).roundToDouble();
    final contractLength = 3 + random.nextInt(3);
    final players = [...game.players];
    final playerIndex = players.indexWhere((item) => item.id == player.id);
    players[playerIndex] = player.copyWith(
      clubId: buyer.id,
      salary: salary,
      contractEndSeason: game.currentSeason + contractLength,
    );

    final clubs = [...game.clubs];
    clubs[sellerIndex] = seller.copyWith(
      squadValue: max(0, seller.squadValue - player.value).toDouble(),
      totalSalary: max(0, seller.totalSalary - player.salary).toDouble(),
      budget: seller.budget + fee,
      balance: seller.balance + fee,
      playerIds: seller.playerIds.where((id) => id != player.id).toList(),
    );
    clubs[buyerIndex] = buyer.copyWith(
      squadValue: buyer.squadValue + player.value,
      totalSalary: buyer.totalSalary + salary,
      budget: buyer.budget - fee,
      balance: buyer.balance - fee,
      playerIds: [...buyer.playerIds, player.id],
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
