import 'dart:math';

import '../models/player.dart';
import '../models/player_personality.dart';
import 'game_balance.dart';
import 'player_attribute_generator.dart';

class TalentRatingBand {
  const TalentRatingBand({
    required this.minimumAbility,
    required this.maximumAbility,
  });

  final int minimumAbility;
  final int maximumAbility;
}

class TalentGenerator {
  const TalentGenerator({
    this.attributeGenerator = const PlayerAttributeGenerator(),
    this.balance = const GameBalance(),
  });

  final PlayerAttributeGenerator attributeGenerator;
  final GameBalance balance;

  static const _firstNames = [
    'Leo',
    'Mateo',
    'Noah',
    'Eli',
    'Luka',
    'Milan',
    'Theo',
    'Rayan',
    'Nico',
    'Jonas',
    'Amir',
    'Tomas',
  ];

  static const _lastNames = [
    'Silva',
    'Kovac',
    'Bennett',
    'Costa',
    'Diallo',
    'Novak',
    'Santos',
    'Ibrahim',
    'Meyer',
    'Rossi',
    'Petrov',
    'Mensah',
  ];

  /// Reputation has no maximum. Its effect is logarithmic so every order of
  /// magnitude improves scouting quality without breaking the 1–99 ratings.
  TalentRatingBand ratingBandForReputation(int reputation) {
    final safeReputation = max(0, reputation);
    final reputationBonus = (log(safeReputation + 1) * 6).floor();
    final minimumAbility = min(82, 34 + reputationBonus);
    final maximumAbility = min(94, minimumAbility + 12);
    return TalentRatingBand(
      minimumAbility: minimumAbility,
      maximumAbility: maximumAbility,
    );
  }

  List<Player> generate({
    required int count,
    required int reputation,
    required int seed,
    required String idPrefix,
  }) {
    final ratingBand = ratingBandForReputation(reputation);
    return _generateInBand(
      count: count,
      ratingBand: ratingBand,
      seed: seed,
      idPrefix: idPrefix,
    );
  }

  List<Player> generateForScout({
    required int count,
    required int scoutAbility,
    String? scoutedByScoutId,
    int maximumAbility = 99,
    required int seed,
    required String idPrefix,
  }) {
    final safeAbility = scoutAbility.clamp(25, 99);
    final safeMaximum = min(safeAbility + 5, maximumAbility.clamp(25, 99));
    return _generateInBand(
      count: count,
      ratingBand: TalentRatingBand(
        minimumAbility: max(25, min(safeAbility - 25, safeMaximum - 8)),
        maximumAbility: safeMaximum,
      ),
      seed: seed,
      idPrefix: idPrefix,
      scoutedByScoutId: scoutedByScoutId,
    );
  }

  List<Player> generateForTrainingGround({
    required int count,
    required int minimumAbility,
    required int maximumAbility,
    required int seed,
    required String idPrefix,
  }) {
    return _generateInBand(
      count: count,
      ratingBand: TalentRatingBand(
        minimumAbility: minimumAbility.clamp(25, 99),
        maximumAbility: maximumAbility.clamp(minimumAbility, 99),
      ),
      seed: seed,
      idPrefix: idPrefix,
    );
  }

  List<Player> _generateInBand({
    required int count,
    required TalentRatingBand ratingBand,
    required int seed,
    required String idPrefix,
    String? scoutedByScoutId,
  }) {
    final random = Random(seed);

    return List.generate(count, (index) {
      final abilityRange =
          ratingBand.maximumAbility - ratingBand.minimumAbility + 1;
      final targetAbility =
          ratingBand.minimumAbility + random.nextInt(abilityRange);
      final age = 16 + random.nextInt(4);
      final position = PlayerPosition.values[random.nextInt(
        PlayerPosition.values.length,
      )];
      var attributes = attributeGenerator.generate(
        ability: targetAbility,
        position: position,
        random: random,
      );
      final body = attributeGenerator.generateBody(
        position: position,
        random: random,
      );
      var ability = Player.calculateOverall(position, attributes);
      for (var attempt = 0;
          ability > ratingBand.maximumAbility && attempt < 5;
          attempt++) {
        final reduction = ability - ratingBand.maximumAbility;
        attributes = attributes.evolve(
          technicalDelta: -reduction,
          mentalDelta: -reduction,
          physicalDelta: -reduction,
        );
        ability = Player.calculateOverall(position, attributes);
      }
      final potential =
          min(99, max(ability, targetAbility + 10 + random.nextInt(16)));
      final value = balance.playerMarketValue(
        ability: ability,
        potential: potential,
        age: age,
        position: position,
      );

      return Player(
        id: '$idPrefix-${index + 1}',
        name:
            '${_firstNames[random.nextInt(_firstNames.length)]} ${_lastNames[random.nextInt(_lastNames.length)]}',
        age: age,
        heightCm: body.heightCm,
        weightKg: body.weightKg,
        position: position,
        potential: potential,
        attributes: attributes,
        value: value.roundToDouble(),
        salary: 0,
        isRecruited: false,
        personality: PlayerPersonality(
          professionalism: 30 + random.nextInt(61),
          discipline: 25 + random.nextInt(71),
          ambition: 35 + random.nextInt(61),
          mediaAppeal: 20 + random.nextInt(76),
        ),
        scoutedByScoutId: scoutedByScoutId,
      );
    }, growable: false);
  }
}
