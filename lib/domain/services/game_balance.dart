import 'dart:math';

import '../models/player.dart';
import '../models/player_training_plan.dart';

/// Central tuning rules for the connected football economy and player health.
///
/// Keep formulas here pure so a balance change can be tested without running a
/// widget or advancing a save. Existing saves remain compatible; stored values
/// are only recalculated when an existing game event already calls for it.
class GameBalance {
  const GameBalance();

  static const int weeksPerSeason = 50;

  double playerMarketValue({
    required int ability,
    required int potential,
    required int age,
    required PlayerPosition position,
  }) {
    final safeAbility = ability.clamp(1, 99);
    final base = pow(max(1, safeAbility - 25), 2.5).toDouble() * 1600;
    final potentialPremium =
        (1 + (max(0, potential - safeAbility) * 0.025)).clamp(1.0, 1.55);
    final ageMultiplier = switch (age) {
      <= 20 => 1.12,
      <= 23 => 1.18,
      <= 26 => 1.10,
      <= 29 => 1.0,
      <= 32 => 0.80,
      <= 35 => 0.58,
      _ => 0.40,
    };
    final positionMultiplier = switch (position) {
      PlayerPosition.goalkeeper => 0.88,
      PlayerPosition.defender => 0.94,
      PlayerPosition.midfielder => 1.0,
      PlayerPosition.forward => 1.06,
    };
    return (base * potentialPremium * ageMultiplier * positionMultiplier)
        .roundToDouble();
  }

  double weeklyWage({
    required int ability,
    required int potential,
    required int age,
    double marketMultiplier = 1,
  }) {
    final safeAbility = ability.clamp(1, 99);
    final potentialPremium =
        (1 + (max(0, potential - safeAbility) * 0.008)).clamp(1.0, 1.16);
    final experienceMultiplier = switch (age) {
      <= 19 => 0.72,
      <= 22 => 0.86,
      <= 30 => 1.0,
      <= 33 => 0.94,
      _ => 0.84,
    };
    return (pow(safeAbility, 3).toDouble() *
            0.12 *
            potentialPremium *
            experienceMultiplier *
            marketMultiplier)
        .roundToDouble();
  }

  double agentSigningFee({
    required double weeklyWage,
    required double clubBudget,
    required int contractLength,
    required double feeRate,
  }) {
    final calculated = weeklyWage *
        weeksPerSeason *
        contractLength.clamp(1, 6) *
        feeRate.clamp(0, 0.30);
    return min(calculated, clubBudget * 0.035).roundToDouble();
  }

  double representationTerminationCost({
    required double weeklySalary,
    required double marketValue,
  }) =>
      max(2500, (weeklySalary * 2) + (marketValue * 0.0005)).roundToDouble();

  double transferFee({
    required double marketValue,
    required double negotiationDelta,
    required double randomFactor,
  }) {
    final multiplier =
        (0.90 + negotiationDelta + (randomFactor * 0.20)).clamp(0.82, 1.22);
    return (marketValue * multiplier).roundToDouble();
  }

  double weeklyFatigueRecovery(int stamina) =>
      12 + (stamina.clamp(1, 99) * 0.12);

  double matchFatigueLoad({
    required int minutes,
    required int stamina,
    required int consecutiveStarts,
    required double tacticalLoad,
  }) {
    final minutesRatio = (minutes / 90).clamp(0.0, 1.35);
    final staminaPenalty = (100 - stamina.clamp(1, 99)) * 0.08;
    final repetitionLoad = min(8.0, consecutiveStarts * 1.25);
    return (minutesRatio * (24 + staminaPenalty)) +
        repetitionLoad +
        tacticalLoad;
  }

  double incidentalInjuryChance({
    required bool hasClub,
    required int age,
    required double fatigue,
    required int consecutiveStarts,
  }) {
    final baseRisk = hasClub ? 0.00065 : 0.00018;
    return (baseRisk *
            _ageInjuryMultiplier(age) *
            _fatigueInjuryMultiplier(fatigue) *
            _repetitionInjuryMultiplier(consecutiveStarts))
        .clamp(0.0, 0.08);
  }

  double matchInjuryChance({
    required int age,
    required double durability,
    required double fatigue,
    required int consecutiveStarts,
  }) {
    final durabilityRisk = ((110 - durability) / 55).clamp(0.55, 1.55);
    return (0.004 *
            _ageInjuryMultiplier(age) *
            durabilityRisk *
            _fatigueInjuryMultiplier(fatigue) *
            _repetitionInjuryMultiplier(consecutiveStarts))
        .clamp(0.0, 0.16);
  }

  int weeklyTrainingProgress({
    required int age,
    required int ability,
    required int potential,
    required int coachAbility,
    required double fatigue,
    required TrainingIntensity intensity,
  }) {
    final ageProgress = switch (age) {
      <= 18 => 10,
      <= 21 => 8,
      <= 24 => 6,
      <= 28 => 4,
      <= 31 => 2,
      _ => 1,
    };
    final potentialBonus = ((potential - ability) ~/ 10).clamp(0, 4);
    final coachBonus = coachAbility ~/ 20;
    final fatiguePenalty = switch (fatigue) {
      >= 85 => 6,
      >= 70 => 4,
      >= 50 => 2,
      _ => 0,
    };
    final raw =
        max(1, ageProgress + potentialBonus + coachBonus - fatiguePenalty);
    return max(1, (raw * intensity.progressMultiplier).round());
  }

  double _ageInjuryMultiplier(int age) =>
      age <= 29 ? 1.0 : 1 + ((age - 29) * 0.07);

  double _fatigueInjuryMultiplier(double fatigue) {
    final normalized = fatigue.clamp(0, 100) / 55;
    return 1 + (normalized * normalized * 2.2);
  }

  double _repetitionInjuryMultiplier(int consecutiveStarts) =>
      1 + (max(0, consecutiveStarts - 2) * 0.09);
}
