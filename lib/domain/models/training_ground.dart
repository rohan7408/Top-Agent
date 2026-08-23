class TrainingGround {
  const TrainingGround({
    this.level = 1,
    this.lastIntakeAbsoluteWeek = 1,
  }) : assert(level >= 1 && level <= maximumLevel);

  static const int maximumLevel = 5;

  final int level;
  final int lastIntakeAbsoluteWeek;

  int get minimumAbility => const [32, 38, 44, 50, 56][level - 1];
  int get maximumAbility => const [48, 55, 62, 70, 78][level - 1];
  int get intakeIntervalWeeks => const [12, 10, 8, 6, 4][level - 1];
  bool get canUpgrade => level < maximumLevel;

  double get nextUpgradeMoneyCost => canUpgrade
      ? const [50000.0, 200000.0, 750000.0, 3000000.0][level - 1]
      : 0.0;

  int get nextUpgradeReputationRequirement =>
      canUpgrade ? const [10, 30, 80, 250][level - 1] : 0;

  int get nextUpgradeReputationCost =>
      canUpgrade ? const [5, 15, 40, 100][level - 1] : 0;

  int weeksUntilIntake(int currentAbsoluteWeek) {
    final elapsed = currentAbsoluteWeek - lastIntakeAbsoluteWeek;
    return (intakeIntervalWeeks - elapsed).clamp(0, intakeIntervalWeeks);
  }

  TrainingGround upgrade() => canUpgrade
      ? TrainingGround(
          level: level + 1,
          lastIntakeAbsoluteWeek: lastIntakeAbsoluteWeek,
        )
      : this;

  TrainingGround recordIntake(int absoluteWeek) => TrainingGround(
        level: level,
        lastIntakeAbsoluteWeek: absoluteWeek,
      );

  Map<String, Object> toJson() => {
        'level': level,
        'lastIntakeAbsoluteWeek': lastIntakeAbsoluteWeek,
      };

  factory TrainingGround.fromJson(Map<String, Object?> json) => TrainingGround(
        level: ((json['level'] as int?) ?? 1).clamp(1, maximumLevel),
        lastIntakeAbsoluteWeek: (json['lastIntakeAbsoluteWeek'] as int?) ?? 1,
      );
}
