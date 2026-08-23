import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/application/game_controller.dart';
import 'package:football_agent/application/persistence_providers.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/models/player_training_plan.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/models/agency_event.dart';
import 'package:football_agent/simulation/engines/random_event_engine.dart';

import 'helpers/in_memory_game_save_repository.dart';

void main() {
  test('recruiting moves an available talent into the agency roster', () {
    final container = _container();
    addTearDown(container.dispose);

    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );

    final initialState = container.read(gameControllerProvider)!;
    final talent = initialState.availableTalents.first;
    final initialPlayerCount = initialState.players.length;

    final result = controller.recruitPlayer(talent.id);
    final updatedState = container.read(gameControllerProvider)!;

    expect(result, RecruitmentResult.success);
    expect(updatedState.players, hasLength(initialPlayerCount));
    expect(updatedState.availableTalents, hasLength(1));
    expect(updatedState.representedPlayers, hasLength(1));
    expect(updatedState.representedPlayers.single.id, talent.id);
    expect(
        updatedState.representedPlayers.single.agentId, updatedState.agent.id);
    expect(updatedState.representedPlayers.single.isRecruited, isTrue);
    expect(
      controller.recruitPlayer(talent.id),
      RecruitmentResult.playerUnavailable,
    );
  });

  test('clearing the talent pool preserves represented clients', () async {
    final repository = InMemoryGameSaveRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );

    final recruited =
        container.read(gameControllerProvider)!.availableTalents.first;
    expect(controller.recruitPlayer(recruited.id), RecruitmentResult.success);
    expect(
      container.read(gameControllerProvider)!.availableTalents,
      isNotEmpty,
    );

    expect(controller.clearTalentPool(), TalentPoolActionResult.success);
    final cleared = container.read(gameControllerProvider)!;
    expect(cleared.availableTalents, isEmpty);
    expect(cleared.representedPlayers, hasLength(1));
    expect(cleared.representedPlayers.single.id, recruited.id);
    expect(cleared.players.any((player) => player.id == recruited.id), isTrue);
    expect(
      controller.clearTalentPool(),
      TalentPoolActionResult.alreadyEmpty,
    );

    await controller.waitForPendingSaves();
    final saved = await repository.loadLatest();
    expect(saved!.availableTalents, isEmpty);
    expect(saved.representedPlayers.single.id, recruited.id);
  });

  test('suggesting and accepting a deal updates every connected entity', () {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );

    final talent =
        container.read(gameControllerProvider)!.availableTalents.first;
    expect(controller.recruitPlayer(talent.id), RecruitmentResult.success);

    final suggestion = controller.suggestPlayer(talent.id);
    expect(suggestion.status, SuggestionStatus.success);
    expect(suggestion.offerCount, inInclusiveRange(1, 3));

    final offeredState = container.read(gameControllerProvider)!;
    final offer = offeredState.pendingOffersForPlayer(talent.id).first;
    final clubBefore = offeredState.clubById(offer.clubId)!;
    final moneyBefore = offeredState.agent.money;
    final reputationBefore = offeredState.agent.reputation;

    expect(controller.acceptOffer(offer.id), DealActionResult.success);
    final signedState = container.read(gameControllerProvider)!;
    final signedPlayer = signedState.representedPlayers.single;
    final clubAfter = signedState.clubById(offer.clubId)!;

    expect(signedPlayer.clubId, offer.clubId);
    expect(signedPlayer.salary, offer.weeklySalary);
    expect(signedState.contracts, hasLength(1));
    expect(
      signedState.contracts.single.salaryCommissionRate,
      signedState.office.salaryCommissionRate,
    );
    expect(signedState.contractEvents, hasLength(1));
    expect(signedState.agent.money, moneyBefore + offer.agentFee);
    expect(signedState.agent.reputation, greaterThan(reputationBefore));
    expect(clubAfter.playerIds, contains(talent.id));
    expect(clubAfter.playerIds.length, clubBefore.playerIds.length + 1);
    expect(clubAfter.totalSalary, clubBefore.totalSalary + offer.weeklySalary);
    expect(signedState.pendingOffersForPlayer(talent.id), isEmpty);

    final beforeCommission = signedState.agent.money;
    final summary = controller.simulateNextWeek()!;
    final afterCommission = container.read(gameControllerProvider)!;
    expect(summary.salaryCommission, offer.weeklySalary * 0.02);
    expect(
      afterCommission.agent.money,
      beforeCommission + summary.salaryCommission,
    );
  });

  test('a scout can be hired, paid weekly, and dismissed', () {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );

    final initial = container.read(gameControllerProvider)!;
    final scout = initial.scouts.firstWhere(
      (candidate) =>
          candidate.isCandidate &&
          candidate.requiredReputation <= initial.agent.reputation,
    );
    final otherScout =
        initial.scouts.firstWhere((candidate) => candidate.id != scout.id);

    expect(controller.hireScout(scout.id), ScoutActionResult.success);
    final hired = container.read(gameControllerProvider)!;
    expect(
      hired.scouts
          .singleWhere((candidate) => candidate.id == scout.id)
          .agencyId,
      hired.agent.id,
    );
    expect(hired.agent.money, initial.agent.money - scout.signingCost);
    expect(
      controller.hireScout(otherScout.id),
      ScoutActionResult.officeFull,
    );

    final beforePayroll = container.read(gameControllerProvider)!.agent.money;
    final summary = controller.simulateNextWeek()!;
    final afterPayroll = container.read(gameControllerProvider)!;
    expect(summary.scoutPayroll, scout.salary);
    expect(afterPayroll.agent.money, beforePayroll - scout.salary);
    expect(
      afterPayroll.scouts.where((candidate) => candidate.isCandidate),
      hasLength(4),
    );

    expect(controller.dismissScout(scout.id), ScoutActionResult.success);
    final dismissed = container.read(gameControllerProvider)!;
    expect(
      dismissed.scouts
          .singleWhere((candidate) => candidate.id == scout.id)
          .isCandidate,
      isTrue,
    );
  });

  test('office upgrade can create debt and deducts reputation', () {
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final prepared = base.copyWith(
      agent: base.agent.copyWith(money: 1000, reputation: 5),
    );
    final container = _container(null, _FixedGameFactory(prepared));
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Ignored',
      agencyName: 'Ignored',
      agentAge: 30,
    );

    expect(controller.upgradeOffice(), OfficeUpgradeResult.success);
    final upgraded = container.read(gameControllerProvider)!;
    expect(upgraded.office.level, 2);
    expect(upgraded.agent.money, -24000);
    expect(upgraded.agent.reputation, 2);
    expect(upgraded.agencyTransactions.last.amount, -25000);
  });

  test('training ground upgrade creates debt and improves youth intake', () {
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final prepared = base.copyWith(
      agent: base.agent.copyWith(money: 1000, reputation: 10),
    );
    final container = _container(null, _FixedGameFactory(prepared));
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Ignored',
      agencyName: 'Ignored',
      agentAge: 30,
    );

    expect(
      controller.upgradeTrainingGround(),
      TrainingGroundUpgradeResult.success,
    );
    final upgraded = container.read(gameControllerProvider)!;
    expect(upgraded.trainingGround.level, 2);
    expect(upgraded.trainingGround.minimumAbility, 38);
    expect(upgraded.trainingGround.intakeIntervalWeeks, 10);
    expect(upgraded.agent.money, -49000);
    expect(upgraded.agent.reputation, 5);
    expect(upgraded.agencyTransactions.last.amount, -50000);
  });

  test('ending representation preserves club status and applies penalties', () {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );
    final talent =
        container.read(gameControllerProvider)!.availableTalents.first;
    controller.recruitPlayer(talent.id);
    final before = container.read(gameControllerProvider)!;
    final cost = controller.representationTerminationCost(talent.id)!;

    expect(
      controller.endRepresentation(talent.id),
      RepresentationActionResult.success,
    );
    final after = container.read(gameControllerProvider)!;
    final released = after.players.firstWhere((item) => item.id == talent.id);
    expect(released.agentId, isNull);
    expect(released.isRecruited, isTrue);
    expect(after.availableTalents.any((item) => item.id == talent.id), isFalse);
    expect(
        after.trainingPlans.any((plan) => plan.playerId == talent.id), isFalse);
    expect(after.agent.money, before.agent.money - cost);
    expect(after.agent.reputation, before.agent.reputation - 2);
    expect(after.agencyTransactions.last.amount, -cost);
  });

  test('represented players keep an autosaved training plan', () async {
    final repository = InMemoryGameSaveRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );
    final talent =
        container.read(gameControllerProvider)!.availableTalents.first;

    controller.recruitPlayer(talent.id);
    expect(
      controller.updateTrainingPlan(
        talent.id,
        focus: TrainingFocus.technical,
        intensity: TrainingIntensity.intense,
      ),
      TrainingPlanActionResult.success,
    );
    await controller.waitForPendingSaves();

    final current = container.read(gameControllerProvider)!;
    final saved = await repository.loadLatest();
    expect(current.trainingPlanForPlayer(talent.id).focus,
        TrainingFocus.technical);
    expect(current.trainingPlanForPlayer(talent.id).intensity,
        TrainingIntensity.intense);
    expect(
        saved!.trainingPlanForPlayer(talent.id).focus, TrainingFocus.technical);
  });

  test('Next Week simulates and advances exactly one week', () {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );

    final firstSummary = controller.simulateNextWeek()!;
    final afterOneWeek = container.read(gameControllerProvider)!;

    expect(firstSummary.simulatedWeek, 1);
    expect(firstSummary.nextWeek, 2);
    expect(firstSummary.matchesPlayed, 10);
    expect(afterOneWeek.currentWeek, 2);
    expect(afterOneWeek.currentSeason, 1);
    expect(afterOneWeek.matchResults, hasLength(10));
    expect(afterOneWeek.playerPerformances, hasLength(220));
    expect(afterOneWeek.playerSeasonStats, hasLength(220));
    expect(
      afterOneWeek.players.where((player) => player.consecutiveStarts == 1),
      hasLength(220),
    );
    expect(
      afterOneWeek.players
          .where((player) => player.consecutiveStarts == 1)
          .every((player) => player.fatigue > 0),
      isTrue,
    );
    expect(
      afterOneWeek.playerPerformances
          .where((performance) => performance.playerOfTheMatch),
      hasLength(10),
    );
    expect(
      afterOneWeek.playerPerformances
          .map((performance) => performance.goals)
          .fold<int>(0, (total, goals) => total + goals),
      afterOneWeek.matchResults
          .map((result) => result.homeGoals + result.awayGoals)
          .fold<int>(0, (total, goals) => total + goals),
    );
    expect(
      afterOneWeek.currentStandings.every((record) => record.played == 1),
      isTrue,
    );

    controller.simulateNextWeek();
    final afterTwoTaps = container.read(gameControllerProvider)!;
    expect(afterTwoTaps.currentWeek, 3);
    expect(afterTwoTaps.matchResults, hasLength(20));
    final weekOneClubStarters = afterOneWeek.playerPerformances
        .where((item) => item.clubId == afterOneWeek.clubs.first.id)
        .map((item) => item.playerId)
        .toSet();
    final weekTwoClubStarters = afterTwoTaps.playerPerformances
        .where((item) =>
            item.clubId == afterTwoTaps.clubs.first.id && item.week == 2)
        .map((item) => item.playerId)
        .toSet();
    expect(weekOneClubStarters, hasLength(11));
    expect(weekTwoClubStarters, hasLength(11));
  });

  test('a complete season produces 38 matches per club, not 36 or 50', () {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );

    for (var week = 0; week < 50; week++) {
      controller.simulateNextWeek();
    }
    final state = container.read(gameControllerProvider)!;
    final seasonOneTable =
        state.standings.where((record) => record.season == 1).toList();

    expect(state.currentSeason, 2);
    expect(state.currentWeek, 1);
    expect(state.matchResults, hasLength(380));
    expect(seasonOneTable, hasLength(20));
    expect(seasonOneTable.every((record) => record.played == 38), isTrue);
    expect(state.playerPerformances, hasLength(380 * 22));
    expect(state.injuries, isNotEmpty);
    expect(
      state.fixtures.where((fixture) => fixture.season == 2),
      hasLength(380),
    );
  });

  test('Week 50 advances to Week 1 of the next season only', () {
    final container = _container();
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );
    final game = container.read(gameControllerProvider)!;
    final ageBefore = game.players.first.age;
    final engine = container.read(gameEngineProvider);
    final result = engine.simulateOneWeek(
      game.copyWith(
        agent: game.agent.copyWith(currentWeek: 50),
      ),
    );

    expect(result.summary.simulatedWeek, 50);
    expect(result.state.currentWeek, 1);
    expect(result.state.currentSeason, 2);
    expect(result.state.players.first.age, ageBefore + 1);
    expect(result.summary.matchesPlayed, 0);
    expect(
      result.state.standings.where((record) => record.season == 2),
      hasLength(20),
    );
  });

  test('autosaves are ordered and a new controller loads the latest state',
      () async {
    final repository = InMemoryGameSaveRepository(
      saveDelay: const Duration(milliseconds: 2),
    );
    final firstContainer = _container(repository);
    final firstController =
        firstContainer.read(gameControllerProvider.notifier);
    firstController.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );
    final talent =
        firstContainer.read(gameControllerProvider)!.availableTalents.first;
    firstController.recruitPlayer(talent.id);
    firstController.simulateNextWeek();
    firstController.simulateNextWeek();
    await firstController.waitForPendingSaves();
    firstContainer.dispose();

    final secondContainer = _container(repository);
    addTearDown(secondContainer.dispose);
    final secondController =
        secondContainer.read(gameControllerProvider.notifier);
    final result = await secondController.loadLatestGame();
    final restored = secondContainer.read(gameControllerProvider)!;

    expect(result, LoadGameResult.success);
    expect(restored.agent.agencyName, 'North Star Sports');
    expect(restored.currentWeek, 3);
    expect(restored.representedPlayers.single.id, talent.id);
    expect(restored.matchResults, hasLength(20));
  });

  test('agency event decisions resolve once and autosave their effects',
      () async {
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2025, 1, 1),
    );
    final generated = const RandomEventEngine().processWeek(
      base,
      season: 1,
      week: 8,
      seed: 22,
      forceType: AgencyEventType.officeRepair,
    );
    final repository = InMemoryGameSaveRepository();
    final container =
        _container(repository, _FixedGameFactory(generated.state));
    addTearDown(container.dispose);
    final controller = container.read(gameControllerProvider.notifier);
    controller.startNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
    );
    final event = container.read(gameControllerProvider)!.agencyEvents.single;

    final result = controller.resolveAgencyEvent(event.id, 'postpone');
    await controller.waitForPendingSaves();
    final saved = await repository.loadLatest();

    expect(result.status, AgencyEventActionStatus.success);
    expect(result.event!.status, AgencyEventStatus.resolved);
    expect(saved!.agencyEvents.single.status, AgencyEventStatus.resolved);
    expect(saved.agent.reputation, base.agent.reputation - 1);
    expect(
      controller.resolveAgencyEvent(event.id, 'repair').status,
      AgencyEventActionStatus.alreadyResolved,
    );
  });
}

ProviderContainer _container(
    [InMemoryGameSaveRepository? repository, GameFactory? gameFactory]) {
  return ProviderContainer(
    overrides: [
      gameSaveRepositoryProvider.overrideWithValue(
        repository ?? InMemoryGameSaveRepository(),
      ),
      if (gameFactory != null)
        gameFactoryProvider.overrideWithValue(gameFactory),
    ],
  );
}

class _FixedGameFactory extends GameFactory {
  const _FixedGameFactory(this.game);

  final GameState game;

  @override
  GameState createNewGame({
    required String agentName,
    required String agencyName,
    required int agentAge,
    DateTime? createdAt,
  }) =>
      game;
}
