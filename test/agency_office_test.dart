import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/agency_office.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/scout_candidate_generator.dart';

void main() {
  test('office tiers increase capacity and commercial rates', () {
    const starter = AgencyOffice();
    const top = AgencyOffice(level: 5);

    expect(starter.clientCapacity, 3);
    expect(starter.scoutCapacity, 1);
    expect(starter.salaryCommissionRate, 0.02);
    expect(starter.agentFeeRate, 0.08);
    expect(top.clientCapacity, 50);
    expect(top.scoutCapacity, 8);
    expect(top.salaryCommissionRate, 0.10);
    expect(top.agentFeeRate, 0.18);
    expect(top.canUpgrade, isFalse);
  });

  test('negative reputation produces accessible low-tier scout candidates', () {
    final candidates = const ScoutCandidateGenerator().generateInitial(
      reputation: -20,
      seed: 7,
      idPrefix: 'negative-rep',
    );

    expect(candidates, hasLength(4));
    expect(candidates.first.requiredReputation, lessThanOrEqualTo(-20));
    expect(candidates.every((scout) => scout.ability <= 51), isTrue);
  });

  test('client capacity counts every represented player', () {
    final game = const GameFactory().createNewGame(
      agentName: 'Capacity Agent',
      agencyName: 'Small Office',
      agentAge: 31,
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final represented = game.players.take(3).map(
          (player) => player.copyWith(
            agentId: game.agent.id,
            isRecruited: true,
          ),
        );
    final prepared = game.copyWith(
      players: [...represented, ...game.players.skip(3)],
    );

    expect(prepared.representedPlayers, hasLength(3));
    expect(prepared.isAgencyAtClientCapacity, isTrue);
  });

  test('current schema migrates only scouts from legacy staff saves', () {
    final game = const GameFactory().createNewGame(
      agentName: 'Legacy Agent',
      agencyName: 'Legacy Agency',
      agentAge: 40,
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final json = Map<String, Object?>.from(game.toJson())
      ..remove('office')
      ..remove('scouts')
      ..['staff'] = [
        {
          'id': 'legacy-scout',
          'name': 'Old Scout',
          'role': 'scout',
          'ability': 67,
          'salary': 900,
          'agencyId': game.agent.id,
        },
        {
          'id': 'legacy-coach',
          'name': 'Old Coach',
          'role': 'coach',
          'ability': 80,
          'salary': 1200,
          'agencyId': game.agent.id,
        },
      ];

    final migrated = GameState.fromJson(json);

    expect(migrated.schemaVersion, GameState.currentSchemaVersion);
    expect(migrated.trainingGround.level, 1);
    expect(migrated.scouts, hasLength(1));
    expect(migrated.scouts.single.name, 'Old Scout');
    expect(migrated.hiredScouts, hasLength(1));
    expect(migrated.office.scoutCapacity, greaterThanOrEqualTo(1));
  });
}
