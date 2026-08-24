import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();

    return ListView(
      key: const Key('moreScreen'),
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        CompactSectionBar(
          title: 'Agency management',
          trailing: game.agent.agencyName.toUpperCase(),
        ),
        _MoreLinkRow(
          key: const Key('moreFinanceButton'),
          icon: Icons.account_balance_wallet_rounded,
          title: 'Finance',
          subtitle: 'Cash position, commission and agency transactions',
          value: GameFormatters.compactCurrency(game.agent.money),
          accent: game.agent.money < 0 ? AppColors.danger : AppColors.amber,
          onTap: () => context.push(AppRoutes.finance),
        ),
        _MoreLinkRow(
          key: const Key('moreFacilitiesButton'),
          icon: Icons.apartment_rounded,
          title: 'Facilities',
          subtitle:
              'Office Level ${game.office.level} · Training Ground Level ${game.trainingGround.level}',
          value: '${game.office.clientCapacity} clients',
          onTap: () => context.push(AppRoutes.facilities),
        ),
        _MoreLinkRow(
          key: const Key('moreStaffButton'),
          icon: Icons.badge_rounded,
          title: 'Staff',
          subtitle: 'Hire scouts according to agency reputation and capacity',
          value: '${game.hiredScouts.length}/${game.office.scoutCapacity}',
          accent: AppColors.ratingBlue,
          onTap: () => context.push(AppRoutes.staff),
        ),
        CompactSectionBar(
          title: 'Football world',
          trailing: '${game.clubs.length} CLUBS',
          accent: AppColors.ratingBlue,
        ),
        _MoreLinkRow(
          key: const Key('moreClubsButton'),
          icon: Icons.stadium_rounded,
          title: 'Clubs & league',
          subtitle:
              '${game.leagues.length} league · fixtures, table and club details',
          value: game.seasonLabel(game.currentSeason),
          accent: AppColors.ratingBlue,
          onTap: () => context.push(AppRoutes.clubs),
        ),
        _MoreLinkRow(
          key: const Key('moreWorldTransfersButton'),
          icon: Icons.swap_horiz_rounded,
          title: 'Recent transfers',
          subtitle: 'Latest completed moves and all-time record fees',
          value: '${game.transfers.length}',
          accent: AppColors.amber,
          onTap: () => context.push(AppRoutes.transfers),
        ),
      ],
    );
  }
}

class _MoreLinkRow extends StatelessWidget {
  const _MoreLinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
    this.accent = AppColors.teal,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CompactRowSurface(
        railColor: accent,
        height: 58,
        onTap: onTap,
        semanticLabel: '$title, $subtitle, $value',
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadii.small,
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: AppColors.paper,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      );
}
