import '../models/agent.dart';
import '../models/agency_office.dart';
import '../models/club_season_record.dart';
import '../models/game_state.dart';
import '../models/training_ground.dart';
import '../../simulation/engines/fixture_calendar_engine.dart';
import 'football_world_factory.dart';
import 'talent_generator.dart';
import 'scout_candidate_generator.dart';

class GameFactory {
  const GameFactory({
    this.footballWorldFactory = const FootballWorldFactory(),
    this.talentGenerator = const TalentGenerator(),
    this.fixtureCalendarEngine = const FixtureCalendarEngine(),
    this.scoutCandidateGenerator = const ScoutCandidateGenerator(),
  });

  final FootballWorldFactory footballWorldFactory;
  final TalentGenerator talentGenerator;
  final FixtureCalendarEngine fixtureCalendarEngine;
  final ScoutCandidateGenerator scoutCandidateGenerator;

  static const double startingMoney = 10000;
  static const int startingReputation = 1;
  static const int startingWeek = 1;
  static const int startingSeason = 1;

  GameState createNewGame({
    required String agentName,
    required String agencyName,
    required int agentAge,
    DateTime? createdAt,
  }) {
    final timestamp = (createdAt ?? DateTime.now()).toUtc();
    final agent = Agent(
      id: 'agent-${timestamp.microsecondsSinceEpoch}',
      name: agentName.trim(),
      agencyName: agencyName.trim(),
      age: agentAge,
      money: startingMoney,
      reputation: startingReputation,
      currentWeek: startingWeek,
      currentSeason: startingSeason,
    );

    final seed = timestamp.microsecondsSinceEpoch & 0x7FFFFFFF;
    final world = footballWorldFactory.createPremierLeague(seed: seed);
    const trainingGround = TrainingGround();
    final startingTalents = talentGenerator.generateForTrainingGround(
      count: 2,
      minimumAbility: trainingGround.minimumAbility,
      maximumAbility: trainingGround.maximumAbility,
      seed: seed ^ 0x5F3759DF,
      idPrefix: 'talent-${timestamp.microsecondsSinceEpoch}',
    );
    final scoutCandidates = scoutCandidateGenerator.generateInitial(
      reputation: agent.reputation,
      seed: seed ^ 0x57AFF,
      idPrefix: 'scout-${timestamp.microsecondsSinceEpoch}',
      officeLevel: 1,
    );
    final fixtures = world.leagues
        .expand(
          (league) => fixtureCalendarEngine.createSeasonFixtures(
            league: league,
            season: startingSeason,
          ),
        )
        .toList(growable: false);

    return GameState(
      agent: agent,
      office: const AgencyOffice(),
      trainingGround: trainingGround,
      createdAt: timestamp,
      players: [...world.players, ...startingTalents],
      clubs: world.clubs,
      leagues: world.leagues,
      standings: world.clubs
          .map(
            (club) => ClubSeasonRecord(
              clubId: club.id,
              season: startingSeason,
            ),
          )
          .toList(growable: false),
      fixtures: fixtures,
      clubManagers: world.managers,
      scouts: scoutCandidates,
    );
  }
}
