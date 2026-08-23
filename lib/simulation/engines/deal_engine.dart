import 'dart:math';

import '../../domain/models/club_offer.dart';
import '../../domain/models/agency_transaction.dart';
import '../../domain/models/contract.dart';
import '../../domain/models/contract_event.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_email.dart';

class DealEngine {
  const DealEngine();

  GameState? acceptOffer(GameState game, String offerId) {
    final offer = game.offerById(offerId);
    if (offer == null || offer.status != ClubOfferStatus.pending) return null;

    final playerIndex = game.players.indexWhere(
      (player) => player.id == offer.playerId,
    );
    final clubIndex = game.clubs.indexWhere((club) => club.id == offer.clubId);
    if (playerIndex == -1 || clubIndex == -1) return null;

    final player = game.players[playerIndex];
    if (player.agentId != game.agent.id || player.clubId != null) return null;

    final club = game.clubs[clubIndex];
    final updatedPlayers = [...game.players];
    updatedPlayers[playerIndex] = player.copyWith(
      clubId: club.id,
      salary: offer.weeklySalary,
      contractEndSeason: game.currentSeason + offer.contractLength,
    );

    final updatedClubs = [...game.clubs];
    updatedClubs[clubIndex] = club.copyWith(
      squadValue: club.squadValue + player.value,
      totalSalary: club.totalSalary + offer.weeklySalary,
      budget: max(0, club.budget - offer.agentFee).toDouble(),
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

    return game.copyWith(
      agent: game.agent.copyWith(
        money: game.agent.money + offer.agentFee,
        reputation: game.agent.reputation + reputationGain,
      ),
      players: updatedPlayers,
      clubs: updatedClubs,
      contracts: [...game.contracts, contract],
      contractEvents: [...game.contractEvents, contractEvent],
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
