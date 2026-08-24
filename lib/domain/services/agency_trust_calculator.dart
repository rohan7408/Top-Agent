import 'dart:math';

class AgencyTrustCalculator {
  const AgencyTrustCalculator();

  static const int maximumTrust = 300;
  static const int clientExitThreshold = 50;
  static const int scoutJoiningThreshold = 80;

  int initialPlayerTrust({
    required int playerAbility,
    required int reputation,
    required int officeLevel,
  }) {
    final ratingPressure = max(0, playerAbility - 40) * 2.4;
    return (145 +
            (reputation.clamp(-300, 600) / 4) +
            (officeLevel * 10) -
            ratingPressure)
        .round()
        .clamp(0, maximumTrust);
  }

  int initialScoutTrust({
    required int scoutAbility,
    required int reputation,
    required int officeLevel,
  }) {
    final ratingPressure = max(0, scoutAbility - 35) * 2.2;
    return (140 +
            (reputation.clamp(-300, 600) / 3) +
            (officeLevel * 12) -
            ratingPressure)
        .round()
        .clamp(0, maximumTrust);
  }

  int updatePlayerTrust({
    required int currentTrust,
    required int playerAbility,
    required int reputation,
    required int officeLevel,
    required int relationshipWeeks,
  }) {
    final timeTrust = min(80, relationshipWeeks ~/ 2);
    final target = (initialPlayerTrust(
              playerAbility: playerAbility,
              reputation: reputation,
              officeLevel: officeLevel,
            ) +
            timeTrust)
        .clamp(0, maximumTrust);
    return _moveToward(currentTrust, target);
  }

  int updateScoutTrust({
    required int currentTrust,
    required int scoutAbility,
    required int reputation,
    required int officeLevel,
    required int employmentWeeks,
  }) {
    final timeTrust = min(70, employmentWeeks ~/ 2);
    final target = (initialScoutTrust(
              scoutAbility: scoutAbility,
              reputation: reputation,
              officeLevel: officeLevel,
            ) +
            timeTrust)
        .clamp(0, maximumTrust);
    return _moveToward(currentTrust, target);
  }

  double clientExitChance(int trust) {
    if (trust >= clientExitThreshold) return 0;
    return ((clientExitThreshold - trust) * 0.02).clamp(0.02, 0.75);
  }

  int _moveToward(int current, int target) {
    final difference = target - current;
    if (difference == 0) return current.clamp(0, maximumTrust);
    var change = (difference / 12).round().clamp(-5, 5);
    if (change == 0) change = difference > 0 ? 1 : -1;
    return (current + change).clamp(0, maximumTrust);
  }
}
