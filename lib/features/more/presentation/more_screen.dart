import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
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
          key: const Key('moreOfficeButton'),
          icon: Icons.business_rounded,
          title: 'Office & scouts',
          subtitle:
              'Level ${game.office.level} · ${game.representedPlayers.length}/${game.office.clientCapacity} clients · ${game.hiredScouts.length}/${game.office.scoutCapacity} scouts',
          value: '${GameFormatters.compactCurrency(
            game.hiredScouts.fold<double>(
              0,
              (total, scout) => total + scout.salary,
            ),
          )}/wk',
          onTap: () => context.push(AppRoutes.office),
        ),
        _MoreLinkRow(
          icon: Icons.grass_rounded,
          title: 'Training Ground',
          subtitle:
              'Level ${game.trainingGround.level} · prospects ${game.trainingGround.minimumAbility}-${game.trainingGround.maximumAbility}',
          value:
              '${game.trainingGround.weeksUntilIntake(game.currentAbsoluteWeek)} weeks',
          onTap: () => context.push(AppRoutes.office),
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
  Widget build(BuildContext context) => Material(
        color: AppColors.navy,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 58,
            padding: const EdgeInsets.fromLTRB(11, 0, 8, 0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.slate)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
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
        ),
      );
}
