import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../core/widgets/compact_page_chrome.dart';
import '../../../core/widgets/section_placeholder.dart';
import '../../../domain/models/game_state.dart';
import '../../../domain/models/league_season_history.dart';

class LeagueHistoryScreen extends ConsumerWidget {
  const LeagueHistoryScreen({required this.leagueId, super.key});

  final String leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final league = game?.leagueById(leagueId);
    if (game == null || league == null) {
      return const Scaffold(
        body: SectionPlaceholder(
          icon: Icons.history_toggle_off_outlined,
          title: 'League unavailable',
          message: 'This league could not be found in the active career.',
        ),
      );
    }

    final history = game.historyForLeague(leagueId);
    return Scaffold(
      appBar: AppBar(
        title: CompactPageTitle(
          title: '${league.name} history',
          eyebrow: 'Past honours',
        ),
      ),
      body: history.isEmpty
          ? const SectionPlaceholder(
              icon: Icons.emoji_events_outlined,
              title: 'No completed seasons yet',
              message:
                  'Finish the current season to record its champion and leaders.',
            )
          : ListView.builder(
              key: const Key('leagueHistoryList'),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: history.length,
              itemBuilder: (context, index) => _SeasonHistory(
                game: game,
                history: history[index],
              ),
            ),
    );
  }
}

class _SeasonHistory extends StatelessWidget {
  const _SeasonHistory({required this.game, required this.history});

  final GameState game;
  final LeagueSeasonHistory history;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompactSectionBar(
            title: game.seasonLabel(history.season),
            trailing: 'FINAL HONOURS',
          ),
          _HonourRow(
            icon: Icons.emoji_events_outlined,
            label: 'Champion',
            value:
                game.clubById(history.championClubId)?.name ?? 'Unknown club',
            accent: AppColors.amber,
            onTap: () => context.push(
              AppRoutes.clubDetails(history.championClubId),
            ),
          ),
          _HonourRow(
            icon: Icons.military_tech_outlined,
            label: 'Runner-up',
            value:
                game.clubById(history.runnerUpClubId)?.name ?? 'Unknown club',
            onTap: () => context.push(
              AppRoutes.clubDetails(history.runnerUpClubId),
            ),
          ),
          _PlayerHonourRow(
            game: game,
            label: 'Top scorer',
            shortMetric: 'G',
            honour: history.topScorer,
          ),
          _PlayerHonourRow(
            game: game,
            label: 'Top assists',
            shortMetric: 'A',
            honour: history.topAssister,
          ),
          _PlayerHonourRow(
            game: game,
            label: 'Top clean sheets',
            shortMetric: 'CS',
            honour: history.cleanSheetLeader,
          ),
          const SizedBox(height: 8),
        ],
      );
}

class _PlayerHonourRow extends StatelessWidget {
  const _PlayerHonourRow({
    required this.game,
    required this.label,
    required this.shortMetric,
    required this.honour,
  });

  final GameState game;
  final String label;
  final String shortMetric;
  final LeaguePlayerHonour? honour;

  @override
  Widget build(BuildContext context) {
    final item = honour;
    if (item == null) {
      return _HonourRow(
        icon: Icons.person_outline,
        label: label,
        value: 'Not awarded',
      );
    }
    final player = game.players
        .where((candidate) => candidate.id == item.playerId)
        .firstOrNull;
    final clubName = game.clubById(item.clubId)?.name ?? 'Unknown club';
    return _HonourRow(
      icon: shortMetric == 'CS'
          ? Icons.sports_handball_outlined
          : Icons.person_outline,
      label: label,
      value: player?.name ?? 'Unknown player',
      detail: '$clubName · ${item.value} $shortMetric',
      accent: AppColors.teal,
      onTap: player == null
          ? null
          : () => context.push(AppRoutes.playerDetails(player.id)),
    );
  }
}

class _HonourRow extends StatelessWidget {
  const _HonourRow({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
    this.accent = AppColors.textPrimary,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.navy,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.slate)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Icon(icon, size: 17, color: accent),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    label,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (detail != null)
                        Text(
                          detail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.muted,
                  ),
              ],
            ),
          ),
        ),
      );
}
