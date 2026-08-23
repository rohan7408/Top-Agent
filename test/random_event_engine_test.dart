import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/agency_event.dart';
import 'package:football_agent/domain/models/agency_transaction.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/simulation/engines/random_event_engine.dart';

void main() {
  const engine = RandomEventEngine();

  test('all 12 event templates are eligible and produce three choices', () {
    final game = _preparedGame();

    expect(engine.eligibleTypes(game).toSet(), AgencyEventType.values.toSet());
    for (final type in AgencyEventType.values) {
      final result = engine.processWeek(
        game,
        season: 1,
        week: 8,
        seed: 700 + type.index,
        forceType: type,
      );

      expect(result.newEventId, isNotNull, reason: type.name);
      expect(result.state.pendingAgencyEvents, hasLength(1), reason: type.name);
      expect(result.state.pendingAgencyEvents.single.type, type);
      expect(result.state.pendingAgencyEvents.single.choices, hasLength(3));
    }
  });

  test('a decision is applied exactly once and allows negative reputation', () {
    final game = _preparedGame().copyWith(
      agent: _preparedGame().agent.copyWith(reputation: -1),
    );
    final generated = engine.processWeek(
      game,
      season: 1,
      week: 8,
      seed: 91,
      forceType: AgencyEventType.propertyDamage,
    );
    final event = generated.state.pendingAgencyEvents.single;

    final resolution = engine.resolve(
      generated.state,
      eventId: event.id,
      choiceId: 'refuse',
    )!;

    expect(resolution.state.agent.reputation, -3);
    expect(resolution.event.status, AgencyEventStatus.resolved);
    expect(resolution.event.resolvedReputationImpact, -2);
    expect(
      engine.resolve(
        resolution.state,
        eventId: event.id,
        choiceId: 'pay',
      ),
      isNull,
    );
  });

  test('event costs can put agency money below zero and create a transaction',
      () {
    final prepared = _preparedGame();
    final game = prepared.copyWith(
      agent: prepared.agent.copyWith(money: 100),
    );
    final generated = engine.processWeek(
      game,
      season: 1,
      week: 8,
      seed: 29,
      forceType: AgencyEventType.officeRepair,
    );
    final event = generated.state.pendingAgencyEvents.single;
    final resolution = engine.resolve(
      generated.state,
      eventId: event.id,
      choiceId: 'repair',
    )!;

    expect(resolution.state.agent.money, lessThan(0));
    expect(
      resolution.state.agencyTransactions.last.type,
      AgencyTransactionType.agencyEvent,
    );
    expect(resolution.state.agencyTransactions.last.amount, -5000);
  });

  test('funding scout travel can discover a real available talent', () {
    final game = _preparedGame();
    final generated = engine.processWeek(
      game,
      season: 1,
      week: 8,
      seed: 101,
      forceType: AgencyEventType.scoutTravelRequest,
    );
    final event = generated.state.pendingAgencyEvents.single;
    final before = generated.state.availableTalents.length;
    final resolution = engine.resolve(
      generated.state,
      eventId: event.id,
      choiceId: 'fund',
    )!;

    expect(resolution.state.availableTalents, hasLength(before + 1));
    expect(resolution.outcome, contains('returned with'));
  });

  test('pending events block another event and then expire after two weeks',
      () {
    final game = _preparedGame();
    final generated = engine.processWeek(
      game,
      season: 1,
      week: 8,
      seed: 2,
      forceType: AgencyEventType.officeRepair,
    );

    final blocked = engine.processWeek(
      generated.state,
      season: 1,
      week: 9,
      seed: 3,
      forceType: AgencyEventType.localAdvertising,
    );
    expect(blocked.newEventId, isNull);
    expect(blocked.state.pendingAgencyEvents, hasLength(1));

    final expired = engine.processWeek(
      blocked.state,
      season: 1,
      week: 11,
      seed: 4,
    );
    expect(expired.state.pendingAgencyEvents, isEmpty);
    expect(expired.state.agencyEvents.single.status, AgencyEventStatus.expired);
  });

  test('agency events survive a full GameState JSON round trip', () {
    final generated = engine.processWeek(
      _preparedGame(),
      season: 1,
      week: 8,
      seed: 8,
      forceType: AgencyEventType.bootSponsorship,
    );

    final restored = GameState.fromJson(generated.state.toJson());

    expect(restored.agencyEvents, hasLength(1));
    expect(restored.agencyEvents.single.type, AgencyEventType.bootSponsorship);
    expect(restored.agencyEvents.single.choices, hasLength(3));
  });

  test('onboarding weeks do not create unsolicited events', () {
    final result = engine.processWeek(
      _preparedGame(),
      season: 1,
      week: 3,
      seed: 1,
    );
    expect(result.newEventId, isNull);
    expect(result.state.agencyEvents, isEmpty);
  });

  test('failed uncertain outcomes remain failures after save migration', () {
    AgencyEventResolution? failure;
    for (var week = 4; week <= 50 && failure == null; week++) {
      final generated = engine.processWeek(
        _preparedGame(),
        season: 1,
        week: week,
        seed: week,
        forceType: AgencyEventType.bootSponsorship,
      );
      final event = generated.state.pendingAgencyEvents.single;
      final resolution = engine.resolve(
        generated.state,
        eventId: event.id,
        choiceId: 'negotiate',
      )!;
      if (!resolution.succeeded) failure = resolution;
    }

    expect(failure, isNotNull);
    expect(failure!.event.outcome, AgencyEventOutcome.failed);
    expect(failure.event.resolvedSucceeded, isFalse);

    final legacyJson = Map<String, Object?>.from(failure.event.toJson())
      ..remove('resolvedSucceeded');
    final restoredLegacyEvent = AgencyEvent.fromJson(legacyJson);
    expect(restoredLegacyEvent.outcome, AgencyEventOutcome.failed);
  });
}

GameState _preparedGame() {
  final game = const GameFactory().createNewGame(
    agentName: 'Alex Morgan',
    agencyName: 'North Star Sports',
    agentAge: 34,
    createdAt: DateTime.utc(2025, 1, 1),
  );
  final talent = game.availableTalents.first;
  final represented = talent.copyWith(
    agentId: game.agent.id,
    isRecruited: true,
    clubId: game.clubs.first.id,
    salary: 1200,
    fatigue: 35,
  );
  final players = game.players
      .map((player) => player.id == talent.id ? represented : player)
      .toList(growable: false);
  final hiredScout = game.scouts.first.copyWith(agencyId: game.agent.id);
  final scouts = game.scouts
      .map((scout) => scout.id == hiredScout.id ? hiredScout : scout)
      .toList(growable: false);
  return game.copyWith(players: players, scouts: scouts);
}
