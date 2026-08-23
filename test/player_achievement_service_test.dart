import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/club_season_record.dart';
import 'package:football_agent/domain/models/player_achievement.dart';
import 'package:football_agent/domain/models/player_season_stats.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/player_achievement_service.dart';

void main() {
  test('completed football results produce connected player achievements', () {
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final league = base.leagues.first;
    final champion = base.clubs.first;
    final runnerUp = base.clubs[1];
    final winner = base.players.firstWhere(
      (player) => player.clubId == champion.id,
    );
    final challenger = base.players.firstWhere(
      (player) => player.clubId == runnerUp.id,
    );
    final completed = base.copyWith(
      agent: base.agent.copyWith(currentSeason: 2, currentWeek: 1),
      standings: [
        for (final club in base.clubs)
          ClubSeasonRecord(
            clubId: club.id,
            season: 1,
            played: 38,
            won: club.id == champion.id ? 31 : 10,
            drawn: club.id == champion.id ? 5 : 8,
            lost: club.id == champion.id ? 2 : 20,
            goalsFor: club.id == champion.id ? 88 : 45,
            goalsAgainst: club.id == champion.id ? 22 : 55,
            points: club.id == champion.id ? 98 : 38,
          ),
      ],
      playerSeasonStats: [
        PlayerSeasonStats(
          playerId: winner.id,
          clubId: champion.id,
          leagueId: league.id,
          season: 1,
          appearances: 30,
          starts: 29,
          minutes: 2550,
          goals: 24,
          assists: 9,
          playerOfTheMatchAwards: 6,
          totalRating: 246,
        ),
        PlayerSeasonStats(
          playerId: challenger.id,
          clubId: runnerUp.id,
          leagueId: league.id,
          season: 1,
          appearances: 30,
          starts: 30,
          minutes: 2700,
          goals: 18,
          assists: 5,
          playerOfTheMatchAwards: 2,
          totalRating: 219,
        ),
      ],
    );

    final achievements =
        const PlayerAchievementService().achievementsFor(completed, winner.id);

    expect(
      achievements.map((achievement) => achievement.type),
      containsAll(PlayerAchievementType.values),
    );
    expect(
      achievements
          .singleWhere(
            (achievement) => achievement.type == PlayerAchievementType.matchMvp,
          )
          .count,
      6,
    );
  });
}
