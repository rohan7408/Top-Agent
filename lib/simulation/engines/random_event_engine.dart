import 'dart:math';

import '../../domain/models/agency_event.dart';
import '../../domain/models/agency_transaction.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/models/scout.dart';
import '../../domain/services/talent_generator.dart';

class RandomEventWeekResult {
  const RandomEventWeekResult({required this.state, this.newEventId});

  final GameState state;
  final String? newEventId;
}

class AgencyEventResolution {
  const AgencyEventResolution({
    required this.state,
    required this.event,
    required this.outcome,
    required this.succeeded,
  });

  final GameState state;
  final AgencyEvent event;
  final String outcome;
  final bool succeeded;
}

class RandomEventEngine {
  const RandomEventEngine({
    this.talentGenerator = const TalentGenerator(),
  });

  static const double weeklyEventChance = 0.16;
  static const int globalCooldownWeeks = 2;
  static const int templateCooldownWeeks = 8;
  static const int onboardingWeeks = 3;

  final TalentGenerator talentGenerator;

  RandomEventWeekResult processWeek(
    GameState game, {
    required int season,
    required int week,
    required int seed,
    AgencyEventType? forceType,
  }) {
    final absoluteWeek = ((season - 1) * 50) + week;
    final expiredEvents = game.agencyEvents.map((event) {
      if (event.status == AgencyEventStatus.pending &&
          event.expiresAbsoluteWeek < absoluteWeek) {
        return event.copyWith(
          status: AgencyEventStatus.expired,
          outcomeSummary: 'No decision was made before the event expired.',
          resolvedSeason: season,
          resolvedWeek: week,
        );
      }
      return event;
    }).toList(growable: false);
    var updatedGame = game.copyWith(agencyEvents: expiredEvents);
    if (updatedGame.pendingAgencyEvents.isNotEmpty) {
      return RandomEventWeekResult(state: updatedGame);
    }

    final random = Random(seed ^ 0xA63E71);
    if (forceType == null) {
      if (absoluteWeek <= onboardingWeeks) {
        return RandomEventWeekResult(state: updatedGame);
      }
      final latestAbsoluteWeek = expiredEvents.fold<int>(
        -999999,
        (latest, event) => max(latest, event.absoluteWeek),
      );
      if (absoluteWeek - latestAbsoluteWeek < globalCooldownWeeks ||
          random.nextDouble() >= weeklyEventChance) {
        return RandomEventWeekResult(state: updatedGame);
      }
    }

    final eligible = eligibleTypes(updatedGame).where((type) {
      if (forceType != null) return type == forceType;
      final latestOfType = expiredEvents
          .where((event) => event.type == type)
          .fold<int>(
              -999999, (latest, event) => max(latest, event.absoluteWeek));
      return absoluteWeek - latestOfType >= templateCooldownWeeks;
    }).toList(growable: false);
    if (eligible.isEmpty) return RandomEventWeekResult(state: updatedGame);

    final type = forceType ?? eligible[random.nextInt(eligible.length)];
    final event = _buildEvent(
      updatedGame,
      type: type,
      season: season,
      week: week,
      seed: seed,
    );
    if (event == null) return RandomEventWeekResult(state: updatedGame);
    updatedGame = updatedGame.copyWith(
      agencyEvents: [...updatedGame.agencyEvents, event],
    );
    return RandomEventWeekResult(state: updatedGame, newEventId: event.id);
  }

  List<AgencyEventType> eligibleTypes(GameState game) {
    final clients =
        game.representedPlayers.where((player) => !player.isRetired);
    final clubClients = clients.where((player) => player.clubId != null);
    return [
      if (clients.isNotEmpty) ...[
        AgencyEventType.localAdvertising,
        AgencyEventType.bootSponsorship,
        AgencyEventType.paidAppearance,
        AgencyEventType.familyEmergency,
      ],
      if (clubClients.isNotEmpty) ...[
        AgencyEventType.propertyDamage,
        AgencyEventType.missedTraining,
        AgencyEventType.nightclubIncident,
        AgencyEventType.playingTimeComplaint,
        AgencyEventType.transferRequest,
        AgencyEventType.specialistTreatment,
      ],
      if (game.hiredScouts.isNotEmpty) AgencyEventType.scoutTravelRequest,
      AgencyEventType.officeRepair,
    ];
  }

  AgencyEventResolution? resolve(
    GameState game, {
    required String eventId,
    required String choiceId,
  }) {
    final eventIndex =
        game.agencyEvents.indexWhere((event) => event.id == eventId);
    if (eventIndex < 0) return null;
    final event = game.agencyEvents[eventIndex];
    if (event.status != AgencyEventStatus.pending) return null;
    final choice =
        event.choices.where((item) => item.id == choiceId).firstOrNull;
    if (choice == null) return null;

    final succeeded = !choice.isUncertain ||
        Random(_stableHash('${event.id}|${choice.id}')).nextDouble() <=
            choice.successChance;
    final moneyImpact =
        succeeded ? choice.moneyImpact : choice.failureMoneyImpact;
    final reputationImpact =
        succeeded ? choice.reputationImpact : choice.failureReputationImpact;
    final fatigueImpact =
        succeeded ? choice.fatigueImpact : choice.failureFatigueImpact;
    var outcome = succeeded
        ? choice.successMessage
        : choice.failureMessage ?? 'The decision did not work as planned.';
    var players = [...game.players];
    if (event.playerId != null && fatigueImpact != 0) {
      final playerIndex =
          players.indexWhere((player) => player.id == event.playerId);
      if (playerIndex >= 0) {
        final player = players[playerIndex];
        players[playerIndex] = player.copyWith(
          fatigue: (player.fatigue + fatigueImpact).clamp(0, 100).toDouble(),
        );
      }
    }

    if (succeeded &&
        event.type == AgencyEventType.scoutTravelRequest &&
        choice.id != 'decline') {
      final scout = game.scouts
          .where((candidate) => candidate.id == event.scoutId)
          .firstOrNull;
      if (scout != null) {
        final talent = talentGenerator
            .generateForScout(
              count: 1,
              scoutAbility: scout.ability,
              seed: _stableHash(event.id),
              idPrefix: 'event-scout-${event.id}',
            )
            .single;
        players.add(talent);
        outcome =
            '$outcome ${scout.name} returned with ${talent.name}, a ${talent.age}-year-old rated ${talent.ability}.';
      }
    }

    final resolved = event.copyWith(
      status: AgencyEventStatus.resolved,
      resolvedChoiceId: choice.id,
      outcomeSummary: outcome,
      resolvedSeason: game.currentSeason,
      resolvedWeek: game.currentWeek,
      resolvedMoneyImpact: moneyImpact,
      resolvedReputationImpact: reputationImpact,
      resolvedFatigueImpact: fatigueImpact,
      resolvedSucceeded: choice.isUncertain ? succeeded : null,
    );
    final events = [...game.agencyEvents]..[eventIndex] = resolved;
    final transactions = [
      ...game.agencyTransactions,
      if (moneyImpact != 0)
        AgencyTransaction(
          id: 'transaction-event-${event.id}-${choice.id}',
          type: AgencyTransactionType.agencyEvent,
          amount: moneyImpact,
          description: event.title,
          season: game.currentSeason,
          week: game.currentWeek,
        ),
    ];
    final state = game.copyWith(
      agent: game.agent.copyWith(
        money: game.agent.money + moneyImpact,
        reputation: game.agent.reputation + reputationImpact,
      ),
      players: players,
      agencyEvents: events,
      agencyTransactions: transactions,
    );
    return AgencyEventResolution(
      state: state,
      event: resolved,
      outcome: outcome,
      succeeded: succeeded,
    );
  }

  AgencyEvent? _buildEvent(
    GameState game, {
    required AgencyEventType type,
    required int season,
    required int week,
    required int seed,
  }) {
    final random = Random(seed ^ _stableHash(type.name));
    final clients = game.representedPlayers
        .where((player) => !player.isRetired)
        .toList(growable: false);
    final clubClients = clients
        .where((player) => player.clubId != null)
        .toList(growable: false);
    final player =
        clients.isEmpty ? null : clients[random.nextInt(clients.length)];
    final clubPlayer = clubClients.isEmpty
        ? null
        : clubClients[random.nextInt(clubClients.length)];
    final scout = game.hiredScouts.isEmpty
        ? null
        : game.hiredScouts[random.nextInt(game.hiredScouts.length)];
    final subject = switch (type) {
      AgencyEventType.propertyDamage ||
      AgencyEventType.missedTraining ||
      AgencyEventType.nightclubIncident ||
      AgencyEventType.playingTimeComplaint ||
      AgencyEventType.transferRequest ||
      AgencyEventType.specialistTreatment =>
        clubPlayer,
      AgencyEventType.scoutTravelRequest ||
      AgencyEventType.officeRepair =>
        null,
      _ => player,
    };
    if (type != AgencyEventType.scoutTravelRequest &&
        type != AgencyEventType.officeRepair &&
        subject == null) {
      return null;
    }
    if (type == AgencyEventType.scoutTravelRequest && scout == null) {
      return null;
    }
    final clubName =
        subject?.clubId == null ? null : game.clubById(subject!.clubId!)?.name;
    final eventId = 'event-s$season-w$week-${type.name}';
    final expires = ((season - 1) * 50) + week + 2;

    return switch (type) {
      AgencyEventType.localAdvertising => _event(
          id: eventId,
          type: type,
          title: 'Local advertising offer',
          body:
              'A regional business wants ${subject!.name} in a short advertising campaign.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: _commercialChoices(
            amount: max(5000, subject.value * 0.003).roundToDouble(),
            playerName: subject.name,
            fatigue: 2,
          ),
        ),
      AgencyEventType.bootSponsorship => _event(
          id: eventId,
          type: type,
          title: 'Boot sponsorship',
          body:
              'A sportswear company has offered ${subject!.name} a season-long boot agreement.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: _commercialChoices(
            amount: max(12000, subject.value * 0.006).roundToDouble(),
            playerName: subject.name,
            fatigue: 1,
          ),
        ),
      AgencyEventType.paidAppearance => _event(
          id: eventId,
          type: type,
          title: 'Paid public appearance',
          body:
              '${subject!.name} has been invited to a paid supporter event during a rest day.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            AgencyEventChoice(
              id: 'attend',
              label: 'Attend the event',
              detail: 'Earn money · +1 REP · +4 fatigue',
              moneyImpact: max(4000, subject.value * 0.0015).roundToDouble(),
              reputationImpact: 1,
              fatigueImpact: 4,
              successMessage: '${subject.name} completed the appearance.',
            ),
            AgencyEventChoice(
              id: 'remote',
              label: 'Offer a video appearance',
              detail: 'Medium risk · smaller payment',
              successChance: 0.65,
              moneyImpact: max(2500, subject.value * 0.0008).roundToDouble(),
              fatigueImpact: 1,
              successMessage: 'The organiser accepted the remote appearance.',
              failureMessage: 'The organiser withdrew the appearance fee.',
            ),
            AgencyEventChoice(
              id: 'rest',
              label: 'Prioritise rest',
              detail: 'No payment · -3 fatigue',
              fatigueImpact: -3,
              successMessage: '${subject.name} used the day to recover.',
            ),
          ],
        ),
      AgencyEventType.propertyDamage => _event(
          id: eventId,
          type: type,
          title: 'Club property damaged',
          body:
              '$clubName says ${subject!.name} caused damage during a dressing-room incident.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: _damageChoices(
            cost: max(2500, (subject.salary * 1.5) + subject.value * 0.0005)
                .roundToDouble(),
            playerName: subject.name,
          ),
        ),
      AgencyEventType.missedTraining => _event(
          id: eventId,
          type: type,
          title: 'Missed training',
          body:
              '$clubName has asked for an explanation after ${subject!.name} missed training.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: _disciplineChoices(subject.name, 'training'),
        ),
      AgencyEventType.nightclubIncident => _event(
          id: eventId,
          type: type,
          title: 'Nightclub incident',
          body:
              'Photos of ${subject!.name} leaving a nightclub before a club session are circulating.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: _disciplineChoices(subject.name, 'the incident'),
        ),
      AgencyEventType.playingTimeComplaint => _event(
          id: eventId,
          type: type,
          title: 'Playing-time complaint',
          body:
              '${subject!.name} is unhappy with their role at $clubName and wants your advice.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            AgencyEventChoice(
              id: 'meet_manager',
              label: 'Meet the manager privately',
              detail: 'Professional approach · +1 REP',
              reputationImpact: 1,
              successMessage:
                  'The concern was raised privately with $clubName.',
            ),
            AgencyEventChoice(
              id: 'patience',
              label: 'Advise patience',
              detail: 'Calm the situation · -2 fatigue',
              fatigueImpact: -2,
              successMessage: '${subject.name} agreed to remain patient.',
            ),
            AgencyEventChoice(
              id: 'public_pressure',
              label: 'Pressure the club publicly',
              detail: 'Aggressive approach · -2 REP',
              reputationImpact: -2,
              successMessage:
                  'The public comments increased pressure on $clubName.',
            ),
          ],
        ),
      AgencyEventType.transferRequest => _event(
          id: eventId,
          type: type,
          title: 'Client wants a transfer',
          body:
              '${subject!.name} has asked you to explore a move away from $clubName.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            AgencyEventChoice(
              id: 'explore',
              label: 'Quietly contact clubs',
              detail: 'Agency work -£2k · +1 REP',
              moneyImpact: -2000,
              reputationImpact: 1,
              successMessage: 'You began discreetly assessing the market.',
            ),
            AgencyEventChoice(
              id: 'stay',
              label: 'Recommend staying',
              detail: 'No immediate cost',
              successMessage: '${subject.name} will reassess later.',
            ),
            AgencyEventChoice(
              id: 'reject',
              label: 'Reject the request',
              detail: 'Dismiss the concern · -2 REP',
              reputationImpact: -2,
              successMessage:
                  'The request was rejected without further action.',
            ),
          ],
        ),
      AgencyEventType.specialistTreatment => _event(
          id: eventId,
          type: type,
          title: 'Specialist treatment request',
          body:
              '${subject!.name} wants additional recovery treatment outside $clubName.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: _treatmentChoices(
            cost: max(3000, subject.salary + subject.fatigue * 200)
                .roundToDouble(),
            playerName: subject.name,
          ),
        ),
      AgencyEventType.familyEmergency => _event(
          id: eventId,
          type: type,
          title: 'Family emergency',
          body:
              '${subject!.name} needs urgent support dealing with a family matter.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            AgencyEventChoice(
              id: 'support',
              label: 'Give full support',
              detail: 'Support costs £2k · +1 REP · -10 fatigue',
              moneyImpact: -2000,
              reputationImpact: 1,
              fatigueImpact: -10,
              successMessage:
                  '${subject.name} received time and agency support.',
            ),
            AgencyEventChoice(
              id: 'travel',
              label: 'Arrange urgent travel',
              detail: 'Cost £5k · +2 REP · -7 fatigue',
              moneyImpact: -5000,
              reputationImpact: 2,
              fatigueImpact: -7,
              successMessage: 'The agency arranged everything immediately.',
            ),
            AgencyEventChoice(
              id: 'decline',
              label: 'Stay out of it',
              detail: 'No cost · -2 REP · +3 fatigue',
              reputationImpact: -2,
              fatigueImpact: 3,
              successMessage: 'The agency declined to become involved.',
            ),
          ],
        ),
      AgencyEventType.scoutTravelRequest => _scoutTravelEvent(
          id: eventId,
          season: season,
          week: week,
          expires: expires,
          scout: scout!,
        ),
      AgencyEventType.officeRepair => _officeRepairEvent(
          id: eventId,
          season: season,
          week: week,
          expires: expires,
          level: game.office.level,
        ),
    };
  }

  AgencyEvent _event({
    required String id,
    required AgencyEventType type,
    required String title,
    required String body,
    required int season,
    required int week,
    required int expires,
    required Player player,
    required List<AgencyEventChoice> choices,
  }) =>
      AgencyEvent(
        id: id,
        type: type,
        title: title,
        body: body,
        season: season,
        week: week,
        expiresAbsoluteWeek: expires,
        choices: choices,
        playerId: player.id,
        clubId: player.clubId,
      );

  List<AgencyEventChoice> _commercialChoices({
    required double amount,
    required String playerName,
    required double fatigue,
  }) =>
      [
        AgencyEventChoice(
          id: 'accept',
          label: 'Accept the offer',
          detail: 'Guaranteed income · +1 REP',
          moneyImpact: amount,
          reputationImpact: 1,
          fatigueImpact: fatigue,
          successMessage: '$playerName completed the campaign.',
        ),
        AgencyEventChoice(
          id: 'negotiate',
          label: 'Negotiate a higher fee',
          detail: 'Medium risk · 40% higher income',
          successChance: 0.55,
          moneyImpact: (amount * 1.4).roundToDouble(),
          reputationImpact: 2,
          fatigueImpact: fatigue,
          successMessage: 'The brand accepted the improved terms.',
          failureMessage: 'The brand withdrew its offer.',
          failureReputationImpact: -1,
        ),
        AgencyEventChoice(
          id: 'decline',
          label: 'Decline',
          detail: 'No financial or reputation change',
          successMessage: 'The offer was declined.',
        ),
      ];

  List<AgencyEventChoice> _damageChoices({
    required double cost,
    required String playerName,
  }) =>
      [
        AgencyEventChoice(
          id: 'pay',
          label: 'Pay the full damage',
          detail: 'Protect the client relationship',
          moneyImpact: -cost,
          successMessage: 'The agency settled the damage immediately.',
        ),
        AgencyEventChoice(
          id: 'split',
          label: 'Negotiate a split payment',
          detail: 'Medium risk · pay half if accepted',
          successChance: 0.60,
          moneyImpact: -(cost * 0.5).roundToDouble(),
          successMessage: 'The club accepted a shared settlement.',
          failureMessage: 'The club demanded full payment.',
          failureMoneyImpact: -cost,
          failureReputationImpact: -1,
        ),
        AgencyEventChoice(
          id: 'refuse',
          label: 'Refuse responsibility',
          detail: 'No payment · -2 REP',
          reputationImpact: -2,
          successMessage: '$playerName was left to handle the dispute.',
        ),
      ];

  List<AgencyEventChoice> _disciplineChoices(
    String playerName,
    String issue,
  ) =>
      [
        AgencyEventChoice(
          id: 'apologise',
          label: 'Arrange a formal apology',
          detail: 'Media support -£1k · +1 REP',
          moneyImpact: -1000,
          reputationImpact: 1,
          successMessage: '$playerName apologised for $issue.',
        ),
        AgencyEventChoice(
          id: 'private',
          label: 'Handle it privately',
          detail: 'Low risk · no immediate cost',
          successChance: 0.72,
          successMessage: 'The issue was contained privately.',
          failureMessage: 'The private response failed to calm the situation.',
          failureReputationImpact: -1,
        ),
        AgencyEventChoice(
          id: 'defend',
          label: 'Defend the player publicly',
          detail: 'Protect the client · -2 REP',
          reputationImpact: -2,
          successMessage: 'The agency publicly defended $playerName.',
        ),
      ];

  List<AgencyEventChoice> _treatmentChoices({
    required double cost,
    required String playerName,
  }) =>
      [
        AgencyEventChoice(
          id: 'fund',
          label: 'Fund full treatment',
          detail: 'Best recovery · +1 REP · -12 fatigue',
          moneyImpact: -cost,
          reputationImpact: 1,
          fatigueImpact: -12,
          successMessage: '$playerName completed specialist treatment.',
        ),
        AgencyEventChoice(
          id: 'split',
          label: 'Offer half the cost',
          detail: 'Partial recovery · -7 fatigue',
          moneyImpact: -(cost * 0.5).roundToDouble(),
          fatigueImpact: -7,
          successMessage: 'A reduced treatment programme was arranged.',
        ),
        AgencyEventChoice(
          id: 'decline',
          label: 'Decline the request',
          detail: 'No cost · -1 REP',
          reputationImpact: -1,
          successMessage: 'The agency declined to fund extra treatment.',
        ),
      ];

  AgencyEvent _scoutTravelEvent({
    required String id,
    required int season,
    required int week,
    required int expires,
    required Scout scout,
  }) =>
      AgencyEvent(
        id: id,
        type: AgencyEventType.scoutTravelRequest,
        title: 'Urgent scouting trip',
        body:
            '${scout.name} has an unverified lead and needs a travel budget this week.',
        season: season,
        week: week,
        expiresAbsoluteWeek: expires,
        scoutId: scout.id,
        choices: [
          AgencyEventChoice(
            id: 'fund',
            label: 'Fund the full trip',
            detail: 'Guaranteed scouting visit · +1 REP',
            moneyImpact: -(scout.salary * 3).roundToDouble(),
            reputationImpact: 1,
            successMessage: 'The full scouting trip was approved.',
          ),
          AgencyEventChoice(
            id: 'basic',
            label: 'Approve a basic budget',
            detail: 'Medium risk · half the travel cost',
            successChance: 0.60,
            moneyImpact: -(scout.salary * 1.5).roundToDouble(),
            successMessage: 'The reduced trip still produced a useful lead.',
            failureMessage:
                'The reduced budget was not enough to verify the lead.',
            failureMoneyImpact: -(scout.salary * 1.5).roundToDouble(),
          ),
          const AgencyEventChoice(
            id: 'decline',
            label: 'Decline the trip',
            detail: 'No cost · -1 REP',
            reputationImpact: -1,
            successMessage: 'The scouting lead was abandoned.',
          ),
        ],
      );

  AgencyEvent _officeRepairEvent({
    required String id,
    required int season,
    required int week,
    required int expires,
    required int level,
  }) {
    final cost = (5000 * level).toDouble();
    return AgencyEvent(
      id: id,
      type: AgencyEventType.officeRepair,
      title: 'Office equipment failure',
      body:
          'Essential office and scouting equipment needs repair before it disrupts agency work.',
      season: season,
      week: week,
      expiresAbsoluteWeek: expires,
      choices: [
        AgencyEventChoice(
          id: 'repair',
          label: 'Authorise full repair',
          detail: 'Reliable solution',
          moneyImpact: -cost,
          successMessage: 'The office equipment was fully repaired.',
        ),
        AgencyEventChoice(
          id: 'temporary',
          label: 'Use a temporary fix',
          detail: 'Medium risk · 40% of full cost',
          successChance: 0.62,
          moneyImpact: -(cost * 0.4).roundToDouble(),
          successMessage: 'The temporary repair held.',
          failureMessage:
              'The temporary repair failed and harmed the agency image.',
          failureMoneyImpact: -(cost * 0.4).roundToDouble(),
          failureReputationImpact: -1,
        ),
        const AgencyEventChoice(
          id: 'postpone',
          label: 'Postpone repairs',
          detail: 'No cost · -1 REP',
          reputationImpact: -1,
          successMessage: 'Repairs were postponed.',
        ),
      ],
    );
  }

  static int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7FFFFFFF;
    }
    return hash;
  }
}
