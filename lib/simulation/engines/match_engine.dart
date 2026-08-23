import 'dart:math';

import '../../domain/models/game_state.dart';
import '../../domain/models/club_manager.dart';
import '../../domain/models/league_fixture.dart';
import '../../domain/models/match_result.dart';
import '../../domain/models/player.dart';
import '../../domain/models/player_match_performance.dart';
import '../../domain/models/player_injury.dart';
import '../../domain/services/game_balance.dart';

class MatchSimulationBatch {
  const MatchSimulationBatch({
    required this.results,
    required this.performances,
    required this.injuries,
  });

  final List<MatchResult> results;
  final List<PlayerMatchPerformance> performances;
  final List<PlayerInjury> injuries;
}

class MatchEngine {
  const MatchEngine({this.balance = const GameBalance()});

  final GameBalance balance;

  MatchSimulationBatch simulateFixtures({
    required GameState game,
    required List<LeagueFixture> fixtures,
    required int seed,
  }) {
    final random = Random(seed);
    final results = <MatchResult>[];
    final performances = <PlayerMatchPerformance>[];
    final injuries = <PlayerInjury>[];
    final unavailableIds = game.injuries
        .where((injury) => injury.isActive)
        .map((injury) => injury.playerId)
        .toSet();

    for (final fixture in fixtures) {
      final homeManager = game.managerForClub(fixture.homeClubId);
      final awayManager = game.managerForClub(fixture.awayClubId);
      final homeLineup = _selectLineup(
        game
            .playersForClub(fixture.homeClubId)
            .where((player) => !unavailableIds.contains(player.id))
            .toList(),
        homeManager,
      );
      final awayLineup = _selectLineup(
        game
            .playersForClub(fixture.awayClubId)
            .where((player) => !unavailableIds.contains(player.id))
            .toList(),
        awayManager,
      );
      if (homeLineup.length < 11 || awayLineup.length < 11) continue;

      final homeStrength = _lineupStrength(homeLineup) +
          (((homeManager?.ability ?? 60) - 60) * 0.025);
      final awayStrength = _lineupStrength(awayLineup) +
          (((awayManager?.ability ?? 60) - 60) * 0.025);
      final difference = homeStrength - awayStrength;
      final homeExpected = (1.5 +
              (difference * 0.045) +
              _attackModifier(homeManager?.tacticalStyle) -
              _defenseModifier(awayManager?.tacticalStyle))
          .clamp(0.25, 3.8)
          .toDouble();
      final awayExpected = (1.15 -
              (difference * 0.04) +
              _attackModifier(awayManager?.tacticalStyle) -
              _defenseModifier(homeManager?.tacticalStyle))
          .clamp(0.2, 3.5)
          .toDouble();
      final matchId = 'match-${fixture.id}';
      final result = MatchResult(
        id: matchId,
        leagueId: fixture.leagueId,
        homeClubId: fixture.homeClubId,
        awayClubId: fixture.awayClubId,
        homeGoals: _poisson(random, homeExpected),
        awayGoals: _poisson(random, awayExpected),
        week: fixture.week,
        season: fixture.season,
      );
      results.add(result);

      final matchPerformances = [
        ..._createTeamPerformances(
          lineup: homeLineup,
          clubId: fixture.homeClubId,
          goalsScored: result.homeGoals,
          goalsConceded: result.awayGoals,
          opponentGoals: result.awayGoals,
          matchId: matchId,
          leagueId: fixture.leagueId,
          week: fixture.week,
          season: fixture.season,
          random: random,
        ),
        ..._createTeamPerformances(
          lineup: awayLineup,
          clubId: fixture.awayClubId,
          goalsScored: result.awayGoals,
          goalsConceded: result.homeGoals,
          opponentGoals: result.homeGoals,
          matchId: matchId,
          leagueId: fixture.leagueId,
          week: fixture.week,
          season: fixture.season,
          random: random,
        ),
      ];
      if (matchPerformances.isNotEmpty) {
        var bestIndex = 0;
        for (var index = 1; index < matchPerformances.length; index++) {
          if (matchPerformances[index].rating >
              matchPerformances[bestIndex].rating) {
            bestIndex = index;
          }
        }
        matchPerformances[bestIndex] = matchPerformances[bestIndex].copyWith(
          playerOfTheMatch: true,
        );
      }
      performances.addAll(matchPerformances);
      injuries.addAll(
        _createMatchInjuries(
          players: [...homeLineup, ...awayLineup],
          matchId: matchId,
          season: fixture.season,
          week: fixture.week,
          random: random,
        ),
      );
    }

    return MatchSimulationBatch(
      results: List.unmodifiable(results),
      performances: List.unmodifiable(performances),
      injuries: List.unmodifiable(injuries),
    );
  }

  List<PlayerInjury> _createMatchInjuries({
    required List<Player> players,
    required String matchId,
    required int season,
    required int week,
    required Random random,
  }) {
    final injuries = <PlayerInjury>[];
    for (final player in players) {
      final durability = (player.attributes.stamina +
              player.attributes.strength +
              player.attributes.agility) /
          3;
      final injuryChance = balance.matchInjuryChance(
        age: player.age,
        durability: durability,
        fatigue: player.fatigue,
        consecutiveStarts: player.consecutiveStarts,
      );
      if (random.nextDouble() >= injuryChance) {
        continue;
      }

      final roll = random.nextDouble();
      final (name, duration) = switch (roll) {
        < 0.32 => ('Minor knock', 1),
        < 0.62 => ('Muscle strain', 2 + random.nextInt(3)),
        < 0.82 => ('Ankle sprain', 3 + random.nextInt(4)),
        < 0.96 => ('Hamstring injury', 4 + random.nextInt(4)),
        _ => ('Knee injury', 8 + random.nextInt(9)),
      };
      injuries.add(
        PlayerInjury(
          id: 'injury-$matchId-${player.id}',
          playerId: player.id,
          name: name,
          startSeason: season,
          startWeek: week,
          totalWeeks: duration,
          weeksRemaining: duration,
        ),
      );
    }
    return injuries;
  }

  double _attackModifier(TacticalStyle? style) => switch (style) {
        TacticalStyle.highPress => 0.14,
        TacticalStyle.possession => 0.08,
        TacticalStyle.counterAttack => 0.05,
        TacticalStyle.defensive => -0.16,
        TacticalStyle.balanced || null => 0,
      };

  double _defenseModifier(TacticalStyle? style) => switch (style) {
        TacticalStyle.defensive => 0.18,
        TacticalStyle.possession => 0.07,
        TacticalStyle.counterAttack => 0.03,
        TacticalStyle.highPress => -0.05,
        TacticalStyle.balanced || null => 0,
      };

  List<Player> _selectLineup(List<Player> squad, ClubManager? manager) {
    final selected = <Player>[];
    final usedIds = <String>{};

    void selectPosition(PlayerPosition position, int count) {
      final candidates = squad
          .where((player) => player.position == position)
          .toList(growable: true)
        ..sort((first, second) => _selectionScore(second, manager)
            .compareTo(_selectionScore(first, manager)));
      for (final player in candidates.take(count)) {
        selected.add(player);
        usedIds.add(player.id);
      }
    }

    selectPosition(PlayerPosition.goalkeeper, 1);
    selectPosition(PlayerPosition.defender, 4);
    selectPosition(PlayerPosition.midfielder, 4);
    selectPosition(PlayerPosition.forward, 2);

    if (selected.length < 11) {
      final remaining = squad
          .where((player) => !usedIds.contains(player.id))
          .toList(growable: true)
        ..sort((first, second) => _selectionScore(second, manager)
            .compareTo(_selectionScore(first, manager)));
      selected.addAll(remaining.take(11 - selected.length));
    }
    return List.unmodifiable(selected.take(11));
  }

  double _selectionScore(Player player, ClubManager? manager) {
    final rotation = manager?.rotation ?? 60;
    final fatiguePenalty = player.fatigue * (0.12 + rotation / 180);
    final repetitionPenalty = player.consecutiveStarts * (rotation / 35);
    return _roleRating(player) - fatiguePenalty - repetitionPenalty;
  }

  List<PlayerMatchPerformance> _createTeamPerformances({
    required List<Player> lineup,
    required String clubId,
    required int goalsScored,
    required int goalsConceded,
    required int opponentGoals,
    required String matchId,
    required String leagueId,
    required int week,
    required int season,
    required Random random,
  }) {
    final goals = {for (final player in lineup) player.id: 0};
    final assists = {for (final player in lineup) player.id: 0};

    for (var goal = 0; goal < goalsScored; goal++) {
      final scorer = _weightedPlayer(
        lineup,
        random,
        (player) => _scoringSkill(player) * _scoringWeight(player.position),
      );
      goals[scorer.id] = goals[scorer.id]! + 1;
      if (random.nextDouble() < 0.72 && lineup.length > 1) {
        final assistingCandidates =
            lineup.where((player) => player.id != scorer.id).toList();
        final assister = _weightedPlayer(
          assistingCandidates,
          random,
          (player) => _creativeSkill(player) * _assistWeight(player.position),
        );
        assists[assister.id] = assists[assister.id]! + 1;
      }
    }

    final didWin = goalsScored > opponentGoals;
    final didDraw = goalsScored == opponentGoals;
    return lineup.map((player) {
      final redCard = random.nextDouble() < 0.008 ? 1 : 0;
      final yellowCard =
          redCard == 0 && random.nextDouble() < _yellowCardChance(player)
              ? 1
              : 0;
      final cleanSheet = goalsConceded == 0 &&
          (player.position == PlayerPosition.goalkeeper ||
              player.position == PlayerPosition.defender);
      final resultBonus = didWin
          ? 0.35
          : didDraw
              ? 0.08
              : -0.22;
      final cleanSheetBonus = cleanSheet
          ? player.position == PlayerPosition.goalkeeper
              ? 0.65
              : 0.45
          : 0.0;
      final rating = (6.0 +
              resultBonus +
              (goals[player.id]! * 0.85) +
              (assists[player.id]! * 0.5) +
              cleanSheetBonus -
              (yellowCard * 0.2) -
              (redCard * 1.2) +
              ((random.nextDouble() - 0.5) * 0.8))
          .clamp(3.0, 10.0)
          .toDouble();

      return PlayerMatchPerformance(
        id: 'performance-$matchId-${player.id}',
        matchId: matchId,
        leagueId: leagueId,
        playerId: player.id,
        clubId: clubId,
        week: week,
        season: season,
        started: true,
        minutes: 90,
        goals: goals[player.id]!,
        assists: assists[player.id]!,
        cleanSheet: cleanSheet,
        yellowCards: yellowCard,
        redCards: redCard,
        rating: double.parse(rating.toStringAsFixed(2)),
      );
    }).toList(growable: true);
  }

  Player _weightedPlayer(
    List<Player> players,
    Random random,
    double Function(Player player) weightFor,
  ) {
    final totalWeight = players.fold<double>(
      0,
      (total, player) => total + weightFor(player),
    );
    var target = random.nextDouble() * totalWeight;
    for (final player in players) {
      target -= weightFor(player);
      if (target <= 0) return player;
    }
    return players.last;
  }

  double _lineupStrength(List<Player> lineup) =>
      lineup.map(_roleRating).reduce((a, b) => a + b) / lineup.length;

  double _roleRating(Player player) {
    final attributes = player.attributes;
    return switch (player.position) {
      PlayerPosition.goalkeeper => (attributes.goalkeeping * 0.50) +
          (attributes.positioning * 0.18) +
          (attributes.decisions * 0.14) +
          (attributes.agility * 0.10) +
          (attributes.composure * 0.08),
      PlayerPosition.defender => (attributes.tackling * 0.28) +
          (attributes.positioning * 0.22) +
          (attributes.anticipation * 0.14) +
          (attributes.strength * 0.12) +
          (attributes.jumping * 0.10) +
          (attributes.decisions * 0.08) +
          (attributes.pace * 0.06),
      PlayerPosition.midfielder => (attributes.passing * 0.24) +
          (attributes.vision * 0.19) +
          (attributes.firstTouch * 0.15) +
          (attributes.decisions * 0.14) +
          (attributes.workRate * 0.11) +
          (attributes.stamina * 0.09) +
          (attributes.dribbling * 0.08),
      PlayerPosition.forward => (attributes.finishing * 0.27) +
          (attributes.composure * 0.18) +
          (attributes.positioning * 0.17) +
          (attributes.firstTouch * 0.12) +
          (attributes.dribbling * 0.10) +
          (attributes.pace * 0.09) +
          (attributes.acceleration * 0.07),
    };
  }

  double _scoringSkill(Player player) {
    final attributes = player.attributes;
    return (attributes.finishing * 0.52) +
        (attributes.composure * 0.20) +
        (attributes.positioning * 0.16) +
        (attributes.firstTouch * 0.12);
  }

  double _creativeSkill(Player player) {
    final attributes = player.attributes;
    return (attributes.passing * 0.43) +
        (attributes.vision * 0.29) +
        (attributes.decisions * 0.17) +
        (attributes.firstTouch * 0.11);
  }

  double _scoringWeight(PlayerPosition position) => switch (position) {
        PlayerPosition.goalkeeper => 0.03,
        PlayerPosition.defender => 0.7,
        PlayerPosition.midfielder => 2.3,
        PlayerPosition.forward => 4.5,
      };

  double _assistWeight(PlayerPosition position) => switch (position) {
        PlayerPosition.goalkeeper => 0.05,
        PlayerPosition.defender => 1.0,
        PlayerPosition.midfielder => 3.8,
        PlayerPosition.forward => 2.2,
      };

  double _yellowCardChance(Player player) {
    final baseChance = switch (player.position) {
      PlayerPosition.goalkeeper => 0.02,
      PlayerPosition.defender => 0.13,
      PlayerPosition.midfielder => 0.1,
      PlayerPosition.forward => 0.06,
    };
    final decisionModifier =
        ((120 - player.attributes.decisions) / 70).clamp(0.55, 1.4);
    return baseChance * decisionModifier;
  }

  int _poisson(Random random, double expectedGoals) {
    final threshold = exp(-expectedGoals);
    var product = 1.0;
    var goals = 0;
    do {
      goals++;
      product *= random.nextDouble();
    } while (product > threshold && goals < 10);
    return goals - 1;
  }
}
