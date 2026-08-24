import '../models/club_season_record.dart';
import '../models/game_state.dart';

class ClubLeagueFinish {
  const ClubLeagueFinish({
    required this.season,
    required this.position,
    required this.played,
    required this.isCurrentSeason,
  });

  final int season;
  final int position;
  final int played;
  final bool isCurrentSeason;
}

enum ClubHonourType { champion, runnerUp }

class ClubHonour {
  const ClubHonour({
    required this.season,
    required this.competition,
    required this.type,
  });

  final int season;
  final String competition;
  final ClubHonourType type;
}

/// Produces read-only club history used by reporting screens.
///
/// Keeping the table calculations here means presentation widgets only render
/// the simulation state and never decide league positions themselves.
class ClubHistoryService {
  const ClubHistoryService();

  List<ClubLeagueFinish> leagueFinishes(
    GameState game,
    String clubId, {
    int limit = 6,
  }) {
    final club = game.clubById(clubId);
    if (club == null) return const [];

    final league = game.leagueById(club.leagueId);
    if (league == null) return const [];

    final seasons = game.standings
        .where(
          (record) =>
              league.clubIds.contains(record.clubId) && record.played > 0,
        )
        .map((record) => record.season)
        .toSet()
        .toList(growable: true)
      ..sort();

    final finishes = <ClubLeagueFinish>[];
    for (final season in seasons) {
      final table = _tableForSeason(game, league.clubIds, season);
      final index = table.indexWhere((record) => record.clubId == clubId);
      if (index < 0 || table[index].played == 0) continue;
      finishes.add(
        ClubLeagueFinish(
          season: season,
          position: index + 1,
          played: table[index].played,
          isCurrentSeason: season == game.currentSeason,
        ),
      );
    }

    if (finishes.length <= limit) return List.unmodifiable(finishes);
    return List.unmodifiable(finishes.sublist(finishes.length - limit));
  }

  List<ClubHonour> honours(GameState game, String clubId) {
    final club = game.clubById(clubId);
    if (club == null) return const [];
    final league = game.leagueById(club.leagueId);
    if (league == null) return const [];

    final honoursBySeason = <int, ClubHonour>{};

    // Stored league history is authoritative for completed seasons.
    for (final history in game.leagueHistory) {
      if (history.leagueId != league.id) continue;
      if (history.championClubId == clubId) {
        honoursBySeason[history.season] = ClubHonour(
          season: history.season,
          competition: league.name,
          type: ClubHonourType.champion,
        );
      } else if (history.runnerUpClubId == clubId) {
        honoursBySeason[history.season] = ClubHonour(
          season: history.season,
          competition: league.name,
          type: ClubHonourType.runnerUp,
        );
      }
    }

    // Older saves can contain completed tables created before league history
    // was persisted. Recover first and second place from those tables.
    final pastSeasons = game.standings
        .where(
          (record) =>
              record.season < game.currentSeason &&
              league.clubIds.contains(record.clubId) &&
              record.played > 0,
        )
        .map((record) => record.season)
        .toSet();
    for (final season in pastSeasons) {
      if (honoursBySeason.containsKey(season)) continue;
      final table = _tableForSeason(game, league.clubIds, season);
      final position = table.indexWhere((record) => record.clubId == clubId);
      if (position == 0 || position == 1) {
        honoursBySeason[season] = ClubHonour(
          season: season,
          competition: league.name,
          type:
              position == 0 ? ClubHonourType.champion : ClubHonourType.runnerUp,
        );
      }
    }

    final honours = honoursBySeason.values.toList(growable: true)
      ..sort((first, second) => second.season.compareTo(first.season));
    return List.unmodifiable(honours);
  }

  List<ClubSeasonRecord> _tableForSeason(
    GameState game,
    List<String> leagueClubIds,
    int season,
  ) {
    final table = game.standings
        .where(
          (record) =>
              record.season == season && leagueClubIds.contains(record.clubId),
        )
        .toList(growable: true);
    table.sort((first, second) {
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
}
