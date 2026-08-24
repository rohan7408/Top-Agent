import '../models/contract.dart';
import '../models/game_state.dart';
import '../models/player.dart';

class TransferEligibility {
  const TransferEligibility();

  static const int minimumPermanentStayWeeks = 50;

  Contract? activeContract(GameState game, Player player) {
    final owningClubId = player.loanParentClubId ?? player.clubId;
    if (owningClubId == null) return null;
    return game.contracts
        .where(
          (contract) =>
              contract.playerId == player.id && contract.clubId == owningClubId,
        )
        .lastOrNull;
  }

  int weeksAtOwningClub(GameState game, Player player) {
    final contract = activeContract(game, player);
    if (contract == null) {
      return player.clubId == null ? 0 : game.currentAbsoluteWeek - 1;
    }
    final startAbsoluteWeek =
        ((contract.startSeason - 1) * 50) + contract.startWeek;
    return game.currentAbsoluteWeek - startAbsoluteWeek;
  }

  bool canTransferPermanently(GameState game, Player player) =>
      !player.isOnLoan &&
      player.clubId != null &&
      weeksAtOwningClub(game, player) >= minimumPermanentStayWeeks;

  int permanentTransferWaitWeeks(GameState game, Player player) =>
      (minimumPermanentStayWeeks - weeksAtOwningClub(game, player))
          .clamp(0, minimumPermanentStayWeeks);
}
