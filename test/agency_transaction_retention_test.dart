import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/agency_transaction.dart';
import 'package:football_agent/domain/services/agency_transaction_retention.dart';

void main() {
  test('agency finance retains only the latest 20 weeks and 60 entries', () {
    final transactions = [
      for (var absoluteWeek = 1; absoluteWeek <= 120; absoluteWeek++)
        for (var entry = 0; entry < 4; entry++)
          AgencyTransaction(
            id: 'transaction-$absoluteWeek-$entry',
            type: AgencyTransactionType.salaryCommission,
            amount: 100,
            description: 'Weekly commission',
            season: ((absoluteWeek - 1) ~/ 50) + 1,
            week: ((absoluteWeek - 1) % 50) + 1,
          ),
    ];

    final retained = const AgencyTransactionRetention().prune(
      transactions,
      currentSeason: 3,
      currentWeek: 20,
    );

    expect(retained, hasLength(60));
    expect(retained.first.id, 'transaction-106-0');
    expect(retained.last.id, 'transaction-120-3');
    expect(retained.every((item) => item.season == 3), isTrue);
  });
}
