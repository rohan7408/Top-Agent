import '../../domain/models/league.dart';
import '../../domain/models/league_fixture.dart';

class FixtureCalendarEngine {
  const FixtureCalendarEngine();

  static const firstLegWeeks = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
  ];

  static const secondLegWeeks = [
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
  ];

  List<LeagueFixture> createSeasonFixtures({
    required League league,
    required int season,
  }) {
    final clubIds = league.clubIds;
    if (clubIds.length < 2 || clubIds.length.isOdd) return const [];
    final roundsPerLeg = clubIds.length - 1;
    if (roundsPerLeg != firstLegWeeks.length) {
      throw StateError(
        'The current 50-week calendar supports exactly 20 clubs per league.',
      );
    }

    final rotation = [...clubIds];
    final fixtures = <LeagueFixture>[];
    for (var round = 0; round < roundsPerLeg; round++) {
      for (var pairing = 0; pairing < rotation.length ~/ 2; pairing++) {
        final first = rotation[pairing];
        final second = rotation[rotation.length - 1 - pairing];
        final firstAtHome = (round + pairing).isEven;
        final firstLegHome = firstAtHome ? first : second;
        final firstLegAway = firstAtHome ? second : first;

        fixtures.add(
          LeagueFixture(
            id: 'fixture-$season-${league.id}-${round + 1}-$pairing',
            leagueId: league.id,
            homeClubId: firstLegHome,
            awayClubId: firstLegAway,
            round: round + 1,
            week: firstLegWeeks[round],
            season: season,
          ),
        );
        fixtures.add(
          LeagueFixture(
            id: 'fixture-$season-${league.id}-${round + 20}-$pairing',
            leagueId: league.id,
            homeClubId: firstLegAway,
            awayClubId: firstLegHome,
            round: round + 20,
            week: secondLegWeeks[round],
            season: season,
          ),
        );
      }

      final last = rotation.removeLast();
      rotation.insert(1, last);
    }

    fixtures.sort((first, second) {
      final week = first.week.compareTo(second.week);
      return week != 0 ? week : first.id.compareTo(second.id);
    });
    return List.unmodifiable(fixtures);
  }
}
