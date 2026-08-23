import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/transfer_record.dart';

class WorldTransfersScreen extends ConsumerWidget {
  const WorldTransfersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();
    final recent = [...game.transfers]..sort(_byMostRecent);
    final records = [...game.transfers]..sort(_byHighestFee);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text('World transfers'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _TransferHalf(
              key: const Key('recentTransfersHalf'),
              title: 'Recent transfers',
              trailing: '${recent.length} COMPLETED',
              transfers: recent,
              game: game,
              listKey: const Key('recentTransferList'),
              accent: AppColors.ratingBlue,
            ),
          ),
          Container(height: 3, color: AppColors.midnight),
          Expanded(
            child: _TransferHalf(
              key: const Key('allTimeTransfersHalf'),
              title: 'Top transfers of all time',
              trailing: records.isEmpty
                  ? 'NO RECORDS'
                  : 'RECORD ${GameFormatters.compactCurrency(records.first.fee)}',
              transfers: records,
              game: game,
              listKey: const Key('allTimeTransferList'),
              accent: AppColors.amber,
              showRank: true,
            ),
          ),
        ],
      ),
    );
  }

  static int _byMostRecent(TransferRecord first, TransferRecord second) {
    final season = second.season.compareTo(first.season);
    if (season != 0) return season;
    final week = second.week.compareTo(first.week);
    if (week != 0) return week;
    return second.id.compareTo(first.id);
  }

  static int _byHighestFee(TransferRecord first, TransferRecord second) {
    final fee = second.fee.compareTo(first.fee);
    return fee != 0 ? fee : _byMostRecent(first, second);
  }
}

class _TransferHalf extends StatelessWidget {
  const _TransferHalf({
    required this.title,
    required this.trailing,
    required this.transfers,
    required this.game,
    required this.listKey,
    required this.accent,
    this.showRank = false,
    super.key,
  });

  final String title;
  final String trailing;
  final List<TransferRecord> transfers;
  final GameState game;
  final Key listKey;
  final Color accent;
  final bool showRank;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          CompactSectionBar(
            title: title,
            trailing: trailing,
            accent: accent,
          ),
          const CompactTableHeader(
            identityLabel: 'PLAYER / MOVE',
            trailing: [
              CompactColumnLabel('WHEN', width: 58),
              CompactColumnLabel('FEE', width: 74),
            ],
          ),
          Expanded(
            child: transfers.isEmpty
                ? _EmptyTransfers(accent: accent)
                : ListView.builder(
                    key: listKey,
                    padding: EdgeInsets.zero,
                    itemCount: transfers.length,
                    itemBuilder: (context, index) => _TransferRow(
                      key: Key(
                        '${showRank ? 'record' : 'recent'}TransferRow-${transfers[index].id}',
                      ),
                      transfer: transfers[index],
                      game: game,
                      rank: showRank ? index + 1 : null,
                      accent: accent,
                      isAlternate: index.isOdd,
                    ),
                  ),
          ),
        ],
      );
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.game,
    required this.accent,
    required this.isAlternate,
    this.rank,
    super.key,
  });

  final TransferRecord transfer;
  final GameState game;
  final Color accent;
  final bool isAlternate;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final player = game.players
        .where((candidate) => candidate.id == transfer.playerId)
        .firstOrNull;
    final from = game.clubById(transfer.fromClubId)?.name ?? 'Unknown club';
    final to = game.clubById(transfer.toClubId)?.name ?? 'Unknown club';
    return Material(
      color: isAlternate ? AppColors.panelAlt : AppColors.navy,
      child: InkWell(
        onTap: player == null
            ? null
            : () => context.push(AppRoutes.playerDetails(player.id)),
        child: Container(
          height: 50,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.slate)),
          ),
          child: Row(
            children: [
              Container(width: 3, color: accent),
              if (rank != null)
                SizedBox(
                  width: 28,
                  child: Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: rank! <= 3 ? AppColors.amber : AppColors.muted,
                          fontSize: 8,
                        ),
                  ),
                )
              else
                const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player?.name ?? 'Unknown player',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.paper,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$from → $to',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontSize: 9,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 58,
                child: Text(
                  '${game.seasonLabel(transfer.season)}\nW${transfer.week}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 8,
                        height: 1.2,
                      ),
                ),
              ),
              Container(
                width: 74,
                height: double.infinity,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                color: accent.withValues(alpha: 0.08),
                child: Text(
                  GameFormatters.compactCurrency(transfer.fee),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransfers extends StatelessWidget {
  const _EmptyTransfers({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz_rounded, color: accent, size: 25),
            const SizedBox(height: 5),
            Text(
              'No completed transfers yet',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      );
}
