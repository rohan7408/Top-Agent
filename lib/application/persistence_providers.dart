import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/drift_game_save_repository.dart';
import '../domain/models/saved_career_summary.dart';
import '../domain/repositories/game_save_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final gameSaveRepositoryProvider = Provider<GameSaveRepository>(
  (ref) => DriftGameSaveRepository(ref.watch(appDatabaseProvider)),
);

final savedCareerSummaryProvider = FutureProvider<SavedCareerSummary?>(
  (ref) => ref.watch(gameSaveRepositoryProvider).latestSummary(),
);
