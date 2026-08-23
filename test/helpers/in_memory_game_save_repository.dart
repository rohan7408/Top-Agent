import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/models/saved_career_summary.dart';
import 'package:football_agent/domain/repositories/game_save_repository.dart';

class InMemoryGameSaveRepository implements GameSaveRepository {
  InMemoryGameSaveRepository({this.saveDelay = Duration.zero});

  final Duration saveDelay;
  GameState? _game;
  DateTime? _savedAt;

  @override
  Future<void> save(GameState game) async {
    if (saveDelay > Duration.zero) await Future<void>.delayed(saveDelay);
    _game = GameState.fromJson(game.toJson());
    _savedAt = DateTime.now().toUtc();
  }

  @override
  Future<GameState?> loadLatest() async => _game;

  @override
  Future<SavedCareerSummary?> latestSummary() async {
    final game = _game;
    if (game == null) return null;
    return SavedCareerSummary(
      slotId: 'autosave',
      agentName: game.agent.name,
      agencyName: game.agent.agencyName,
      currentSeason: game.currentSeason,
      currentWeek: game.currentWeek,
      careerStartYear: game.careerStartYear,
      savedAt: _savedAt ?? DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> deleteAll() async {
    _game = null;
    _savedAt = null;
  }
}
