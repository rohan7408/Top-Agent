class SavedCareerSummary {
  const SavedCareerSummary({
    required this.slotId,
    required this.agentName,
    required this.agencyName,
    required this.currentSeason,
    required this.currentWeek,
    required this.careerStartYear,
    required this.savedAt,
  });

  final String slotId;
  final String agentName;
  final String agencyName;
  final int currentSeason;
  final int currentWeek;
  final int careerStartYear;
  final DateTime savedAt;

  String get seasonLabel {
    final startYear = careerStartYear + currentSeason - 1;
    return '$startYear/${startYear + 1}';
  }
}
