import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/talent_generator.dart';
import 'package:football_agent/domain/services/talent_pool_policy.dart';

void main() {
  test('talent pool removes over-age and excess prospects', () {
    final game = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final extra = const TalentGenerator().generate(
      count: 4,
      reputation: 0,
      seed: 99,
      idPrefix: 'extra',
    );
    final oldTalent = game.availableTalents.first.copyWith(age: 31);
    final prepared = game.copyWith(
      players: [
        oldTalent,
        ...game.players.where((player) => player.id != oldTalent.id),
        ...extra,
      ],
    );

    final cleaned = const TalentPoolPolicy().clean(prepared);

    expect(cleaned.availableTalents, hasLength(3));
    expect(
        cleaned.availableTalents.every((player) => player.age <= 21), isTrue);
  });

  test('low-level scout prospects obey the office rating ceiling', () {
    final prospects = const TalentGenerator().generateForScout(
      count: 40,
      scoutAbility: 90,
      maximumAbility: 45,
      seed: 12,
      idPrefix: 'capped',
    );

    expect(prospects.every((player) => player.age <= 19), isTrue);
    expect(prospects.every((player) => player.ability <= 45), isTrue);
  });
}
