import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../core/widgets/compact_page_chrome.dart';
import '../../../core/widgets/section_placeholder.dart';
import '../../../domain/models/agency_transaction.dart';
import '../../../domain/models/contract.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 50,
          title: const CompactPageTitle(
            title: 'Finance',
            eyebrow: 'Agency accounts',
            accent: AppColors.amber,
          ),
        ),
        body: const FinanceScreen(),
      );
}

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();

    final clients = game.representedPlayers;
    final clientIds = clients.map((player) => player.id).toSet();
    final totalFees = game.agent.totalAgentFeesEarned;
    final portfolioValue = clients.fold<double>(
      0,
      (total, player) => total + player.value,
    );
    final clientWages = clients.fold<double>(
      0,
      (total, player) => total + player.salary,
    );
    final scoutCost = game.hiredScouts.fold<double>(
      0,
      (total, scout) => total + scout.salary,
    );
    final commissionContracts = <String, Contract>{};
    for (final contract in game.contracts) {
      if (!clientIds.contains(contract.playerId) ||
          contract.endSeason < game.currentSeason) {
        continue;
      }
      final current = commissionContracts[contract.playerId];
      if (current == null || contract.startSeason >= current.startSeason) {
        commissionContracts[contract.playerId] = contract;
      }
    }
    final clientsById = {for (final player in clients) player.id: player};
    final weeklyCommission = commissionContracts.entries.fold<double>(
      0,
      (total, entry) =>
          total +
          ((clientsById[entry.key]?.salary ?? entry.value.salary) *
              entry.value.salaryCommissionRate),
    );
    final transactions = game.agencyTransactions.reversed.toList();

    return Column(
      key: const Key('agencyFinanceScreen'),
      children: [
        CompactSectionBar(
          title: 'Agency position',
          trailing:
              '${game.seasonLabel(game.currentSeason)} · W${game.currentWeek}',
        ),
        _AgencyMetricStrip(
          items: [
            ('CASH', GameFormatters.compactCurrency(game.agent.money)),
            ('AGENT FEES', GameFormatters.compactCurrency(totalFees)),
            ('CLIENTS', '${clients.length}'),
            ('REP', '${game.agent.reputation}'),
          ],
        ),
        CompactInfoRow(
          label: 'Client portfolio value',
          value: GameFormatters.compactCurrency(portfolioValue),
          valueColor: AppColors.amber,
          height: 31,
        ),
        CompactInfoRow(
          label: 'Combined client wages',
          value: '${GameFormatters.compactCurrency(clientWages)}/wk',
          height: 31,
        ),
        CompactInfoRow(
          label: 'Salary commission income',
          value: '+${GameFormatters.compactCurrency(weeklyCommission)}/wk',
          valueColor: weeklyCommission > 0 ? AppColors.teal : AppColors.muted,
          height: 31,
        ),
        CompactInfoRow(
          label: 'Career salary commission',
          value: GameFormatters.compactCurrency(
            game.agent.totalSalaryCommissionEarned,
          ),
          valueColor: AppColors.teal,
          height: 31,
        ),
        CompactInfoRow(
          label: 'Scout payroll',
          value: '-${GameFormatters.compactCurrency(scoutCost)}/wk',
          valueColor: scoutCost > 0 ? AppColors.danger : AppColors.muted,
          height: 31,
        ),
        CompactSectionBar(
          title: 'Agency transactions',
          trailing: '${transactions.length} ENTRIES',
        ),
        const CompactTableHeader(
          identityLabel: 'TRANSACTION',
          trailing: [
            CompactColumnLabel('WEEK', width: 55),
            CompactColumnLabel('AMOUNT', width: 72),
          ],
        ),
        Expanded(
          child: transactions.isEmpty
              ? const _NoTransactionsYet()
              : ListView.builder(
                  key: const Key('agencyTransactionList'),
                  padding: const EdgeInsets.only(bottom: 14),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) => _TransactionRow(
                    transaction: transactions[index],
                    seasonLabel: game.seasonLabel(transactions[index].season),
                    isAlternate: index.isOdd,
                  ),
                ),
        ),
      ],
    );
  }
}

class _AgencyMetricStrip extends StatelessWidget {
  const _AgencyMetricStrip({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        decoration: const BoxDecoration(
          color: AppColors.navy,
          border: Border(bottom: BorderSide(color: AppColors.slate)),
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[index].$1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.muted,
                              fontSize: 8,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[index].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: index == 0
                              ? AppColors.teal
                              : index == 1
                                  ? AppColors.amber
                                  : AppColors.paper,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (index != items.length - 1)
                const VerticalDivider(width: 1, thickness: 1),
            ],
          ],
        ),
      );
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.seasonLabel,
    required this.isAlternate,
  });

  final AgencyTransaction transaction;
  final String seasonLabel;
  final bool isAlternate;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: isAlternate ? AppColors.panelAlt : AppColors.navy,
          border: Border(
            left: BorderSide(
              color:
                  transaction.amount >= 0 ? AppColors.teal : AppColors.danger,
              width: 3,
            ),
            bottom: const BorderSide(color: AppColors.slate),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.type.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 9),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 55,
              child: Text(
                '${transaction.week}\n$seasonLabel',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              width: 72,
              height: 52,
              alignment: Alignment.center,
              color:
                  (transaction.amount >= 0 ? AppColors.teal : AppColors.danger)
                      .withValues(alpha: 0.14),
              child: Text(
                '${transaction.amount >= 0 ? '+' : '-'}${GameFormatters.compactCurrency(transaction.amount.abs())}',
                style: TextStyle(
                  color: transaction.amount >= 0
                      ? AppColors.teal
                      : AppColors.danger,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
}

class _NoTransactionsYet extends StatelessWidget {
  const _NoTransactionsYet();

  @override
  Widget build(BuildContext context) => const SectionPlaceholder(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions yet',
        message: 'Agency income and expenses will be recorded here.',
      );
}
