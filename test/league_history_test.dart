import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/club_season_record.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/models/player.dart';
import 'package:football_agent/domain/models/player_season_stats.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/league_history_service.dart';
import 'package:football_agent/simulation/game_engine.dart';

void main() {
  test('completed league season records table and player honours', () {
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final league = base.leagues.single;
    final champion = base.clubs[0];
    final runnerUp = base.clubs[1];
    final scorer = base.players.firstWhere(
      (player) => player.position == PlayerPosition.forward,
    );
    final assister = base.players.firstWhere(
      (player) =>
          player.position == PlayerPosition.midfielder &&
          player.id != scorer.id,
    );
    final goalkeeper = base.players.firstWhere(
      (player) => player.position == PlayerPosition.goalkeeper,
    );
    final completed = base.copyWith(
      standings: [
        ClubSeasonRecord(
          clubId: champion.id,
          season: 1,
          played: 38,
          won: 30,
          points: 94,
          goalsFor: 80,
          goalsAgainst: 20,
        ),
        ClubSeasonRecord(
          clubId: runnerUp.id,
          season: 1,
          played: 38,
          won: 27,
          points: 86,
          goalsFor: 74,
          goalsAgainst: 25,
        ),
        ...base.clubs.skip(2).map(
              (club) => ClubSeasonRecord(
                clubId: club.id,
                season: 1,
                played: 38,
                points: 40,
              ),
            ),
      ],
      playerSeasonStats: [
        PlayerSeasonStats(
          playerId: scorer.id,
          clubId: scorer.clubId!,
          leagueId: league.id,
          season: 1,
          appearances: 32,
          goals: 28,
          assists: 4,
          totalRating: 240,
        ),
        PlayerSeasonStats(
          playerId: assister.id,
          clubId: assister.clubId!,
          leagueId: league.id,
          season: 1,
          appearances: 31,
          goals: 6,
          assists: 18,
          totalRating: 230,
        ),
        PlayerSeasonStats(
          playerId: goalkeeper.id,
          clubId: goalkeeper.clubId!,
          leagueId: league.id,
          season: 1,
          appearances: 34,
          cleanSheets: 17,
          totalRating: 245,
        ),
      ],
    );

    final captured = const LeagueHistoryService()
        .captureCompletedSeason(completed)
        .leagueHistory
        .single;

    expect(captured.championClubId, champion.id);
    expect(captured.runnerUpClubId, runnerUp.id);
    expect(captured.topScorer?.playerId, scorer.id);
    expect(captured.topScorer?.value, 28);
    expect(captured.topAssister?.playerId, assister.id);
    expect(captured.topAssister?.value, 18);
    expect(captured.cleanSheetLeader?.playerId, goalkeeper.id);
    expect(captured.cleanSheetLeader?.value, 17);
  });

  test('season rollover persists one immutable history snapshot', () {
    var state = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24, 12),
    );
    const engine = GameEngine();
    for (var week = 0; week < 50; week++) {
      state = engine.simulateOneWeek(state).state;
    }

    expect(state.currentSeason, 2);
    expect(state.leagueHistory, hasLength(1));
    expect(state.leagueHistory.single.season, 1);
    expect(state.leagueHistory.single.topScorer, isNotNull);
    expect(state.leagueHistory.single.topAssister, isNotNull);
    expect(state.leagueHistory.single.cleanSheetLeader, isNotNull);

    final restored = GameState.fromJson(state.toJson());
    expect(restored.leagueHistory, hasLength(1));
    expect(
      restored.leagueHistory.single.championClubId,
      state.leagueHistory.single.championClubId,
    );

    final legacyJson = Map<String, Object?>.from(state.toJson())
      ..remove('leagueHistory');
    expect(GameState.fromJson(legacyJson).leagueHistory, isEmpty);
  });
}
