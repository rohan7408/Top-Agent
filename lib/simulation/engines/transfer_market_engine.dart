import 'dart:math';

import '../../domain/models/club.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/transfer_record.dart';
import '../../domain/services/season_calendar.dart';
import '../../domain/services/transfer_eligibility.dart';
import 'offer_engine.dart';

class TransferMarketEngine {
  const TransferMarketEngine({
    this.offerEngine = const OfferEngine(),
    this.seasonCalendar = const SeasonCalendar(),
    this.transferEligibility = const TransferEligibility(),
  });

  final OfferEngine offerEngine;
  final SeasonCalendar seasonCalendar;
  final TransferEligibility transferEligibility;

  GameState processWeek(GameState game, {required int seed}) {
    var working = _returnExpiredLoans(game);
    if (!seasonCalendar.isTransferWindow(working.currentWeek)) return working;

    working = _applyManagerListings(working, seed: seed);
    working = _completeManagerLoans(working, seed: seed);
    final generatedOffers = [
      for (final player in working.representedPlayers)
        if ((player.isTransferListed || player.isLoanListed) &&
            !player.isOnLoan &&
            !working
                .pendingOffersForPlayer(player.id)
                .any((offer) => offer.isMarketMove))
          ...offerEngine.generateOffers(game: working, player: player),
    ];
    if (generatedOffers.isEmpty) return working;
    return working.copyWith(offers: [...working.offers, ...generatedOffers]);
  }

  GameState _applyManagerListings(GameState game, {required int seed}) {
    final players = [...game.players];
    for (final club in game.clubs) {
      final squad = game
          .playersForClub(club.id)
          .where((player) => !player.isOnLoan)
          .toList(growable: true)
        ..sort((first, second) => first.ability.compareTo(second.ability));
      if (squad.length < 17) continue;
      final manager = game.managerForClub(club.id);
      final random =
          Random(seed ^ _stableHash('${club.id}-${game.currentWeek}'));
      final averageAppearances = squad.isEmpty
          ? 0
          : squad
                  .map((player) => game
                      .statsForPlayer(player.id)
                      .where((stats) => stats.season == game.currentSeason)
                      .fold<int>(
                          0, (total, stats) => total + stats.appearances))
                  .fold<int>(0, (first, second) => first + second) /
              squad.length;

      final loanCandidates = squad.where((player) {
        if (player.age > 21 ||
            player.potential < player.ability + 6 ||
            player.isTransferListed ||
            player.isLoanListed) {
          return false;
        }
        final appearances = game
            .statsForPlayer(player.id)
            .where((stats) => stats.season == game.currentSeason)
            .fold<int>(0, (total, stats) => total + stats.appearances);
        return appearances < max(3, averageAppearances * 0.55);
      }).toList(growable: false);
      final existingOutgoingLoans = game.players
          .where((player) => player.loanParentClubId == club.id)
          .length;
      final alreadyLoanListed = squad.any((player) => player.isLoanListed);
      if (loanCandidates.isNotEmpty &&
          existingOutgoingLoans < 2 &&
          !alreadyLoanListed &&
          random.nextInt(100) < 8 + ((manager?.rotation ?? 60) ~/ 10)) {
        final candidate = loanCandidates.first;
        final index = players.indexWhere((player) => player.id == candidate.id);
        players[index] = candidate.copyWith(
          isTransferListed: false,
          isLoanListed: true,
        );
      }

      final transferCandidates = squad.where((player) {
        if (player.isTransferListed || player.isLoanListed) return false;
        return transferEligibility.canTransferPermanently(game, player) &&
            (player.age >= 28 || player == squad.first);
      }).toList(growable: false);
      if (transferCandidates.isNotEmpty && random.nextInt(100) < 18) {
        final candidate = transferCandidates.first;
        final index = players.indexWhere((player) => player.id == candidate.id);
        players[index] = candidate.copyWith(
          isTransferListed: true,
          isLoanListed: false,
        );
      }
    }
    return game.copyWith(players: players);
  }

  GameState _returnExpiredLoans(GameState game) {
    final returningIds = game.players
        .where((player) {
          if (!player.isOnLoan ||
              player.loanEndSeason == null ||
              player.loanEndWeek == null) {
            return false;
          }
          final end = ((player.loanEndSeason! - 1) * 50) + player.loanEndWeek!;
          return game.currentAbsoluteWeek >= end;
        })
        .map((player) => player.id)
        .toSet();
    if (returningIds.isEmpty) return game;

    final players = game.players.map((player) {
      if (!returningIds.contains(player.id)) return player;
      final parentClubId = player.loanParentClubId;
      final contract = game.contracts
          .where(
            (contract) =>
                contract.playerId == player.id &&
                contract.clubId == parentClubId,
          )
          .lastOrNull;
      return player.copyWith(
        clubId: parentClubId,
        salary: contract?.salary ?? player.loanOriginalSalary ?? player.salary,
        isTransferListed: false,
        isLoanListed: false,
        clearLoanParentClubId: true,
        clearLoanEndSeason: true,
        clearLoanEndWeek: true,
        clearLoanOriginalSalary: true,
      );
    }).toList(growable: false);
    return game.copyWith(
      players: players,
      clubs: _rebuildClubSquads(game, players),
    );
  }

  GameState _completeManagerLoans(GameState game, {required int seed}) {
    if (Random(seed ^ 0x10A4).nextInt(100) >= 38) return game;
    var working = game;
    var completed = 0;
    final candidates = game.players
        .where(
          (player) =>
              player.agentId == null &&
              player.isLoanListed &&
              !player.isOnLoan &&
              player.clubId != null,
        )
        .toList(growable: true)
      ..sort((first, second) => first.age.compareTo(second.age));
    for (final candidate in candidates) {
      if (completed >= 1) break;
      final current = working.players
          .where((player) => player.id == candidate.id)
          .firstOrNull;
      if (current == null || !current.isLoanListed || current.isOnLoan) {
        continue;
      }
      final offers = offerEngine.generateOffers(game: working, player: current);
      if (offers.isEmpty) continue;
      final random = Random(seed ^ _stableHash(current.id));
      final offer = offers[random.nextInt(offers.length)];
      final parentId = current.clubId!;
      final buyer = working.clubById(offer.clubId);
      final parent = working.clubById(parentId);
      if (buyer == null || parent == null || offer.transferFee > buyer.budget) {
        continue;
      }
      final players = working.players.map((player) {
        if (player.id != current.id) return player;
        return player.copyWith(
          clubId: buyer.id,
          salary: offer.weeklySalary,
          isTransferListed: false,
          isLoanListed: false,
          loanParentClubId: parent.id,
          loanEndSeason: working.currentSeason + 1,
          loanEndWeek: 1,
          loanOriginalSalary: player.salary,
        );
      }).toList(growable: false);
      final rebuilt = _rebuildClubSquads(working, players).map((club) {
        if (club.id == parent.id) {
          return club.copyWith(
            budget: club.budget + offer.transferFee,
            balance: club.balance + offer.transferFee,
          );
        }
        if (club.id == buyer.id) {
          return club.copyWith(
            budget: club.budget - offer.transferFee,
            balance: club.balance - offer.transferFee,
          );
        }
        return club;
      }).toList(growable: false);
      final loanId =
          'ai-loan-s${working.currentSeason}-w${working.currentWeek}-${current.id}-${buyer.id}';
      working = working.copyWith(
        players: players,
        clubs: rebuilt,
        transfers: [
          ...working.transfers,
          TransferRecord(
            id: loanId,
            playerId: current.id,
            fromClubId: parent.id,
            toClubId: buyer.id,
            fee: offer.transferFee,
            season: working.currentSeason,
            week: working.currentWeek,
            type: TransferMoveType.loan,
          ),
        ],
      );
      completed++;
    }
    return working;
  }

  List<Club> _rebuildClubSquads(GameState game, List<Player> players) =>
      game.clubs.map((club) {
        final squad = players
            .where((player) => player.clubId == club.id && !player.isRetired)
            .toList(growable: false);
        return club.copyWith(
          playerIds: squad.map((player) => player.id).toList(growable: false),
          squadValue: squad.fold<double>(
            0,
            (total, player) => total + player.value,
          ),
          totalSalary: squad.fold<double>(
            0,
            (total, player) => total + player.salary,
          ),
        );
      }).toList(growable: false);

  int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7FFFFFFF;
    }
    return hash;
  }
}
