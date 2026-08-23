import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/game_state.dart';
import '../../domain/models/saved_career_summary.dart';
import '../../domain/repositories/game_save_repository.dart';
import '../database/app_database.dart';

class DriftGameSaveRepository implements GameSaveRepository {
  const DriftGameSaveRepository(this.database);

  static const autosaveSlotId = 'autosave';

  final AppDatabase database;

  @override
  Future<void> save(GameState game) {
    return database.upsertCareer(
      CareerSavesCompanion(
        slotId: const Value(autosaveSlotId),
        agentName: Value(game.agent.name),
        agencyName: Value(game.agent.agencyName),
        currentSeason: Value(game.currentSeason),
        currentWeek: Value(game.currentWeek),
        careerStartYear: Value(game.careerStartYear),
        gameSchemaVersion: Value(game.schemaVersion),
        gameJson: Value(jsonEncode(game.toJson())),
        savedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<GameState?> loadLatest() async {
    final row = await database.latestCareer();
    if (row == null) return null;
    if (row.gameSchemaVersion > GameState.currentSchemaVersion) {
      throw IncompatibleSaveException(
        'This career was created by a newer game version.',
      );
    }
    final decoded = jsonDecode(row.gameJson);
    if (decoded is! Map) {
      throw const FormatException('Saved career has an invalid root object.');
    }
    return GameState.fromJson(decoded.cast<String, Object?>());
  }

  @override
  Future<SavedCareerSummary?> latestSummary() async {
    final row = await database.latestCareer();
    if (row == null) return null;
    return SavedCareerSummary(
      slotId: row.slotId,
      agentName: row.agentName,
      agencyName: row.agencyName,
      currentSeason: row.currentSeason,
      currentWeek: row.currentWeek,
      careerStartYear: row.careerStartYear,
      savedAt: row.savedAt.toUtc(),
    );
  }

  @override
  Future<void> deleteAll() => database.deleteCareers();
}
