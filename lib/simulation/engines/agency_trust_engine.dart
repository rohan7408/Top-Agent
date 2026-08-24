import 'dart:math';

import '../../domain/models/club_offer.dart';
import '../../domain/models/game_email.dart';
import '../../domain/models/game_state.dart';
import '../../domain/services/agency_trust_calculator.dart';

class AgencyTrustWeekResult {
  const AgencyTrustWeekResult({
    required this.state,
    required this.clientsLeft,
  });

  final GameState state;
  final int clientsLeft;
}

class AgencyTrustEngine {
  const AgencyTrustEngine({
    this.calculator = const AgencyTrustCalculator(),
  });

  final AgencyTrustCalculator calculator;

  GameState initializeExistingRelationships(GameState game) {
    final players = game.players.map((player) {
      if (player.agentId != game.agent.id ||
          !player.isRecruited ||
          player.agencyRelationshipWeeks > 0) {
        return player;
      }
      return player.copyWith(
        agentTrust: calculator.initialPlayerTrust(
          playerAbility: player.ability,
          reputation: game.agent.reputation,
          officeLevel: game.office.level,
        ),
        agencyRelationshipWeeks: 1,
      );
    }).toList(growable: false);
    final scouts = game.scouts.map((scout) {
      if (scout.agencyId != game.agent.id || scout.weeksWithAgency > 0) {
        return scout;
      }
      return scout.copyWith(
        agencyTrust: calculator.initialScoutTrust(
          scoutAbility: scout.ability,
          reputation: game.agent.reputation,
          officeLevel: game.office.level,
        ),
        weeksWithAgency: 1,
      );
    }).toList(growable: false);
    return game.copyWith(players: players, scouts: scouts);
  }

  AgencyTrustWeekResult processWeek(
    GameState game, {
    required int nextSeason,
    required int nextWeek,
    required int seed,
  }) {
    final initialized = initializeExistingRelationships(game);
    final departedClients = <({String id, String name})>[];
    final players = initialized.players.map((player) {
      if (player.agentId != initialized.agent.id || !player.isRecruited) {
        return player;
      }
      final relationshipWeeks = player.agencyRelationshipWeeks + 1;
      final trust = calculator.updatePlayerTrust(
        currentTrust: player.agentTrust,
        playerAbility: player.ability,
        reputation: initialized.agent.reputation,
        officeLevel: initialized.office.level,
        relationshipWeeks: relationshipWeeks,
      );
      final exitChance = calculator.clientExitChance(
        min(player.agentTrust, trust),
      );
      final roll = Random(seed ^ _stableHash(player.id)).nextDouble();
      if (exitChance > 0 && roll < exitChance) {
        departedClients.add((id: player.id, name: player.name));
        return player.copyWith(
          clearAgentId: true,
          agentTrust: trust,
          agencyRelationshipWeeks: 0,
        );
      }
      return player.copyWith(
        agentTrust: trust,
        agencyRelationshipWeeks: relationshipWeeks,
      );
    }).toList(growable: false);
    final scouts = initialized.scouts.map((scout) {
      final employed = scout.agencyId == initialized.agent.id;
      final weeks = employed ? scout.weeksWithAgency + 1 : 0;
      return scout.copyWith(
        agencyTrust: calculator.updateScoutTrust(
          currentTrust: scout.agencyTrust,
          scoutAbility: scout.ability,
          reputation: initialized.agent.reputation,
          officeLevel: initialized.office.level,
          employmentWeeks: weeks,
        ),
        weeksWithAgency: weeks,
      );
    }).toList(growable: false);
    final departedIds = departedClients.map((client) => client.id).toSet();
    final departureEmails = [
      for (final client in departedClients)
        GameEmail(
          id: 'email-client-left-s$nextSeason-w$nextWeek-${client.id}',
          type: GameEmailType.world,
          subject: '${client.name} leaves the agency',
          body:
              '${client.name} no longer trusted the agency enough to continue the representation agreement.',
          season: nextSeason,
          week: nextWeek,
        ),
    ];
    return AgencyTrustWeekResult(
      state: initialized.copyWith(
        players: players,
        scouts: scouts,
        offers: initialized.offers
            .where(
              (offer) =>
                  !departedIds.contains(offer.playerId) ||
                  offer.status != ClubOfferStatus.pending,
            )
            .toList(growable: false),
        trainingPlans: initialized.trainingPlans
            .where((plan) => !departedIds.contains(plan.playerId))
            .toList(growable: false),
        emails: [...departureEmails, ...initialized.emails],
      ),
      clientsLeft: departedClients.length,
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
