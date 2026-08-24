import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/services/agency_trust_calculator.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/simulation/engines/agency_trust_engine.dart';

void main() {
  const calculator = AgencyTrustCalculator();

  test('low-rated people trust a developing agency more readily', () {
    final lowRatedPlayer = calculator.initialPlayerTrust(
      playerAbility: 42,
      reputation: 20,
      officeLevel: 1,
    );
    final elitePlayer = calculator.initialPlayerTrust(
      playerAbility: 90,
      reputation: 20,
      officeLevel: 1,
    );
    final lowRatedScout = calculator.initialScoutTrust(
      scoutAbility: 42,
      reputation: 20,
      officeLevel: 1,
    );
    final eliteScout = calculator.initialScoutTrust(
      scoutAbility: 90,
      reputation: 20,
      officeLevel: 1,
    );

    expect(lowRatedPlayer, greaterThan(elitePlayer));
    expect(lowRatedScout, greaterThan(eliteScout));
    expect(lowRatedScout, greaterThanOrEqualTo(80));
    expect(eliteScout, lessThan(80));
  });

  test('reputation, office level, and relationship time build trust', () {
    final basic = calculator.initialPlayerTrust(
      playerAbility: 70,
      reputation: 10,
      officeLevel: 1,
    );
    final established = calculator.initialPlayerTrust(
      playerAbility: 70,
      reputation: 160,
      officeLevel: 4,
    );
    final afterTime = calculator.updatePlayerTrust(
      currentTrust: basic,
      playerAbility: 70,
      reputation: 160,
      officeLevel: 4,
      relationshipWeeks: 100,
    );

    expect(established, greaterThan(basic));
    expect(afterTime, greaterThan(basic));
    expect(afterTime, lessThanOrEqualTo(AgencyTrustCalculator.maximumTrust));
  });

  test('a client below 50 trust can leave the agency', () {
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final talent = base.availableTalents.first;
    final represented = talent.copyWith(
      agentId: base.agent.id,
      isRecruited: true,
      agentTrust: 0,
      agencyRelationshipWeeks: 10,
    );
    final prepared = base.copyWith(
      agent: base.agent.copyWith(reputation: -300),
      players: base.players
          .map((player) => player.id == talent.id ? represented : player)
          .toList(growable: false),
    );
    const engine = AgencyTrustEngine();

    final result = List.generate(
      100,
      (seed) => engine.processWeek(
        prepared,
        nextSeason: 1,
        nextWeek: 2,
        seed: seed,
      ),
    ).firstWhere((week) => week.clientsLeft == 1);

    expect(result.clientsLeft, 1);
    expect(result.state.representedPlayers, isEmpty);
    expect(
      result.state.availableTalents.any((player) => player.id == talent.id),
      isFalse,
    );
    expect(result.state.emails.first.subject, contains('leaves the agency'));
  });
}
