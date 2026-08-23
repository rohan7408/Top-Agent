import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CareerSaves extends Table {
  TextColumn get slotId => text()();
  TextColumn get agentName => text()();
  TextColumn get agencyName => text()();
  IntColumn get currentSeason => integer()();
  IntColumn get currentWeek => integer()();
  IntColumn get careerStartYear => integer()();
  IntColumn get gameSchemaVersion => integer()();
  TextColumn get gameJson => text()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {slotId};
}

@DriftDatabase(tables: [CareerSaves])
final class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'touchline_agent'));

  @override
  int get schemaVersion => 1;

  Future<void> upsertCareer(CareerSavesCompanion save) async {
    await into(careerSaves).insertOnConflictUpdate(save);
  }

  Future<CareerSave?> latestCareer() {
    return (select(careerSaves)
          ..orderBy([(row) => OrderingTerm.desc(row.savedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> deleteCareers() => delete(careerSaves).go();
}
