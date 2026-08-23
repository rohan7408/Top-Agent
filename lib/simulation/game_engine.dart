import '../domain/models/club_offer.dart';
import '../domain/models/club_season_record.dart';
import '../domain/models/game_state.dart';
import '../domain/models/game_email.dart';
import '../domain/models/match_result.dart';
import '../domain/models/player_match_performance.dart';
import '../domain/models/player_injury.dart';
import '../domain/models/player_season_stats.dart';
import 'engines/fixture_calendar_engine.dart';
import 'engines/fatigue_engine.dart';
import 'engines/club_management_engine.dart';
import 'engines/match_engine.dart';
import 'engines/player_lifecycle_engine.dart';
import 'engines/weekly_injury_engine.dart';
import 'engines/agency_office_engine.dart';
import 'engines/training_engine.dart';
import 'engines/training_ground_engine.dart';

enum SeasonPhase {
  playWeeks,
  midTransferWindow,
  mainTransferWindow,
}

extension SeasonPhaseLabel on SeasonPhase {
  String get label => switch (this) {
        SeasonPhase.playWeeks => 'Play week',
        SeasonPhase.midTransferWindow => 'Mid transfer window',
        SeasonPhase.mainTransferWindow => 'Main transfer window',
      };
}

class WeekSimulationSummary {
  const WeekSimulationSummary({
    required this.simulatedWeek,
    required this.simulatedSeason,
    required this.nextWeek,
    required this.nextSeason,
    required this.matchesPlayed,
    required this.phase,
    required this.transfersCompleted,
    required this.contractsRenewed,
    required this.injuriesThisWeek,
    required this.playersImproved,
    required this.playersDeclined,
    required this.playersRetired,
    required this.contractsExpired,
    required this.scoutPayroll,
    required this.salaryCommission,
    required this.talentsDiscovered,
    required this.trainingGroundTalents,
    required this.trainingImprovements,
  });

  final int simulatedWeek;
  final int simulatedSeason;
  final int nextWeek;
  final int nextSeason;
  final int matchesPlayed;
  final SeasonPhase phase;
  final int transfersCompleted;
  final int contractsRenewed;
  final int injuriesThisWeek;
  final int playersImproved;
  final int playersDeclined;
  final int playersRetired;
  final int contractsExpired;
  final double scoutPayroll;
  final double salaryCommission;
  final int talentsDiscovered;
  final int trainingGroundTalents;
  final int trainingImprovements;
}

class GameEngineResult {
  const GameEngineResult({required this.state, required this.summary});

  final GameState state;
  final WeekSimulationSummary summary;
}

class GameEngine {
  const GameEngine({
    this.matchEngine = const MatchEngine(),
    this.fixtureCalendarEngine = const FixtureCalendarEngine(),
    this.clubManagementEngine = const ClubManagementEngine(),
    this.playerLifecycleEngine = const PlayerLifecycleEngine(),
    this.fatigueEngine = const FatigueEngine(),
    this.weeklyInjuryEngine = const WeeklyInjuryEngine(),
    this.agencyOfficeEngine = const AgencyOfficeEngine(),
    this.trainingEngine = const TrainingEngine(),
    this.trainingGroundEngine = const TrainingGroundEngine(),
  });

  final MatchEngine matchEngine;
  final FixtureCalendarEngine fixtureCalendarEngine;
  final ClubManagementEngine clubManagementEngine;
  final PlayerLifecycleEngine playerLifecycleEngine;
  final FatigueEngine fatigueEngine;
  final WeeklyInjuryEngine weeklyInjuryEngine;
  final AgencyOfficeEngine agencyOfficeEngine;
  final TrainingEngine trainingEngine;
  final TrainingGroundEngine trainingGroundEngine;

  GameEngineResult simulateOneWeek(GameState game) {
    final simulatedWeek = game.currentWeek;
    final simulatedSeason = game.currentSeason;
    final phase = phaseForWeek(simulatedWeek);
    final scheduledFixtures = game.fixturesForWeek(
      simulatedSeason,
      simulatedWeek,
    );
    final recoveredGame = fatigueEngine.recoverBeforeWeek(game);
    final batch = matchEngine.simulateFixtures(
      game: recoveredGame,
      fixtures: scheduledFixtures,
      seed: _simulationSeed(game),
    );
    final newResults = batch.results;
    final newPerformances = batch.performances;
    final updatedStandings = _applyResults(game, newResults);
    final updatedPlayerStats = _applyPerformances(game, newPerformances);
    final gameAfterMatchLoad =
        fatigueEngine.applyMatchLoad(recoveredGame, newPerformances);
    final incidentalInjuries = weeklyInjuryEngine.createIncidentalInjuries(
      game: gameAfterMatchLoad,
      excludedPlayerIds:
          batch.injuries.map((injury) => injury.playerId).toSet(),
      seed: _simulationSeed(game),
    );
    final newInjuries = [...batch.injuries, ...incidentalInjuries];
    final injuryEmails = _injuryEmails(gameAfterMatchLoad, newInjuries);
    final worldAfterMatches = gameAfterMatchLoad.copyWith(
      matchResults: [...game.matchResults, ...newResults],
      standings: updatedStandings,
      playerPerformances: [...game.playerPerformances, ...newPerformances],
      playerSeasonStats: updatedPlayerStats,
      injuries: [
        ...game.injuries.map((injury) => injury.advanceWeek()),
        ...newInjuries,
      ],
      emails: [...injuryEmails, ...game.emails],
    );
    final clubManagement = clubManagementEngine.processWeek(
      worldAfterMatches,
      seed: _simulationSeed(game),
    );

    final isNewSeason = simulatedWeek >= 50;
    final nextWeek = isNewSeason ? 1 : simulatedWeek + 1;
    final nextSeason = isNewSeason ? simulatedSeason + 1 : simulatedSeason;
    final standingsWithNextSeason = isNewSeason
        ? [
            ...updatedStandings,
            ...game.clubs.map(
              (club) => ClubSeasonRecord(
                clubId: club.id,
                season: nextSeason,
              ),
            ),
          ]
        : updatedStandings;
    final fixturesWithNextSeason = isNewSeason
        ? [
            ...game.fixtures,
            ...game.leagues.expand(
              (league) => fixtureCalendarEngine.createSeasonFixtures(
                league: league,
                season: nextSeason,
              ),
            ),
          ]
        : game.fixtures;
    final updatedOffers = _expireOldOffers(
      game.offers,
      nextWeek: nextWeek,
      nextSeason: nextSeason,
    );

    final financiallySettledState = isNewSeason
        ? _awardSeasonPrizeMoney(clubManagement.state)
        : clubManagement.state;

    final lifecycle = isNewSeason
        ? playerLifecycleEngine.processSeasonEnd(
            financiallySettledState,
            nextSeason: nextSeason,
            seed: _simulationSeed(game),
          )
        : PlayerLifecycleResult(
            state: financiallySettledState,
            playersImproved: 0,
            playersDeclined: 0,
            playersRetired: 0,
            contractsExpired: 0,
          );

    final officeWeek = agencyOfficeEngine.processWeek(
      lifecycle.state,
      nextSeason: nextSeason,
      nextWeek: nextWeek,
      seed: _simulationSeed(game),
    );

    final trainingGroundWeek = trainingGroundEngine.processWeek(
      officeWeek.state,
      nextSeason: nextSeason,
      nextWeek: nextWeek,
      seed: _simulationSeed(game),
    );

    final trainingWeek = trainingEngine.processWeek(
      trainingGroundWeek.state,
      nextSeason: nextSeason,
      nextWeek: nextWeek,
    );

    final updatedState = trainingWeek.state.copyWith(
      agent: trainingWeek.state.agent.copyWith(
        currentWeek: nextWeek,
        currentSeason: nextSeason,
      ),
      offers: updatedOffers,
      standings: standingsWithNextSeason,
      fixtures: fixturesWithNextSeason,
    );

    return GameEngineResult(
      state: updatedState,
      summary: WeekSimulationSummary(
        simulatedWeek: simulatedWeek,
        simulatedSeason: simulatedSeason,
        nextWeek: nextWeek,
        nextSeason: nextSeason,
        matchesPlayed: newResults.length,
        phase: phase,
        transfersCompleted: clubManagement.transfersCompleted,
        contractsRenewed: clubManagement.contractsRenewed,
        injuriesThisWeek: newInjuries.length,
        playersImproved: lifecycle.playersImproved,
        playersDeclined: lifecycle.playersDeclined,
        playersRetired: lifecycle.playersRetired,
        contractsExpired: lifecycle.contractsExpired,
        scoutPayroll: officeWeek.scoutPayroll,
        salaryCommission: officeWeek.salaryCommission,
        talentsDiscovered: officeWeek.talentsDiscovered,
        trainingGroundTalents: trainingGroundWeek.talentsDeveloped,
        trainingImprovements: trainingWeek.attributesImproved,
      ),
    );
  }

  List<GameEmail> _injuryEmails(
    GameState game,
    List<PlayerInjury> injuries,
  ) {
    final emails = <GameEmail>[];
    for (final injury in injuries) {
      final player =
          game.players.where((item) => item.id == injury.playerId).firstOrNull;
      if (player == null || player.agentId != game.agent.id) {
        continue;
      }
      emails.add(
        GameEmail(
          id: 'email-${injury.id}',
          type: GameEmailType.world,
          subject: '${player.name} suffers injury',
          body:
              '${player.name} sustained a ${injury.name.toLowerCase()} and is expected to miss ${injury.totalWeeks} week${injury.totalWeeks == 1 ? '' : 's'}.',
          season: game.currentSeason,
          week: game.currentWeek,
          playerId: player.id,
          clubId: player.clubId,
        ),
      );
    }
    return emails;
  }

  SeasonPhase phaseForWeek(int week) {
    if (week >= 40) return SeasonPhase.mainTransferWindow;
    if (week >= 20 && week < 25) return SeasonPhase.midTransferWindow;
    return SeasonPhase.playWeeks;
  }

  int _simulationSeed(GameState game) {
    return ((game.currentSeason * 100000) +
            (game.currentWeek * 100) +
            (game.createdAt.millisecondsSinceEpoch & 0xFFFF)) &
        0x7FFFFFFF;
  }

  List<ClubSeasonRecord> _applyResults(
    GameState game,
    List<MatchResult> results,
  ) {
    final currentRecords = {
      for (final club in game.clubs)
        club.id: game.currentRecordForClub(club.id) ??
            ClubSeasonRecord(clubId: club.id, season: game.currentSeason),
    };

    for (final result in results) {
      currentRecords[result.homeClubId] =
          currentRecords[result.homeClubId]!.applyResult(result);
      currentRecords[result.awayClubId] =
          currentRecords[result.awayClubId]!.applyResult(result);
    }

    return [
      ...game.standings.where(
        (record) => record.season != game.currentSeason,
      ),
      ...game.clubs.map((club) => currentRecords[club.id]!),
    ];
  }

  List<PlayerSeasonStats> _applyPerformances(
    GameState game,
    List<PlayerMatchPerformance> performances,
  ) {
    final statsByKey = {
      for (final stats in game.playerSeasonStats)
        _statsKey(
          stats.playerId,
          stats.clubId,
          stats.leagueId,
          stats.season,
        ): stats,
    };

    for (final performance in performances) {
      final key = _statsKey(
        performance.playerId,
        performance.clubId,
        performance.leagueId,
        performance.season,
      );
      final current = statsByKey[key] ??
          PlayerSeasonStats(
            playerId: performance.playerId,
            clubId: performance.clubId,
            leagueId: performance.leagueId,
            season: performance.season,
          );
      statsByKey[key] = current.applyPerformance(performance);
    }
    return List.unmodifiable(statsByKey.values);
  }

  String _statsKey(
    String playerId,
    String clubId,
    String leagueId,
    int season,
  ) =>
      '$playerId|$clubId|$leagueId|$season';

  List<ClubOffer> _expireOldOffers(
    List<ClubOffer> offers, {
    required int nextWeek,
    required int nextSeason,
  }) {
    final nextAbsoluteWeek = ((nextSeason - 1) * 50) + nextWeek;
    return offers.map((offer) {
      if (offer.status != ClubOfferStatus.pending) return offer;
      final createdAbsoluteWeek =
          ((offer.createdSeason - 1) * 50) + offer.createdWeek;
      return nextAbsoluteWeek - createdAbsoluteWeek >= 2
          ? offer.copyWith(status: ClubOfferStatus.expired)
          : offer;
    }).toList(growable: false);
  }

  GameState _awardSeasonPrizeMoney(GameState game) {
    final clubs = [...game.clubs];
    for (final league in game.leagues) {
      final table = game.standings
          .where(
            (record) =>
                record.season == game.currentSeason &&
                league.clubIds.contains(record.clubId),
          )
          .toList(growable: true)
        ..sort((first, second) {
          final points = second.points.compareTo(first.points);
          if (points != 0) return points;
          final difference =
              second.goalDifference.compareTo(first.goalDifference);
          if (difference != 0) return difference;
          return second.goalsFor.compareTo(first.goalsFor);
        });

      for (var position = 0; position < table.length; position++) {
        final prize = league.prizeMoneyForPosition(position + 1);
        if (prize <= 0) continue;
        final clubIndex =
            clubs.indexWhere((club) => club.id == table[position].clubId);
        if (clubIndex < 0) continue;
        final club = clubs[clubIndex];
        clubs[clubIndex] = club.copyWith(
          balance: club.balance + prize,
          budget: club.budget + (prize * 0.55),
        );
      }
    }
    return game.copyWith(clubs: clubs);
  }
}
