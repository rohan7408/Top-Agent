import 'dart:math';

import '../models/club.dart';
import '../models/club_season_record.dart';
import '../models/game_state.dart';
import '../models/transfer_record.dart';
import 'season_calendar.dart';
import 'squad_analysis_service.dart';

enum ClubTransferObjective {
  titleDefense,
  titleChallenge,
  strengthen,
  consolidate,
  rebuild,
}

class ClubTransferStrategy {
  const ClubTransferStrategy({
    required this.objective,
    required this.previousPosition,
    required this.currentPosition,
    required this.ambition,
    required this.prestige,
    required this.financialPower,
    required this.squadAverage,
    required this.leagueBestSquadAverage,
    required this.averageAge,
    required this.recruitmentUrgency,
    required this.windowArrivals,
    required this.recentArrivals,
    required this.maxWindowArrivals,
  });

  final ClubTransferObjective objective;
  final int? previousPosition;
  final int? currentPosition;
  final double ambition;
  final double prestige;
  final double financialPower;
  final double squadAverage;
  final double leagueBestSquadAverage;
  final double averageAge;
  final double recruitmentUrgency;
  final int windowArrivals;
  final int recentArrivals;
  final int maxWindowArrivals;

  bool get isDefendingChampion =>
      objective == ClubTransferObjective.titleDefense;

  bool get canRecruit => windowArrivals < maxWindowArrivals;

  double get squadQualityGap =>
      max(0, leagueBestSquadAverage - squadAverage).toDouble();
}

class ClubTransferStrategyService {
  const ClubTransferStrategyService({
    this.squadAnalysis = const SquadAnalysisService(),
    this.seasonCalendar = const SeasonCalendar(),
  });

  final SquadAnalysisService squadAnalysis;
  final SeasonCalendar seasonCalendar;

  ClubTransferStrategy forClub(GameState game, Club club) {
    final league = game.leagues
        .where((candidate) => candidate.id == club.leagueId)
        .firstOrNull;
    final leagueClubIds = league?.clubIds ?? const <String>[];
    final previousTable = game.currentSeason <= 1
        ? const <ClubSeasonRecord>[]
        : _rankedTable(
            game,
            leagueClubIds,
            game.currentSeason - 1,
          );
    final currentTable = _rankedTable(
      game,
      leagueClubIds,
      game.currentSeason,
    );
    final hasPreviousMatches = previousTable.any((record) => record.played > 0);
    final previousPosition =
        hasPreviousMatches ? _positionIn(previousTable, club.id) : null;
    final hasCurrentMatches = currentTable.any((record) => record.played > 0);
    final currentPosition =
        hasCurrentMatches ? _positionIn(currentTable, club.id) : null;

    final leagueClubs = game.clubs
        .where((candidate) => candidate.leagueId == club.leagueId)
        .toList(growable: false);
    final squad = game.playersForClub(club.id);
    final squadAverage = squad.isEmpty
        ? 45.0
        : squad.fold<int>(0, (sum, player) => sum + player.ability) /
            squad.length;
    final averageAge = squad.isEmpty
        ? 25.0
        : squad.fold<int>(0, (sum, player) => sum + player.age) / squad.length;
    final leagueBestSquadAverage = leagueClubs.fold<double>(
      squadAverage,
      (best, candidate) => max(
        best,
        _squadAverage(game, candidate),
      ),
    );
    final prestige = _normalizedLog(
      club.clubValue,
      leagueClubs.map((candidate) => candidate.clubValue),
    );
    final financialPower = _normalizedLog(
      max(1, min(club.budget, club.balance)),
      leagueClubs.map(
        (candidate) => max(1, min(candidate.budget, candidate.balance)),
      ),
    );
    final previousScore = _positionScore(
      previousPosition,
      leagueClubIds.length,
      fallback: prestige,
    );
    final currentScore = _positionScore(
      currentPosition,
      leagueClubIds.length,
      fallback: previousScore,
    );
    final qualityGap = ((leagueBestSquadAverage - squadAverage) / 12)
        .clamp(0.0, 1.0)
        .toDouble();
    final manager = game.managerForClub(club.id);
    final managerDrive = ((manager?.ability ?? 60) / 100).clamp(0.0, 1.0);
    final championBonus = previousPosition == 1 ? 0.22 : 0.0;
    final ambition = (0.18 +
            prestige * 0.18 +
            financialPower * 0.05 +
            previousScore * 0.14 +
            currentScore * 0.10 +
            managerDrive * 0.09 +
            qualityGap * 0.08 +
            championBonus)
        .clamp(0.20, 0.98)
        .toDouble();

    final needs = squadAnalysis.prioritiesForClub(club, game.players);
    final shortage = needs.fold<double>(0, (largest, need) {
      final target = SquadAnalysisService.targetDepth[need.position]!;
      return max(largest, ((target - need.playerCount) / target).clamp(0, 1));
    });
    final agePressure = ((averageAge - 27) / 6).clamp(0.0, 1.0);
    final objective = _objective(
      previousPosition: previousPosition,
      currentPosition: currentPosition,
      clubCount: leagueClubIds.length,
      qualityGap: qualityGap,
      agePressure: agePressure,
    );
    final window = seasonCalendar.transferWindowForWeek(game.currentWeek);
    final windowArrivals = window == null
        ? 0
        : game.transfers.where((move) {
            return move.toClubId == club.id &&
                move.season == game.currentSeason &&
                move.week >= window.startWeek &&
                move.week <= window.endWeek &&
                move.type != TransferMoveType.loan;
          }).length;
    final recentArrivals = game.transfers.where((move) {
      if (move.toClubId != club.id || move.type == TransferMoveType.loan) {
        return false;
      }
      final movedAt = ((move.season - 1) * 50) + move.week;
      return game.currentAbsoluteWeek - movedAt <= 10;
    }).length;
    final baseArrivalLimit = switch (objective) {
      ClubTransferObjective.titleDefense => 3,
      ClubTransferObjective.titleChallenge => 3,
      ClubTransferObjective.rebuild => 3,
      ClubTransferObjective.strengthen => 2,
      ClubTransferObjective.consolidate => 2,
    };
    final maxWindowArrivals =
        (baseArrivalLimit + (squad.length < 16 ? 1 : 0)).clamp(1, 4);
    final recruitmentUrgency = (ambition * 0.36 +
            qualityGap * 0.26 +
            shortage * 0.24 +
            agePressure * 0.08 +
            (1 - recentArrivals / maxWindowArrivals).clamp(0, 1) * 0.06)
        .clamp(0.0, 1.0)
        .toDouble();

    return ClubTransferStrategy(
      objective: objective,
      previousPosition: previousPosition,
      currentPosition: currentPosition,
      ambition: ambition,
      prestige: prestige,
      financialPower: financialPower,
      squadAverage: squadAverage,
      leagueBestSquadAverage: leagueBestSquadAverage,
      averageAge: averageAge,
      recruitmentUrgency: recruitmentUrgency,
      windowArrivals: windowArrivals,
      recentArrivals: recentArrivals,
      maxWindowArrivals: maxWindowArrivals,
    );
  }

  List<ClubSeasonRecord> _rankedTable(
    GameState game,
    List<String> clubIds,
    int season,
  ) {
    final table = game.standings
        .where(
          (record) =>
              record.season == season && clubIds.contains(record.clubId),
        )
        .toList(growable: true)
      ..sort((first, second) {
        final points = second.points.compareTo(first.points);
        if (points != 0) return points;
        final goalDifference =
            second.goalDifference.compareTo(first.goalDifference);
        if (goalDifference != 0) return goalDifference;
        final goalsFor = second.goalsFor.compareTo(first.goalsFor);
        if (goalsFor != 0) return goalsFor;
        return first.clubId.compareTo(second.clubId);
      });
    return table;
  }

  int? _positionIn(List<ClubSeasonRecord> table, String clubId) {
    final index = table.indexWhere((record) => record.clubId == clubId);
    return index < 0 ? null : index + 1;
  }

  double _positionScore(
    int? position,
    int clubCount, {
    required double fallback,
  }) {
    if (position == null || clubCount <= 1) return fallback;
    return ((clubCount - position) / (clubCount - 1)).clamp(0, 1);
  }

  double _squadAverage(GameState game, Club club) {
    final squad = game.playersForClub(club.id);
    return squad.isEmpty
        ? 45
        : squad.fold<int>(0, (sum, player) => sum + player.ability) /
            squad.length;
  }

  double _normalizedLog(double value, Iterable<double> values) {
    final logs = values.map((item) => log(max(1, item))).toList();
    if (logs.isEmpty) return 0.5;
    final low = logs.reduce(min);
    final high = logs.reduce(max);
    if ((high - low).abs() < 0.0001) return 0.5;
    return ((log(max(1, value)) - low) / (high - low)).clamp(0, 1);
  }

  ClubTransferObjective _objective({
    required int? previousPosition,
    required int? currentPosition,
    required int clubCount,
    required double qualityGap,
    required double agePressure,
  }) {
    if (previousPosition == 1) return ClubTransferObjective.titleDefense;
    if ((previousPosition ?? clubCount) <= 4 ||
        (currentPosition ?? clubCount) <= 4) {
      return ClubTransferObjective.titleChallenge;
    }
    if (agePressure >= 0.55 || qualityGap >= 0.62) {
      return ClubTransferObjective.rebuild;
    }
    if ((currentPosition ?? 1) > max(1, clubCount - 5)) {
      return ClubTransferObjective.strengthen;
    }
    return ClubTransferObjective.consolidate;
  }
}
