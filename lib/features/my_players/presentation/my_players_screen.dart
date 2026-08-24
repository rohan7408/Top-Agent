import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../core/widgets/section_placeholder.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/player_season_stats.dart';

class MyPlayersScreen extends ConsumerWidget {
  const MyPlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();
    final players = game.representedPlayers;

    if (players.isEmpty) {
      return const SectionPlaceholder(
        icon: Icons.groups_2_outlined,
        title: 'Your roster is empty',
        message: 'Open Talents and recruit a prospect to build your agency.',
      );
    }

    return Column(
      children: [
        _RosterHeader(
          playerCount: players.length,
          portfolioValue:
              players.fold(0, (total, player) => total + player.value),
        ),
        CompactTableHeader(
          identityLabel: 'PLAYER / STATUS',
          trailing: const [
            CompactColumnLabel('AGE', width: 28),
            CompactColumnLabel('OVR', width: 36),
            CompactColumnLabel('P', width: 22),
            CompactColumnLabel('G', width: 20),
            CompactColumnLabel('A', width: 20),
            CompactColumnLabel('PTS', width: 30),
            CompactColumnLabel('EXP', width: 38),
          ],
        ),
        Expanded(
          child: ListView.builder(
            key: const Key('representedPlayerList'),
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final clubName = player.clubId == null
                  ? player.isRetired
                      ? 'Retired'
                      : 'Free agent'
                  : '${game.clubById(player.clubId!)?.name ?? 'Unknown club'}${player.isOnLoan ? ' (loan)' : ''}';
              final injury = game.activeInjuryForPlayer(player.id);
              final currentStats = _CurrentOutput.from(
                game
                    .statsForPlayer(player.id)
                    .where((stats) => stats.season == game.currentSeason),
              );
              return _PlayerRow(
                player: player,
                clubName: clubName,
                offerCount: game.pendingOffersForPlayer(player.id).length,
                availabilityLabel: injury == null
                    ? 'Fatigue ${player.fatigue.round()}%'
                    : game.injuryAvailabilityLabel(injury),
                isInjured: injury != null,
                isAlternate: index.isOdd,
                currentStats: currentStats,
                showPotential: game.canViewPotential(player),
                contractExpiry: player.contractEndSeason == null
                    ? '—'
                    : '${game.careerStartYear + player.contractEndSeason!}',
                isExpiringSoon: player.contractEndSeason != null &&
                    player.contractEndSeason! <= game.currentSeason + 1,
                onOpen: () => context.push(AppRoutes.playerDetails(player.id)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RosterHeader extends StatelessWidget {
  const _RosterHeader({
    required this.playerCount,
    required this.portfolioValue,
  });

  final int playerCount;
  final double portfolioValue;

  @override
  Widget build(BuildContext context) => CompactSectionBar(
        title:
            '$playerCount ${playerCount == 1 ? 'player' : 'players'} represented',
        trailing:
            'PORTFOLIO  ${GameFormatters.compactCurrency(portfolioValue)}',
        accent: AppColors.teal,
      );
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.clubName,
    required this.offerCount,
    required this.availabilityLabel,
    required this.isInjured,
    required this.isAlternate,
    required this.currentStats,
    required this.showPotential,
    required this.contractExpiry,
    required this.isExpiringSoon,
    required this.onOpen,
  });

  final Player player;
  final String clubName;
  final int offerCount;
  final String availabilityLabel;
  final bool isInjured;
  final bool isAlternate;
  final _CurrentOutput currentStats;
  final bool showPotential;
  final String contractExpiry;
  final bool isExpiringSoon;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final canSuggest = player.clubId == null && !player.isRetired;
    final railColor = player.isRetired
        ? AppColors.muted
        : isInjured
            ? AppColors.danger
            : canSuggest
                ? AppColors.amber
                : AppColors.teal;
    return CompactRowSurface(
      key: Key('representedPlayerCard-${player.id}'),
      railColor: railColor,
      isAlternate: isAlternate,
      onTap: onOpen,
      semanticLabel: '${player.name}, $clubName, ${player.age} years old',
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (offerCount > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        key: Key('playerOfferCount-${player.id}'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        color: AppColors.amber.withValues(alpha: 0.14),
                        child: Text(
                          '$offerCount ${offerCount == 1 ? 'OFFER' : 'OFFERS'}',
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.35,
                          ),
                        ),
                      ),
                    ],
                    if (showPotential) ...[
                      const SizedBox(width: 5),
                      Text(
                        'POT ${player.potential}',
                        key: Key('knownPotential-${player.id}'),
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.position.shortLabel}  ·  $clubName  ·  $availabilityLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isInjured ? AppColors.danger : AppColors.muted,
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
            width: 36,
          ),
          _NumberCell(value: '${currentStats.appearances}', width: 22),
          _NumberCell(value: '${currentStats.goals}', width: 20),
          _NumberCell(value: '${currentStats.assists}', width: 20),
          _NumberCell(
            value: currentStats.appearances == 0
                ? '—'
                : currentStats.averageRating.toStringAsFixed(1),
            width: 30,
            color: currentStats.appearances == 0
                ? AppColors.muted
                : AppColors.teal,
          ),
          _NumberCell(
            value: contractExpiry,
            width: 38,
            color: isExpiringSoon ? AppColors.amber : AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class _CurrentOutput {
  const _CurrentOutput({
    required this.appearances,
    required this.goals,
    required this.assists,
    required this.totalRating,
  });

  factory _CurrentOutput.from(Iterable<PlayerSeasonStats> rows) {
    var appearances = 0;
    var goals = 0;
    var assists = 0;
    var totalRating = 0.0;
    for (final row in rows) {
      appearances += row.appearances;
      goals += row.goals;
      assists += row.assists;
      totalRating += row.totalRating;
    }
    return _CurrentOutput(
      appearances: appearances,
      goals: goals,
      assists: assists,
      totalRating: totalRating,
    );
  }

  final int appearances;
  final int goals;
  final int assists;
  final double totalRating;

  double get averageRating => appearances == 0 ? 0 : totalRating / appearances;
}

class _NumberCell extends StatelessWidget {
  const _NumberCell({
    required this.value,
    required this.width,
    this.color = AppColors.paper,
  });

  final String value;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
}
