import 'dart:math';

import '../models/scout.dart';
import 'agency_trust_calculator.dart';

class ScoutCandidateGenerator {
  const ScoutCandidateGenerator({
    this.trustCalculator = const AgencyTrustCalculator(),
  });

  final AgencyTrustCalculator trustCalculator;

  static const int candidatePoolSize = 4;

  static const _firstNames = [
    'Maya',
    'Daniel',
    'Sofia',
    'Jonas',
    'Aisha',
    'Marco',
    'Nina',
    'Tomas',
    'Leila',
    'Ruben',
    'Anika',
    'Emil',
  ];

  static const _lastNames = [
    'Bennett',
    'Costa',
    'Kovac',
    'Mensah',
    'Novak',
    'Silva',
    'Meyer',
    'Rossi',
    'Diallo',
    'Petrov',
    'Santos',
    'Ibrahim',
  ];

  List<Scout> generateInitial({
    required int reputation,
    required int seed,
    required String idPrefix,
    int officeLevel = 1,
  }) =>
      _generate(
        existing: const [],
        reputation: reputation,
        seed: seed,
        idPrefix: idPrefix,
        officeLevel: officeLevel,
      );

  List<Scout> replenish({
    required List<Scout> existing,
    required int reputation,
    required int seed,
    required String idPrefix,
    int officeLevel = 1,
  }) =>
      _generate(
        existing: existing,
        reputation: reputation,
        seed: seed,
        idPrefix: idPrefix,
        officeLevel: officeLevel,
      );

  List<Scout> _generate({
    required List<Scout> existing,
    required int reputation,
    required int seed,
    required String idPrefix,
    required int officeLevel,
  }) {
    final candidateCount = existing.where((scout) => scout.isCandidate).length;
    final additions = <Scout>[];
    for (var index = candidateCount; index < candidatePoolSize; index++) {
      final random = Random(seed ^ (index * 104729));
      final center = reputation < 0
          ? (38 + (reputation / 5)).round().clamp(25, 38)
          : (42 + (log(reputation + 1) * 7)).round().clamp(35, 86);
      final generatedAbility = (center - 10 + random.nextInt(24)).clamp(25, 95);
      final ability = index == 0 && reputation < 5
          ? generatedAbility.clamp(25, 49)
          : generatedAbility;
      final salary = ((ability * 14) + 120).roundToDouble();
      final firstName = _firstNames[random.nextInt(_firstNames.length)];
      final lastName = _lastNames[random.nextInt(_lastNames.length)];
      additions.add(
        Scout(
          id: '$idPrefix-scout-${existing.length + additions.length + 1}',
          name: '$firstName $lastName',
          ability: ability,
          salary: salary,
          agencyId: Scout.candidatePoolAgencyId,
          agencyTrust: trustCalculator.initialScoutTrust(
            scoutAbility: ability,
            reputation: reputation,
            officeLevel: officeLevel,
          ),
        ),
      );
    }
    return additions;
  }
}
