import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/data/database/app_database.dart';
import 'package:football_agent/data/repositories/drift_game_save_repository.dart';
import 'package:football_agent/domain/services/game_factory.dart';

void main() {
  test('Drift autosave persists and replaces a complete career state',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftGameSaveRepository(database);
    final game = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );

    await repository.save(game);
    final summary = await repository.latestSummary();
    final restored = await repository.loadLatest();

    expect(summary, isNotNull);
    expect(summary!.agencyName, 'North Star Sports');
    expect(summary.seasonLabel, '2025/2026');
    expect(summary.currentWeek, 1);
    expect(restored, isNotNull);
    expect(restored!.players.length, game.players.length);
    expect(restored.clubs.length, game.clubs.length);
    expect(restored.fixtures.length, game.fixtures.length);
    expect(restored.scouts.length, game.scouts.length);
    expect(restored.office.level, game.office.level);

    final advanced = game.copyWith(
      agent: game.agent.copyWith(currentWeek: 7, money: 123456),
    );
    await repository.save(advanced);
    final rows = await database.select(database.careerSaves).get();
    final replaced = await repository.loadLatest();

    expect(rows, hasLength(1));
    expect(replaced!.currentWeek, 7);
    expect(replaced.agent.money, 123456);

    await repository.deleteAll();
    expect(await repository.latestSummary(), isNull);
  });
}
