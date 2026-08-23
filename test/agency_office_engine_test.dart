import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/contract.dart';
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
    expect(discoveryWeek.state.scouts.where((item) => item.isCandidate),
        hasLength(4));
  });
}
