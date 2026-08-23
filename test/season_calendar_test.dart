import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/domain/models/agency_transaction.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/services/season_calendar.dart';

void main() {
  const calendar = SeasonCalendar();

  test('transfer-window progress matches the real simulation windows', () {
    expect(calendar.transferWindowForWeek(19), isNull);

    final midStart = calendar.transferWindowForWeek(20)!;
    expect(midStart.kind, TransferWindowKind.midSeason);
    expect(midStart.elapsedWeeks, 1);
    expect(midStart.totalWeeks, 5);
    expect(calendar.transferWindowForWeek(24)!.elapsedWeeks, 5);
    expect(calendar.transferWindowForWeek(25), isNull);

    final mainStart = calendar.transferWindowForWeek(40)!;
    expect(mainStart.kind, TransferWindowKind.main);
    expect(mainStart.elapsedWeeks, 1);
    expect(mainStart.totalWeeks, 11);
    expect(calendar.transferWindowForWeek(50)!.elapsedWeeks, 11);
  });

  test('status balance totals only transactions from the current week', () {
    final game = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2025, 1, 1),
    );
    final updated = game.copyWith(
      agencyTransactions: const [
        AgencyTransaction(
          id: 'previous',
          type: AgencyTransactionType.scoutPayroll,
          amount: -500,
          description: 'Previous week',
          season: 1,
          week: 2,
        ),
        AgencyTransaction(
          id: 'income',
          type: AgencyTransactionType.salaryCommission,
          amount: 1200,
          description: 'Commission',
          season: 1,
          week: 3,
        ),
        AgencyTransaction(
          id: 'expense',
          type: AgencyTransactionType.scoutPayroll,
          amount: -300,
          description: 'Payroll',
          season: 1,
          week: 3,
        ),
      ],
      agent: game.agent.copyWith(currentWeek: 3),
    );

    expect(updated.currentYear, 2025);
    expect(updated.currentWeekAgencyBalance, 900);
  });
}
