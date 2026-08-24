import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/agency_event.dart';
import 'package:football_agent/domain/models/club_agency_relationship.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/models/player.dart';
import 'package:football_agent/domain/models/player_personality.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/simulation/engines/random_event_engine.dart';

void main() {
  const engine = RandomEventEngine();

  test('event decisions update trust and club relationship', () {
    final game = _preparedGame();
    final client = game.representedPlayers.single;
    final generated = engine.processWeek(
      game,
      season: 1,
      week: 8,
      seed: 41,
      forceType: AgencyEventType.propertyDamage,
    );
    final event = generated.state.pendingAgencyEvents.single;

    final resolution = engine.resolve(
      generated.state,
      eventId: event.id,
      choiceId: 'refuse',
    )!;
    final updatedClient =
        resolution.state.players.firstWhere((player) => player.id == client.id);

    expect(updatedClient.agentTrust, client.agentTrust - 3);
    expect(
      resolution.state.clubAgencyRelationshipScore(client.clubId!),
      -6,
    );
    expect(resolution.event.resolvedTrustImpact, -3);
    expect(resolution.event.resolvedClubRelationshipImpact, -6);
  });

  test('media appeal and trust alter commercial negotiation probability', () {
    final lowGame = _preparedGame(mediaAppeal: 10, trust: 30);
    final highGame = _preparedGame(mediaAppeal: 90, trust: 180);

    AgencyEventChoice negotiateChoice(GameState game) => engine
        .processWeek(
          game,
          season: 1,
          week: 8,
          seed: 8,
          forceType: AgencyEventType.bootSponsorship,
        )
        .state
        .pendingAgencyEvents
        .single
        .choices
        .firstWhere((choice) => choice.id == 'negotiate');

    expect(
      negotiateChoice(highGame).successChance,
      greaterThan(negotiateChoice(lowGame).successChance),
    );
  });

  test('personality and club relationships persist with legacy defaults', () {
    final game = _preparedGame().copyWith(
      clubAgencyRelationships: const [
        ClubAgencyRelationship(clubId: 'club-premier-1', score: 27),
      ],
    );
    final restored = GameState.fromJson(game.toJson());
    final restoredClient = restored.representedPlayers.single;

    expect(restoredClient.personality.professionalism, 70);
    expect(restoredClient.agentTrust, 60);
    expect(restoredClient.agencyRelationshipWeeks, 12);
    expect(restored.clubAgencyRelationshipScore('club-premier-1'), 27);

    final legacyJson = Map<String, Object?>.from(restoredClient.toJson())
      ..remove('personality')
      ..remove('agentTrust')
      ..remove('agencyRelationshipWeeks');
    final legacyPlayer = Player.fromJson(legacyJson);
    expect(legacyPlayer.personality.professionalism, 50);
    expect(legacyPlayer.agentTrust, 100);
    expect(legacyPlayer.agencyRelationshipWeeks, 0);
  });
}

GameState _preparedGame({int mediaAppeal = 60, int trust = 60}) {
  final game = const GameFactory().createNewGame(
    agentName: 'Alex Morgan',
    agencyName: 'North Star Sports',
    agentAge: 34,
    createdAt: DateTime.utc(2026, 8, 24),
  );
  final talent = game.availableTalents.first;
  final represented = talent.copyWith(
    agentId: game.agent.id,
    isRecruited: true,
    clubId: game.clubs.first.id,
    salary: 1500,
    agentTrust: trust,
    agencyRelationshipWeeks: 12,
    personality: PlayerPersonality(
      professionalism: 70,
      discipline: 65,
      ambition: 75,
      mediaAppeal: mediaAppeal,
    ),
  );
  return game.copyWith(
    players: game.players
        .map((player) => player.id == talent.id ? represented : player)
        .toList(growable: false),
  );
}
