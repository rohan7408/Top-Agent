import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/section_placeholder.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/player.dart';
import '../../../domain/services/league_statistics_service.dart';

class LeagueLeadersTab extends StatefulWidget {
  const LeagueLeadersTab({
    required this.game,
    required this.leagueId,
    super.key,
  });

  final GameState game;
  final String leagueId;

  @override
  State<LeagueLeadersTab> createState() => _LeagueLeadersTabState();
}

class _LeagueLeadersTabState extends State<LeagueLeadersTab> {
  static const _statisticsService = LeagueStatisticsService();
  LeagueLeaderboardMetric _metric = LeagueLeaderboardMetric.goals;

  @override
  Widget build(BuildContext context) {
    final rankings = _statisticsService.rankPlayers(
      stats: widget.game.playerSeasonStats,
      leagueId: widget.leagueId,
      season: widget.game.currentSeason,
      metric: _metric,
    );
    final players = {
      for (final player in widget.game.players) player.id: player,
    };

    return Column(
      key: const Key('leagueLeadersTab'),
      children: [
        _MetricSelector(
          value: _metric,
          onChanged: (value) => setState(() => _metric = value),
        ),
        _LeaderboardHeader(metric: _metric),
        Expanded(
          child: rankings.isEmpty
              ? const _EmptyLeaders()
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: rankings.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ranking = rankings[index];
                    final player = players[ranking.playerId];
                    if (player == null) return const SizedBox.shrink();
                    final clubName = player.clubId == null
                        ? 'Free agent'
                        : widget.game.clubById(player.clubId!)?.name ??
                            'Unknown club';
                    return _LeaderboardRow(
                      position: index + 1,
                      player: player,
                      clubName: clubName,
                      appearances: ranking.appearances,
                      value: _formatValue(ranking.valueFor(_metric)),
                      onTap: () =>
                          context.push(AppRoutes.playerDetails(player.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatValue(double value) =>
      _metric == LeagueLeaderboardMetric.averageRating
          ? value.toStringAsFixed(2)
          : value.round().toString();
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({required this.value, required this.onChanged});

  final LeagueLeaderboardMetric value;
  final ValueChanged<LeagueLeaderboardMetric> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.slate)),
        ),
        child: Row(
          children: [
            Text(
              'RANKING',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 8,
                  ),
            ),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<LeagueLeaderboardMetric>(
                key: const Key('leaderboardMetricDropdown'),
                value: value,
                isDense: true,
                dropdownColor: AppColors.navy,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w800,
                    ),
                items: LeagueLeaderboardMetric.values
                    .map(
                      (metric) => DropdownMenuItem(
                        value: metric,
                        child: Text(metric.label),
                      ),
                    )
                    .toList(),
                onChanged: (metric) {
                  if (metric != null) onChanged(metric);
                },
              ),
            ),
          ],
        ),
      );
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({required this.metric});

  final LeagueLeaderboardMetric metric;

  @override
  Widget build(BuildContext context) => Container(
        height: 30,
        color: AppColors.navy,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const SizedBox(width: 26, child: _HeaderText('#')),
            const Expanded(child: _HeaderText('PLAYER')),
            const SizedBox(width: 34, child: _HeaderText('APP', right: true)),
            SizedBox(
              width: 42,
              child: _HeaderText(metric.shortLabel, right: true),
            ),
          ],
        ),
      );
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text, {this.right = false});

  final String text;
  final bool right;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontSize: 8,
            ),
      );
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.position,
    required this.player,
    required this.clubName,
    required this.appearances,
    required this.value,
    required this.onTap,
  });

  final int position;
  final Player player;
  final String clubName;
  final int appearances;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('leaderboardPlayer-${player.id}'),
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '$position',
                      style: TextStyle(
                        color: position <= 3 ? AppColors.teal : AppColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.slate,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      player.position.shortLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.teal,
                            fontSize: 8,
                          ),
                    ),
                  ),
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        Text(
                          clubName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.muted,
                                    fontSize: 9,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    child: Text('$appearances', textAlign: TextAlign.right),
                  ),
                  SizedBox(
                    width: 42,
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _EmptyLeaders extends StatelessWidget {
  const _EmptyLeaders();

  @override
  Widget build(BuildContext context) => const SectionPlaceholder(
        icon: Icons.leaderboard_outlined,
        title: 'No player statistics yet',
        message: 'Advance to the first match week to populate the rankings.',
      );
}
