import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/league.dart';
import 'package:football_agent/simulation/engines/fixture_calendar_engine.dart';

void main() {
  test('20-club calendar creates a balanced 38-round double round robin', () {
    final league = League(
      id: 'league',
      name: 'Test League',
      country: 'Test',
      clubIds: List.generate(20, (index) => 'club-${index + 1}'),
    );
    final fixtures = const FixtureCalendarEngine().createSeasonFixtures(
      league: league,
      season: 1,
    );

    expect(fixtures, hasLength(380));
    expect(fixtures.map((fixture) => fixture.round).toSet(), hasLength(38));
    expect(fixtures.map((fixture) => fixture.week).toSet(), hasLength(38));
    expect(fixtures.where((fixture) => fixture.week == 20), isEmpty);
    expect(fixtures.where((fixture) => fixture.week == 25), hasLength(10));
    expect(fixtures.where((fixture) => fixture.week == 43), hasLength(10));

    for (final clubId in league.clubIds) {
      final clubFixtures = fixtures.where(
        (fixture) =>
            fixture.homeClubId == clubId || fixture.awayClubId == clubId,
      );
      expect(clubFixtures, hasLength(38));
      expect(
        clubFixtures.where((fixture) => fixture.homeClubId == clubId),
        hasLength(19),
      );
      expect(
        clubFixtures.where((fixture) => fixture.awayClubId == clubId),
        hasLength(19),
      );
    }

    final pairCounts = <String, int>{};
    for (final fixture in fixtures) {
      final clubs = [fixture.homeClubId, fixture.awayClubId]..sort();
      final key = '${clubs[0]}|${clubs[1]}';
      pairCounts[key] = (pairCounts[key] ?? 0) + 1;
    }
    expect(pairCounts, hasLength(190));
    expect(pairCounts.values.every((count) => count == 2), isTrue);
  });
}
