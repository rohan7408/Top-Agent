import 'dart:math';

import '../../domain/models/club_offer.dart';
import '../../domain/models/agency_transaction.dart';
import '../../domain/models/contract.dart';
import '../../domain/models/contract_event.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_email.dart';
import '../../domain/models/transfer_record.dart';
import '../../domain/services/season_calendar.dart';
import '../../domain/services/transfer_eligibility.dart';
import '../../domain/services/player_move_adjustment.dart';
import '../../domain/services/club_roster_accounting.dart';

class DealEngine {
  const DealEngine({
    this.seasonCalendar = const SeasonCalendar(),
    this.transferEligibility = const TransferEligibility(),
    this.playerMoveAdjustment = const PlayerMoveAdjustment(),
    this.clubRosterAccounting = const ClubRosterAccounting(),
  });

  final SeasonCalendar seasonCalendar;
  final TransferEligibility transferEligibility;
  final PlayerMoveAdjustment playerMoveAdjustment;
  final ClubRosterAccounting clubRosterAccounting;

  GameState? acceptOffer(GameState game, String offerId) {
    final offer = game.offerById(offerId);
    if (offer == null || offer.status != ClubOfferStatus.pending) return null;
    if (offer.isMarketMove) {
      final createdAbsoluteWeek =
          ((offer.createdSeason - 1) * 50) + offer.createdWeek;
      if (!seasonCalendar.isTransferWindow(game.currentWeek) ||
          createdAbsoluteWeek != game.currentAbsoluteWeek) {
        return null;
      }
    }
    return switch (offer.type) {
      ClubOfferType.freeAgent => _acceptFreeAgent(game, offer),
      ClubOfferType.transfer => _acceptPermanentTransfer(game, offer),
      ClubOfferType.loan => _acceptLoan(game, offer),
    };
  }

  GameState? _acceptFreeAgent(GameState game, ClubOffer offer) {
    final playerIndex = game.players.indexWhere(
      (player) => player.id == offer.playerId,
    );
    final clubIndex = game.clubs.indexWhere((club) => club.id == offer.clubId);
    if (playerIndex == -1 || clubIndex == -1) return null;

    final player = game.players[playerIndex];
    if (player.agentId != game.agent.id || player.clubId != null) return null;

    final club = game.clubs[clubIndex];
    if (offer.agentFee > club.budget || offer.agentFee > club.balance) {
      return null;
    }
    final updatedPlayers = [...game.players];
    updatedPlayers[playerIndex] = player.copyWith(
      clubId: club.id,
      salary: offer.weeklySalary,
      contractEndSeason: game.currentSeason + offer.contractLength,
      isTransferListed: false,
      isLoanListed: false,
    );

    final updatedClubs = [...game.clubs];
    updatedClubs[clubIndex] = club.copyWith(
      squadValue: club.squadValue + player.value,
      totalSalary: club.totalSalary + offer.weeklySalary,
      budget: club.budget - offer.agentFee,
      balance: club.balance - offer.agentFee,
      playerIds: [...club.playerIds, player.id],
    );

    final updatedOffers = game.offers.map((candidate) {
      if (candidate.id == offer.id) {
        return candidate.copyWith(status: ClubOfferStatus.accepted);
      }
      if (candidate.playerId == offer.playerId &&
          candidate.status == ClubOfferStatus.pending) {
        return candidate.copyWith(status: ClubOfferStatus.declined);
      }
      return candidate;
    }).toList(growable: false);

    final contract = Contract(
      id: 'contract-${offer.id}',
      playerId: player.id,
      clubId: club.id,
      salary: offer.weeklySalary,
      agentFee: offer.agentFee,
      contractLength: offer.contractLength,
      startSeason: game.currentSeason,
      endSeason: game.currentSeason + offer.contractLength,
      startWeek: game.currentWeek,
      salaryCommissionRate: offer.salaryCommissionRate,
    );
    final reputationGain = max(1, player.ability ~/ 12);
    final contractEvent = ContractEvent(
      id: 'contract-event-${offer.id}',
      type: ContractEventType.signed,
      playerId: player.id,
      clubId: club.id,
      season: game.currentSeason,
      week: game.currentWeek,
      weeklySalary: offer.weeklySalary,
      endSeason: game.currentSeason + offer.contractLength,
    );
    final email = GameEmail(
      id: 'email-deal-${offer.id}',
      type: GameEmailType.contract,
      subject: '${player.name} signs for ${club.name}',
      body:
          '${player.name} agreed a ${offer.contractLength}-year contract worth £${offer.weeklySalary.toStringAsFixed(0)} per week. Your agency earned £${offer.agentFee.toStringAsFixed(0)}.',
      season: game.currentSeason,
      week: game.currentWeek,
      playerId: player.id,
      clubId: club.id,
    );
    final transfer = TransferRecord(
      id: 'free-agent-${offer.id}',
      playerId: player.id,
      fromClubId: '',
      toClubId: club.id,
      fee: 0,
      agentFee: offer.agentFee,
      season: game.currentSeason,
      week: game.currentWeek,
      type: TransferMoveType.freeAgent,
    );

    return game.copyWith(
      agent: game.agent.copyWith(
        money: game.agent.money + offer.agentFee,
        reputation: game.agent.reputation + reputationGain,
        totalAgentFeesEarned: game.agent.totalAgentFeesEarned + offer.agentFee,
      ),
      players: updatedPlayers,
      clubs: updatedClubs,
      contracts: [...game.contracts, contract],
      contractEvents: [...game.contractEvents, contractEvent],
      transfers: [...game.transfers, transfer],
      offers: updatedOffers,
      emails: [email, ...game.emails],
      agencyTransactions: [
        ...game.agencyTransactions,
        AgencyTransaction(
          id: 'transaction-agent-fee-${offer.id}',
          type: AgencyTransactionType.agentFee,
          amount: offer.agentFee,
          description: '${player.name} signed for ${club.name}',
          season: game.currentSeason,
          week: game.currentWeek,
        ),
      ],
    );
  }

  GameState? _acceptPermanentTransfer(GameState game, ClubOffer offer) {
    final playerIndex =
        game.players.indexWhere((player) => player.id == offer.playerId);
    final buyerIndex = game.clubs.indexWhere((club) => club.id == offer.clubId);
    if (playerIndex < 0 || buyerIndex < 0) return null;
    final player = game.players[playerIndex];
    final sellerId = offer.fromClubId;
    final sellerIndex = game.clubs.indexWhere((club) => club.id == sellerId);
    if (player.agentId != game.agent.id ||
        player.clubId != sellerId ||
        sellerIndex < 0 ||
        !transferEligibility.canTransferPermanently(game, player)) {
      return null;
    }
    final seller = game.clubs[sellerIndex];
    final buyer = game.clubs[buyerIndex];
    final totalCost = offer.transferFee + offer.agentFee;
    if (totalCost > buyer.budget || totalCost > buyer.balance) {
      return null;
    }

    final movedPlayer =
        playerMoveAdjustment.applyRapidMoveRisk(game, player).copyWith(
              clubId: buyer.id,
              value: offer.transferFee,
              salary: offer.weeklySalary,
              contractEndSeason: game.currentSeason + offer.contractLength,
              isTransferListed: false,
              isLoanListed: false,
            );
    final players = [...game.players]..[playerIndex] = movedPlayer;
    final clubs = [...game.clubs];
    clubs[sellerIndex] = clubRosterAccounting.synchronize(
      seller.copyWith(
        budget: seller.budget + offer.transferFee,
        balance: seller.balance + offer.transferFee,
      ),
      players,
    );
    clubs[buyerIndex] = clubRosterAccounting.synchronize(
      buyer.copyWith(
        budget: buyer.budget - totalCost,
        balance: buyer.balance - totalCost,
      ),
      players,
    );
    final transferId =
        'agent-transfer-s${game.currentSeason}-w${game.currentWeek}-${player.id}-${buyer.id}';
    final contract = Contract(
      id: 'contract-$transferId',
      playerId: player.id,
      clubId: buyer.id,
      salary: offer.weeklySalary,
      agentFee: offer.agentFee,
      contractLength: offer.contractLength,
      startSeason: game.currentSeason,
      endSeason: game.currentSeason + offer.contractLength,
      startWeek: game.currentWeek,
      salaryCommissionRate: offer.salaryCommissionRate,
    );
    final contractEvent = ContractEvent(
      id: 'contract-event-$transferId',
      type: ContractEventType.signed,
      playerId: player.id,
      clubId: buyer.id,
      season: game.currentSeason,
      week: game.currentWeek,
      weeklySalary: offer.weeklySalary,
      previousSalary: player.salary,
      endSeason: game.currentSeason + offer.contractLength,
    );
    final transfer = TransferRecord(
      id: transferId,
      playerId: player.id,
      fromClubId: seller.id,
      toClubId: buyer.id,
      fee: offer.transferFee,
      agentFee: offer.agentFee,
      season: game.currentSeason,
      week: game.currentWeek,
    );
    final abilityNote = movedPlayer.ability < player.ability
        ? ' The quick move affected his settling-in period: overall ${player.ability} → ${movedPlayer.ability}.'
        : '';
    return game.copyWith(
      agent: game.agent.copyWith(
        money: game.agent.money + offer.agentFee,
        reputation: game.agent.reputation + max(1, player.ability ~/ 15),
        totalAgentFeesEarned: game.agent.totalAgentFeesEarned + offer.agentFee,
      ),
      players: players,
      clubs: clubs,
      contracts: [
        ...game.contracts.where((contract) => contract.playerId != player.id),
        contract,
      ],
      contractEvents: [...game.contractEvents, contractEvent],
      transfers: [...game.transfers, transfer],
      offers: _closePlayerOffers(game, offer),
      emails: [
        GameEmail(
          id: 'email-$transferId',
          type: GameEmailType.transfer,
          subject: '${player.name} joins ${buyer.name}',
          body:
              '${buyer.name} signed ${player.name} from ${seller.name} for ${_money(offer.transferFee)}.$abilityNote',
          season: game.currentSeason,
          week: game.currentWeek,
          playerId: player.id,
          clubId: buyer.id,
        ),
        ...game.emails,
      ],
      agencyTransactions: [
        ...game.agencyTransactions,
        AgencyTransaction(
          id: 'transaction-agent-fee-$transferId',
          type: AgencyTransactionType.agentFee,
          amount: offer.agentFee,
          description: '${player.name} transferred to ${buyer.name}',
          season: game.currentSeason,
          week: game.currentWeek,
        ),
      ],
    );
  }

  GameState? _acceptLoan(GameState game, ClubOffer offer) {
    final playerIndex =
        game.players.indexWhere((player) => player.id == offer.playerId);
    final buyerIndex = game.clubs.indexWhere((club) => club.id == offer.clubId);
    if (playerIndex < 0 || buyerIndex < 0) return null;
    final player = game.players[playerIndex];
    final parentId = offer.fromClubId;
    final parentIndex = game.clubs.indexWhere((club) => club.id == parentId);
    if (player.agentId != game.agent.id ||
        player.clubId != parentId ||
        player.isOnLoan ||
        parentIndex < 0) {
      return null;
    }
    final parent = game.clubs[parentIndex];
    final buyer = game.clubs[buyerIndex];
    final totalCost = offer.transferFee + offer.agentFee;
    if (totalCost > buyer.budget || totalCost > buyer.balance) {
      return null;
    }
    final loanEndSeason =
        game.currentSeason + max(1, offer.contractLength).toInt();
    final movedPlayer = player.copyWith(
      clubId: buyer.id,
      salary: offer.weeklySalary,
      isTransferListed: false,
      isLoanListed: false,
      loanParentClubId: parent.id,
      loanEndSeason: loanEndSeason,
      loanEndWeek: 1,
      loanOriginalSalary: player.salary,
    );
    final players = [...game.players]..[playerIndex] = movedPlayer;
    final clubs = [...game.clubs];
    clubs[parentIndex] = parent.copyWith(
      squadValue: max(0, parent.squadValue - player.value).toDouble(),
      totalSalary: max(0, parent.totalSalary - player.salary).toDouble(),
      budget: parent.budget + offer.transferFee,
      balance: parent.balance + offer.transferFee,
      playerIds: parent.playerIds.where((id) => id != player.id).toList(),
    );
    clubs[buyerIndex] = buyer.copyWith(
      squadValue: buyer.squadValue + player.value,
      totalSalary: buyer.totalSalary + offer.weeklySalary,
      budget: buyer.budget - totalCost,
      balance: buyer.balance - totalCost,
      playerIds: [...buyer.playerIds, player.id],
    );
    final loanId =
        'agent-loan-s${game.currentSeason}-w${game.currentWeek}-${player.id}-${buyer.id}';
    return game.copyWith(
      agent: game.agent.copyWith(
        money: game.agent.money + offer.agentFee,
        reputation: game.agent.reputation + 1,
        totalAgentFeesEarned: game.agent.totalAgentFeesEarned + offer.agentFee,
      ),
      players: players,
      clubs: clubs,
      transfers: [
        ...game.transfers,
        TransferRecord(
          id: loanId,
          playerId: player.id,
          fromClubId: parent.id,
          toClubId: buyer.id,
          fee: offer.transferFee,
          agentFee: offer.agentFee,
          season: game.currentSeason,
          week: game.currentWeek,
          type: TransferMoveType.loan,
        ),
      ],
      offers: _closePlayerOffers(game, offer),
      emails: [
        GameEmail(
          id: 'email-$loanId',
          type: GameEmailType.transfer,
          subject: '${player.name} loaned to ${buyer.name}',
          body:
              '${player.name} joined ${buyer.name} on loan from ${parent.name} until ${game.seasonLabel(loanEndSeason)}.',
          season: game.currentSeason,
          week: game.currentWeek,
          playerId: player.id,
          clubId: buyer.id,
        ),
        ...game.emails,
      ],
      agencyTransactions: [
        ...game.agencyTransactions,
        AgencyTransaction(
          id: 'transaction-agent-fee-$loanId',
          type: AgencyTransactionType.agentFee,
          amount: offer.agentFee,
          description: '${player.name} loaned to ${buyer.name}',
          season: game.currentSeason,
          week: game.currentWeek,
        ),
      ],
    );
  }

  List<ClubOffer> _closePlayerOffers(GameState game, ClubOffer accepted) =>
      game.offers.map((candidate) {
        if (candidate.id == accepted.id) {
          return candidate.copyWith(status: ClubOfferStatus.accepted);
        }
        if (candidate.playerId == accepted.playerId &&
            candidate.status == ClubOfferStatus.pending) {
          return candidate.copyWith(status: ClubOfferStatus.declined);
        }
        return candidate;
      }).toList(growable: false);

  String _money(double amount) {
    if (amount >= 1000000) return '£${(amount / 1000000).toStringAsFixed(1)}m';
    if (amount >= 1000) return '£${(amount / 1000).toStringAsFixed(0)}k';
    return '£${amount.toStringAsFixed(0)}';
  }

  GameState? declineOffer(GameState game, String offerId) {
    final offer = game.offerById(offerId);
    if (offer == null || offer.status != ClubOfferStatus.pending) return null;
    return game.copyWith(
      offers: game.offers
          .map(
            (candidate) => candidate.id == offerId
                ? candidate.copyWith(status: ClubOfferStatus.declined)
                : candidate,
          )
          .toList(growable: false),
    );
  }
}
