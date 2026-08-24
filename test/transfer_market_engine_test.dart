import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/contract.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/models/transfer_record.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/player_move_adjustment.dart';
import 'package:football_agent/simulation/engines/club_listing_request_engine.dart';
import 'package:football_agent/simulation/engines/deal_engine.dart';
import 'package:football_agent/simulation/engines/offer_engine.dart';
import 'package:football_agent/simulation/engines/transfer_market_engine.dart';
import 'package:football_agent/simulation/game_engine.dart';

void main() {
  const factory = GameFactory();

  test('listing requests require a window and one completed club year', () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final player = base.playersForClub(base.clubs.first.id).first;
    final represented = player.copyWith(
      agentId: base.agent.id,
      isRecruited: true,
    );
    final contract = Contract(
      id: 'eligibility-contract',
      playerId: player.id,
      clubId: player.clubId!,
      salary: player.salary,
      agentFee: 0,
      contractLength: 4,
      startSeason: 1,
      endSeason: 5,
      startWeek: 1,
    );
    final players = [
      for (final candidate in base.players)
        candidate.id == player.id ? represented : candidate,
    ];
    const engine = ClubListingRequestEngine();

    final closed = engine.resolve(
      game: base.copyWith(players: players, contracts: [contract]),
      playerId: player.id,
      type: ClubListingType.transfer,
    );
    expect(closed.status, ClubListingRequestStatus.transferWindowClosed);

    final tooSoon = engine.resolve(
      game: base.copyWith(
        agent: base.agent.copyWith(currentWeek: 20),
        players: players,
        contracts: [contract],
      ),
      playerId: player.id,
      type: ClubListingType.transfer,
    );
    expect(tooSoon.status, ClubListingRequestStatus.permanentTransferTooSoon);

    final eligible = engine.resolve(
      game: base.copyWith(
        agent: base.agent.copyWith(currentSeason: 2, currentWeek: 20),
        players: players,
        contracts: [contract],
      ),
      playerId: player.id,
      type: ClubListingType.transfer,
    );
    expect(eligible.status, ClubListingRequestStatus.accepted);
    expect(
      eligible.state.players
          .firstWhere((candidate) => candidate.id == player.id)
          .isTransferListed,
      isTrue,
    );
  });

  test('listed client receives a one-week transfer offer and can move clubs',
      () {
    final setup = _listedClient(loan: false);
    final market = const TransferMarketEngine().processWeek(
      setup.game,
      seed: 77,
    );
    final offer = market.pendingOffersForPlayer(setup.playerId).first;
    expect(offer.type.name, 'transfer');
    expect(offer.transferFee, greaterThan(0));

    final seller = market.clubById(offer.fromClubId!)!;
    final buyer = market.clubById(offer.clubId)!;
    final completed = const DealEngine().acceptOffer(market, offer.id)!;
    final moved =
        completed.players.firstWhere((player) => player.id == setup.playerId);
    expect(moved.clubId, buyer.id);
    expect(moved.value, offer.transferFee);
    expect(moved.isTransferListed, isFalse);
    expect(completed.clubById(seller.id)!.playerIds, isNot(contains(moved.id)));
    expect(completed.clubById(buyer.id)!.playerIds, contains(moved.id));
    expect(
      completed.clubById(buyer.id)!.squadValue,
      completed
          .playersForClub(buyer.id)
          .fold<double>(0, (total, player) => total + player.value),
    );
    expect(
      completed.clubById(seller.id)!.squadValue,
      completed
          .playersForClub(seller.id)
          .fold<double>(0, (total, player) => total + player.value),
    );
    expect(completed.transfers.last.fee, offer.transferFee);
    expect(completed.transfers.last.agentFee, offer.agentFee);
    expect(
      completed.transfers.last.totalDealCost,
      offer.transferFee + offer.agentFee,
    );
    expect(
      completed.clubById(buyer.id)!.balance,
      buyer.balance - offer.transferFee - offer.agentFee,
    );
    expect(
      completed.clubById(seller.id)!.balance,
      seller.balance + offer.transferFee,
    );
    expect(completed.agent.totalAgentFeesEarned, offer.agentFee);
    expect(completed.transfers.last.type, TransferMoveType.permanent);
    expect(
      completed.contracts
          .singleWhere((item) => item.playerId == moved.id)
          .clubId,
      buyer.id,
    );

    final advanced = const GameEngine().simulateOneWeek(market).state;
    expect(advanced.offerById(offer.id)!.status.name, 'expired');
  });

  test('loan offer keeps parent contract and player returns to parent club',
      () {
    final setup = _listedClient(loan: true);
    final offers = const OfferEngine().generateOffers(
      game: setup.game,
      player: setup.game.players
          .firstWhere((player) => player.id == setup.playerId),
    );
    final offered = setup.game.copyWith(offers: offers);
    final offer = offers.first;
    expect(offer.type.name, 'loan');
    expect(offers, hasLength(1));

    final completed = const DealEngine().acceptOffer(offered, offer.id)!;
    final loaned =
        completed.players.firstWhere((player) => player.id == setup.playerId);
    final original =
        setup.game.players.firstWhere((player) => player.id == setup.playerId);
    expect(loaned.isOnLoan, isTrue);
    expect(loaned.loanParentClubId, offer.fromClubId);
    expect(loaned.clubId, offer.clubId);
    expect(loaned.value, original.value);
    expect(completed.transfers.last.type, TransferMoveType.loan);
    expect(completed.transfers.last.fee, offer.transferFee);
    expect(completed.transfers.last.agentFee, offer.agentFee);
    expect(completed.agent.totalAgentFeesEarned, offer.agentFee);
    expect(
      completed.contracts
          .singleWhere((item) => item.playerId == loaned.id)
          .clubId,
      offer.fromClubId,
    );
    final restored = GameState.fromJson(completed.toJson());
    expect(
      restored.offerById(offer.id)!.type.name,
      'loan',
    );
    expect(restored.transfers.last.type, TransferMoveType.loan);
    expect(restored.transfers.last.agentFee, offer.agentFee);
    expect(
      restored.players
          .firstWhere((player) => player.id == setup.playerId)
          .isOnLoan,
      isTrue,
    );

    final returnWeek = restored.copyWith(
      agent: restored.agent.copyWith(
        currentSeason: loaned.loanEndSeason!,
        currentWeek: loaned.loanEndWeek!,
      ),
    );
    final returned = const TransferMarketEngine().processWeek(
      returnWeek,
      seed: 78,
    );
    final playerBack =
        returned.players.firstWhere((player) => player.id == setup.playerId);
    expect(playerBack.clubId, offer.fromClubId);
    expect(playerBack.isOnLoan, isFalse);
    expect(returned.clubById(offer.fromClubId!)!.playerIds,
        contains(playerBack.id));
  });

  test('club managers can loan fringe young players during a window', () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final window = base.copyWith(
      agent: base.agent.copyWith(currentWeek: 20),
    );
    GameState? processed;
    for (var seed = 0; seed < 500 && processed == null; seed++) {
      final candidate = const TransferMarketEngine().processWeek(
        window,
        seed: seed,
      );
      if (candidate.transfers
          .any((move) => move.type == TransferMoveType.loan)) {
        processed = candidate;
      }
    }

    expect(
      processed!.transfers.where((move) => move.type == TransferMoveType.loan),
      isNotEmpty,
    );
    expect(processed.players.where((player) => player.isOnLoan), hasLength(1));
  });

  test('another permanent move within 75 weeks can reduce overall', () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    var foundDecline = false;
    for (final player in base.players.take(30)) {
      final transfer = TransferRecord(
        id: 'previous-${player.id}',
        playerId: player.id,
        fromClubId: base.clubs.first.id,
        toClubId: player.clubId!,
        fee: player.value,
        season: 1,
        week: 20,
      );
      final game = base.copyWith(
        agent: base.agent.copyWith(currentSeason: 2, currentWeek: 20),
        transfers: [transfer],
      );
      final adjusted = const PlayerMoveAdjustment().applyRapidMoveRisk(
        game,
        player,
      );
      if (adjusted.ability < player.ability) {
        foundDecline = true;
        break;
      }
    }
    expect(foundDecline, isTrue);
  });
}

({GameState game, String playerId}) _listedClient({required bool loan}) {
  const factory = GameFactory();
  final base = factory.createNewGame(
    agentName: 'Alex Morgan',
    agencyName: 'North Star Sports',
    agentAge: 34,
    createdAt: DateTime.utc(2026, 8, 24),
  );
  final player = loan
      ? base.players.firstWhere(
          (player) =>
              player.clubId != null &&
              player.age <= 23 &&
              player.potential >= player.ability + 4,
        )
      : base.playersForClub(base.clubs.first.id).first;
  final represented = player.copyWith(
    agentId: base.agent.id,
    isRecruited: true,
    isTransferListed: !loan,
    isLoanListed: loan,
  );
  final contract = Contract(
    id: 'client-contract',
    playerId: player.id,
    clubId: player.clubId!,
    salary: player.salary,
    agentFee: 0,
    contractLength: 4,
    startSeason: 1,
    endSeason: 5,
    startWeek: 1,
    salaryCommissionRate: 0.02,
  );
  return (
    game: base.copyWith(
      agent: base.agent.copyWith(currentSeason: 2, currentWeek: 20),
      players: [
        for (final candidate in base.players)
          candidate.id == player.id ? represented : candidate,
      ],
      contracts: [contract],
    ),
    playerId: player.id,
  );
}
