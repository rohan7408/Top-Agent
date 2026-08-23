// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CareerSavesTable extends CareerSaves
    with TableInfo<$CareerSavesTable, CareerSave> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CareerSavesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slotIdMeta = const VerificationMeta('slotId');
  @override
  late final GeneratedColumn<String> slotId = GeneratedColumn<String>(
      'slot_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agentNameMeta =
      const VerificationMeta('agentName');
  @override
  late final GeneratedColumn<String> agentName = GeneratedColumn<String>(
      'agent_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _agencyNameMeta =
      const VerificationMeta('agencyName');
  @override
  late final GeneratedColumn<String> agencyName = GeneratedColumn<String>(
      'agency_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentSeasonMeta =
      const VerificationMeta('currentSeason');
  @override
  late final GeneratedColumn<int> currentSeason = GeneratedColumn<int>(
      'current_season', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currentWeekMeta =
      const VerificationMeta('currentWeek');
  @override
  late final GeneratedColumn<int> currentWeek = GeneratedColumn<int>(
      'current_week', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _careerStartYearMeta =
      const VerificationMeta('careerStartYear');
  @override
  late final GeneratedColumn<int> careerStartYear = GeneratedColumn<int>(
      'career_start_year', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _gameSchemaVersionMeta =
      const VerificationMeta('gameSchemaVersion');
  @override
  late final GeneratedColumn<int> gameSchemaVersion = GeneratedColumn<int>(
      'game_schema_version', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _gameJsonMeta =
      const VerificationMeta('gameJson');
  @override
  late final GeneratedColumn<String> gameJson = GeneratedColumn<String>(
      'game_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        slotId,
        agentName,
        agencyName,
        currentSeason,
        currentWeek,
        careerStartYear,
        gameSchemaVersion,
        gameJson,
        savedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'career_saves';
  @override
  VerificationContext validateIntegrity(Insertable<CareerSave> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slot_id')) {
      context.handle(_slotIdMeta,
          slotId.isAcceptableOrUnknown(data['slot_id']!, _slotIdMeta));
    } else if (isInserting) {
      context.missing(_slotIdMeta);
    }
    if (data.containsKey('agent_name')) {
      context.handle(_agentNameMeta,
          agentName.isAcceptableOrUnknown(data['agent_name']!, _agentNameMeta));
    } else if (isInserting) {
      context.missing(_agentNameMeta);
    }
    if (data.containsKey('agency_name')) {
      context.handle(
          _agencyNameMeta,
          agencyName.isAcceptableOrUnknown(
              data['agency_name']!, _agencyNameMeta));
    } else if (isInserting) {
      context.missing(_agencyNameMeta);
    }
    if (data.containsKey('current_season')) {
      context.handle(
          _currentSeasonMeta,
          currentSeason.isAcceptableOrUnknown(
              data['current_season']!, _currentSeasonMeta));
    } else if (isInserting) {
      context.missing(_currentSeasonMeta);
    }
    if (data.containsKey('current_week')) {
      context.handle(
          _currentWeekMeta,
          currentWeek.isAcceptableOrUnknown(
              data['current_week']!, _currentWeekMeta));
    } else if (isInserting) {
      context.missing(_currentWeekMeta);
    }
    if (data.containsKey('career_start_year')) {
      context.handle(
          _careerStartYearMeta,
          careerStartYear.isAcceptableOrUnknown(
              data['career_start_year']!, _careerStartYearMeta));
    } else if (isInserting) {
      context.missing(_careerStartYearMeta);
    }
    if (data.containsKey('game_schema_version')) {
      context.handle(
          _gameSchemaVersionMeta,
          gameSchemaVersion.isAcceptableOrUnknown(
              data['game_schema_version']!, _gameSchemaVersionMeta));
    } else if (isInserting) {
      context.missing(_gameSchemaVersionMeta);
    }
    if (data.containsKey('game_json')) {
      context.handle(_gameJsonMeta,
          gameJson.isAcceptableOrUnknown(data['game_json']!, _gameJsonMeta));
    } else if (isInserting) {
      context.missing(_gameJsonMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta,
          savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slotId};
  @override
  CareerSave map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CareerSave(
      slotId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slot_id'])!,
      agentName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agent_name'])!,
      agencyName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}agency_name'])!,
      currentSeason: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_season'])!,
      currentWeek: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_week'])!,
      careerStartYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}career_start_year'])!,
      gameSchemaVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}game_schema_version'])!,
      gameJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}game_json'])!,
      savedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $CareerSavesTable createAlias(String alias) {
    return $CareerSavesTable(attachedDatabase, alias);
  }
}

class CareerSave extends DataClass implements Insertable<CareerSave> {
  final String slotId;
  final String agentName;
  final String agencyName;
  final int currentSeason;
  final int currentWeek;
  final int careerStartYear;
  final int gameSchemaVersion;
  final String gameJson;
  final DateTime savedAt;
  const CareerSave(
      {required this.slotId,
      required this.agentName,
      required this.agencyName,
      required this.currentSeason,
      required this.currentWeek,
      required this.careerStartYear,
      required this.gameSchemaVersion,
      required this.gameJson,
      required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slot_id'] = Variable<String>(slotId);
    map['agent_name'] = Variable<String>(agentName);
    map['agency_name'] = Variable<String>(agencyName);
    map['current_season'] = Variable<int>(currentSeason);
    map['current_week'] = Variable<int>(currentWeek);
    map['career_start_year'] = Variable<int>(careerStartYear);
    map['game_schema_version'] = Variable<int>(gameSchemaVersion);
    map['game_json'] = Variable<String>(gameJson);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  CareerSavesCompanion toCompanion(bool nullToAbsent) {
    return CareerSavesCompanion(
      slotId: Value(slotId),
      agentName: Value(agentName),
      agencyName: Value(agencyName),
      currentSeason: Value(currentSeason),
      currentWeek: Value(currentWeek),
      careerStartYear: Value(careerStartYear),
      gameSchemaVersion: Value(gameSchemaVersion),
      gameJson: Value(gameJson),
      savedAt: Value(savedAt),
    );
  }

  factory CareerSave.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CareerSave(
      slotId: serializer.fromJson<String>(json['slotId']),
      agentName: serializer.fromJson<String>(json['agentName']),
      agencyName: serializer.fromJson<String>(json['agencyName']),
      currentSeason: serializer.fromJson<int>(json['currentSeason']),
      currentWeek: serializer.fromJson<int>(json['currentWeek']),
      careerStartYear: serializer.fromJson<int>(json['careerStartYear']),
      gameSchemaVersion: serializer.fromJson<int>(json['gameSchemaVersion']),
      gameJson: serializer.fromJson<String>(json['gameJson']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slotId': serializer.toJson<String>(slotId),
      'agentName': serializer.toJson<String>(agentName),
      'agencyName': serializer.toJson<String>(agencyName),
      'currentSeason': serializer.toJson<int>(currentSeason),
      'currentWeek': serializer.toJson<int>(currentWeek),
      'careerStartYear': serializer.toJson<int>(careerStartYear),
      'gameSchemaVersion': serializer.toJson<int>(gameSchemaVersion),
      'gameJson': serializer.toJson<String>(gameJson),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  CareerSave copyWith(
          {String? slotId,
          String? agentName,
          String? agencyName,
          int? currentSeason,
          int? currentWeek,
          int? careerStartYear,
          int? gameSchemaVersion,
          String? gameJson,
          DateTime? savedAt}) =>
      CareerSave(
        slotId: slotId ?? this.slotId,
        agentName: agentName ?? this.agentName,
        agencyName: agencyName ?? this.agencyName,
        currentSeason: currentSeason ?? this.currentSeason,
        currentWeek: currentWeek ?? this.currentWeek,
        careerStartYear: careerStartYear ?? this.careerStartYear,
        gameSchemaVersion: gameSchemaVersion ?? this.gameSchemaVersion,
        gameJson: gameJson ?? this.gameJson,
        savedAt: savedAt ?? this.savedAt,
      );
  CareerSave copyWithCompanion(CareerSavesCompanion data) {
    return CareerSave(
      slotId: data.slotId.present ? data.slotId.value : this.slotId,
      agentName: data.agentName.present ? data.agentName.value : this.agentName,
      agencyName:
          data.agencyName.present ? data.agencyName.value : this.agencyName,
      currentSeason: data.currentSeason.present
          ? data.currentSeason.value
          : this.currentSeason,
      currentWeek:
          data.currentWeek.present ? data.currentWeek.value : this.currentWeek,
      careerStartYear: data.careerStartYear.present
          ? data.careerStartYear.value
          : this.careerStartYear,
      gameSchemaVersion: data.gameSchemaVersion.present
          ? data.gameSchemaVersion.value
          : this.gameSchemaVersion,
      gameJson: data.gameJson.present ? data.gameJson.value : this.gameJson,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CareerSave(')
          ..write('slotId: $slotId, ')
          ..write('agentName: $agentName, ')
          ..write('agencyName: $agencyName, ')
          ..write('currentSeason: $currentSeason, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('careerStartYear: $careerStartYear, ')
          ..write('gameSchemaVersion: $gameSchemaVersion, ')
          ..write('gameJson: $gameJson, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(slotId, agentName, agencyName, currentSeason,
      currentWeek, careerStartYear, gameSchemaVersion, gameJson, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CareerSave &&
          other.slotId == this.slotId &&
          other.agentName == this.agentName &&
          other.agencyName == this.agencyName &&
          other.currentSeason == this.currentSeason &&
          other.currentWeek == this.currentWeek &&
          other.careerStartYear == this.careerStartYear &&
          other.gameSchemaVersion == this.gameSchemaVersion &&
          other.gameJson == this.gameJson &&
          other.savedAt == this.savedAt);
}

class CareerSavesCompanion extends UpdateCompanion<CareerSave> {
  final Value<String> slotId;
  final Value<String> agentName;
  final Value<String> agencyName;
  final Value<int> currentSeason;
  final Value<int> currentWeek;
  final Value<int> careerStartYear;
  final Value<int> gameSchemaVersion;
  final Value<String> gameJson;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const CareerSavesCompanion({
    this.slotId = const Value.absent(),
    this.agentName = const Value.absent(),
    this.agencyName = const Value.absent(),
    this.currentSeason = const Value.absent(),
    this.currentWeek = const Value.absent(),
    this.careerStartYear = const Value.absent(),
    this.gameSchemaVersion = const Value.absent(),
    this.gameJson = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CareerSavesCompanion.insert({
    required String slotId,
    required String agentName,
    required String agencyName,
    required int currentSeason,
    required int currentWeek,
    required int careerStartYear,
    required int gameSchemaVersion,
    required String gameJson,
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  })  : slotId = Value(slotId),
        agentName = Value(agentName),
        agencyName = Value(agencyName),
        currentSeason = Value(currentSeason),
        currentWeek = Value(currentWeek),
        careerStartYear = Value(careerStartYear),
        gameSchemaVersion = Value(gameSchemaVersion),
        gameJson = Value(gameJson),
        savedAt = Value(savedAt);
  static Insertable<CareerSave> custom({
    Expression<String>? slotId,
    Expression<String>? agentName,
    Expression<String>? agencyName,
    Expression<int>? currentSeason,
    Expression<int>? currentWeek,
    Expression<int>? careerStartYear,
    Expression<int>? gameSchemaVersion,
    Expression<String>? gameJson,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (slotId != null) 'slot_id': slotId,
      if (agentName != null) 'agent_name': agentName,
      if (agencyName != null) 'agency_name': agencyName,
      if (currentSeason != null) 'current_season': currentSeason,
      if (currentWeek != null) 'current_week': currentWeek,
      if (careerStartYear != null) 'career_start_year': careerStartYear,
      if (gameSchemaVersion != null) 'game_schema_version': gameSchemaVersion,
      if (gameJson != null) 'game_json': gameJson,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CareerSavesCompanion copyWith(
      {Value<String>? slotId,
      Value<String>? agentName,
      Value<String>? agencyName,
      Value<int>? currentSeason,
      Value<int>? currentWeek,
      Value<int>? careerStartYear,
      Value<int>? gameSchemaVersion,
      Value<String>? gameJson,
      Value<DateTime>? savedAt,
      Value<int>? rowid}) {
    return CareerSavesCompanion(
      slotId: slotId ?? this.slotId,
      agentName: agentName ?? this.agentName,
      agencyName: agencyName ?? this.agencyName,
      currentSeason: currentSeason ?? this.currentSeason,
      currentWeek: currentWeek ?? this.currentWeek,
      careerStartYear: careerStartYear ?? this.careerStartYear,
      gameSchemaVersion: gameSchemaVersion ?? this.gameSchemaVersion,
      gameJson: gameJson ?? this.gameJson,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slotId.present) {
      map['slot_id'] = Variable<String>(slotId.value);
    }
    if (agentName.present) {
      map['agent_name'] = Variable<String>(agentName.value);
    }
    if (agencyName.present) {
      map['agency_name'] = Variable<String>(agencyName.value);
    }
    if (currentSeason.present) {
      map['current_season'] = Variable<int>(currentSeason.value);
    }
    if (currentWeek.present) {
      map['current_week'] = Variable<int>(currentWeek.value);
    }
    if (careerStartYear.present) {
      map['career_start_year'] = Variable<int>(careerStartYear.value);
    }
    if (gameSchemaVersion.present) {
      map['game_schema_version'] = Variable<int>(gameSchemaVersion.value);
    }
    if (gameJson.present) {
      map['game_json'] = Variable<String>(gameJson.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CareerSavesCompanion(')
          ..write('slotId: $slotId, ')
          ..write('agentName: $agentName, ')
          ..write('agencyName: $agencyName, ')
          ..write('currentSeason: $currentSeason, ')
          ..write('currentWeek: $currentWeek, ')
          ..write('careerStartYear: $careerStartYear, ')
          ..write('gameSchemaVersion: $gameSchemaVersion, ')
          ..write('gameJson: $gameJson, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CareerSavesTable careerSaves = $CareerSavesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [careerSaves];
}

typedef $$CareerSavesTableCreateCompanionBuilder = CareerSavesCompanion
    Function({
  required String slotId,
  required String agentName,
  required String agencyName,
  required int currentSeason,
  required int currentWeek,
  required int careerStartYear,
  required int gameSchemaVersion,
  required String gameJson,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$CareerSavesTableUpdateCompanionBuilder = CareerSavesCompanion
    Function({
  Value<String> slotId,
  Value<String> agentName,
  Value<String> agencyName,
  Value<int> currentSeason,
  Value<int> currentWeek,
  Value<int> careerStartYear,
  Value<int> gameSchemaVersion,
  Value<String> gameJson,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$CareerSavesTableFilterComposer
    extends Composer<_$AppDatabase, $CareerSavesTable> {
  $$CareerSavesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get slotId => $composableBuilder(
      column: $table.slotId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agentName => $composableBuilder(
      column: $table.agentName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get agencyName => $composableBuilder(
      column: $table.agencyName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentSeason => $composableBuilder(
      column: $table.currentSeason, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentWeek => $composableBuilder(
      column: $table.currentWeek, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get careerStartYear => $composableBuilder(
      column: $table.careerStartYear,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get gameSchemaVersion => $composableBuilder(
      column: $table.gameSchemaVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gameJson => $composableBuilder(
      column: $table.gameJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$CareerSavesTableOrderingComposer
    extends Composer<_$AppDatabase, $CareerSavesTable> {
  $$CareerSavesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get slotId => $composableBuilder(
      column: $table.slotId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agentName => $composableBuilder(
      column: $table.agentName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get agencyName => $composableBuilder(
      column: $table.agencyName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentSeason => $composableBuilder(
      column: $table.currentSeason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentWeek => $composableBuilder(
      column: $table.currentWeek, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get careerStartYear => $composableBuilder(
      column: $table.careerStartYear,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get gameSchemaVersion => $composableBuilder(
      column: $table.gameSchemaVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gameJson => $composableBuilder(
      column: $table.gameJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$CareerSavesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CareerSavesTable> {
  $$CareerSavesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get slotId =>
      $composableBuilder(column: $table.slotId, builder: (column) => column);

  GeneratedColumn<String> get agentName =>
      $composableBuilder(column: $table.agentName, builder: (column) => column);

  GeneratedColumn<String> get agencyName => $composableBuilder(
      column: $table.agencyName, builder: (column) => column);

  GeneratedColumn<int> get currentSeason => $composableBuilder(
      column: $table.currentSeason, builder: (column) => column);

  GeneratedColumn<int> get currentWeek => $composableBuilder(
      column: $table.currentWeek, builder: (column) => column);

  GeneratedColumn<int> get careerStartYear => $composableBuilder(
      column: $table.careerStartYear, builder: (column) => column);

  GeneratedColumn<int> get gameSchemaVersion => $composableBuilder(
      column: $table.gameSchemaVersion, builder: (column) => column);

  GeneratedColumn<String> get gameJson =>
      $composableBuilder(column: $table.gameJson, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$CareerSavesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CareerSavesTable,
    CareerSave,
    $$CareerSavesTableFilterComposer,
    $$CareerSavesTableOrderingComposer,
    $$CareerSavesTableAnnotationComposer,
    $$CareerSavesTableCreateCompanionBuilder,
    $$CareerSavesTableUpdateCompanionBuilder,
    (CareerSave, BaseReferences<_$AppDatabase, $CareerSavesTable, CareerSave>),
    CareerSave,
    PrefetchHooks Function()> {
  $$CareerSavesTableTableManager(_$AppDatabase db, $CareerSavesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CareerSavesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CareerSavesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CareerSavesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> slotId = const Value.absent(),
            Value<String> agentName = const Value.absent(),
            Value<String> agencyName = const Value.absent(),
            Value<int> currentSeason = const Value.absent(),
            Value<int> currentWeek = const Value.absent(),
            Value<int> careerStartYear = const Value.absent(),
            Value<int> gameSchemaVersion = const Value.absent(),
            Value<String> gameJson = const Value.absent(),
            Value<DateTime> savedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CareerSavesCompanion(
            slotId: slotId,
            agentName: agentName,
            agencyName: agencyName,
            currentSeason: currentSeason,
            currentWeek: currentWeek,
            careerStartYear: careerStartYear,
            gameSchemaVersion: gameSchemaVersion,
            gameJson: gameJson,
            savedAt: savedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String slotId,
            required String agentName,
            required String agencyName,
            required int currentSeason,
            required int currentWeek,
            required int careerStartYear,
            required int gameSchemaVersion,
            required String gameJson,
            required DateTime savedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CareerSavesCompanion.insert(
            slotId: slotId,
            agentName: agentName,
            agencyName: agencyName,
            currentSeason: currentSeason,
            currentWeek: currentWeek,
            careerStartYear: careerStartYear,
            gameSchemaVersion: gameSchemaVersion,
            gameJson: gameJson,
            savedAt: savedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CareerSavesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CareerSavesTable,
    CareerSave,
    $$CareerSavesTableFilterComposer,
    $$CareerSavesTableOrderingComposer,
    $$CareerSavesTableAnnotationComposer,
    $$CareerSavesTableCreateCompanionBuilder,
    $$CareerSavesTableUpdateCompanionBuilder,
    (CareerSave, BaseReferences<_$AppDatabase, $CareerSavesTable, CareerSave>),
    CareerSave,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CareerSavesTableTableManager get careerSaves =>
      $$CareerSavesTableTableManager(_db, _db.careerSaves);
}
