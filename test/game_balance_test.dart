import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/club_season_record.dart';
import 'package:football_agent/domain/models/player.dart';
import 'package:football_agent/domain/models/player_training_plan.dart';
import 'package:football_agent/domain/services/football_world_factory.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/game_balance.dart';
import 'package:football_agent/simulation/game_engine.dart';

void main() {
  const balance = GameBalance();

  group('connected economy balance', () {
    test('ability, potential, age, and position shape market value', () {
      final established = balance.playerMarketValue(
        ability: 70,
        potential: 70,
        age: 27,
        position: PlayerPosition.midfielder,
      );
      final elite = balance.playerMarketValue(
        ability: 85,
        potential: 88,
        age: 25,
        position: PlayerPosition.forward,
      );
      final prospect = balance.playerMarketValue(
        ability: 70,
        potential: 90,
        age: 19,
        position: PlayerPosition.midfielder,
      );
      final veteran = balance.playerMarketValue(
        ability: 70,
        potential: 70,
        age: 35,
        position: PlayerPosition.midfielder,
      );

      expect(established, inInclusiveRange(15000000, 30000000));
      expect(elite, greaterThan(established * 2));
      expect(prospect, greaterThan(established));
      expect(veteran, lessThan(established));
    });

    test('wages scale below value and commissions respect club budget', () {
      final wage = balance.weeklyWage(
        ability: 72,
        potential: 82,
        age: 22,
      );
      final starterOfficeFee = balance.agentSigningFee(
        weeklyWage: wage,
        clubBudget: 40000000,
        contractLength: 3,
        feeRate: 0.08,
      );
      final topOfficeFee = balance.agentSigningFee(
        weeklyWage: wage,
        clubBudget: 40000000,
        contractLength: 3,
        feeRate: 0.18,
      );

      expect(wage, inInclusiveRange(25000, 75000));
      expect(topOfficeFee, greaterThan(starterOfficeFee));
      expect(topOfficeFee, lessThanOrEqualTo(40000000 * 0.035));
    });

    test('new clubs start with sustainable connected finances', () {
      final world = const FootballWorldFactory().createPremierLeague(seed: 7);

      expect(world.clubs, hasLength(20));
      expect(world.players, hasLength(20 * FootballWorldFactory.squadSize));
      for (final club in world.clubs) {
        expect(club.squadValue, greaterThan(0));
        expect(club.clubValue, greaterThan(club.squadValue));
        expect(
            club.budget,
            inInclusiveRange(
              club.squadValue * 0.16,
              club.squadValue * 0.28,
            ));
        expect(club.balance, greaterThan(club.totalSalary * 50));
      }
    });

    test('season prize money reaches club cash and transfer budgets', () {
      final initial = const GameFactory().createNewGame(
        agentName: 'Balance Tester',
        agencyName: 'Numbers FC',
        agentAge: 35,
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final clubsWithoutTransferFunds = initial.clubs
          .map((club) => club.copyWith(budget: 0))
          .toList(growable: false);
      final rankedTable = List.generate(
        initial.clubs.length,
        (index) => ClubSeasonRecord(
          clubId: initial.clubs[index].id,
          season: 1,
          played: 38,
          won: 20 - index,
          points: 80 - index,
          goalsFor: 70 - index,
          goalsAgainst: 30 + index,
        ),
        growable: false,
      );
      final gameAtSeasonEnd = initial.copyWith(
        agent: initial.agent.copyWith(currentWeek: 50),
        clubs: clubsWithoutTransferFunds,
        standings: rankedTable,
      );

      final settled = const GameEngine().simulateOneWeek(gameAtSeasonEnd).state;
      final league = initial.leagues.single;
      for (var index = 0; index < initial.clubs.length; index++) {
        final before = clubsWithoutTransferFunds[index];
        final after = settled.clubById(before.id)!;
        final prize = league.prizeMoneyForPosition(index + 1);
        expect(after.balance, before.balance - before.totalSalary + prize);
        expect(after.budget, prize * 0.55);
      }
    });
  });

  group('development and player health balance', () {
    test('heavy workloads create more fatigue and injury risk', () {
      final freshRisk = balance.matchInjuryChance(
        age: 24,
        durability: 75,
        fatigue: 5,
        consecutiveStarts: 0,
      );
      final overloadedRisk = balance.matchInjuryChance(
        age: 33,
        durability: 55,
        fatigue: 90,
        consecutiveStarts: 7,
      );
      final freshLoad = balance.matchFatigueLoad(
        minutes: 90,
        stamina: 85,
        consecutiveStarts: 0,
        tacticalLoad: 0,
      );
      final repeatedLoad = balance.matchFatigueLoad(
        minutes: 90,
        stamina: 55,
        consecutiveStarts: 7,
        tacticalLoad: 6,
      );

      expect(overloadedRisk, greaterThan(freshRisk * 5));
      expect(repeatedLoad, greaterThan(freshLoad));
      expect(
        balance.weeklyFatigueRecovery(90),
        greaterThan(balance.weeklyFatigueRecovery(45)),
      );
    });

    test('young prospects and good coaching develop faster', () {
      final youngIntense = balance.weeklyTrainingProgress(
        age: 18,
        ability: 52,
        potential: 80,
        coachAbility: 82,
        fatigue: 15,
        intensity: TrainingIntensity.intense,
      );
      final olderTired = balance.weeklyTrainingProgress(
        age: 31,
        ability: 72,
        potential: 76,
        coachAbility: 0,
        fatigue: 82,
        intensity: TrainingIntensity.normal,
      );

      expect(youngIntense, greaterThanOrEqualTo(18));
      expect(olderTired, 1);
    });
  });
}
