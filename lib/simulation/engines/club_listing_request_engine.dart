import '../../domain/models/club_agency_relationship.dart';
import '../../domain/models/game_state.dart';
import '../../domain/services/season_calendar.dart';
import '../../domain/services/transfer_eligibility.dart';

enum ClubListingType { transfer, loan }

enum ClubListingRequestStatus {
  accepted,
  noActiveContract,
  playerUnavailable,
  alreadyListed,
  transferWindowClosed,
  permanentTransferTooSoon,
  alreadyOnLoan,
}

class ClubListingRequestResolution {
  const ClubListingRequestResolution({
    required this.state,
    required this.status,
    required this.recentSigningPenaltyApplied,
  });

  final GameState state;
  final ClubListingRequestStatus status;
  final bool recentSigningPenaltyApplied;
}

class ClubListingRequestEngine {
  const ClubListingRequestEngine({
    this.seasonCalendar = const SeasonCalendar(),
    this.transferEligibility = const TransferEligibility(),
  });

  final SeasonCalendar seasonCalendar;
  final TransferEligibility transferEligibility;

  static const int recentSigningWindowWeeks = 10;
  static const int recentSigningRelationshipPenalty = -8;

  ClubListingRequestResolution resolve({
    required GameState game,
    required String playerId,
    required ClubListingType type,
  }) {
    final playerIndex = game.players.indexWhere(
      (player) => player.id == playerId,
    );
    if (playerIndex < 0) {
      return ClubListingRequestResolution(
        state: game,
        status: ClubListingRequestStatus.playerUnavailable,
        recentSigningPenaltyApplied: false,
      );
    }
    final player = game.players[playerIndex];
    if (player.agentId != game.agent.id ||
        player.clubId == null ||
        player.isRetired) {
      return ClubListingRequestResolution(
        state: game,
        status: ClubListingRequestStatus.playerUnavailable,
        recentSigningPenaltyApplied: false,
      );
    }
    if (!seasonCalendar.isTransferWindow(game.currentWeek)) {
      return ClubListingRequestResolution(
        state: game,
        status: ClubListingRequestStatus.transferWindowClosed,
        recentSigningPenaltyApplied: false,
      );
    }
    if (player.isOnLoan) {
      return ClubListingRequestResolution(
        state: game,
        status: ClubListingRequestStatus.alreadyOnLoan,
        recentSigningPenaltyApplied: false,
      );
    }
    final alreadyListed = type == ClubListingType.transfer
        ? player.isTransferListed
        : player.isLoanListed;
    if (alreadyListed) {
      return ClubListingRequestResolution(
        state: game,
        status: ClubListingRequestStatus.alreadyListed,
        recentSigningPenaltyApplied: false,
      );
    }

    final activeContract = transferEligibility.activeContract(game, player);
    if (activeContract == null) {
      return ClubListingRequestResolution(
        state: game,
        status: ClubListingRequestStatus.noActiveContract,
        recentSigningPenaltyApplied: false,
      );
    }

    if (type == ClubListingType.transfer &&
        !transferEligibility.canTransferPermanently(game, player)) {
      return ClubListingRequestResolution(
        state: game,
        status: ClubListingRequestStatus.permanentTransferTooSoon,
        recentSigningPenaltyApplied: false,
      );
    }

    final contractStart =
        ((activeContract.startSeason - 1) * 50) + activeContract.startWeek;
    final weeksAtClub = game.currentAbsoluteWeek - contractStart;
    final isRecentSigning = weeksAtClub < recentSigningWindowWeeks;
    final players = [...game.players];
    players[playerIndex] = player.copyWith(
      isTransferListed: type == ClubListingType.transfer,
      isLoanListed: type == ClubListingType.loan,
    );

    final relationships = [...game.clubAgencyRelationships];
    if (isRecentSigning) {
      final relationshipIndex = relationships.indexWhere(
        (relationship) => relationship.clubId == player.clubId,
      );
      if (relationshipIndex < 0) {
        relationships.add(
          ClubAgencyRelationship(
            clubId: player.clubId!,
            score: recentSigningRelationshipPenalty,
          ),
        );
      } else {
        relationships[relationshipIndex] =
            relationships[relationshipIndex].adjust(
          recentSigningRelationshipPenalty,
        );
      }
    }

    return ClubListingRequestResolution(
      state: game.copyWith(
        agent: isRecentSigning
            ? game.agent.copyWith(reputation: game.agent.reputation - 2)
            : game.agent,
        players: players,
        clubAgencyRelationships: relationships,
      ),
      status: ClubListingRequestStatus.accepted,
      recentSigningPenaltyApplied: isRecentSigning,
    );
  }
}
