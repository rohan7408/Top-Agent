import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
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
        Material(
          color: AppColors.navy,
          child: InkWell(
            onTap: () => context.push(AppRoutes.clubs),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.public_rounded,
                      color: AppColors.amber, size: 16),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      game.isAgencyAtClientCapacity
                          ? 'Agency full · upgrade Office'
                          : '$leagueName · ${game.clubs.length} clubs',
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
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.muted, size: 18),
                ],
              ),
            ),
          ),
        ),
        CompactTableHeader(
          identityLabel: 'SCOUTED PLAYER',
          trailing: const [
            CompactColumnLabel('AGE', width: 28),
            CompactColumnLabel('OVR', width: 38),
            CompactColumnLabel('POT', width: 38),
            CompactColumnLabel('SIGN', width: 48),
          ],
        ),
        Expanded(
          child: ListView.builder(
            key: const Key('talentList'),
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: talents.length,
            itemBuilder: (context, index) {
              final player = talents[index];
              return _TalentRow(
                player: player,
                isAlternate: index.isOdd,
                onOpen: () => context.push(AppRoutes.playerDetails(player.id)),
                onRecruit: () => _recruit(context, ref, player),
                canRecruit: !game.isAgencyAtClientCapacity,
              );
            },
          ),
        ),
      ],
    );
  }

  void _recruit(BuildContext context, WidgetRef ref, Player player) {
    final result =
        ref.read(gameControllerProvider.notifier).recruitPlayer(player.id);
    final message = switch (result) {
      RecruitmentResult.success => '${player.name} joined your agency.',
      RecruitmentResult.noActiveGame => 'Start a career before recruiting.',
      RecruitmentResult.playerNotFound => 'That player no longer exists.',
      RecruitmentResult.playerUnavailable =>
        '${player.name} is no longer available.',
      RecruitmentResult.officeFull =>
        'Agency full · upgrade the Office before recruiting another player.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TalentRow extends StatelessWidget {
  const _TalentRow({
    required this.player,
    required this.isAlternate,
    required this.onOpen,
    required this.onRecruit,
    required this.canRecruit,
  });

  final Player player;
  final bool isAlternate;
  final VoidCallback onOpen;
  final VoidCallback onRecruit;
  final bool canRecruit;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('talentCard-${player.id}'),
      color: isAlternate ? AppColors.panelAlt : AppColors.navy,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          height: 59,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.slate)),
          ),
          child: Row(
            children: [
              Container(width: 3, color: AppColors.amber),
              const SizedBox(width: 7),
              CompactPositionBadge(label: player.position.shortLabel),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
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
              CompactRatingCell(
                value: player.potential,
                color: AppColors.teal,
                emphasized: true,
              ),
              SizedBox(
                width: 48,
                child: IconButton(
                  key: Key('recruitPlayerButton-${player.id}'),
                  tooltip: canRecruit
                      ? 'Recruit player'
                      : 'Upgrade Office for more client capacity',
                  onPressed: canRecruit ? onRecruit : null,
                  color: AppColors.teal,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
