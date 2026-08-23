class AgencyOffice {
  const AgencyOffice({this.level = 1});

  static const int maximumLevel = 5;

  final int level;

  int get clientCapacity => switch (level) {
        1 => 3,
        2 => 6,
        3 => 12,
        4 => 25,
        _ => 50,
      };

  int get scoutCapacity => switch (level) {
        1 => 1,
        2 => 2,
        3 => 3,
        4 => 5,
        _ => 8,
      };

  double get salaryCommissionRate => switch (level) {
        1 => 0.02,
        2 => 0.04,
        3 => 0.06,
        4 => 0.08,
        _ => 0.10,
      };

  double get agentFeeRate => switch (level) {
        1 => 0.08,
        2 => 0.10,
        3 => 0.12,
        4 => 0.15,
        _ => 0.18,
      };

  bool get canUpgrade => level < maximumLevel;

  double get nextUpgradeMoneyCost => switch (level) {
        1 => 25000,
        2 => 100000,
        3 => 500000,
        4 => 2500000,
        _ => 0,
      };

  int get nextUpgradeReputationRequirement => switch (level) {
        1 => 5,
        2 => 20,
        3 => 60,
        4 => 200,
        _ => 0,
      };

  int get nextUpgradeReputationCost => switch (level) {
        1 => 3,
        2 => 10,
        3 => 30,
        4 => 100,
        _ => 0,
      };

  AgencyOffice upgrade() => canUpgrade ? AgencyOffice(level: level + 1) : this;

  Map<String, Object> toJson() => {'level': level};

  factory AgencyOffice.fromJson(Map<String, Object?> json) => AgencyOffice(
        level: ((json['level'] as int?) ?? 1).clamp(1, maximumLevel),
      );

  static AgencyOffice supporting({
    required int clientCount,
    required int scoutCount,
    int preferredLevel = 1,
  }) {
    for (var candidate = preferredLevel.clamp(1, maximumLevel);
        candidate <= maximumLevel;
        candidate++) {
      final office = AgencyOffice(level: candidate);
      if (office.clientCapacity >= clientCount &&
          office.scoutCapacity >= scoutCount) {
        return office;
      }
    }
    return const AgencyOffice(level: maximumLevel);
  }
}
