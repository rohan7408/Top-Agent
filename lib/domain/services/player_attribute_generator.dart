import 'dart:math';

import '../models/player.dart';
import '../models/player_attributes.dart';

class PlayerAttributeGenerator {
  const PlayerAttributeGenerator();

  PlayerAttributes generate({
    required int ability,
    required PlayerPosition position,
    required Random random,
  }) {
    int rating(int bias, {int variation = 7}) {
      final noise = random.nextInt((variation * 2) + 1) - variation;
      return (ability + bias + noise).clamp(1, 99);
    }

    final biases = _biasesFor(position);
    return PlayerAttributes(
      finishing: rating(biases.finishing),
      passing: rating(biases.passing),
      dribbling: rating(biases.dribbling),
      tackling: rating(biases.tackling),
      firstTouch: rating(biases.firstTouch),
      goalkeeping: rating(biases.goalkeeping, variation: 5),
      decisions: rating(biases.decisions),
      composure: rating(biases.composure),
      anticipation: rating(biases.anticipation),
      positioning: rating(biases.positioning),
      vision: rating(biases.vision),
      workRate: rating(biases.workRate),
      pace: rating(biases.pace),
      acceleration: rating(biases.acceleration),
      agility: rating(biases.agility),
      stamina: rating(biases.stamina),
      strength: rating(biases.strength),
      jumping: rating(biases.jumping),
    );
  }

  PlayerBodyMeasurements generateBody({
    required PlayerPosition position,
    required Random random,
  }) {
    final (minimumHeight, maximumHeight, bmiBase) = switch (position) {
      PlayerPosition.goalkeeper => (182, 201, 23.1),
      PlayerPosition.defender => (176, 198, 23.4),
      PlayerPosition.midfielder => (168, 191, 22.2),
      PlayerPosition.forward => (171, 195, 22.7),
    };
    final heightCm =
        minimumHeight + random.nextInt(maximumHeight - minimumHeight + 1);
    final heightMeters = heightCm / 100;
    final bmi = bmiBase + ((random.nextDouble() - 0.5) * 2.4);
    final weightKg = (bmi * heightMeters * heightMeters).round().clamp(58, 105);
    return PlayerBodyMeasurements(heightCm: heightCm, weightKg: weightKg);
  }

  _AttributeBiases _biasesFor(PlayerPosition position) => switch (position) {
        PlayerPosition.goalkeeper => const _AttributeBiases(
            finishing: -45,
            passing: -8,
            dribbling: -20,
            tackling: -18,
            firstTouch: -7,
            goalkeeping: 12,
            decisions: 2,
            composure: 3,
            anticipation: 5,
            positioning: 7,
            vision: -5,
            workRate: -3,
            pace: -10,
            acceleration: -8,
            agility: 4,
            stamina: -7,
            strength: 3,
            jumping: 5,
          ),
        PlayerPosition.defender => const _AttributeBiases(
            finishing: -20,
            passing: -4,
            dribbling: -8,
            tackling: 10,
            firstTouch: -3,
            goalkeeping: -50,
            decisions: 3,
            composure: 1,
            anticipation: 6,
            positioning: 8,
            vision: -6,
            workRate: 5,
            pace: -1,
            acceleration: -2,
            agility: -3,
            stamina: 4,
            strength: 7,
            jumping: 8,
          ),
        PlayerPosition.midfielder => const _AttributeBiases(
            finishing: -5,
            passing: 9,
            dribbling: 6,
            tackling: 0,
            firstTouch: 8,
            goalkeeping: -50,
            decisions: 5,
            composure: 3,
            anticipation: 3,
            positioning: 1,
            vision: 9,
            workRate: 6,
            pace: 0,
            acceleration: 1,
            agility: 4,
            stamina: 7,
            strength: -3,
            jumping: -4,
          ),
        PlayerPosition.forward => const _AttributeBiases(
            finishing: 10,
            passing: -2,
            dribbling: 7,
            tackling: -22,
            firstTouch: 7,
            goalkeeping: -50,
            decisions: 3,
            composure: 7,
            anticipation: 6,
            positioning: 8,
            vision: 1,
            workRate: 1,
            pace: 5,
            acceleration: 6,
            agility: 5,
            stamina: 1,
            strength: 1,
            jumping: 3,
          ),
      };
}

class PlayerBodyMeasurements {
  const PlayerBodyMeasurements({
    required this.heightCm,
    required this.weightKg,
  });

  final int heightCm;
  final int weightKg;
}

class _AttributeBiases {
  const _AttributeBiases({
    required this.finishing,
    required this.passing,
    required this.dribbling,
    required this.tackling,
    required this.firstTouch,
    required this.goalkeeping,
    required this.decisions,
    required this.composure,
    required this.anticipation,
    required this.positioning,
    required this.vision,
    required this.workRate,
    required this.pace,
    required this.acceleration,
    required this.agility,
    required this.stamina,
    required this.strength,
    required this.jumping,
  });

  final int finishing;
  final int passing;
  final int dribbling;
  final int tackling;
  final int firstTouch;
  final int goalkeeping;
  final int decisions;
  final int composure;
  final int anticipation;
  final int positioning;
  final int vision;
  final int workRate;
  final int pace;
  final int acceleration;
  final int agility;
  final int stamina;
  final int strength;
  final int jumping;
}
