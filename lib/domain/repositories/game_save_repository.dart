import '../models/game_state.dart';
import '../models/saved_career_summary.dart';

class IncompatibleSaveException implements Exception {
  const IncompatibleSaveException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class GameSaveRepository {
  Future<void> save(GameState game);

  Future<GameState?> loadLatest();

  Future<SavedCareerSummary?> latestSummary();

  Future<void> deleteAll();
}
