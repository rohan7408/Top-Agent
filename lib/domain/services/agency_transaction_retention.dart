import '../models/agency_transaction.dart';
import '../models/game_state.dart';

class AgencyTransactionRetention {
  const AgencyTransactionRetention();

  static const int retainedWeeks = 20;
  static const int maximumEntries = 60;

  GameState clean(GameState game) {
    final retained = prune(
      game.agencyTransactions,
      currentSeason: game.currentSeason,
      currentWeek: game.currentWeek,
    );
    if (retained.length == game.agencyTransactions.length) return game;
    return game.copyWith(agencyTransactions: retained);
  }

  List<AgencyTransaction> prune(
    Iterable<AgencyTransaction> transactions, {
    required int currentSeason,
    required int currentWeek,
  }) {
    final currentAbsoluteWeek = _absoluteWeek(currentSeason, currentWeek);
    final firstRetainedWeek = currentAbsoluteWeek - retainedWeeks + 1;
    final recent = transactions.where((transaction) {
      final week = _absoluteWeek(transaction.season, transaction.week);
      return week >= firstRetainedWeek && week <= currentAbsoluteWeek;
    }).toList(growable: false)
      ..sort((a, b) {
        final byWeek = _absoluteWeek(a.season, a.week)
            .compareTo(_absoluteWeek(b.season, b.week));
        return byWeek != 0 ? byWeek : a.id.compareTo(b.id);
      });
    if (recent.length <= maximumEntries) return recent;
    return recent.sublist(recent.length - maximumEntries);
  }

  int _absoluteWeek(int season, int week) => ((season - 1) * 50) + week;
}
