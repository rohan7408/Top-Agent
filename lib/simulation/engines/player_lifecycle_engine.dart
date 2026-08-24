import 'dart:math';

import '../../domain/models/game_email.dart';
import '../../domain/models/contract_event.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_season_stats.dart';
import '../../domain/services/game_balance.dart';

class PlayerLifecycleResult {
  const PlayerLifecycleResult({
    required this.state,
    required this.playersImproved,
    required this.playersDeclined,
    required this.playersRetired,
    required this.contractsExpired,
  });

  final GameState state;
  final int playersImproved;
  final int playersDeclined;
  final int playersRetired;
  final int contractsExpired;
}

class PlayerLifecycleEngine {
  const PlayerLifecycleEngine({this.balance = const GameBalance()});

  final GameBalance balance;

  PlayerLifecycleResult processSeasonEnd(
    GameState game, {
    required int nextSeason,
    required int seed,
  }) {
    final random = Random(seed ^ 0x53454153);
    final updatedPlayers = <Player>[];
    final emails = [...game.emails];
    final contractEvents = [...game.contractEvents];
    var improved = 0;
    var declined = 0;
    var retired = 0;
    var contractsExpired = 0;
    final championClubIds = _championClubIds(game);

    for (final player in game.players) {
      if (player.isRetired) {
        updatedPlayers.add(player);
        continue;
      }
      final oldAbility = player.ability;
      final stats = game.playerSeasonStats.where(
        (item) =>
            item.playerId == player.id && item.season == game.currentSeason,
      );
      final season = _SeasonPerformance.from(stats);
      final performanceDelta = _performanceDelta(
        player,
        season,
        wonLeague: player.clubId != null &&
            championClubIds.contains(player.clubId) &&
            season.appearances >= 15,
      );
      final newAge = player.age + 1;
      final technicalDelta = _technicalAgeDelta(newAge) + performanceDelta;
      final mentalDelta = _mentalAgeDelta(newAge) + performanceDelta;
      final physicalDelta = _physicalAgeDelta(newAge) +
          (performanceDelta > 0 ? 1 : performanceDelta);
      final attributes = player.attributes.evolve(
        technicalDelta: technicalDelta.clamp(-3, 3),
        mentalDelta: mentalDelta.clamp(-2, 3),
        physicalDelta: physicalDelta.clamp(-4, 3),
      );
      final evolvedAbility =
          Player.calculateOverall(player.position, attributes);
      var potential = player.potential +
          _potentialDelta(
            age: newAge,
            performanceDelta: performanceDelta,
            appearances: season.appearances,
          );
      potential = potential.clamp(evolvedAbility, 99);
      final shouldRetire = _shouldRetire(player, newAge, random);
      final owningClubId = player.loanParentClubId ?? player.clubId;
      final contractExpired = !shouldRetire &&
          owningClubId != null &&
          (player.contractEndSeason ?? 999) <= game.currentSeason;
      final leavesClub = shouldRetire || contractExpired;
      final value = shouldRetire
          ? 0.0
          : balance.playerMarketValue(
              ability: evolvedAbility,
              potential: potential,
              age: newAge,
              position: player.position,
            );

      final updated = player.copyWith(
        age: newAge,
        attributes: attributes,
        potential: potential,
        value: value,
        clearClubId: leavesClub,
        isTransferListed: leavesClub ? false : player.isTransferListed,
        isLoanListed: leavesClub ? false : player.isLoanListed,
        salary: leavesClub ? 0 : player.salary,
        clearContractEndSeason: leavesClub,
        clearLoanParentClubId: leavesClub,
        clearLoanEndSeason: leavesClub,
        clearLoanEndWeek: leavesClub,
        clearLoanOriginalSalary: leavesClub,
        isRetired: shouldRetire,
        retirementSeason: shouldRetire ? nextSeason : null,
        fatigue: leavesClub ? 0 : player.fatigue,
        consecutiveStarts: leavesClub ? 0 : player.consecutiveStarts,
      );
      updatedPlayers.add(updated);

      if (updated.ability > oldAbility) improved++;
      if (updated.ability < oldAbility) declined++;
      if (shouldRetire) {
        retired++;
        if (player.agentId == game.agent.id) {
          emails.insert(
            0,
            GameEmail(
              id: 'email-retirement-s$nextSeason-${player.id}',
              type: GameEmailType.world,
              subject: '${player.name} retires',
              body:
                  '${player.name} has retired from professional football at age $newAge.',
              season: nextSeason,
              week: 1,
              playerId: player.id,
              clubId: player.clubId,
            ),
          );
        }
      } else if (contractExpired) {
        contractsExpired++;
        final eventId = 'contract-expired-s${game.currentSeason}-${player.id}';
        contractEvents.add(
          ContractEvent(
            id: eventId,
            type: ContractEventType.expired,
            playerId: player.id,
            clubId: owningClubId,
            season: game.currentSeason,
            week: 50,
            weeklySalary: player.salary,
            previousSalary: player.salary,
            endSeason: game.currentSeason,
          ),
        );
        if (player.agentId == game.agent.id) {
          final clubName = game.clubById(owningClubId)?.name ?? 'the club';
          emails.insert(
            0,
            GameEmail(
              id: 'email-$eventId',
              type: GameEmailType.contract,
              subject: '${player.name} leaves $clubName',
              body:
                  '${player.name}\'s contract expired and he is now a free agent.',
              season: nextSeason,
              week: 1,
              playerId: player.id,
              clubId: owningClubId,
            ),
          );
        }
      } else if (player.agentId == game.agent.id &&
          (updated.ability != oldAbility || potential != player.potential)) {
        emails.insert(
          0,
          GameEmail(
            id: 'email-development-s$nextSeason-${player.id}',
            type: GameEmailType.world,
            subject: '${player.name}: season development',
            body:
                'Overall $oldAbility → ${updated.ability}; potential ${player.potential} → $potential. Age is now $newAge.',
            season: nextSeason,
            week: 1,
            playerId: player.id,
            clubId: player.clubId,
          ),
        );
      }
    }

    final clubs = game.clubs.map((club) {
      final squad = updatedPlayers
          .where((player) => player.clubId == club.id && !player.isRetired)
          .toList(growable: false);
      return club.copyWith(
        playerIds: squad.map((player) => player.id).toList(growable: false),
        squadValue: squad.fold<double>(0, (sum, player) => sum + player.value),
        totalSalary:
            squad.fold<double>(0, (sum, player) => sum + player.salary),
      );
    }).toList(growable: false);
    final playersBeforeDevelopment = {
      for (final player in game.players) player.id: player,
    };
    final finalizedSeasonStats = game.playerSeasonStats.map((stats) {
      if (stats.season != game.currentSeason) return stats;
      final player = playersBeforeDevelopment[stats.playerId];
      if (player == null) return stats;
      return stats.withSnapshot(
        overall: player.ability,
        marketValue: player.value,
      );
    }).toList(growable: false);

    return PlayerLifecycleResult(
      state: game.copyWith(
        players: updatedPlayers,
        playerSeasonStats: finalizedSeasonStats,
        clubs: clubs,
        contracts: game.contracts.where((contract) {
          final player = updatedPlayers
              .firstWhere((player) => player.id == contract.playerId);
          return !player.isRetired &&
              (player.loanParentClubId ?? player.clubId) == contract.clubId;
        }).toList(growable: false),
        emails: emails,
        contractEvents: contractEvents,
      ),
      playersImproved: improved,
      playersDeclined: declined,
      playersRetired: retired,
      contractsExpired: contractsExpired,
    );
  }

  int _performanceDelta(
    Player player,
    _SeasonPerformance stats, {
    required bool wonLeague,
  }) {
    if (stats.appearances < 5) return player.age <= 22 ? 0 : -1;
    var score = 0;
    if (stats.averageRating >= 7.25) {
      score += 2;
    } else if (stats.averageRating >= 6.85) {
      score += 1;
    } else if (stats.averageRating < 6.2) {
      score -= 1;
    }
    final achievementTarget = switch (player.position) {
      PlayerPosition.goalkeeper => stats.cleanSheets >= 10,
      PlayerPosition.defender => stats.cleanSheets >= 10,
      PlayerPosition.midfielder => stats.goals + stats.assists >= 12,
      PlayerPosition.forward => stats.goals + stats.assists >= 15,
    };
    if (achievementTarget || stats.playerOfTheMatchAwards >= 4) score++;
    if (wonLeague) score++;
    return score.clamp(-1, 3);
  }

  Set<String> _championClubIds(GameState game) {
    final champions = <String>{};
    for (final league in game.leagues) {
      final records = game.standings
          .where((record) =>
              record.season == game.currentSeason &&
              league.clubIds.contains(record.clubId))
          .toList(growable: true)
        ..sort((first, second) {
          final points = second.points.compareTo(first.points);
          if (points != 0) return points;
          final goalDifference =
              second.goalDifference.compareTo(first.goalDifference);
          if (goalDifference != 0) return goalDifference;
          return second.goalsFor.compareTo(first.goalsFor);
        });
      if (records.isNotEmpty && records.first.played > 0) {
        champions.add(records.first.clubId);
      }
    }
    return champions;
  }

  int _technicalAgeDelta(int age) {
    if (age <= 22) return 1;
    if (age >= 35) return -1;
    return 0;
  }

  int _mentalAgeDelta(int age) {
    if (age <= 24) return 1;
    if (age <= 31) return 0;
    if (age >= 38) return -1;
    return 0;
  }

  int _physicalAgeDelta(int age) {
    if (age <= 21) return 1;
    if (age <= 29) return 0;
    if (age <= 32) return -1;
    if (age <= 35) return -2;
    return -3;
  }

  int _potentialDelta({
    required int age,
    required int performanceDelta,
    required int appearances,
  }) {
    if (age <= 22 && performanceDelta >= 2 && appearances >= 15) return 2;
    if (age <= 24 && performanceDelta > 0) return 1;
    if (performanceDelta < 0) return -1;
    if (age >= 33) return -2;
    if (age >= 29) return -1;
    return 0;
  }

  bool _shouldRetire(Player player, int newAge, Random random) {
    final goalkeeperBonus =
        player.position == PlayerPosition.goalkeeper ? 2 : 0;
    final firstPossibleAge = 35 + goalkeeperBonus;
    final guaranteedAge = 42 + goalkeeperBonus;
    if (newAge >= guaranteedAge) return true;
    if (newAge < firstPossibleAge) return false;
    final chance = 0.10 + ((newAge - firstPossibleAge) * 0.14);
    return random.nextDouble() < chance.clamp(0.10, 0.85);
  }
}

class _SeasonPerformance {
  const _SeasonPerformance({
    required this.appearances,
    required this.goals,
    required this.assists,
    required this.cleanSheets,
    required this.playerOfTheMatchAwards,
    required this.totalRating,
  });

  factory _SeasonPerformance.from(Iterable<PlayerSeasonStats> items) {
    return _SeasonPerformance(
      appearances: items.fold(0, (sum, item) => sum + item.appearances),
      goals: items.fold(0, (sum, item) => sum + item.goals),
      assists: items.fold(0, (sum, item) => sum + item.assists),
      cleanSheets: items.fold(0, (sum, item) => sum + item.cleanSheets),
      playerOfTheMatchAwards:
          items.fold(0, (sum, item) => sum + item.playerOfTheMatchAwards),
      totalRating: items.fold(0, (sum, item) => sum + item.totalRating),
    );
  }

  final int appearances;
  final int goals;
  final int assists;
  final int cleanSheets;
  final int playerOfTheMatchAwards;
  final double totalRating;

  double get averageRating => appearances == 0 ? 0 : totalRating / appearances;
}
