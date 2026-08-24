import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/club.dart';
import 'package:football_agent/domain/models/club_season_record.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/services/club_financial_policy.dart';
import 'package:football_agent/domain/services/club_transfer_strategy.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/player_transfer_decision.dart';

void main() {
  const factory = GameFactory();
  const strategyService = ClubTransferStrategyService();
  const policyService = ClubFinancialPolicyService();

  test('previous champion receives a title-defense objective', () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final champion = base.clubs.last;
    final game = _seasonTwoWithChampion(base, champion.id);

    final strategy = strategyService.forClub(game, champion);

    expect(strategy.objective, ClubTransferObjective.titleDefense);
    expect(strategy.previousPosition, 1);
    expect(strategy.ambition, greaterThan(0.5));
    expect(strategy.maxWindowArrivals, 3);
  });

  test('financial power separates a rich champion from a poor champion', () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final richOriginal = base.clubs.first;
    final poorOriginal = base.clubs.last;
    final rich = richOriginal.copyWith(
      clubValue: 2000000000,
      budget: 400000000,
      balance: 800000000,
    );
    final poor = poorOriginal.copyWith(
      clubValue: 220000000,
      budget: 15000000,
      balance: 25000000,
    );
    final richGame = _seasonTwoWithChampion(
      base.copyWith(clubs: _replaceClub(base.clubs, rich)),
      rich.id,
    );
    final poorGame = _seasonTwoWithChampion(
      base.copyWith(clubs: _replaceClub(base.clubs, poor)),
      poor.id,
    );
    final richStrategy = strategyService.forClub(richGame, rich);
    final poorStrategy = strategyService.forClub(poorGame, poor);
    final richPolicy = policyService.forClub(
      game: richGame,
      club: rich,
      strategy: richStrategy,
    );
    final poorPolicy = policyService.forClub(
      game: poorGame,
      club: poor,
      strategy: poorStrategy,
    );

    expect(richStrategy.objective, ClubTransferObjective.titleDefense);
    expect(poorStrategy.objective, ClubTransferObjective.titleDefense);
    expect(richPolicy.availableTransferFunds,
        greaterThan(poorPolicy.availableTransferFunds * 8));
    expect(richPolicy.maxOfferWage, greaterThan(poorPolicy.maxOfferWage));
  });

  test('club policy rejects deals that break cash or wage limits', () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final club = base.clubs.first;
    final game = _seasonTwoWithChampion(base, club.id);
    final strategy = strategyService.forClub(game, club);
    final policy = policyService.forClub(
      game: game,
      club: club,
      strategy: strategy,
    );

    expect(
      policy.canFund(
        club: club,
        fee: policy.availableTransferFunds + 1,
        weeklyWage: 0,
      ),
      isFalse,
    );
    expect(
      policy.canFund(
        club: club,
        fee: 0,
        weeklyWage: policy.maxOfferWage + 1,
      ),
      isFalse,
    );
    expect(policy.minimumCashReserve, greaterThan(club.totalSalary * 13));
  });

  test('higher salary materially improves player acceptance', () {
    final base = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final seller = base.clubs.last;
    final buyer = base.clubs.first;
    final game = _seasonTwoWithChampion(base, buyer.id);
    final player = game.playersForClub(seller.id).first;
    final strategy = strategyService.forClub(game, buyer);
    const decision = PlayerTransferDecisionService();

    final lowOffer = decision.acceptanceProbability(
      game: game,
      player: player,
      seller: seller,
      buyer: buyer,
      buyerStrategy: strategy,
      weeklySalary: player.salary * 0.92,
    );
    final highOffer = decision.acceptanceProbability(
      game: game,
      player: player,
      seller: seller,
      buyer: buyer,
      buyerStrategy: strategy,
      weeklySalary: player.salary * 1.50,
    );

    expect(highOffer, greaterThan(lowOffer + 0.25));
    expect(lowOffer, greaterThan(0));
    expect(highOffer, lessThan(1));
  });
}

GameState _seasonTwoWithChampion(GameState base, String championId) {
  final ordered = [
    championId,
    ...base.clubs
        .map((club) => club.id)
        .where((clubId) => clubId != championId),
  ];
  final seasonOne = List.generate(
    ordered.length,
    (index) => ClubSeasonRecord(
      clubId: ordered[index],
      season: 1,
      played: 38,
      won: 26 - index.clamp(0, 18),
      drawn: 6,
      lost: 6 + index.clamp(0, 18),
      goalsFor: 80 - index,
      goalsAgainst: 25 + index,
      points: 84 - index,
    ),
    growable: false,
  );
  return base.copyWith(
    agent: base.agent.copyWith(currentSeason: 2, currentWeek: 20),
    standings: [
      ...seasonOne,
      ...base.clubs.map(
        (club) => ClubSeasonRecord(clubId: club.id, season: 2),
      ),
    ],
  );
}

List<Club> _replaceClub(List<Club> clubs, Club replacement) => clubs
    .map((club) => club.id == replacement.id ? replacement : club)
    .toList(growable: false);
