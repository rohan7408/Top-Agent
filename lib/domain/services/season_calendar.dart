enum TransferWindowKind { midSeason, main }

class TransferWindowStatus {
  const TransferWindowStatus({
    required this.kind,
    required this.startWeek,
    required this.endWeek,
    required this.currentWeek,
  });

  final TransferWindowKind kind;
  final int startWeek;
  final int endWeek;
  final int currentWeek;

  int get elapsedWeeks => currentWeek - startWeek + 1;
  int get totalWeeks => endWeek - startWeek + 1;
}

class SeasonCalendar {
  const SeasonCalendar();

  static const int weeksPerSeason = 50;
  static const int midWindowStartWeek = 20;
  static const int midWindowEndWeek = 24;
  static const int mainWindowStartWeek = 40;
  static const int mainWindowEndWeek = weeksPerSeason;

  TransferWindowStatus? transferWindowForWeek(int week) {
    if (week >= midWindowStartWeek && week <= midWindowEndWeek) {
      return TransferWindowStatus(
        kind: TransferWindowKind.midSeason,
        startWeek: midWindowStartWeek,
        endWeek: midWindowEndWeek,
        currentWeek: week,
      );
    }
    if (week >= mainWindowStartWeek && week <= mainWindowEndWeek) {
      return TransferWindowStatus(
        kind: TransferWindowKind.main,
        startWeek: mainWindowStartWeek,
        endWeek: mainWindowEndWeek,
        currentWeek: week,
      );
    }
    return null;
  }

  bool isTransferWindow(int week) => transferWindowForWeek(week) != null;
}
