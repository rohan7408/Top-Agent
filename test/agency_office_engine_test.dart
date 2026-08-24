import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/contract.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/simulation/engines/agency_office_engine.dart';

void main() {
  test('office engine connects scout payroll, commission, and discovery', () {
    final game = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final talent = game.availableTalents.first.copyWith(
      agentId: game.agent.id,
      isRecruited: true,
      clubId: game.clubs.first.id,
      salary: 20000,
      contractEndSeason: 4,
    );
    final scout = game.scouts.first.copyWith(agencyId: game.agent.id);
    final prepared = game.copyWith(
      players: [
        talent,
        ...game.players.where((player) => player.id != talent.id),
      ],
      scouts: [scout, ...game.scouts.skip(1)],
      contracts: [
        Contract(
          id: 'represented-contract',
          playerId: talent.id,
          clubId: game.clubs.first.id,
          salary: 20000,
          agentFee: 100000,
          contractLength: 3,
          startSeason: 1,
          endSeason: 4,
          salaryCommissionRate: 0.02,
        ),
      ],
    );

    AgencyOfficeWeekResult? discoveryWeek;
    for (var week = 2; week <= 20; week++) {
      final result = const AgencyOfficeEngine().processWeek(
        prepared,
        nextSeason: 1,
        nextWeek: week,
        seed: 42,
      );
      if (result.talentsDiscovered > 0) {
        discoveryWeek = result;
        break;
      }
    }

    expect(discoveryWeek, isNotNull);
    expect(discoveryWeek!.salaryCommission, 400);
    expect(discoveryWeek.scoutPayroll, scout.salary);
    expect(
      discoveryWeek.state.agent.money,
      prepared.agent.money + 400 - scout.salary,
    );
    expect(discoveryWeek.state.availableTalents, hasLength(2));
    final scoutedProspect = discoveryWeek.state.availableTalents
        .firstWhere((player) => player.scoutedByScoutId != null);
    expect(scoutedProspect.scoutedByScoutId, scout.id);
    expect(discoveryWeek.state.canViewPotential(scoutedProspect), isTrue);
    final legacyJson = discoveryWeek.state.toJson();
    final legacyPlayers = (legacyJson['players']! as List<Object?>)
        .map((item) => Map<String, Object?>.from(item! as Map))
        .toList(growable: false);
    legacyPlayers
        .firstWhere((item) => item['id'] == scoutedProspect.id)
        .remove('scoutedByScoutId');
    final migrated = GameState.fromJson({
      ...legacyJson,
      'players': legacyPlayers,
    });
    expect(
      migrated.canViewPotential(
        migrated.players
            .firstWhere((player) => player.id == scoutedProspect.id),
      ),
      isTrue,
    );
    expect(
      discoveryWeek.state.canViewPotential(
        discoveryWeek.state.availableTalents
            .firstWhere((player) => player.scoutedByScoutId == null),
      ),
      isFalse,
    );
    expect(
      discoveryWeek.state.availableTalents.every(
        (player) => player.age <= 21 && player.ability <= 45,
      ),
      isTrue,
    );
    expect(discoveryWeek.state.scouts.where((item) => item.isCandidate),
        hasLength(4));
  });
}
