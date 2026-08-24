import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/agent.dart';
import 'package:football_agent/domain/models/club.dart';
import 'package:football_agent/domain/models/club_season_record.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/models/league.dart';
import 'package:football_agent/domain/models/league_season_history.dart';
import 'package:football_agent/domain/services/club_history_service.dart';

void main() {
  const service = ClubHistoryService();

  test('builds chronological league finishes from season tables', () {
    final game = _game(
      standings: const [
        ClubSeasonRecord(
          clubId: 'club-a',
          season: 1,
          played: 2,
          won: 2,
          points: 6,
          goalsFor: 4,
        ),
        ClubSeasonRecord(
          clubId: 'club-b',
          season: 1,
          played: 2,
          won: 1,
          lost: 1,
          points: 3,
          goalsFor: 2,
          goalsAgainst: 2,
        ),
        ClubSeasonRecord(
          clubId: 'club-a',
          season: 2,
          played: 1,
          lost: 1,
          goalsAgainst: 1,
        ),
        ClubSeasonRecord(
          clubId: 'club-b',
          season: 2,
          played: 1,
          won: 1,
          points: 3,
          goalsFor: 1,
        ),
      ],
    );

    final finishes = service.leagueFinishes(game, 'club-a');

    expect(finishes.map((item) => item.season), [1, 2]);
    expect(finishes.map((item) => item.position), [1, 2]);
    expect(finishes.last.isCurrentSeason, isTrue);
  });

  test('uses stored league history for winner and runner-up honours', () {
    final game = _game(
      leagueHistory: const [
        LeagueSeasonHistory(
          leagueId: 'league',
          season: 1,
          championClubId: 'club-a',
          runnerUpClubId: 'club-b',
        ),
      ],
    );

    final winner = service.honours(game, 'club-a').single;
    final runnerUp = service.honours(game, 'club-b').single;

    expect(winner.type, ClubHonourType.champion);
    expect(runnerUp.type, ClubHonourType.runnerUp);
    expect(winner.competition, 'Premier League');
  });
}

GameState _game({
  List<ClubSeasonRecord> standings = const [],
  List<LeagueSeasonHistory> leagueHistory = const [],
}) {
  return GameState(
    agent: const Agent(
      id: 'agent',
      name: 'Agent',
      agencyName: 'Agency',
      age: 30,
      money: 0,
      reputation: 0,
      currentWeek: 10,
      currentSeason: 2,
    ),
    createdAt: DateTime(2025),
    clubs: [
      for (final id in ['club-a', 'club-b'])
        Club(
          id: id,
          name: id,
          leagueId: 'league',
          clubValue: 1,
          squadValue: 1,
          totalSalary: 1,
          budget: 1,
          balance: 1,
        ),
    ],
    leagues: [
      League(
        id: 'league',
        name: 'Premier League',
        country: 'England',
        clubIds: const ['club-a', 'club-b'],
      ),
    ],
    standings: standings,
    leagueHistory: leagueHistory,
  );
}
