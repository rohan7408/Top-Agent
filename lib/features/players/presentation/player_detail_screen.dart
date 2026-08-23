import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/match_result.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/player_achievement.dart';
import '../../../domain/models/player_match_performance.dart';
import '../../../domain/models/player_season_stats.dart';
import '../../../domain/models/player_training_plan.dart';
import '../../../domain/services/player_achievement_service.dart';

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({required this.playerId, super.key});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final player =
        game?.players.where((item) => item.id == playerId).firstOrNull;
    if (game == null || player == null) {
      return const Scaffold(body: Center(child: Text('Player not found.')));
    }

    final stats = game.statsForPlayer(player.id);
    final currentStats = _PlayerTotals.from(
      stats.where((item) => item.season == game.currentSeason),
    );
    final careerStats = _PlayerTotals.from(stats);
    final performances = game.performancesForPlayer(player.id);
    final achievements =
        const PlayerAchievementService().achievementsFor(game, player.id);
    final clubName = player.clubId == null
        ? player.isRetired
            ? 'Retired'
            : 'Free agent'
        : game.clubById(player.clubId!)?.name ?? 'Unknown club';
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
          title: Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(38),
            child: SizedBox(
              height: 38,
              child: TabBar(
                isScrollable: false,
                labelPadding: EdgeInsets.zero,
                labelStyle:
                    TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                unselectedLabelStyle:
                    TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Career'),
                  Tab(text: 'Season'),
                ],
              ),
            ),
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
              totals: careerStats,
              seasonCount: stats.map((item) => item.season).toSet().length,
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
                      fontSize: 7,
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
                    fontSize: 7,
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
    required this.onEndRepresentation,
  });

  final Player player;
  final String clubName;
  final _PlayerTotals currentStats;
  final bool representedByAgent;
  final String availability;
  final List<PlayerAchievement> achievements;
  final VoidCallback? onEndRepresentation;

  @override
  Widget build(BuildContext context) => Padding(
        key: const Key('playerOverviewTab'),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          children: [
            _PlayerHeader(
              player: player,
              clubName: clubName,
              representedByAgent: representedByAgent,
            ),
            const SizedBox(height: 8),
            _RatingsPanel(player: player),
            const SizedBox(height: 8),
            _EssentialInformationPanel(
              player: player,
              clubName: clubName,
              availability: availability,
            ),
            const SizedBox(height: 8),
            _SeasonStrip(totals: currentStats),
            const SizedBox(height: 8),
            _AchievementsPanel(achievements: achievements),
            if (onEndRepresentation != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('endRepresentationButton'),
                  onPressed: onEndRepresentation,
                  icon: const Icon(Icons.person_remove_alt_1_rounded, size: 14),
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
}

class _EssentialInformationPanel extends StatelessWidget {
  const _EssentialInformationPanel({
    required this.player,
    required this.clubName,
    required this.availability,
  });

  final Player player;
  final String clubName;
  final String availability;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.slate),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 26,
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
            height: 26,
            child: _EssentialRow(
              label: 'Position',
              value: player.position.label,
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 26,
            child: _EssentialRow(label: 'Age', value: '${player.age} years'),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 26,
            child: _EssentialRow(
              label: 'Body',
              value: '${player.heightCm} cm / ${player.weightKg} kg',
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 26,
            child: _EssentialRow(
              label: 'Value',
              value: GameFormatters.compactCurrency(player.value),
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 26,
            child: _EssentialRow(
              label: 'Wage',
              value: '${GameFormatters.compactCurrency(player.salary)}/wk',
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 26,
            child: _EssentialRow(
              label: 'Fitness',
              value: availability,
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
                  width: 52,
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
  const _AchievementsPanel({required this.achievements});

  final List<PlayerAchievement> achievements;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('playerAchievementsPanel'),
        height: 72,
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
                            fontSize: 7,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${achievements.fold<int>(0, (sum, item) => sum + item.count)} WON',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 7,
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
                  ? const Center(
                      child: Text(
                        'No senior honours yet',
                        style: TextStyle(color: AppColors.muted, fontSize: 9),
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
                  style: const TextStyle(color: AppColors.muted, fontSize: 6.5),
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
  const _RatingsPanel({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final ratings = [
      _AttributeScore('Overall', player.ability, AppColors.amber),
      _AttributeScore('Potential', player.potential, AppColors.teal),
      _AttributeScore('Attacking', player.attacking, AppColors.amber),
      _AttributeScore('Defending', player.defending, const Color(0xFF74A7FF)),
      _AttributeScore('Technical', player.technical, AppColors.teal),
      _AttributeScore('Mental', player.mental, const Color(0xFFB59AF2)),
      _AttributeScore('Physical', player.physical, const Color(0xFFE27D9A)),
      _AttributeScore('Speed', player.speed, const Color(0xFF67C8E8)),
    ];
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
                const VerticalDivider(width: 1),
                Expanded(
                  child: _CompactRating(score: ratings[1], prominent: true),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 34,
            child: Row(
              children: [
                for (var index = 2; index < 5; index++) ...[
                  Expanded(child: _CompactRating(score: ratings[index])),
                  if (index != 4) const VerticalDivider(width: 1),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 34,
            child: Row(
              children: [
                for (var index = 5; index < 8; index++) ...[
                  Expanded(child: _CompactRating(score: ratings[index])),
                  if (index != 7) const VerticalDivider(width: 1),
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
                  fontSize: 7,
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
                  style: const TextStyle(color: AppColors.muted, fontSize: 7),
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
    required this.totals,
    required this.seasonCount,
  });

  final _PlayerTotals totals;
  final int seasonCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('playerCareerTab'),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        CompactSectionBar(
          title: 'Career output',
          trailing: '$seasonCount SEASON${seasonCount == 1 ? '' : 'S'}',
          accent: AppColors.amber,
        ),
        _StatsGrid(items: [
          ('Appearances', '${totals.appearances}'),
          ('Starts', '${totals.starts}'),
          ('Minutes', '${totals.minutes}'),
          ('Goals', '${totals.goals}'),
          ('Assists', '${totals.assists}'),
          ('Clean sheets', '${totals.cleanSheets}'),
          ('Yellow cards', '${totals.yellowCards}'),
          ('Red cards', '${totals.redCards}'),
          ('Player of match', '${totals.playerOfTheMatchAwards}'),
          (
            'Average rating',
            totals.averageRating == 0
                ? '—'
                : totals.averageRating.toStringAsFixed(2)
          ),
        ]),
        if (totals.appearances == 0)
          const _Notice('No senior career appearances recorded yet.'),
      ],
    );
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
    final seasons = {
      ...stats.map((item) => item.season),
      ...performances.map((item) => item.season),
    }.toList(growable: true)
      ..sort((first, second) => second.compareTo(first));
    if (seasons.isEmpty) {
      return const Center(
        key: Key('playerSeasonsTab'),
        child: _Notice('No senior season appearances recorded yet.'),
      );
    }
    return ListView(
      key: const Key('playerSeasonsTab'),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final season in seasons)
          _SeasonAppearanceSection(
            game: game,
            season: season,
            stats: stats
                .where((item) => item.season == season)
                .toList(growable: false),
            performances: performances
                .where((item) => item.season == season)
                .toList(growable: false),
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
          title: game.seasonLabel(season),
          trailing:
              '${totals.appearances} APP · ${totals.goals} G · ${totals.assists} A',
          accent: AppColors.ratingBlue,
        ),
        for (final item in stats)
          _CareerRow(
            stats: item,
            seasonLabel: game.seasonLabel(item.season),
            clubName: game.clubById(item.clubId)?.name ?? 'Unknown club',
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
                      fontSize: 7,
                    ),
              ),
              const Spacer(),
              const Text(
                'MIN   G   A   RTG',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (performances.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'No appearances recorded in this season.',
              textAlign: TextAlign.center,
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

class _CareerRow extends StatelessWidget {
  const _CareerRow({
    required this.stats,
    required this.clubName,
    required this.seasonLabel,
  });
  final PlayerSeasonStats stats;
  final String clubName;
  final String seasonLabel;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(seasonLabel,
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.w900)),
            ),
            Expanded(
              child:
                  Text(clubName, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            _CareerMetric('${stats.appearances}', 'APP'),
            _CareerMetric('${stats.goals}', 'G'),
            _CareerMetric('${stats.assists}', 'A'),
            _CareerMetric(
                stats.averageRating == 0
                    ? '—'
                    : stats.averageRating.toStringAsFixed(1),
                'RTG'),
          ],
        ),
      );
}

class _CareerMetric extends StatelessWidget {
  const _CareerMetric(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 40,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 7,
                    )),
          ],
        ),
      );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});
  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: AppColors.slate),
          ),
        ),
        child: Column(
          children: [
            for (var index = 0; index < items.length; index += 2) ...[
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(child: _StatCell(item: items[index])),
                    const VerticalDivider(width: 1),
                    Expanded(child: _StatCell(item: items[index + 1])),
                  ],
                ),
              ),
              if (index < items.length - 2) const Divider(height: 1),
            ],
          ],
        ),
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.item});

  final (String, String) item;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.$1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              item.$2,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(message,
              textAlign: TextAlign.center,
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
