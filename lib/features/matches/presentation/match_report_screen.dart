import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/player_match_performance.dart';
import '../../../domain/services/match_report_service.dart';

class MatchReportScreen extends ConsumerWidget {
  const MatchReportScreen({required this.matchId, super.key});

  final String matchId;
  static const _reportService = MatchReportService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final report = game == null ? null : _reportService.build(game, matchId);
    if (game == null || report == null) {
      return const Scaffold(body: Center(child: Text('Match not found.')));
    }

    final homeName = game.clubById(report.home.clubId)?.name ?? 'Home';
    final awayName = game.clubById(report.away.clubId)?.name ?? 'Away';
    final playerOfTheMatch = report.playerOfTheMatch == null
        ? null
        : game.players
            .where((player) => player.id == report.playerOfTheMatch!.playerId)
            .firstOrNull;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 46,
          titleSpacing: 0,
          title: Text(
            '${game.seasonLabel(report.result.season)} · Week ${report.result.week}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: Column(
          children: [
            _Scoreboard(
              homeName: homeName,
              awayName: awayName,
              homeGoals: report.result.homeGoals,
              awayGoals: report.result.awayGoals,
            ),
            _MatchSummary(report: report),
            if (playerOfTheMatch != null)
              _PlayerOfTheMatchRow(
                player: playerOfTheMatch,
                rating: report.playerOfTheMatch!.rating,
              ),
            Container(
              height: 36,
              decoration: const BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.slate),
                ),
              ),
              child: TabBar(
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
                tabs: [
                  const Tab(text: 'Home ratings'),
                  const Tab(text: 'Away ratings'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TeamRatingsList(
                    game: game,
                    performances: report.home.performances,
                  ),
                  _TeamRatingsList(
                    game: game,
                    performances: report.away.performances,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({
    required this.homeName,
    required this.awayName,
    required this.homeGoals,
    required this.awayGoals,
  });

  final String homeName;
  final String awayName;
  final int homeGoals;
  final int awayGoals;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('matchReportScoreboard'),
        height: 86,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.slate)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                homeName,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.slate,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '$homeGoals  –  $awayGoals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                awayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
      );
}

class _MatchSummary extends StatelessWidget {
  const _MatchSummary({required this.report});

  final MatchReport report;

  @override
  Widget build(BuildContext context) => Column(
        key: const Key('matchReportSummary'),
        children: [
          _SummaryRow(
            label: 'Average rating',
            home: report.home.averageRating.toStringAsFixed(2),
            away: report.away.averageRating.toStringAsFixed(2),
          ),
          _SummaryRow(
            label: 'Assists',
            home: '${report.home.assists}',
            away: '${report.away.assists}',
          ),
          _SummaryRow(
            label: 'Yellow cards',
            home: '${report.home.yellowCards}',
            away: '${report.away.yellowCards}',
          ),
          _SummaryRow(
            label: 'Red cards',
            home: '${report.home.redCards}',
            away: '${report.away.redCards}',
          ),
        ],
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.home,
    required this.away,
  });

  final String label;
  final String home;
  final String away;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 29,
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(home,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
              ),
            ),
            SizedBox(
              width: 54,
              child: Text(away,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      );
}

class _PlayerOfTheMatchRow extends StatelessWidget {
  const _PlayerOfTheMatchRow({required this.player, required this.rating});

  final Player player;
  final double rating;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.amber.withValues(alpha: 0.08),
        child: InkWell(
          onTap: () => context.push(AppRoutes.playerDetails(player.id)),
          child: Container(
            key: const Key('playerOfTheMatchRow'),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: AppColors.slate),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 16, color: AppColors.amber),
                const SizedBox(width: 7),
                Text('POTM',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.amber,
                          fontSize: 7,
                        )),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player.name,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(rating.toStringAsFixed(1),
                    style: const TextStyle(
                        color: AppColors.amber, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      );
}

class _TeamRatingsList extends StatelessWidget {
  const _TeamRatingsList({required this.game, required this.performances});

  final GameState game;
  final List<PlayerMatchPerformance> performances;

  @override
  Widget build(BuildContext context) => ListView.separated(
        key: const Key('matchTeamRatingsList'),
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: performances.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final performance = performances[index];
          final player = game.players
              .where((item) => item.id == performance.playerId)
              .firstOrNull;
          if (player == null) return const SizedBox.shrink();
          return _PerformanceRow(player: player, performance: performance);
        },
      );
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.player, required this.performance});

  final Player player;
  final PlayerMatchPerformance performance;

  @override
  Widget build(BuildContext context) {
    final contributions = <String>[
      if (performance.goals > 0) '${performance.goals}G',
      if (performance.assists > 0) '${performance.assists}A',
      if (performance.yellowCards > 0) '${performance.yellowCards}YC',
      if (performance.redCards > 0) '${performance.redCards}RC',
    ].join(' · ');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.playerDetails(player.id)),
        child: SizedBox(
          height: 43,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    player.position.shortLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.teal,
                          fontSize: 7,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (contributions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      contributions,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontSize: 9,
                          ),
                    ),
                  ),
                SizedBox(
                  width: 34,
                  child: Text(
                    performance.rating.toStringAsFixed(1),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: _ratingColor(performance.rating),
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

  Color _ratingColor(double rating) {
    if (rating >= 8) return AppColors.amber;
    if (rating >= 7) return AppColors.teal;
    if (rating < 6) return AppColors.danger;
    return AppColors.paper;
  }
}
