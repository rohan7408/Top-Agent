import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../core/widgets/compact_page_chrome.dart';
import '../../../core/widgets/section_placeholder.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/match_result.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/player_achievement.dart';
import '../../../domain/models/player_match_performance.dart';
import '../../../domain/models/player_season_stats.dart';
import '../../../domain/models/player_training_plan.dart';
import '../../../domain/services/player_achievement_service.dart';
import '../../../domain/services/season_calendar.dart';
import '../../../domain/services/transfer_eligibility.dart';
import '../../offers/presentation/offer_negotiation_sheet.dart';

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({required this.playerId, super.key});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final player =
        game?.players.where((item) => item.id == playerId).firstOrNull;
    if (game == null || player == null) {
      return const Scaffold(
        body: SectionPlaceholder(
          icon: Icons.person_off_outlined,
          title: 'Player not found',
          message: 'This player is no longer available in the current career.',
        ),
      );
    }

    final stats = _careerStatsForPlayer(game, player);
    final currentStats = _PlayerTotals.from(
      stats.where((item) => item.season == game.currentSeason),
    );
    final performances = game.performancesForPlayer(player.id);
    final achievements =
        const PlayerAchievementService().achievementsFor(game, player.id);
    final currentClubName = player.clubId == null
        ? player.isRetired
            ? 'Retired'
            : 'Free agent'
        : game.clubById(player.clubId!)?.name ?? 'Unknown club';
    final clubName = player.isOnLoan
        ? '$currentClubName · Loan from ${game.clubById(player.loanParentClubId!)?.name ?? 'parent club'}'
        : currentClubName;
    final injury = game.activeInjuryForPlayer(player.id);
    final availability = player.isRetired
        ? 'Retired · ${game.seasonLabel(player.retirementSeason ?? game.currentSeason)}'
        : injury == null
            ? 'Fatigue ${player.fatigue.round()}%'
            : '${injury.name} · ${game.injuryAvailabilityLabel(injury)}';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 46,
          titleSpacing: 0,
          title: CompactPageTitle(
            title: player.name,
            eyebrow: '$clubName · ${player.position.shortLabel}',
          ),
          bottom: const CompactTabBar(
            labels: ['Overview', 'Career', 'Season'],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
              player: player,
              clubName: clubName,
              currentStats: currentStats,
              representedByAgent: player.agentId == game.agent.id,
              availability: availability,
              achievements: achievements,
              showPotential: game.canViewPotential(player),
              onEndRepresentation: player.agentId == game.agent.id
                  ? () => _confirmEndRepresentation(
                        context,
                        ref,
                        game,
                        player,
                      )
                  : null,
            ),
            _CareerTab(
              game: game,
              player: player,
              stats: stats,
            ),
            _SeasonsTab(
              game: game,
              stats: stats,
              performances: performances,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEndRepresentation(
    BuildContext context,
    WidgetRef ref,
    GameState game,
    Player player,
  ) async {
    final controller = ref.read(gameControllerProvider.notifier);
    final cost = controller.representationTerminationCost(player.id);
    if (cost == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('End representation of ${player.name}?'),
        content: Text(
          'Settlement: ${GameFormatters.compactCurrency(cost)}\nReputation: -2\nCash after: ${GameFormatters.compactCurrency(game.agent.money - cost)}\n\nTheir club and football contract stay unchanged. Pending offers and your training plan are cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep client'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End representation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = controller.endRepresentation(player.id);
    final message = switch (result) {
      RepresentationActionResult.success =>
        '${player.name} has left the agency.',
      RepresentationActionResult.noActiveGame ||
      RepresentationActionResult.playerNotFound ||
      RepresentationActionResult.notRepresented =>
        'Representation could not be ended.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({
    required this.player,
    required this.clubName,
    required this.representedByAgent,
  });

  final Player player;
  final String clubName;
  final bool representedByAgent;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.slate)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(player.position.shortLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.teal,
                        fontSize: 8,
                      )),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '${player.position.label} · ${player.age} · $clubName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: (representedByAgent ? AppColors.teal : AppColors.slate)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                representedByAgent ? 'YOUR CLIENT' : 'SCOUTED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:
                          representedByAgent ? AppColors.teal : AppColors.muted,
                      fontSize: 8,
                    ),
              ),
            ),
          ],
        ),
      );
}

class _Rating extends StatelessWidget {
  const _Rating({required this.label, required this.value, this.accent});
  final String label;
  final Object value;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$value',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  )),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 8,
                  )),
        ],
      );
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.player,
    required this.clubName,
    required this.currentStats,
    required this.representedByAgent,
    required this.availability,
    required this.achievements,
    required this.showPotential,
    required this.onEndRepresentation,
  });

  final Player player;
  final String clubName;
  final _PlayerTotals currentStats;
  final bool representedByAgent;
  final String availability;
  final List<PlayerAchievement> achievements;
  final bool showPotential;
  final VoidCallback? onEndRepresentation;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight = constraints.maxHeight < 600;
          final gap = compactHeight ? 4.0 : 8.0;
          return Padding(
            key: const Key('playerOverviewTab'),
            padding: EdgeInsets.fromLTRB(
              12,
              4,
              12,
              compactHeight ? 4 : 12,
            ),
            child: Column(
              children: [
                _PlayerHeader(
                  player: player,
                  clubName: clubName,
                  representedByAgent: representedByAgent,
                ),
                SizedBox(height: gap),
                _RatingsPanel(
                  player: player,
                  showPotential: showPotential,
                ),
                SizedBox(height: gap),
                _EssentialInformationPanel(
                  player: player,
                  clubName: clubName,
                  availability: availability,
                  compact: compactHeight,
                ),
                SizedBox(height: gap),
                _SeasonStrip(totals: currentStats),
                SizedBox(height: gap),
                _AchievementsPanel(
                  achievements: achievements,
                  compact: compactHeight,
                ),
                if (onEndRepresentation != null) ...[
                  SizedBox(height: gap),
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('endRepresentationButton'),
                      onPressed: onEndRepresentation,
                      icon: const Icon(
                        Icons.person_remove_alt_1_rounded,
                        size: 14,
                      ),
                      label: const Text('END REPRESENTATION'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        textStyle: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
}

class _EssentialInformationPanel extends StatelessWidget {
  const _EssentialInformationPanel({
    required this.player,
    required this.clubName,
    required this.availability,
    required this.compact,
  });

  final Player player;
  final String clubName;
  final String availability;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rowHeight = compact ? 24.0 : 26.0;
    return Container(
      height: compact ? 176 : 190,
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.slate),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: rowHeight,
            child: _EssentialRow(
              label: 'Club',
              value: clubName,
              onTap: player.clubId == null
                  ? null
                  : () => context.push(AppRoutes.clubDetails(player.clubId!)),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: rowHeight,
            child: _EssentialRow(
              label: 'Role',
              value: '${player.position.label} · ${player.age} years',
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: rowHeight,
            child: _EssentialRow(
              label: 'Body',
              value: '${player.heightCm} cm / ${player.weightKg} kg',
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: rowHeight,
            child: _EssentialRow(
              label: 'Value / wage',
              value:
                  '${GameFormatters.compactCurrency(player.value)} / ${GameFormatters.compactCurrency(player.salary)}/wk',
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: rowHeight,
            child: _EssentialRow(
              label: 'Fitness',
              value: availability,
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: rowHeight,
            child: _EssentialRow(
              label: 'Agency trust',
              value: player.agencyRelationshipWeeks == 0
                  ? '${player.agentTrust}'
                  : '${player.agentTrust} · ${player.agencyRelationshipWeeks} weeks',
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: rowHeight,
            child: _EssentialRow(
              label: 'Character',
              value:
                  'PRO ${player.personality.professionalism} · DIS ${player.personality.discipline} · AMB ${player.personality.ambition} · MED ${player.personality.mediaAppeal}',
            ),
          ),
        ],
      ),
    );
  }
}

class _EssentialRow extends StatelessWidget {
  const _EssentialRow({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: AppColors.muted,
                  ),
              ],
            ),
          ),
        ),
      );
}

class _SeasonStrip extends StatelessWidget {
  const _SeasonStrip({required this.totals});

  final _PlayerTotals totals;

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        decoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: AppColors.slate),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _Rating(label: 'APPS', value: totals.appearances),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _Rating(label: 'GOALS', value: totals.goals)),
            const VerticalDivider(width: 1),
            Expanded(child: _Rating(label: 'ASSISTS', value: totals.assists)),
            const VerticalDivider(width: 1),
            Expanded(
              child: _Rating(
                label: 'RATING',
                value: totals.averageRating == 0
                    ? '—'
                    : totals.averageRating.toStringAsFixed(1),
                accent: AppColors.amber,
              ),
            ),
          ],
        ),
      );
}

class _AchievementsPanel extends StatelessWidget {
  const _AchievementsPanel({
    required this.achievements,
    required this.compact,
  });

  final List<PlayerAchievement> achievements;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('playerAchievementsPanel'),
        height: compact ? 64 : 72,
        decoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: AppColors.slate),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: AppColors.amber,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ACHIEVEMENTS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.amber,
                            fontSize: 8,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${achievements.fold<int>(0, (sum, item) => sum + item.count)} WON',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: achievements.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'No senior honours yet',
                          textAlign: TextAlign.left,
                          style: TextStyle(color: AppColors.muted, fontSize: 9),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        for (var index = 0;
                            index < achievements.length;
                            index++) ...[
                          Expanded(
                            child: _AchievementCell(
                              achievement: achievements[index],
                            ),
                          ),
                          if (index != achievements.length - 1)
                            const VerticalDivider(width: 1),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      );
}

class _AchievementCell extends StatelessWidget {
  const _AchievementCell({required this.achievement});

  final PlayerAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final icon = switch (achievement.type) {
      PlayerAchievementType.leagueTitle => Icons.emoji_events_rounded,
      PlayerAchievementType.goldenBoot => Icons.directions_run_rounded,
      PlayerAchievementType.leagueMvp => Icons.workspace_premium_rounded,
      PlayerAchievementType.matchMvp => Icons.star_rounded,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppColors.amber),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.count > 1
                      ? '${achievement.title} ×${achievement.count}'
                      : achievement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  achievement.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingsPanel extends StatelessWidget {
  const _RatingsPanel({required this.player, required this.showPotential});

  final Player player;
  final bool showPotential;

  @override
  Widget build(BuildContext context) {
    final ratings = [
      _AttributeScore('Overall', player.ability, AppColors.amber),
      if (showPotential)
        _AttributeScore('Potential', player.potential, AppColors.teal),
      _AttributeScore('Attacking', player.attacking, AppColors.amber),
      _AttributeScore('Defending', player.defending, const Color(0xFF74A7FF)),
      _AttributeScore('Technical', player.technical, AppColors.teal),
      _AttributeScore('Mental', player.mental, const Color(0xFFB59AF2)),
      _AttributeScore('Physical', player.physical, const Color(0xFFE27D9A)),
      _AttributeScore('Speed', player.speed, const Color(0xFF67C8E8)),
    ];
    final attributeStart = showPotential ? 2 : 1;
    final attributes = ratings.skip(attributeStart).toList(growable: false);
    return Container(
      key: const Key('playerRatingsPanel'),
      height: 114,
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.slate),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: Row(
              children: [
                Expanded(
                  child: _CompactRating(score: ratings[0], prominent: true),
                ),
                if (showPotential) ...[
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _CompactRating(
                      score: ratings[1],
                      prominent: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 34,
            child: Row(
              children: [
                for (var index = 0; index < 3; index++) ...[
                  Expanded(child: _CompactRating(score: attributes[index])),
                  if (index != 2) const VerticalDivider(width: 1),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 34,
            child: Row(
              children: [
                for (var index = 3; index < 6; index++) ...[
                  Expanded(child: _CompactRating(score: attributes[index])),
                  if (index != 5) const VerticalDivider(width: 1),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRating extends StatelessWidget {
  const _CompactRating({required this.score, this.prominent = false});

  final _AttributeScore score;
  final bool prominent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                score.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: prominent ? 11 : 9,
                    ),
              ),
            ),
            Text(
              '${score.value}',
              style: TextStyle(
                color: score.color,
                fontSize: prominent ? 17 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _AttributeScore {
  const _AttributeScore(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

// Kept as a dormant reusable editor while automatic development remains active.
// ignore: unused_element
class _TrainingTab extends StatelessWidget {
  const _TrainingTab({
    required this.player,
    required this.plan,
    required this.representedByAgent,
    required this.onFocusChanged,
    required this.onIntensityChanged,
    // ignore: unused_element_parameter
    this.injuryLabel,
  });

  final Player player;
  final PlayerTrainingPlan plan;
  final bool representedByAgent;
  final String? injuryLabel;
  final ValueChanged<TrainingFocus> onFocusChanged;
  final ValueChanged<TrainingIntensity> onIntensityChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = representedByAgent && !player.isRetired;
    final status = !representedByAgent
        ? 'Recruit this player before assigning development work.'
        : player.isRetired
            ? 'Training unavailable · player retired'
            : injuryLabel != null
                ? 'Paused · $injuryLabel'
                : player.ability >= player.potential
                    ? 'Potential reached · maintain fitness and performance'
                    : 'Active · progress is processed with Next Week';
    final statusColor = !enabled || injuryLabel != null
        ? AppColors.danger
        : player.ability >= player.potential
            ? AppColors.amber
            : AppColors.teal;

    return ListView(
      key: const Key('playerTrainingTab'),
      padding: const EdgeInsets.only(bottom: 14),
      children: [
        const CompactSectionBar(
          title: 'Development programme',
          trailing: '100 POINT BLOCK',
        ),
        SizedBox(
          height: 52,
          child: Row(
            children: [
              _TrainingMetric(
                label: 'OVERALL',
                value: '${player.ability}',
                color: AppColors.amber,
              ),
              _TrainingMetric(
                label: 'POTENTIAL',
                value: '${player.potential}',
                color: AppColors.teal,
              ),
              _TrainingMetric(
                label: 'FATIGUE',
                value: '${player.fatigue.round()}%',
                color:
                    player.fatigue >= 70 ? AppColors.danger : AppColors.paper,
              ),
              _TrainingMetric(
                label: 'GROWTH GAP',
                value: '${player.potential - player.ability}',
                color: AppColors.ratingBlue,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
          decoration: const BoxDecoration(
            color: AppColors.navy,
            border: Border(bottom: BorderSide(color: AppColors.slate)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${plan.focus.label.toUpperCase()} BLOCK',
                      style: const TextStyle(
                        color: AppColors.paper,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  Text(
                    '${plan.progress}/100',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  key: const Key('trainingProgressRail'),
                  value: plan.progress / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.slate,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
        ),
        const CompactSectionBar(
          title: 'Training focus',
          trailing: 'SELECT ONE',
          accent: AppColors.ratingBlue,
        ),
        for (final focus in TrainingFocus.values)
          _FocusRow(
            focus: focus,
            selected: plan.focus == focus,
            enabled: enabled,
            onTap: () => onFocusChanged(focus),
          ),
        const CompactSectionBar(
          title: 'Intensity',
          trailing: 'PROGRESS / FATIGUE',
          accent: AppColors.amber,
        ),
        SizedBox(
          height: 58,
          child: Row(
            children: [
              for (final intensity in TrainingIntensity.values)
                Expanded(
                  child: _IntensityChoice(
                    intensity: intensity,
                    selected: plan.intensity == intensity,
                    enabled: enabled,
                    onTap: () => onIntensityChanged(intensity),
                  ),
                ),
            ],
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.09),
            border: Border(
              left: BorderSide(color: statusColor, width: 3),
              bottom: const BorderSide(color: AppColors.slate),
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrainingMetric extends StatelessWidget {
  const _TrainingMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            color: AppColors.panelAlt,
            border: Border(right: BorderSide(color: AppColors.slate)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      );
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({
    required this.focus,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final TrainingFocus focus;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected
            ? _trainingFocusColor(focus).withValues(alpha: 0.12)
            : AppColors.navy,
        child: InkWell(
          key: Key('trainingFocus-${focus.name}'),
          onTap: enabled ? onTap : null,
          child: Container(
            height: 42,
            padding: const EdgeInsets.only(right: 11),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color:
                      selected ? _trainingFocusColor(focus) : AppColors.slate,
                  width: 3,
                ),
                bottom: const BorderSide(color: AppColors.slate),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 9),
                SizedBox(
                  width: 72,
                  child: Text(
                    focus.label,
                    style: TextStyle(
                      color: selected
                          ? _trainingFocusColor(focus)
                          : AppColors.paper,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    focus.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 8),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: _trainingFocusColor(focus),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _IntensityChoice extends StatelessWidget {
  const _IntensityChoice({
    required this.intensity,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final TrainingIntensity intensity;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected
            ? AppColors.amber.withValues(alpha: 0.14)
            : AppColors.panelAlt,
        child: InkWell(
          key: Key('trainingIntensity-${intensity.name}'),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: selected ? AppColors.amber : AppColors.slate,
                  width: selected ? 3 : 1,
                ),
                right: const BorderSide(color: AppColors.slate),
                bottom: const BorderSide(color: AppColors.slate),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  intensity.label.toUpperCase(),
                  style: TextStyle(
                    color: selected ? AppColors.amber : AppColors.paper,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  intensity.effectLabel,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      );
}

Color _trainingFocusColor(TrainingFocus focus) => switch (focus) {
      TrainingFocus.balanced => AppColors.paper,
      TrainingFocus.attacking => AppColors.amber,
      TrainingFocus.defending => const Color(0xFF74A7FF),
      TrainingFocus.technical => AppColors.teal,
      TrainingFocus.mental => const Color(0xFFB59AF2),
      TrainingFocus.physical => const Color(0xFFE27D9A),
      TrainingFocus.speed => const Color(0xFF67C8E8),
    };

class _CareerTab extends StatelessWidget {
  const _CareerTab({
    required this.game,
    required this.player,
    required this.stats,
  });

  final GameState game;
  final Player player;
  final List<PlayerSeasonStats> stats;

  @override
  Widget build(BuildContext context) {
    final seasonCount = stats.map((item) => item.season).toSet().length;
    return ListView(
      key: const Key('playerCareerTab'),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _PlayerCareerActions(game: game, player: player),
        CompactSectionBar(
          title: 'Club career',
          trailing: '$seasonCount SEASON${seasonCount == 1 ? '' : 'S'}',
          accent: AppColors.amber,
        ),
        if (stats.isNotEmpty)
          _CareerHistoryTable(game: game, player: player, stats: stats)
        else
          const _Notice('No club career recorded yet.'),
      ],
    );
  }
}

class _PlayerCareerActions extends ConsumerWidget {
  const _PlayerCareerActions({required this.game, required this.player});

  final GameState game;
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (player.isRetired) return const SizedBox.shrink();
    final isRepresented = player.agentId == game.agent.id && player.isRecruited;
    final isAvailableTalent =
        player.clubId == null && player.agentId == null && !player.isRecruited;
    if (!isAvailableTalent && !isRepresented) {
      return const SizedBox.shrink();
    }
    final pendingOffers = game.pendingOffersForPlayer(player.id);
    final transferWindowOpen = const SeasonCalendar().isTransferWindow(
      game.currentWeek,
    );
    final canTransferPermanently =
        const TransferEligibility().canTransferPermanently(game, player);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompactSectionBar(
          title: 'Agency actions',
          trailing: isAvailableTalent
              ? 'AVAILABLE PROSPECT'
              : player.clubId == null
                  ? 'FREE AGENT'
                  : game.clubById(player.clubId!)?.name.toUpperCase(),
          accent: AppColors.teal,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: isAvailableTalent
              ? FilledButton.icon(
                  key: Key('careerRecruitPlayerButton-${player.id}'),
                  onPressed: game.isAgencyAtClientCapacity
                      ? null
                      : () => _recruit(context, ref),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                  label: Text(
                    game.isAgencyAtClientCapacity
                        ? 'Office client limit reached'
                        : 'Recruit player',
                  ),
                )
              : player.clubId == null
                  ? FilledButton.icon(
                      key: Key('careerSuggestPlayerButton-${player.id}'),
                      onPressed: () => pendingOffers.isEmpty
                          ? _suggest(context, ref)
                          : showPlayerOffersSheet(
                              context,
                              playerId: player.id,
                            ),
                      icon: Icon(
                        pendingOffers.isEmpty
                            ? Icons.campaign_outlined
                            : Icons.description_outlined,
                        size: 17,
                      ),
                      label: Text(
                        pendingOffers.isEmpty
                            ? 'Suggest player'
                            : 'Review ${pendingOffers.length} club ${pendingOffers.length == 1 ? 'offer' : 'offers'}',
                      ),
                    )
                  : pendingOffers.isNotEmpty
                      ? FilledButton.icon(
                          key: Key('careerReviewOffersButton-${player.id}'),
                          onPressed: () => showPlayerOffersSheet(
                            context,
                            playerId: player.id,
                          ),
                          icon:
                              const Icon(Icons.description_outlined, size: 17),
                          label: Text(
                            'Review ${pendingOffers.length} ${pendingOffers.length == 1 ? 'offer' : 'offers'}',
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: Key(
                                      'careerTransferListButton-${player.id}',
                                    ),
                                    onPressed: player.isTransferListed ||
                                            !transferWindowOpen ||
                                            !canTransferPermanently ||
                                            player.isOnLoan
                                        ? null
                                        : () => _requestListing(
                                              context,
                                              ref,
                                              ClubListingActionType.transfer,
                                            ),
                                    icon: const Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 17,
                                    ),
                                    label: Text(
                                      player.isTransferListed
                                          ? 'Transfer listed'
                                          : !transferWindowOpen
                                              ? 'Window closed'
                                              : !canTransferPermanently
                                                  ? 'Available after 1 year'
                                                  : 'Ask for transfer list',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    key: Key(
                                        'careerLoanListButton-${player.id}'),
                                    onPressed: player.isLoanListed ||
                                            !transferWindowOpen ||
                                            player.isOnLoan
                                        ? null
                                        : () => _requestListing(
                                              context,
                                              ref,
                                              ClubListingActionType.loan,
                                            ),
                                    icon: const Icon(
                                      Icons.redo_rounded,
                                      size: 17,
                                    ),
                                    label: Text(
                                      player.isLoanListed
                                          ? 'Loan listed'
                                          : player.isOnLoan
                                              ? 'Currently on loan'
                                              : !transferWindowOpen
                                                  ? 'Window closed'
                                                  : 'Ask for loan list',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!transferWindowOpen)
                              const Padding(
                                padding: EdgeInsets.only(top: 5),
                                child: Text(
                                  'Listing requests open during transfer windows.',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
        ),
      ],
    );
  }

  void _recruit(BuildContext context, WidgetRef ref) {
    final result =
        ref.read(gameControllerProvider.notifier).recruitPlayer(player.id);
    final message = switch (result) {
      RecruitmentResult.success => '${player.name} joined your agency.',
      RecruitmentResult.noActiveGame => 'Start a career before recruiting.',
      RecruitmentResult.playerNotFound => 'That player no longer exists.',
      RecruitmentResult.playerUnavailable =>
        '${player.name} is no longer available.',
      RecruitmentResult.officeFull =>
        'Upgrade the Office before recruiting another client.',
    };
    _message(context, message);
  }

  void _suggest(BuildContext context, WidgetRef ref) {
    final result =
        ref.read(gameControllerProvider.notifier).suggestPlayer(player.id);
    if (result.status == SuggestionStatus.success ||
        result.status == SuggestionStatus.alreadySuggested) {
      showPlayerOffersSheet(context, playerId: player.id);
      return;
    }
    final message = switch (result.status) {
      SuggestionStatus.noActiveGame => 'Start a career first.',
      SuggestionStatus.playerUnavailable =>
        '${player.name} cannot be suggested right now.',
      SuggestionStatus.noClubInterest =>
        'No clubs are interested in ${player.name} this week.',
      SuggestionStatus.success || SuggestionStatus.alreadySuggested => '',
    };
    _message(context, message);
  }

  void _requestListing(
    BuildContext context,
    WidgetRef ref,
    ClubListingActionType type,
  ) {
    final result = ref
        .read(gameControllerProvider.notifier)
        .requestClubListing(player.id, type);
    final label = type == ClubListingActionType.transfer ? 'transfer' : 'loan';
    final message = switch (result.status) {
      ClubListingActionStatus.success when result.recentSigningPenaltyApplied =>
        '${player.name} is now $label listed. The early request cost 2 reputation and damaged the club relationship.',
      ClubListingActionStatus.success => '${player.name} is now $label listed.',
      ClubListingActionStatus.noActiveContract =>
        'No active club contract could be found.',
      ClubListingActionStatus.alreadyListed =>
        '${player.name} is already $label listed.',
      ClubListingActionStatus.transferWindowClosed =>
        'Listing requests are only available during transfer windows.',
      ClubListingActionStatus.permanentTransferTooSoon =>
        '${player.name} must complete one year at the club before transferring.',
      ClubListingActionStatus.alreadyOnLoan =>
        '${player.name} is already away on loan.',
      ClubListingActionStatus.noActiveGame ||
      ClubListingActionStatus.playerUnavailable =>
        'The club request could not be made.',
    };
    _message(context, message);
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.performance,
    required this.match,
    required this.game,
    required this.isAlternate,
  });

  final PlayerMatchPerformance performance;
  final MatchResult? match;
  final GameState game;
  final bool isAlternate;

  @override
  Widget build(BuildContext context) {
    final opponentId = match == null
        ? null
        : match!.homeClubId == performance.clubId
            ? match!.awayClubId
            : match!.homeClubId;
    final opponent = opponentId == null
        ? 'Unknown opponent'
        : game.clubById(opponentId)?.name ?? 'Unknown opponent';
    final score = match == null
        ? '—'
        : performance.clubId == match!.homeClubId
            ? '${match!.homeGoals}-${match!.awayGoals}'
            : '${match!.awayGoals}-${match!.homeGoals}';
    return Material(
      color: isAlternate ? AppColors.panelAlt : AppColors.navy,
      child: InkWell(
        onTap: match == null
            ? null
            : () => context.push(AppRoutes.matchDetails(match!.id)),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.slate)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text('W${performance.week}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 8,
                        )),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$opponent · $score',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.paper,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${performance.started ? 'Started' : 'Substitute'}${performance.playerOfTheMatch ? ' · MATCH MVP' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontSize: 8,
                          ),
                    ),
                  ],
                ),
              ),
              _AppearanceMetric('${performance.minutes}', 28),
              _AppearanceMetric('${performance.goals}', 20),
              _AppearanceMetric('${performance.assists}', 20),
              Container(
                width: 35,
                height: 26,
                alignment: Alignment.center,
                color: _ratingColor(performance.rating).withValues(alpha: 0.12),
                child: Text(
                  performance.rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: _ratingColor(performance.rating),
                    fontSize: 10,
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

  Color _ratingColor(double rating) {
    if (rating >= 8) return AppColors.amber;
    if (rating >= 7) return AppColors.teal;
    if (rating < 6) return AppColors.danger;
    return AppColors.paper;
  }
}

class _AppearanceMetric extends StatelessWidget {
  const _AppearanceMetric(this.value, this.width);

  final String value;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.paper,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _SeasonsTab extends StatelessWidget {
  const _SeasonsTab({
    required this.game,
    required this.stats,
    required this.performances,
  });

  final GameState game;
  final List<PlayerSeasonStats> stats;
  final List<PlayerMatchPerformance> performances;

  @override
  Widget build(BuildContext context) {
    final currentStats = stats
        .where((item) => item.season == game.currentSeason)
        .toList(growable: false);
    final currentPerformances = performances
        .where((item) => item.season == game.currentSeason)
        .toList(growable: false);
    if (currentStats.isEmpty && currentPerformances.isEmpty) {
      return SectionPlaceholder(
        key: Key('playerSeasonsTab'),
        icon: Icons.calendar_month_outlined,
        title: 'No current-season appearances',
        message:
            'Match output for ${game.seasonLabel(game.currentSeason)} will appear here.',
      );
    }
    return ListView(
      key: const Key('playerSeasonsTab'),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _SeasonAppearanceSection(
          game: game,
          season: game.currentSeason,
          stats: currentStats,
          performances: currentPerformances,
        ),
      ],
    );
  }
}

class _SeasonAppearanceSection extends StatelessWidget {
  const _SeasonAppearanceSection({
    required this.game,
    required this.season,
    required this.stats,
    required this.performances,
  });

  final GameState game;
  final int season;
  final List<PlayerSeasonStats> stats;
  final List<PlayerMatchPerformance> performances;

  @override
  Widget build(BuildContext context) {
    final totals = _PlayerTotals.from(stats);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompactSectionBar(
          title: 'Current season · ${game.seasonLabel(season)}',
          trailing:
              '${totals.appearances} APP · ${totals.goals} G · ${totals.assists} A',
          accent: AppColors.ratingBlue,
        ),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: AppColors.midnight,
          child: Row(
            children: [
              Text(
                'ALL APPEARANCES · ${performances.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 8,
                    ),
              ),
              const Spacer(),
              const Text(
                'MIN   G   A   RTG',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (performances.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              'No appearances recorded in this season.',
              textAlign: TextAlign.left,
              style: TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          )
        else
          for (var index = 0; index < performances.length; index++)
            _PerformanceRow(
              performance: performances[index],
              match: game.matchResultById(performances[index].matchId),
              game: game,
              isAlternate: index.isOdd,
            ),
      ],
    );
  }
}

class _CareerHistoryTable extends StatelessWidget {
  const _CareerHistoryTable({
    required this.game,
    required this.player,
    required this.stats,
  });

  final GameState game;
  final Player player;
  final List<PlayerSeasonStats> stats;

  static const _yearWidth = 50.0;
  static const _overallWidth = 34.0;
  static const _valueWidth = 52.0;
  static const _outputWidth = 22.0;
  static const _ratingWidth = 36.0;

  @override
  Widget build(BuildContext context) {
    final totals = _PlayerTotals.from(stats);
    return Column(
      children: [
        _CareerTableLine(
          isHeader: true,
          cells: const [
            _CareerCell('YEAR', width: _yearWidth, alignLeft: true),
            _CareerCell('CLUB', expanded: true, alignLeft: true),
            _CareerCell('OVR', width: _overallWidth),
            _CareerCell('VALUE', width: _valueWidth),
            _CareerCell('P', width: _outputWidth),
            _CareerCell('G', width: _outputWidth),
            _CareerCell('A', width: _outputWidth),
            _CareerCell('PT', width: _ratingWidth),
          ],
        ),
        for (var index = 0; index < stats.length; index++)
          _CareerHistoryRow(
            game: game,
            player: player,
            stats: stats[index],
            isAlternate: index.isOdd,
          ),
        _CareerTableLine(
          key: const Key('playerCareerTotals'),
          emphasized: true,
          cells: [
            const _CareerCell('TOTAL', width: _yearWidth, alignLeft: true),
            const _CareerCell('', expanded: true, alignLeft: true),
            const _CareerCell('', width: _overallWidth),
            const _CareerCell('', width: _valueWidth),
            _CareerCell('${totals.appearances}', width: _outputWidth),
            _CareerCell('${totals.goals}', width: _outputWidth),
            _CareerCell('${totals.assists}', width: _outputWidth),
            _CareerCell(
              totals.averageRating == 0
                  ? '0'
                  : totals.averageRating.toStringAsFixed(1),
              width: _ratingWidth,
            ),
          ],
        ),
      ],
    );
  }
}

class _CareerHistoryRow extends StatelessWidget {
  const _CareerHistoryRow({
    required this.game,
    required this.player,
    required this.stats,
    required this.isAlternate,
  });

  final GameState game;
  final Player player;
  final PlayerSeasonStats stats;
  final bool isAlternate;

  @override
  Widget build(BuildContext context) {
    final overall = stats.overall > 0 ? stats.overall : player.ability;
    final value = stats.marketValue > 0 ? stats.marketValue : player.value;
    final clubName = game.clubById(stats.clubId)?.name ?? 'Unknown club';
    return _CareerTableLine(
      key: Key('playerCareerRow-${stats.season}-${stats.clubId}'),
      isAlternate: isAlternate,
      onTap: game.clubById(stats.clubId) == null
          ? null
          : () => context.push(AppRoutes.clubDetails(stats.clubId)),
      cells: [
        _CareerCell(
          _compactSeasonLabel(game.seasonLabel(stats.season)),
          width: _CareerHistoryTable._yearWidth,
          alignLeft: true,
          color: AppColors.teal,
        ),
        _CareerCell(clubName, expanded: true, alignLeft: true),
        _CareerCell(
          '$overall',
          width: _CareerHistoryTable._overallWidth,
          color: compactRatingColor(overall),
        ),
        _CareerCell(
          GameFormatters.compactCurrency(value),
          width: _CareerHistoryTable._valueWidth,
          color: AppColors.amber,
        ),
        _CareerCell(
          '${stats.appearances}',
          width: _CareerHistoryTable._outputWidth,
        ),
        _CareerCell('${stats.goals}', width: _CareerHistoryTable._outputWidth),
        _CareerCell(
          '${stats.assists}',
          width: _CareerHistoryTable._outputWidth,
        ),
        _CareerCell(
          stats.averageRating == 0
              ? '0'
              : stats.averageRating.toStringAsFixed(1),
          width: _CareerHistoryTable._ratingWidth,
        ),
      ],
    );
  }
}

class _CareerTableLine extends StatelessWidget {
  const _CareerTableLine({
    required this.cells,
    this.isHeader = false,
    this.isAlternate = false,
    this.emphasized = false,
    this.onTap,
    super.key,
  });

  final List<Widget> cells;
  final bool isHeader;
  final bool isAlternate;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      height: isHeader ? 28 : 43,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.slate)),
      ),
      child: Row(children: cells),
    );
    return Material(
      color: emphasized
          ? AppColors.surfaceHigh
          : isHeader
              ? AppColors.midnight
              : isAlternate
                  ? AppColors.panelAlt
                  : AppColors.navy,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class _CareerCell extends StatelessWidget {
  const _CareerCell(
    this.value, {
    this.width,
    this.expanded = false,
    this.alignLeft = false,
    this.color,
  });

  final String value;
  final double? width;
  final bool expanded;
  final bool alignLeft;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final child = Align(
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: color ?? AppColors.paper,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    if (expanded) return Expanded(child: child);
    return SizedBox(width: width, child: child);
  }
}

String _compactSeasonLabel(String label) {
  final parts = label.split('/');
  if (parts.length != 2 || parts[1].length < 2) return label;
  return '${parts[0].substring(parts[0].length - 2)}/${parts[1].substring(parts[1].length - 2)}';
}

List<PlayerSeasonStats> _careerStatsForPlayer(
  GameState game,
  Player player,
) {
  final stats = game.statsForPlayer(player.id).toList(growable: true);
  void addContractSeasons({
    required String clubId,
    required int startSeason,
    required int? endSeason,
  }) {
    final club = game.clubById(clubId);
    if (club == null) return;
    final lastSeason = endSeason == null
        ? game.currentSeason
        : (endSeason - 1).clamp(startSeason, game.currentSeason);
    for (var season = startSeason; season <= lastSeason; season++) {
      final alreadyRecorded = stats.any(
        (item) => item.season == season && item.clubId == clubId,
      );
      if (alreadyRecorded) continue;
      stats.add(
        PlayerSeasonStats(
          playerId: player.id,
          clubId: clubId,
          leagueId: club.leagueId,
          season: season,
          overall: player.ability,
          marketValue: player.value,
        ),
      );
    }
  }

  for (final contract in game.contracts.where(
    (contract) => contract.playerId == player.id,
  )) {
    addContractSeasons(
      clubId: contract.clubId,
      startSeason: contract.startSeason,
      endSeason: contract.endSeason,
    );
  }
  for (final event in game.contractEvents.where(
    (event) => event.playerId == player.id && event.endSeason != null,
  )) {
    addContractSeasons(
      clubId: event.clubId,
      startSeason: event.season,
      endSeason: event.endSeason,
    );
  }

  final clubId = player.clubId;
  final club = clubId == null ? null : game.clubById(clubId);
  final hasCurrentClubSeason = stats.any(
    (item) => item.season == game.currentSeason && item.clubId == player.clubId,
  );
  if (club != null && !hasCurrentClubSeason && !player.isRetired) {
    stats.add(
      PlayerSeasonStats(
        playerId: player.id,
        clubId: club.id,
        leagueId: club.leagueId,
        season: game.currentSeason,
        overall: player.ability,
        marketValue: player.value,
      ),
    );
  }
  stats.sort((first, second) {
    final bySeason = second.season.compareTo(first.season);
    if (bySeason != 0) return bySeason;

    final firstIsCurrent = first.clubId == player.clubId ? 1 : 0;
    final secondIsCurrent = second.clubId == player.clubId ? 1 : 0;
    final byCurrentClub = secondIsCurrent.compareTo(firstIsCurrent);
    if (byCurrentClub != 0) return byCurrentClub;

    int latestArrivalWeek(PlayerSeasonStats item) {
      var week = 0;
      for (final transfer in game.transfers) {
        if (transfer.playerId == player.id &&
            transfer.toClubId == item.clubId &&
            transfer.season == item.season &&
            transfer.week > week) {
          week = transfer.week;
        }
      }
      return week;
    }

    final byArrival =
        latestArrivalWeek(second).compareTo(latestArrivalWeek(first));
    return byArrival != 0 ? byArrival : first.clubId.compareTo(second.clubId);
  });
  return List.unmodifiable(stats);
}

class _Notice extends StatelessWidget {
  const _Notice(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(message,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  )),
        ),
      );
}

class _PlayerTotals {
  const _PlayerTotals({
    this.appearances = 0,
    this.starts = 0,
    this.minutes = 0,
    this.goals = 0,
    this.assists = 0,
    this.cleanSheets = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.playerOfTheMatchAwards = 0,
    this.totalRating = 0,
  });

  factory _PlayerTotals.from(Iterable<PlayerSeasonStats> stats) {
    var result = const _PlayerTotals();
    for (final item in stats) {
      result = _PlayerTotals(
        appearances: result.appearances + item.appearances,
        starts: result.starts + item.starts,
        minutes: result.minutes + item.minutes,
        goals: result.goals + item.goals,
        assists: result.assists + item.assists,
        cleanSheets: result.cleanSheets + item.cleanSheets,
        yellowCards: result.yellowCards + item.yellowCards,
        redCards: result.redCards + item.redCards,
        playerOfTheMatchAwards:
            result.playerOfTheMatchAwards + item.playerOfTheMatchAwards,
        totalRating: result.totalRating + item.totalRating,
      );
    }
    return result;
  }

  final int appearances;
  final int starts;
  final int minutes;
  final int goals;
  final int assists;
  final int cleanSheets;
  final int yellowCards;
  final int redCards;
  final int playerOfTheMatchAwards;
  final double totalRating;

  double get averageRating => appearances == 0 ? 0 : totalRating / appearances;
}
