import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/game_email.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/simulation/game_engine.dart';

void main() {
  final factory = const GameFactory();
  final engine = const GameEngine();

  test('weekly processing charges each club exactly one wage bill', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );

    final result = engine.simulateOneWeek(game);

    for (final before in game.clubs) {
      final after = result.state.clubById(before.id)!;
      expect(after.balance, before.balance - before.totalSalary);
    }
    expect(result.summary.transfersCompleted, 0);
  });

  test('AI clubs complete connected transfers only in a transfer window', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final windowGame = game.copyWith(
      agent: game.agent.copyWith(currentWeek: 20),
    );

    final result = engine.simulateOneWeek(windowGame);

    expect(result.summary.transfersCompleted, inInclusiveRange(1, 2));
    expect(
        result.state.transfers, hasLength(result.summary.transfersCompleted));
    expect(
      result.state.emails.where(
        (email) => email.type == GameEmailType.transfer,
      ),
      isEmpty,
      reason: 'AI transfers do not belong in the agent inbox.',
    );
    expect(result.summary.trainingGroundTalents, 1);
    expect(result.state.players, hasLength(game.players.length + 1));
    for (final transfer in result.state.transfers) {
      final player = result.state.players
          .firstWhere((item) => item.id == transfer.playerId);
      expect(player.clubId, transfer.toClubId);
      expect(result.state.clubById(transfer.toClubId)!.playerIds,
          contains(player.id));
      expect(result.state.clubById(transfer.fromClubId)!.playerIds,
          isNot(contains(player.id)));
      expect(
          result.state.contracts
              .any((contract) => contract.playerId == player.id),
          isTrue);
      expect(
          result.state.contractEvents
              .any((event) => event.playerId == player.id),
          isTrue);
    }
  });

  test('clubs renew eligible expiring contracts in the main window', () {
    final game = factory.createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final club = game.clubs.first;
    final strongest = game.playersForClub(club.id)
      ..sort((first, second) => second.ability.compareTo(first.ability));
    final players = [...game.players];
    final index = players.indexWhere((item) => item.id == strongest.first.id);
    players[index] = players[index].copyWith(contractEndSeason: 1);
    final windowGame = game.copyWith(
      agent: game.agent.copyWith(currentWeek: 40),
      players: players,
    );

    final result = engine.simulateOneWeek(windowGame);
    final renewed = result.state.players
        .firstWhere((item) => item.id == strongest.first.id);

    expect(result.summary.contractsRenewed, greaterThan(0));
    expect(renewed.contractEndSeason, greaterThan(1));
    expect(
        result.state.contracts
            .any((contract) => contract.playerId == renewed.id),
        isTrue);
    expect(
        result.state.contractEvents
            .any((event) => event.playerId == renewed.id),
        isTrue);
  });
}
