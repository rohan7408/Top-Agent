import 'dart:math';

import '../../domain/models/agency_event.dart';
import '../../domain/models/agency_transaction.dart';
import '../../domain/models/club_agency_relationship.dart';
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

    final type = forceType ?? _weightedEventType(updatedGame, eligible, random);
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
        AgencyEventType.televisionInterview,
        AgencyEventType.charityAppearance,
        AgencyEventType.socialMediaControversy,
        AgencyEventType.conflictingSponsors,
        AgencyEventType.documentaryOffer,
        AgencyEventType.familyEmergency,
      ],
      if (clubClients.isNotEmpty) ...[
        AgencyEventType.imageRightsDispute,
        AgencyEventType.propertyDamage,
        AgencyEventType.missedTraining,
        AgencyEventType.nightclubIncident,
        AgencyEventType.playingTimeComplaint,
        AgencyEventType.transferRequest,
        AgencyEventType.specialistTreatment,
      ],
      if (game.hiredScouts.isNotEmpty) AgencyEventType.scoutTravelRequest,
      AgencyEventType.agencySponsorship,
      AgencyEventType.officeRepair,
      AgencyEventType.unexpectedTaxBill,
      AgencyEventType.legalComplaint,
      AgencyEventType.officeLeaseRenewal,
      AgencyEventType.dataBreach,
      AgencyEventType.insuranceRenewal,
      if (game.agent.reputation >= 20) AgencyEventType.investorApproach,
      AgencyEventType.reputationConsultant,
      if (game.agent.money <= 25000) AgencyEventType.cashFlowCrisis,
    ];
  }

  AgencyEventType _weightedEventType(
    GameState game,
    List<AgencyEventType> eligible,
    Random random,
  ) {
    final weighted = <AgencyEventType>[];
    for (final type in eligible) {
      weighted.addAll(List.filled(_eventWeight(game, type), type));
    }
    return weighted[random.nextInt(weighted.length)];
  }

  int _eventWeight(GameState game, AgencyEventType type) {
    final clients = game.representedPlayers
        .where((player) => !player.isRetired)
        .toList(growable: false);
    if (clients.isEmpty) return 1;
    double average(int Function(Player player) value) =>
        clients.fold<int>(0, (sum, player) => sum + value(player)) /
        clients.length;
    final trust = average((player) => player.agentTrust);
    final professionalism =
        average((player) => player.personality.professionalism);
    final discipline = average((player) => player.personality.discipline);
    final ambition = average((player) => player.personality.ambition);
    final mediaAppeal = average((player) => player.personality.mediaAppeal);
    return switch (type.category) {
      AgencyEventCategory.commercial => 1 + (mediaAppeal ~/ 30),
      AgencyEventCategory.media => 1 + (mediaAppeal ~/ 25),
      AgencyEventCategory.discipline =>
        1 + (((200 - professionalism - discipline) / 40).floor()).clamp(0, 3),
      AgencyEventCategory.career =>
        1 + (((ambition + 100 - trust) / 70).floor()).clamp(0, 3),
      AgencyEventCategory.welfare =>
        1 + (((100 - trust) / 25).floor()).clamp(0, 3),
      AgencyEventCategory.agency => 1,
      AgencyEventCategory.finance => game.agent.money < 0 ? 3 : 1,
    };
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
    final trustImpact =
        succeeded ? choice.trustImpact : choice.failureTrustImpact;
    final clubRelationshipImpact = succeeded
        ? choice.clubRelationshipImpact
        : choice.failureClubRelationshipImpact;
    var outcome = succeeded
        ? choice.successMessage
        : choice.failureMessage ?? 'The decision did not work as planned.';
    var players = [...game.players];
    if (event.playerId != null && (fatigueImpact != 0 || trustImpact != 0)) {
      final playerIndex =
          players.indexWhere((player) => player.id == event.playerId);
      if (playerIndex >= 0) {
        final player = players[playerIndex];
        players[playerIndex] = player.copyWith(
          fatigue: (player.fatigue + fatigueImpact).clamp(0, 100).toDouble(),
          agentTrust: player.agentTrust + trustImpact,
        );
      }
    }
    var clubRelationships = [...game.clubAgencyRelationships];
    if (event.clubId != null && clubRelationshipImpact != 0) {
      final relationshipIndex = clubRelationships.indexWhere(
        (relationship) => relationship.clubId == event.clubId,
      );
      if (relationshipIndex < 0) {
        clubRelationships.add(
          ClubAgencyRelationship(
            clubId: event.clubId!,
            score: clubRelationshipImpact.clamp(-100, 100),
          ),
        );
      } else {
        clubRelationships[relationshipIndex] =
            clubRelationships[relationshipIndex].adjust(
          clubRelationshipImpact,
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
        final maximumTalentPool = max(2, game.office.clientCapacity);
        if (game.availableTalents.length >= maximumTalentPool) {
          outcome =
              '$outcome Your talent pool is full, so the lead was not added.';
        } else {
          final talent = talentGenerator
              .generateForScout(
                count: 1,
                scoutAbility: scout.ability,
                maximumAbility: game.office.scoutingRatingCap,
                seed: _stableHash(event.id),
                idPrefix: 'event-scout-${event.id}',
              )
              .single;
          players.add(talent);
          outcome =
              '$outcome ${scout.name} returned with ${talent.name}, a ${talent.age}-year-old rated ${talent.ability}.';
        }
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
      resolvedTrustImpact: trustImpact,
      resolvedClubRelationshipImpact: clubRelationshipImpact,
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
      clubAgencyRelationships: clubRelationships,
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
      AgencyEventType.specialistTreatment ||
      AgencyEventType.imageRightsDispute =>
        clubPlayer,
      AgencyEventType.scoutTravelRequest ||
      AgencyEventType.officeRepair ||
      AgencyEventType.agencySponsorship ||
      AgencyEventType.unexpectedTaxBill ||
      AgencyEventType.legalComplaint ||
      AgencyEventType.officeLeaseRenewal ||
      AgencyEventType.dataBreach ||
      AgencyEventType.insuranceRenewal ||
      AgencyEventType.investorApproach ||
      AgencyEventType.reputationConsultant ||
      AgencyEventType.cashFlowCrisis =>
        null,
      _ => player,
    };
    if (_requiresPlayer(type) && subject == null) {
      return null;
    }
    if (type == AgencyEventType.scoutTravelRequest && scout == null) {
      return null;
    }
    final clubName =
        subject?.clubId == null ? null : game.clubById(subject!.clubId!)?.name;
    final eventId = 'event-s$season-w$week-${type.name}';
    final expires = ((season - 1) * 50) + week + 2;

    final event = switch (type) {
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
      AgencyEventType.televisionInterview => _event(
          id: eventId,
          type: type,
          title: 'Prime-time interview request',
          body:
              'A national football programme wants ${subject!.name} for a live interview about their season.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            AgencyEventChoice(
              id: 'prepare',
              label: 'Arrange media preparation',
              detail: 'Cost £2k · likely positive coverage',
              successChance: 0.82,
              moneyImpact: -2000,
              reputationImpact: 2,
              trustImpact: 2,
              fatigueImpact: 2,
              successMessage:
                  '${subject.name} delivered a composed and popular interview.',
              failureMessage:
                  'The interview was safe but failed to generate interest.',
              failureMoneyImpact: -2000,
            ),
            const AgencyEventChoice(
              id: 'live',
              label: 'Let the player speak freely',
              detail: 'High upside · media-dependent risk',
              successChance: 0.58,
              reputationImpact: 3,
              trustImpact: 3,
              successMessage: 'The live interview became a major success.',
              failureMessage:
                  'An awkward answer created negative headlines for the agency.',
              failureReputationImpact: -3,
              failureTrustImpact: -1,
            ),
            const AgencyEventChoice(
              id: 'decline',
              label: 'Decline the interview',
              detail: 'Avoid risk · small trust loss',
              trustImpact: -1,
              successMessage: 'The interview request was declined.',
            ),
          ],
        ),
      AgencyEventType.charityAppearance => _event(
          id: eventId,
          type: type,
          title: 'Community charity invitation',
          body:
              '${subject!.name} has been invited to support a local youth-football fundraiser.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            const AgencyEventChoice(
              id: 'attend',
              label: 'Attend with the player',
              detail: 'Donate £3k · +3 REP · +3 fatigue',
              moneyImpact: -3000,
              reputationImpact: 3,
              trustImpact: 3,
              fatigueImpact: 3,
              successMessage:
                  'The appearance raised money and strengthened community support.',
            ),
            const AgencyEventChoice(
              id: 'donate',
              label: 'Send an agency donation',
              detail: 'Donate £5k · +2 REP · no fatigue',
              moneyImpact: -5000,
              reputationImpact: 2,
              trustImpact: 1,
              successMessage: 'The agency donation was warmly received.',
            ),
            const AgencyEventChoice(
              id: 'decline',
              label: 'Decline the invitation',
              detail: 'No cost · -1 REP · -1 trust',
              reputationImpact: -1,
              trustImpact: -1,
              successMessage: 'The charity invitation was declined.',
            ),
          ],
        ),
      AgencyEventType.socialMediaControversy => _event(
          id: eventId,
          type: type,
          title: 'Social-media controversy',
          body:
              'A post from ${subject!.name} has attracted criticism and is spreading quickly.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            const AgencyEventChoice(
              id: 'crisis_team',
              label: 'Hire a crisis-media team',
              detail: 'Cost £8k · strong damage control',
              moneyImpact: -8000,
              reputationImpact: 1,
              trustImpact: 2,
              successMessage:
                  'The media team contained the story and issued a clear response.',
            ),
            const AgencyEventChoice(
              id: 'apologise',
              label: 'Publish a direct apology',
              detail: 'Medium risk · no agency cost',
              successChance: 0.68,
              reputationImpact: 1,
              trustImpact: 1,
              successMessage: 'The apology calmed the situation.',
              failureMessage:
                  'The apology was criticised and extended the controversy.',
              failureReputationImpact: -3,
              failureTrustImpact: -1,
            ),
            AgencyEventChoice(
              id: 'defend',
              label: 'Defend the player publicly',
              detail: 'Protect trust · major reputation risk',
              reputationImpact: -3,
              trustImpact: 4,
              successMessage:
                  'The agency publicly backed ${subject.name} despite the criticism.',
            ),
          ],
        ),
      AgencyEventType.conflictingSponsors => _event(
          id: eventId,
          type: type,
          title: 'Conflicting sponsor proposal',
          body:
              'A new brand wants ${subject!.name}, but its campaign conflicts with an existing commercial commitment.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            AgencyEventChoice(
              id: 'renegotiate',
              label: 'Renegotiate both agreements',
              detail: 'Medium risk · strong income',
              successChance: 0.57,
              moneyImpact: max(10000, subject.value * 0.004).roundToDouble(),
              reputationImpact: 2,
              trustImpact: 2,
              successMessage: 'Both brands accepted a revised arrangement.',
              failureMessage:
                  'The brands rejected the compromise and withdrew the new offer.',
              failureReputationImpact: -2,
              failureTrustImpact: -1,
            ),
            AgencyEventChoice(
              id: 'existing',
              label: 'Protect the existing sponsor',
              detail: 'Smaller guaranteed payment',
              moneyImpact: max(5000, subject.value * 0.0015).roundToDouble(),
              trustImpact: 1,
              successMessage: 'The existing partnership was protected.',
            ),
            const AgencyEventChoice(
              id: 'decline',
              label: 'Reject commercial involvement',
              detail: 'No payment · preserve independence',
              reputationImpact: 1,
              successMessage: 'The conflicting campaign was rejected.',
            ),
          ],
        ),
      AgencyEventType.documentaryOffer => _event(
          id: eventId,
          type: type,
          title: 'Behind-the-scenes documentary',
          body:
              'A production company wants access to ${subject!.name} and the agency for a football documentary.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            AgencyEventChoice(
              id: 'full_access',
              label: 'Grant full access',
              detail: 'Highest income · privacy risk',
              successChance: 0.70,
              moneyImpact: max(20000, subject.value * 0.006).roundToDouble(),
              reputationImpact: 4,
              trustImpact: 1,
              fatigueImpact: 5,
              successMessage:
                  'The documentary became a strong showcase for the agency.',
              failureMessage:
                  'Private footage caused tension and damaged the agency image.',
              failureReputationImpact: -4,
              failureTrustImpact: -4,
              failureFatigueImpact: 5,
            ),
            AgencyEventChoice(
              id: 'limited',
              label: 'Offer limited access',
              detail: 'Lower payment · controlled exposure',
              moneyImpact: max(10000, subject.value * 0.003).roundToDouble(),
              reputationImpact: 2,
              trustImpact: 2,
              fatigueImpact: 2,
              successMessage: 'The controlled documentary was well received.',
            ),
            const AgencyEventChoice(
              id: 'decline',
              label: 'Protect client privacy',
              detail: 'No income · +2 trust',
              trustImpact: 2,
              successMessage: 'The documentary offer was declined.',
            ),
          ],
        ),
      AgencyEventType.imageRightsDispute => _event(
          id: eventId,
          type: type,
          title: 'Image-rights dispute',
          body:
              '${subject!.name} and $clubName disagree over control of a new commercial campaign.',
          season: season,
          week: week,
          expires: expires,
          player: subject,
          choices: [
            AgencyEventChoice(
              id: 'support_player',
              label: 'Support the player',
              detail: '+4 trust · damage club relationship',
              trustImpact: 4,
              clubRelationshipImpact: -5,
              successMessage:
                  'The agency firmly supported ${subject.name} in the dispute.',
            ),
            const AgencyEventChoice(
              id: 'mediate',
              label: 'Mediate a compromise',
              detail: 'Medium risk · balanced outcome',
              successChance: 0.64,
              reputationImpact: 2,
              trustImpact: 2,
              clubRelationshipImpact: 2,
              successMessage:
                  'The player and club agreed a shared image-rights arrangement.',
              failureMessage:
                  'The mediation failed and both sides were unhappy.',
              failureReputationImpact: -2,
              failureTrustImpact: -2,
              failureClubRelationshipImpact: -3,
            ),
            const AgencyEventChoice(
              id: 'support_club',
              label: 'Support the club position',
              detail: '-4 trust · improve club relationship',
              trustImpact: -4,
              clubRelationshipImpact: 4,
              successMessage: 'The agency accepted the club position.',
            ),
          ],
        ),
      AgencyEventType.agencySponsorship => _agencyDecisionEvent(
          id: eventId,
          type: type,
          title: 'Agency partnership proposal',
          body:
              'A business wants to become the official commercial partner of ${game.agent.agencyName}.',
          season: season,
          week: week,
          expires: expires,
          choices: _agencySponsorshipChoices(game),
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
      AgencyEventType.unexpectedTaxBill => _agencyDecisionEvent(
          id: eventId,
          type: type,
          title: 'Unexpected tax assessment',
          body:
              'A review of recent agency income has produced an unexpected tax demand.',
          season: season,
          week: week,
          expires: expires,
          choices: _taxBillChoices(game),
        ),
      AgencyEventType.legalComplaint => _agencyDecisionEvent(
          id: eventId,
          type: type,
          title: 'Former-client legal complaint',
          body:
              'A former client has challenged the handling of an old representation agreement.',
          season: season,
          week: week,
          expires: expires,
          choices: _legalComplaintChoices(game),
        ),
      AgencyEventType.officeLeaseRenewal => _agencyDecisionEvent(
          id: eventId,
          type: type,
          title: 'Office lease renewal',
          body:
              'The landlord has increased the annual cost of the Level ${game.office.level} office.',
          season: season,
          week: week,
          expires: expires,
          choices: _officeLeaseChoices(game),
        ),
      AgencyEventType.dataBreach => _agencyDecisionEvent(
          id: eventId,
          type: type,
          title: 'Confidential data breach',
          body:
              'Private client and scouting documents may have been accessed without permission.',
          season: season,
          week: week,
          expires: expires,
          choices: _dataBreachChoices(game),
        ),
      AgencyEventType.insuranceRenewal => _agencyDecisionEvent(
          id: eventId,
          type: type,
          title: 'Agency insurance renewal',
          body:
              'Professional liability and office insurance are due for renewal.',
          season: season,
          week: week,
          expires: expires,
          choices: _insuranceChoices(game),
        ),
      AgencyEventType.investorApproach => _agencyDecisionEvent(
          id: eventId,
          type: type,
          title: 'Outside investment approach',
          body:
              'An investor has offered growth capital in exchange for influence over the agency.',
          season: season,
          week: week,
          expires: expires,
          choices: _investorChoices(game),
        ),
      AgencyEventType.reputationConsultant => _agencyDecisionEvent(
          id: eventId,
          type: type,
          title: 'Reputation campaign proposal',
          body:
              'A communications consultant proposes a campaign to improve the agency profile.',
          season: season,
          week: week,
          expires: expires,
          choices: _reputationConsultantChoices(game),
        ),
      AgencyEventType.cashFlowCrisis => _agencyDecisionEvent(
          id: eventId,
          type: type,
          title: 'Short-term cash-flow crisis',
          body: 'Upcoming agency costs exceed the cash currently available.',
          season: season,
          week: week,
          expires: expires,
          choices: _cashFlowChoices(game),
        ),
    };
    return _withPhaseBConsequences(event, game);
  }

  AgencyEvent _withPhaseBConsequences(AgencyEvent event, GameState game) {
    final player = event.playerId == null
        ? null
        : game.players
            .where((candidate) => candidate.id == event.playerId)
            .firstOrNull;
    final relationship = event.clubId == null
        ? 0
        : game.clubAgencyRelationshipScore(event.clubId!);
    final choices = event.choices.map((choice) {
      final impact = _relationshipImpact(event.type, choice.id);
      var chance = choice.successChance;
      if (choice.isUncertain && player != null) {
        final personalityModifier = switch (event.category) {
          AgencyEventCategory.commercial =>
            (player.personality.mediaAppeal - 50) / 250,
          AgencyEventCategory.media =>
            (player.personality.mediaAppeal - 50) / 220,
          AgencyEventCategory.discipline =>
            (((player.personality.professionalism +
                                player.personality.discipline) /
                            2) -
                        50) /
                    250 +
                ((player.agentTrust - 50) / 500),
          AgencyEventCategory.career => ((player.agentTrust - 50) / 350) +
              ((player.personality.ambition - 50) / 500),
          AgencyEventCategory.welfare => ((player.agentTrust - 50) / 400) +
              ((player.personality.professionalism - 50) / 500),
          AgencyEventCategory.agency => 0,
          AgencyEventCategory.finance => 0,
        };
        chance = (chance + personalityModifier + (relationship / 500))
            .clamp(0.15, 0.92);
      }
      return choice.copyWith(
        successChance: chance,
        trustImpact: choice.trustImpact + impact.trust,
        clubRelationshipImpact: choice.clubRelationshipImpact + impact.club,
        failureTrustImpact: choice.failureTrustImpact + impact.failureTrust,
        failureClubRelationshipImpact:
            choice.failureClubRelationshipImpact + impact.failureClub,
      );
    }).toList(growable: false);
    return event.copyWith(choices: choices);
  }

  ({
    int trust,
    int club,
    int failureTrust,
    int failureClub,
  }) _relationshipImpact(AgencyEventType type, String choiceId) {
    const none = (
      trust: 0,
      club: 0,
      failureTrust: 0,
      failureClub: 0,
    );
    return switch ((type, choiceId)) {
      (AgencyEventType.localAdvertising, 'accept') ||
      (AgencyEventType.bootSponsorship, 'accept') =>
        (
          trust: 1,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.localAdvertising, 'negotiate') ||
      (AgencyEventType.bootSponsorship, 'negotiate') =>
        (
          trust: 2,
          club: 0,
          failureTrust: -1,
          failureClub: 0,
        ),
      (AgencyEventType.localAdvertising, 'decline') ||
      (AgencyEventType.bootSponsorship, 'decline') =>
        (
          trust: -1,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.paidAppearance, 'attend') => (
          trust: 1,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.paidAppearance, 'remote') => (
          trust: 1,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.paidAppearance, 'rest') => (
          trust: 2,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.propertyDamage, 'pay') => (
          trust: 3,
          club: 4,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.propertyDamage, 'split') => (
          trust: 1,
          club: 2,
          failureTrust: -1,
          failureClub: -3,
        ),
      (AgencyEventType.propertyDamage, 'refuse') => (
          trust: -3,
          club: -6,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.missedTraining, 'apologise') ||
      (AgencyEventType.nightclubIncident, 'apologise') =>
        (
          trust: 0,
          club: 4,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.missedTraining, 'private') ||
      (AgencyEventType.nightclubIncident, 'private') =>
        (
          trust: 1,
          club: 2,
          failureTrust: -1,
          failureClub: -2,
        ),
      (AgencyEventType.missedTraining, 'defend') ||
      (AgencyEventType.nightclubIncident, 'defend') =>
        (
          trust: 3,
          club: -5,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.playingTimeComplaint, 'meet_manager') => (
          trust: 2,
          club: 2,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.playingTimeComplaint, 'patience') => (
          trust: -1,
          club: 1,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.playingTimeComplaint, 'public_pressure') => (
          trust: 2,
          club: -5,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.transferRequest, 'explore') => (
          trust: 4,
          club: -2,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.transferRequest, 'stay') => (
          trust: -1,
          club: 1,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.transferRequest, 'reject') => (
          trust: -5,
          club: 1,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.specialistTreatment, 'fund') => (
          trust: 5,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.specialistTreatment, 'split') => (
          trust: 2,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.specialistTreatment, 'decline') => (
          trust: -5,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.familyEmergency, 'support') => (
          trust: 6,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.familyEmergency, 'travel') => (
          trust: 7,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      (AgencyEventType.familyEmergency, 'decline') => (
          trust: -7,
          club: 0,
          failureTrust: 0,
          failureClub: 0,
        ),
      _ => none,
    };
  }

  bool _requiresPlayer(AgencyEventType type) => switch (type) {
        AgencyEventType.scoutTravelRequest ||
        AgencyEventType.officeRepair ||
        AgencyEventType.agencySponsorship ||
        AgencyEventType.unexpectedTaxBill ||
        AgencyEventType.legalComplaint ||
        AgencyEventType.officeLeaseRenewal ||
        AgencyEventType.dataBreach ||
        AgencyEventType.insuranceRenewal ||
        AgencyEventType.investorApproach ||
        AgencyEventType.reputationConsultant ||
        AgencyEventType.cashFlowCrisis =>
          false,
        _ => true,
      };

  AgencyEvent _agencyDecisionEvent({
    required String id,
    required AgencyEventType type,
    required String title,
    required String body,
    required int season,
    required int week,
    required int expires,
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
      );

  List<AgencyEventChoice> _agencySponsorshipChoices(GameState game) {
    final amount = max(
      15000,
      (game.office.level * 10000) + (max(0, game.agent.reputation) * 250),
    ).roundToDouble();
    return [
      AgencyEventChoice(
        id: 'accept',
        label: 'Accept the partnership',
        detail: 'Guaranteed income · +1 REP',
        moneyImpact: amount,
        reputationImpact: 1,
        successMessage: 'The agency partnership was signed.',
      ),
      AgencyEventChoice(
        id: 'negotiate',
        label: 'Negotiate premium terms',
        detail: 'Medium risk · 50% more income',
        successChance: 0.55,
        moneyImpact: (amount * 1.5).roundToDouble(),
        reputationImpact: 2,
        successMessage: 'The partner accepted the premium agency package.',
        failureMessage: 'The business withdrew its partnership offer.',
        failureReputationImpact: -1,
      ),
      const AgencyEventChoice(
        id: 'decline',
        label: 'Remain independent',
        detail: 'No income · +1 REP',
        reputationImpact: 1,
        successMessage: 'The agency chose to remain independent.',
      ),
    ];
  }

  List<AgencyEventChoice> _taxBillChoices(GameState game) {
    final bill = max(
      7500,
      game.agent.totalAgentFeesEarned * 0.06,
    ).roundToDouble();
    return [
      AgencyEventChoice(
        id: 'pay',
        label: 'Pay the full assessment',
        detail: 'Close the matter immediately',
        moneyImpact: -bill,
        successMessage: 'The tax assessment was paid in full.',
      ),
      AgencyEventChoice(
        id: 'payment_plan',
        label: 'Negotiate a payment plan',
        detail: 'Pay 65% now · -1 REP',
        moneyImpact: -(bill * 0.65).roundToDouble(),
        reputationImpact: -1,
        successMessage: 'A reduced structured settlement was agreed.',
      ),
      AgencyEventChoice(
        id: 'dispute',
        label: 'Challenge the assessment',
        detail: 'High risk · legal review',
        successChance: 0.46,
        moneyImpact: -(bill * 0.25).roundToDouble(),
        reputationImpact: 1,
        successMessage: 'The challenge substantially reduced the assessment.',
        failureMessage:
            'The challenge failed and penalties were added to the bill.',
        failureMoneyImpact: -(bill * 1.25).roundToDouble(),
        failureReputationImpact: -3,
      ),
    ];
  }

  List<AgencyEventChoice> _legalComplaintChoices(GameState game) {
    final exposure = max(10000, game.office.level * 7500).roundToDouble();
    return [
      AgencyEventChoice(
        id: 'settle',
        label: 'Settle privately',
        detail: 'Guaranteed cost · -1 REP',
        moneyImpact: -exposure,
        reputationImpact: -1,
        successMessage: 'The complaint was settled confidentially.',
      ),
      AgencyEventChoice(
        id: 'lawyer',
        label: 'Hire specialist counsel',
        detail: 'Medium risk · controlled defence',
        successChance: 0.68,
        moneyImpact: -(exposure * 0.60).roundToDouble(),
        reputationImpact: 1,
        successMessage: 'Specialist counsel successfully defended the agency.',
        failureMessage:
            'The legal defence failed and a settlement was ordered.',
        failureMoneyImpact: -(exposure * 1.10).roundToDouble(),
        failureReputationImpact: -2,
      ),
      AgencyEventChoice(
        id: 'contest',
        label: 'Contest it without settlement',
        detail: 'High risk · no initial payment',
        successChance: 0.32,
        reputationImpact: 2,
        successMessage: 'The complaint was dismissed.',
        failureMessage:
            'The complaint succeeded and caused serious reputational damage.',
        failureMoneyImpact: -(exposure * 1.50).roundToDouble(),
        failureReputationImpact: -4,
      ),
    ];
  }

  List<AgencyEventChoice> _officeLeaseChoices(GameState game) {
    final cost = (6000 * game.office.level).toDouble();
    return [
      AgencyEventChoice(
        id: 'renew',
        label: 'Renew the lease',
        detail: 'Guaranteed annual office cost',
        moneyImpact: -cost,
        successMessage: 'The office lease was renewed.',
      ),
      AgencyEventChoice(
        id: 'negotiate',
        label: 'Negotiate the increase',
        detail: 'Medium risk · seek 30% reduction',
        successChance: 0.62,
        moneyImpact: -(cost * 0.70).roundToDouble(),
        successMessage: 'The landlord accepted a lower renewal price.',
        failureMessage: 'The landlord rejected the reduction.',
        failureMoneyImpact: -cost,
        failureReputationImpact: -1,
      ),
      AgencyEventChoice(
        id: 'relocate',
        label: 'Relocate agency operations',
        detail: 'Higher one-time cost · protect independence',
        moneyImpact: -(cost * 1.20).roundToDouble(),
        reputationImpact: 1,
        successMessage: 'The agency relocated without disrupting clients.',
      ),
    ];
  }

  List<AgencyEventChoice> _dataBreachChoices(GameState game) {
    final responseCost = (10000 * game.office.level).toDouble();
    return [
      AgencyEventChoice(
        id: 'security',
        label: 'Hire a security team',
        detail: 'Full response · +1 REP',
        moneyImpact: -responseCost,
        reputationImpact: 1,
        successMessage: 'The breach was contained and systems were secured.',
      ),
      AgencyEventChoice(
        id: 'disclose',
        label: 'Disclose and notify clients',
        detail: 'Transparent response · +2 REP',
        moneyImpact: -(responseCost * 0.70).roundToDouble(),
        reputationImpact: 2,
        successMessage: 'Clients respected the transparent response.',
      ),
      AgencyEventChoice(
        id: 'conceal',
        label: 'Try to conceal the breach',
        detail: 'High risk · no initial cost',
        successChance: 0.45,
        successMessage: 'The breach remained private.',
        failureMessage: 'The concealed breach became public.',
        failureMoneyImpact: -(responseCost * 1.50).roundToDouble(),
        failureReputationImpact: -5,
      ),
    ];
  }

  List<AgencyEventChoice> _insuranceChoices(GameState game) {
    final premium = (5000 * game.office.level).toDouble();
    return [
      AgencyEventChoice(
        id: 'premium',
        label: 'Buy comprehensive cover',
        detail: 'Full premium · +1 REP',
        moneyImpact: -premium,
        reputationImpact: 1,
        successMessage: 'Comprehensive agency insurance was renewed.',
      ),
      AgencyEventChoice(
        id: 'basic',
        label: 'Choose basic cover',
        detail: 'Half premium · limited protection',
        moneyImpact: -(premium * 0.50).roundToDouble(),
        successMessage: 'Basic agency insurance was renewed.',
      ),
      const AgencyEventChoice(
        id: 'uninsured',
        label: 'Operate without cover',
        detail: 'No cost · -2 REP',
        reputationImpact: -2,
        successMessage: 'The agency remained uninsured.',
      ),
    ];
  }

  List<AgencyEventChoice> _investorChoices(GameState game) {
    final capital = max(
      50000,
      (game.office.level * 75000) + (max(0, game.agent.reputation) * 500),
    ).roundToDouble();
    return [
      AgencyEventChoice(
        id: 'control',
        label: 'Accept the full investment',
        detail: 'Maximum cash · -4 REP',
        moneyImpact: capital,
        reputationImpact: -4,
        successMessage:
            'The investor supplied capital and gained significant influence.',
      ),
      AgencyEventChoice(
        id: 'minority',
        label: 'Negotiate a minority deal',
        detail: 'Medium risk · retain control',
        successChance: 0.58,
        moneyImpact: (capital * 0.60).roundToDouble(),
        reputationImpact: 2,
        successMessage: 'A minority investment was agreed on agency terms.',
        failureMessage: 'The investor rejected the minority structure.',
        failureReputationImpact: -1,
      ),
      const AgencyEventChoice(
        id: 'reject',
        label: 'Reject outside influence',
        detail: 'No cash · +2 REP',
        reputationImpact: 2,
        successMessage: 'The agency rejected the investment approach.',
      ),
    ];
  }

  List<AgencyEventChoice> _reputationConsultantChoices(GameState game) {
    final cost = (8000 * game.office.level).toDouble();
    return [
      AgencyEventChoice(
        id: 'full',
        label: 'Launch the full campaign',
        detail: 'High cost · +4 REP',
        moneyImpact: -cost,
        reputationImpact: 4,
        successMessage: 'The campaign significantly raised the agency profile.',
      ),
      AgencyEventChoice(
        id: 'digital',
        label: 'Try a digital-only campaign',
        detail: 'Medium risk · half cost',
        successChance: 0.60,
        moneyImpact: -(cost * 0.50).roundToDouble(),
        reputationImpact: 3,
        successMessage: 'The digital campaign reached a large audience.',
        failureMessage: 'The campaign attracted negative attention.',
        failureMoneyImpact: -(cost * 0.50).roundToDouble(),
        failureReputationImpact: -2,
      ),
      const AgencyEventChoice(
        id: 'decline',
        label: 'Decline the campaign',
        detail: 'No cost or reputation change',
        successMessage: 'The consultant proposal was declined.',
      ),
    ];
  }

  List<AgencyEventChoice> _cashFlowChoices(GameState game) {
    final needed = max(20000, game.agent.money.abs() + 15000).roundToDouble();
    return [
      AgencyEventChoice(
        id: 'loan',
        label: 'Take emergency finance',
        detail: 'Restore cash · -3 REP',
        moneyImpact: needed,
        reputationImpact: -3,
        successMessage: 'Emergency finance stabilised the agency.',
      ),
      AgencyEventChoice(
        id: 'bridge',
        label: 'Seek private bridge funding',
        detail: 'Medium risk · smaller cash injection',
        successChance: 0.60,
        moneyImpact: (needed * 0.60).roundToDouble(),
        reputationImpact: -1,
        successMessage: 'Private bridge funding was secured.',
        failureMessage: 'The funding request was rejected.',
        failureReputationImpact: -2,
      ),
      AgencyEventChoice(
        id: 'sell',
        label: 'Sell agency equipment',
        detail: 'Immediate limited cash · -1 REP',
        moneyImpact: (needed * 0.35).roundToDouble(),
        reputationImpact: -1,
        successMessage: 'Non-essential equipment was sold for immediate cash.',
      ),
    ];
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
