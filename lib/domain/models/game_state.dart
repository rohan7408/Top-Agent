import 'agent.dart';
import 'agency_transaction.dart';
import 'agency_office.dart';
import 'club.dart';
import 'club_manager.dart';
import 'club_offer.dart';
import 'club_season_record.dart';
import 'contract.dart';
import 'contract_event.dart';
import 'game_email.dart';
import 'league.dart';
import 'league_fixture.dart';
import 'match_result.dart';
import 'player.dart';
import 'player_match_performance.dart';
import 'player_injury.dart';
import 'player_season_stats.dart';
import 'player_training_plan.dart';
import 'scout.dart';
import 'transfer_record.dart';
import 'training_ground.dart';

class GameState {
  static const int currentSchemaVersion = 11;

  GameState({
    required this.agent,
    required this.createdAt,
    this.office = const AgencyOffice(),
    this.trainingGround = const TrainingGround(),
    this.schemaVersion = currentSchemaVersion,
    this.careerStartYear = 2025,
    List<Player> players = const [],
    List<Club> clubs = const [],
    List<League> leagues = const [],
    List<Contract> contracts = const [],
    List<Scout> scouts = const [],
    List<ClubOffer> offers = const [],
    List<MatchResult> matchResults = const [],
    List<ClubSeasonRecord> standings = const [],
    List<LeagueFixture> fixtures = const [],
    List<PlayerMatchPerformance> playerPerformances = const [],
    List<PlayerSeasonStats> playerSeasonStats = const [],
    List<ClubManager> clubManagers = const [],
    List<GameEmail> emails = const [],
    List<TransferRecord> transfers = const [],
    List<PlayerInjury> injuries = const [],
    List<ContractEvent> contractEvents = const [],
    List<PlayerTrainingPlan> trainingPlans = const [],
    List<AgencyTransaction> agencyTransactions = const [],
  })  : players = List.unmodifiable(players),
        clubs = List.unmodifiable(clubs),
        leagues = List.unmodifiable(leagues),
        contracts = List.unmodifiable(contracts),
        scouts = List.unmodifiable(scouts),
        offers = List.unmodifiable(offers),
        matchResults = List.unmodifiable(matchResults),
        standings = List.unmodifiable(standings),
        fixtures = List.unmodifiable(fixtures),
        playerPerformances = List.unmodifiable(playerPerformances),
        playerSeasonStats = List.unmodifiable(playerSeasonStats),
        clubManagers = List.unmodifiable(clubManagers),
        emails = List.unmodifiable(emails),
        transfers = List.unmodifiable(transfers),
        injuries = List.unmodifiable(injuries),
        contractEvents = List.unmodifiable(contractEvents),
        trainingPlans = List.unmodifiable(trainingPlans),
        agencyTransactions = List.unmodifiable(agencyTransactions);

  final int schemaVersion;
  final int careerStartYear;
  final DateTime createdAt;
  final Agent agent;
  final AgencyOffice office;
  final TrainingGround trainingGround;
  final List<Player> players;
  final List<Club> clubs;
  final List<League> leagues;
  final List<Contract> contracts;
  final List<Scout> scouts;
  final List<ClubOffer> offers;
  final List<MatchResult> matchResults;
  final List<ClubSeasonRecord> standings;
  final List<LeagueFixture> fixtures;
  final List<PlayerMatchPerformance> playerPerformances;
  final List<PlayerSeasonStats> playerSeasonStats;
  final List<ClubManager> clubManagers;
  final List<GameEmail> emails;
  final List<TransferRecord> transfers;
  final List<PlayerInjury> injuries;
  final List<ContractEvent> contractEvents;
  final List<PlayerTrainingPlan> trainingPlans;
  final List<AgencyTransaction> agencyTransactions;

  int get currentWeek => agent.currentWeek;
  int get currentSeason => agent.currentSeason;
  int get currentAbsoluteWeek => ((currentSeason - 1) * 50) + currentWeek;

  String seasonLabel(int season) {
    final start = careerStartYear + season - 1;
    return '$start/${start + 1}';
  }

  String injuryAvailabilityLabel(PlayerInjury injury) {
    final currentAbsoluteWeek = ((currentSeason - 1) * 50) + currentWeek - 1;
    final finalUnavailableWeek =
        currentAbsoluteWeek + injury.weeksRemaining - 1;
    final season = (finalUnavailableWeek ~/ 50) + 1;
    final week = (finalUnavailableWeek % 50) + 1;
    return season == currentSeason
        ? 'Injury till Week $week'
        : 'Injury till ${seasonLabel(season)} Week $week';
  }

  List<Player> get availableTalents => players
      .where(
        (player) =>
            player.clubId == null &&
            player.agentId == null &&
            !player.isRetired &&
            !player.isRecruited,
      )
      .toList(growable: false);

  List<Player> get representedPlayers => players
      .where((player) => player.agentId == agent.id && player.isRecruited)
      .toList(growable: false);

  List<Scout> get hiredScouts => scouts
      .where((scout) => scout.agencyId == agent.id)
      .toList(growable: false);

  bool get isAgencyAtClientCapacity =>
      representedPlayers.length >= office.clientCapacity;

  PlayerInjury? activeInjuryForPlayer(String playerId) {
    for (final injury in injuries.reversed) {
      if (injury.playerId == playerId && injury.isActive) return injury;
    }
    return null;
  }

  PlayerTrainingPlan trainingPlanForPlayer(String playerId) {
    for (final plan in trainingPlans) {
      if (plan.playerId == playerId) return plan;
    }
    return PlayerTrainingPlan(playerId: playerId);
  }

  List<ClubOffer> pendingOffersForPlayer(String playerId) => offers
      .where(
        (offer) =>
            offer.playerId == playerId &&
            offer.status == ClubOfferStatus.pending,
      )
      .toList(growable: false);

  ClubOffer? offerById(String offerId) {
    for (final offer in offers) {
      if (offer.id == offerId) return offer;
    }
    return null;
  }

  Club? clubById(String clubId) {
    for (final club in clubs) {
      if (club.id == clubId) return club;
    }
    return null;
  }

  League? leagueById(String leagueId) {
    for (final league in leagues) {
      if (league.id == leagueId) return league;
    }
    return null;
  }

  ClubManager? managerForClub(String clubId) {
    for (final manager in clubManagers) {
      if (manager.clubId == clubId) return manager;
    }
    return null;
  }

  List<TransferRecord> transfersForClub(String clubId) {
    final items = transfers
        .where((item) => item.fromClubId == clubId || item.toClubId == clubId)
        .toList(growable: true);
    items.sort((first, second) {
      final season = second.season.compareTo(first.season);
      return season != 0 ? season : second.week.compareTo(first.week);
    });
    return List.unmodifiable(items);
  }

  List<ContractEvent> contractEventsForClub(String clubId) {
    final items = contractEvents
        .where((item) => item.clubId == clubId)
        .toList(growable: true);
    items.sort((first, second) {
      final season = second.season.compareTo(first.season);
      return season != 0 ? season : second.week.compareTo(first.week);
    });
    return List.unmodifiable(items);
  }

  List<Player> playersForClub(String clubId) => players
      .where((player) => player.clubId == clubId && !player.isRetired)
      .toList(growable: false);

  ClubSeasonRecord? currentRecordForClub(String clubId) {
    for (final record in standings) {
      if (record.clubId == clubId && record.season == currentSeason) {
        return record;
      }
    }
    return null;
  }

  List<ClubSeasonRecord> get currentStandings {
    final table = standings
        .where((record) => record.season == currentSeason)
        .toList(growable: true);
    table.sort((first, second) {
      final points = second.points.compareTo(first.points);
      if (points != 0) return points;
      final goalDifference =
          second.goalDifference.compareTo(first.goalDifference);
      if (goalDifference != 0) return goalDifference;
      return second.goalsFor.compareTo(first.goalsFor);
    });
    return List.unmodifiable(table);
  }

  List<MatchResult> resultsForClub(String clubId) {
    final results = matchResults
        .where(
          (result) =>
              result.homeClubId == clubId || result.awayClubId == clubId,
        )
        .toList(growable: true);
    results.sort((first, second) {
      final season = second.season.compareTo(first.season);
      return season != 0 ? season : second.week.compareTo(first.week);
    });
    return List.unmodifiable(results);
  }

  MatchResult? matchResultById(String matchId) {
    for (final result in matchResults) {
      if (result.id == matchId) return result;
    }
    return null;
  }

  List<PlayerMatchPerformance> performancesForMatch(String matchId) =>
      playerPerformances
          .where((item) => item.matchId == matchId)
          .toList(growable: false);

  List<LeagueFixture> fixturesForWeek(int season, int week) => fixtures
      .where((fixture) => fixture.season == season && fixture.week == week)
      .toList(growable: false);

  List<PlayerSeasonStats> statsForPlayer(String playerId) {
    final stats = playerSeasonStats
        .where((item) => item.playerId == playerId)
        .toList(growable: true);
    stats.sort((first, second) => second.season.compareTo(first.season));
    return List.unmodifiable(stats);
  }

  List<PlayerMatchPerformance> performancesForPlayer(String playerId) {
    final performances = playerPerformances
        .where((item) => item.playerId == playerId)
        .toList(growable: true);
    performances.sort((first, second) {
      final season = second.season.compareTo(first.season);
      return season != 0 ? season : second.week.compareTo(first.week);
    });
    return List.unmodifiable(performances);
  }

  GameState copyWith({
    Agent? agent,
    AgencyOffice? office,
    TrainingGround? trainingGround,
    List<Player>? players,
    List<Club>? clubs,
    List<League>? leagues,
    List<Contract>? contracts,
    List<Scout>? scouts,
    List<ClubOffer>? offers,
    List<MatchResult>? matchResults,
    List<ClubSeasonRecord>? standings,
    List<LeagueFixture>? fixtures,
    List<PlayerMatchPerformance>? playerPerformances,
    List<PlayerSeasonStats>? playerSeasonStats,
    List<ClubManager>? clubManagers,
    List<GameEmail>? emails,
    List<TransferRecord>? transfers,
    List<PlayerInjury>? injuries,
    List<ContractEvent>? contractEvents,
    List<PlayerTrainingPlan>? trainingPlans,
    List<AgencyTransaction>? agencyTransactions,
  }) {
    return GameState(
      schemaVersion: schemaVersion,
      careerStartYear: careerStartYear,
      createdAt: createdAt,
      agent: agent ?? this.agent,
      office: office ?? this.office,
      trainingGround: trainingGround ?? this.trainingGround,
      players: players ?? this.players,
      clubs: clubs ?? this.clubs,
      leagues: leagues ?? this.leagues,
      contracts: contracts ?? this.contracts,
      scouts: scouts ?? this.scouts,
      offers: offers ?? this.offers,
      matchResults: matchResults ?? this.matchResults,
      standings: standings ?? this.standings,
      fixtures: fixtures ?? this.fixtures,
      playerPerformances: playerPerformances ?? this.playerPerformances,
      playerSeasonStats: playerSeasonStats ?? this.playerSeasonStats,
      clubManagers: clubManagers ?? this.clubManagers,
      emails: emails ?? this.emails,
      transfers: transfers ?? this.transfers,
      injuries: injuries ?? this.injuries,
      contractEvents: contractEvents ?? this.contractEvents,
      trainingPlans: trainingPlans ?? this.trainingPlans,
      agencyTransactions: agencyTransactions ?? this.agencyTransactions,
    );
  }

  Map<String, Object> toJson() => {
        'schemaVersion': schemaVersion,
        'careerStartYear': careerStartYear,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'agent': agent.toJson(),
        'office': office.toJson(),
        'trainingGround': trainingGround.toJson(),
        'players': players.map((player) => player.toJson()).toList(),
        'clubs': clubs.map((club) => club.toJson()).toList(),
        'leagues': leagues.map((league) => league.toJson()).toList(),
        'contracts': contracts.map((contract) => contract.toJson()).toList(),
        'scouts': scouts.map((scout) => scout.toJson()).toList(),
        'offers': offers.map((offer) => offer.toJson()).toList(),
        'matchResults': matchResults.map((result) => result.toJson()).toList(),
        'standings': standings.map((record) => record.toJson()).toList(),
        'fixtures': fixtures.map((fixture) => fixture.toJson()).toList(),
        'playerPerformances':
            playerPerformances.map((item) => item.toJson()).toList(),
        'playerSeasonStats':
            playerSeasonStats.map((item) => item.toJson()).toList(),
        'clubManagers': clubManagers.map((item) => item.toJson()).toList(),
        'emails': emails.map((item) => item.toJson()).toList(),
        'transfers': transfers.map((item) => item.toJson()).toList(),
        'injuries': injuries.map((item) => item.toJson()).toList(),
        'contractEvents': contractEvents.map((item) => item.toJson()).toList(),
        'trainingPlans': trainingPlans.map((item) => item.toJson()).toList(),
        'agencyTransactions':
            agencyTransactions.map((item) => item.toJson()).toList(),
      };

  factory GameState.fromJson(Map<String, Object?> json) {
    return GameState(
      schemaVersion: currentSchemaVersion,
      careerStartYear: (json['careerStartYear'] as int?) ?? 2025,
      createdAt: DateTime.parse(json['createdAt']! as String),
      agent: Agent.fromJson((json['agent']! as Map).cast<String, Object?>()),
      office: _officeFromJson(json),
      trainingGround: _trainingGroundFromJson(json),
      players: (json['players']! as List<Object?>)
          .map(
              (item) => Player.fromJson((item! as Map).cast<String, Object?>()))
          .toList(),
      clubs: (json['clubs']! as List<Object?>)
          .map((item) => Club.fromJson((item! as Map).cast<String, Object?>()))
          .toList(),
      leagues: (json['leagues']! as List<Object?>)
          .map(
              (item) => League.fromJson((item! as Map).cast<String, Object?>()))
          .toList(),
      contracts: _contractsFromJson(json),
      scouts: _scoutsFromJson(json),
      offers: ((json['offers'] as List<Object?>?) ?? const [])
          .map((item) =>
              ClubOffer.fromJson((item! as Map).cast<String, Object?>()))
          .toList(),
      matchResults: ((json['matchResults'] as List<Object?>?) ?? const [])
          .map((item) =>
              MatchResult.fromJson((item! as Map).cast<String, Object?>()))
          .toList(),
      standings: ((json['standings'] as List<Object?>?) ?? const [])
          .map((item) => ClubSeasonRecord.fromJson(
                (item! as Map).cast<String, Object?>(),
              ))
          .toList(),
      fixtures: ((json['fixtures'] as List<Object?>?) ?? const [])
          .map((item) =>
              LeagueFixture.fromJson((item! as Map).cast<String, Object?>()))
          .toList(),
      playerPerformances:
          ((json['playerPerformances'] as List<Object?>?) ?? const [])
              .map((item) => PlayerMatchPerformance.fromJson(
                    (item! as Map).cast<String, Object?>(),
                  ))
              .toList(),
      playerSeasonStats:
          ((json['playerSeasonStats'] as List<Object?>?) ?? const [])
              .map((item) => PlayerSeasonStats.fromJson(
                    (item! as Map).cast<String, Object?>(),
                  ))
              .toList(),
      clubManagers: ((json['clubManagers'] as List<Object?>?) ?? const [])
          .map((item) => ClubManager.fromJson(
                (item! as Map).cast<String, Object?>(),
              ))
          .toList(),
      emails: ((json['emails'] as List<Object?>?) ?? const [])
          .map((item) =>
              GameEmail.fromJson((item! as Map).cast<String, Object?>()))
          .toList(),
      transfers: ((json['transfers'] as List<Object?>?) ?? const [])
          .map((item) => TransferRecord.fromJson(
                (item! as Map).cast<String, Object?>(),
              ))
          .toList(),
      injuries: ((json['injuries'] as List<Object?>?) ?? const [])
          .map((item) => PlayerInjury.fromJson(
                (item! as Map).cast<String, Object?>(),
              ))
          .toList(),
      contractEvents: ((json['contractEvents'] as List<Object?>?) ?? const [])
          .map((item) => ContractEvent.fromJson(
                (item! as Map).cast<String, Object?>(),
              ))
          .toList(),
      trainingPlans: ((json['trainingPlans'] as List<Object?>?) ?? const [])
          .map((item) => PlayerTrainingPlan.fromJson(
                (item! as Map).cast<String, Object?>(),
              ))
          .toList(),
      agencyTransactions:
          ((json['agencyTransactions'] as List<Object?>?) ?? const [])
              .map((item) => AgencyTransaction.fromJson(
                    (item! as Map).cast<String, Object?>(),
                  ))
              .toList(),
    );
  }

  static TrainingGround _trainingGroundFromJson(Map<String, Object?> json) {
    if (json['trainingGround'] != null) {
      return TrainingGround.fromJson(
        (json['trainingGround']! as Map).cast<String, Object?>(),
      );
    }
    final agentJson = (json['agent']! as Map).cast<String, Object?>();
    final season = (agentJson['currentSeason'] as int?) ?? 1;
    final week = (agentJson['currentWeek'] as int?) ?? 1;
    return TrainingGround(
      lastIntakeAbsoluteWeek: ((season - 1) * 50) + week,
    );
  }

  static List<Scout> _scoutsFromJson(Map<String, Object?> json) {
    final current = json['scouts'] as List<Object?>?;
    if (current != null) {
      return current
          .map((item) => Scout.fromJson((item! as Map).cast<String, Object?>()))
          .toList(growable: false);
    }
    return ((json['staff'] as List<Object?>?) ?? const [])
        .map((item) => Scout.fromLegacyStaffJson(
              (item! as Map).cast<String, Object?>(),
            ))
        .whereType<Scout>()
        .toList(growable: false);
  }

  static List<Contract> _contractsFromJson(Map<String, Object?> json) {
    final migratedRate = _officeFromJson(json).salaryCommissionRate;
    return ((json['contracts'] as List<Object?>?) ?? const []).map((item) {
      final contractJson = (item! as Map).cast<String, Object?>();
      final contract = Contract.fromJson(contractJson);
      if (contractJson.containsKey('salaryCommissionRate') ||
          contract.agentFee <= 0) {
        return contract;
      }
      return Contract(
        id: contract.id,
        playerId: contract.playerId,
        clubId: contract.clubId,
        salary: contract.salary,
        agentFee: contract.agentFee,
        contractLength: contract.contractLength,
        startSeason: contract.startSeason,
        endSeason: contract.endSeason,
        salaryCommissionRate: migratedRate,
      );
    }).toList(growable: false);
  }

  static AgencyOffice _officeFromJson(Map<String, Object?> json) {
    final agentJson = (json['agent']! as Map).cast<String, Object?>();
    final agentId = agentJson['id']! as String;
    final clientCount =
        ((json['players'] as List<Object?>?) ?? const []).where((item) {
      final player = (item! as Map).cast<String, Object?>();
      return player['agentId'] == agentId &&
          ((player['isRecruited'] as bool?) ?? false);
    }).length;
    final scouts = _scoutsFromJson(json);
    final hiredScoutCount =
        scouts.where((scout) => scout.agencyId == agentId).length;
    final storedOffice = json['office'] == null
        ? const AgencyOffice()
        : AgencyOffice.fromJson(
            (json['office']! as Map).cast<String, Object?>(),
          );
    return AgencyOffice.supporting(
      clientCount: clientCount,
      scoutCount: hiredScoutCount,
      preferredLevel: storedOffice.level,
    );
  }
}
