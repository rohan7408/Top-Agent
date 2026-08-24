import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../core/widgets/section_placeholder.dart';
import '../../../domain/models/player.dart';

class TalentsScreen extends ConsumerWidget {
  const TalentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();
    final talents = game.availableTalents;
    final leagueName = game.leagues.firstOrNull?.name ?? 'Football world';

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Material(
            color: AppColors.navy,
            child: InkWell(
              onTap: () => context.push(AppRoutes.clubs),
              child: Padding(
                padding: const EdgeInsets.only(left: 13, right: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.public_rounded,
                      color: AppColors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        game.isAgencyAtClientCapacity
                            ? 'Agency full · upgrade Office'
                            : '$leagueName · ${game.clubs.length} clubs',
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Text(
                      '${game.representedPlayers.length}/${game.office.clientCapacity} CLIENTS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.teal,
                            fontSize: 8,
                          ),
                    ),
                    IconButton(
                      key: const Key('clearTalentPoolButton'),
                      tooltip: 'Clear talent pool',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: AppSizes.minTouchTarget,
                        height: AppSizes.minTouchTarget,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: talents.isEmpty
                          ? null
                          : () => _confirmClearPool(
                                context,
                                ref,
                                talents.length,
                              ),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        CompactTableHeader(
          identityLabel: 'SCOUTED PLAYER',
          identityIndent: 36,
          trailing: const [
            CompactColumnLabel('AGE', width: 28),
            CompactColumnLabel('OVR', width: 38),
            CompactColumnLabel('POT', width: 38),
          ],
        ),
        Expanded(
          child: talents.isEmpty
              ? const _EmptyTalentPool()
              : ListView.builder(
                  key: const Key('talentList'),
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: talents.length,
                  itemBuilder: (context, index) {
                    final player = talents[index];
                    return _TalentRow(
                      player: player,
                      showPotential: game.canViewPotential(player),
                      isAlternate: index.isOdd,
                      onOpen: () =>
                          context.push(AppRoutes.playerDetails(player.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmClearPool(
    BuildContext context,
    WidgetRef ref,
    int talentCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear talent pool?'),
        content: Text(
          'Remove all $talentCount unsigned prospects? Your clients and club players will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmClearTalentPoolButton'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.paper,
            ),
            child: const Text('Clear pool'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = ref.read(gameControllerProvider.notifier).clearTalentPool();
    if (!context.mounted) return;
    final message = switch (result) {
      TalentPoolActionResult.success => 'Talent pool cleared.',
      TalentPoolActionResult.noActiveGame =>
        'Start a career before managing talents.',
      TalentPoolActionResult.alreadyEmpty => 'Talent pool is already empty.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmptyTalentPool extends StatelessWidget {
  const _EmptyTalentPool();

  @override
  Widget build(BuildContext context) => const Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.fromLTRB(13, 16, 13, 0),
          child: CompactEmptyState(
            icon: Icons.travel_explore_rounded,
            title: 'Talent pool empty',
            message:
                'Scouts and your Training Ground can discover new prospects.',
            accent: AppColors.amber,
          ),
        ),
      );
}

class _TalentRow extends StatelessWidget {
  const _TalentRow({
    required this.player,
    required this.isAlternate,
    required this.showPotential,
    required this.onOpen,
  });

  final Player player;
  final bool isAlternate;
  final bool showPotential;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return CompactRowSurface(
      key: Key('talentCard-${player.id}'),
      railColor: AppColors.amber,
      isAlternate: isAlternate,
      onTap: onOpen,
      semanticLabel:
          '${player.name}, ${player.position.label}, ${player.age} years old',
      child: Row(
        children: [
          CompactPositionBadge(label: player.position.shortLabel),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.position.label}  ·  ${GameFormatters.compactCurrency(player.value)}',
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
            width: 28,
            child: Text(
              '${player.age}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          CompactRatingCell(
            value: player.ability,
            color: compactRatingColor(player.ability),
          ),
          if (showPotential)
            CompactRatingCell(
              value: player.potential,
              color: AppColors.teal,
              emphasized: true,
            )
          else
            const SizedBox(
              width: 38,
              child: Center(
                child: Text(
                  '—',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
