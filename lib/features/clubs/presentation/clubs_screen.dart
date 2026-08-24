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
import '../../../domain/models/club.dart';
import '../../../domain/models/club_season_record.dart';
import '../../../domain/models/league_fixture.dart';
import '../../../domain/models/match_result.dart';
import '../../leagues/presentation/league_leaders_tab.dart';

class ClubsScreen extends ConsumerWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) {
      return const Scaffold(
        body: SectionPlaceholder(
          icon: Icons.public_off_outlined,
          title: 'No active career',
          message: 'Start or continue a career to view the football world.',
        ),
      );
    }

    final leagueName = game.leagues.firstOrNull?.name ?? 'Football world';
    final clubNames = {for (final club in game.clubs) club.id: club.name};

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: CompactPageTitle(
            title: leagueName,
            eyebrow: 'Football world',
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${game.seasonLabel(game.currentSeason)} · W${game.currentWeek}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.amber,
                      ),
                ),
              ),
            ),
          ],
          bottom: const CompactTabBar(
            labels: ['Table', 'Clubs', 'Fixtures', 'Results', 'Leaders'],
            fontSize: 9,
          ),
        ),
        body: TabBarView(
          children: [
            _LeagueTableTab(
              records: game.currentStandings,
              clubs: game.clubs,
              positionPrizeMoney:
                  game.leagues.firstOrNull?.positionPrizeMoney ?? const [],
            ),
            _ClubsTab(
              clubs: game.clubs,
              records: game.currentStandings,
              squadSizes: {
                for (final club in game.clubs)
                  club.id: game.playersForClub(club.id).length,
              },
            ),
            _FixturesTab(
              fixtures: game.fixtures
                  .where((fixture) =>
                      fixture.season == game.currentSeason &&
                      fixture.week >= game.currentWeek)
                  .toList(),
              clubNames: clubNames,
              currentWeek: game.currentWeek,
            ),
            _ResultsTab(
              results: game.matchResults
                  .where((result) => result.season == game.currentSeason)
                  .toList(),
              clubNames: clubNames,
            ),
            LeagueLeadersTab(
              game: game,
              leagueId: game.leagues.firstOrNull?.id ?? '',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.small(
          key: const Key('leagueHistoryButton'),
          heroTag: 'league-history',
          tooltip: 'Past league winners and leaders',
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.ink,
          onPressed: game.leagues.isEmpty
              ? null
              : () => context.push(
                    AppRoutes.leagueHistory(game.leagues.first.id),
                  ),
          child: const Icon(Icons.history),
        ),
      ),
    );
  }
}

class _LeagueTableTab extends StatelessWidget {
  const _LeagueTableTab({
    required this.records,
    required this.clubs,
    required this.positionPrizeMoney,
  });

  final List<ClubSeasonRecord> records;
  final List<Club> clubs;
  final List<double> positionPrizeMoney;

  @override
  Widget build(BuildContext context) {
    final names = {for (final club in clubs) club.id: club.name};
    return Column(
      key: const Key('leagueTableTab'),
      children: [
        const _TableHeader(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: records.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final record = records[index];
              return _TableRow(
                position: index + 1,
                clubName: names[record.clubId] ?? 'Unknown club',
                prizeMoney: index < positionPrizeMoney.length
                    ? positionPrizeMoney[index]
                    : 0,
                record: record,
                onTap: () => context.push(AppRoutes.clubDetails(record.clubId)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.navy,
        padding: const EdgeInsets.fromLTRB(12, 11, 8, 9),
        child: const Row(
          children: [
            SizedBox(width: 28, child: _HeaderLabel('#')),
            Expanded(child: _HeaderLabel('CLUB')),
            _HeaderNumber('P'),
            _HeaderNumber('W'),
            _HeaderNumber('D'),
            _HeaderNumber('L'),
            SizedBox(width: 38, child: _HeaderLabel('GD', alignRight: true)),
            SizedBox(width: 40, child: _HeaderLabel('PTS', alignRight: true)),
          ],
        ),
      );
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text, {this.alignRight = false});
  final String text;
  final bool alignRight;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontSize: 8,
            ),
      );
}

class _HeaderNumber extends StatelessWidget {
  const _HeaderNumber(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 27,
        child: _HeaderLabel(text, alignRight: true),
      );
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.position,
    required this.clubName,
    required this.prizeMoney,
    required this.record,
    required this.onTap,
  });

  final int position;
  final String clubName;
  final double prizeMoney;
  final ClubSeasonRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positionColor = position <= 4
        ? AppColors.teal
        : position >= 18
            ? AppColors.danger
            : AppColors.muted;
    return Material(
      color: position.isEven ? AppColors.navy.withValues(alpha: 0.34) : null,
      child: InkWell(
        key: Key('leagueTableClub-${record.clubId}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('$position',
                    style: TextStyle(
                      color: positionColor,
                      fontWeight: FontWeight.w900,
                    )),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clubName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (prizeMoney > 0)
                      Text(
                        '${GameFormatters.compactCurrency(prizeMoney)} prize',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontSize: 9,
                            ),
                      ),
                  ],
                ),
              ),
              _NumberCell(record.played),
              _NumberCell(record.won),
              _NumberCell(record.drawn),
              _NumberCell(record.lost),
              SizedBox(
                width: 38,
                child: Text(
                  '${record.goalDifference > 0 ? '+' : ''}${record.goalDifference}',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text('${record.points}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberCell extends StatelessWidget {
  const _NumberCell(this.value);
  final int value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 27,
        child: Text('$value',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall),
      );
}

class _ClubsTab extends StatelessWidget {
  const _ClubsTab({
    required this.clubs,
    required this.records,
    required this.squadSizes,
  });

  final List<Club> clubs;
  final List<ClubSeasonRecord> records;
  final Map<String, int> squadSizes;

  @override
  Widget build(BuildContext context) {
    final recordByClub = {for (final record in records) record.clubId: record};
    final sorted = [...clubs]..sort((a, b) => a.name.compareTo(b.name));
    final positionByClub = {
      for (var index = 0; index < records.length; index++)
        records[index].clubId: index + 1,
    };
    return Column(
      children: [
        CompactTableHeader(
          identityLabel: 'CLUB / VALUE',
          trailing: const [
            CompactColumnLabel('POS', width: 32),
            CompactColumnLabel('SQD', width: 36),
            CompactColumnLabel('BUDGET', width: 58),
          ],
        ),
        Expanded(
          child: ListView.builder(
            key: const Key('clubsList'),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final club = sorted[index];
              final position = positionByClub[club.id] ?? 0;
              final positionColor = position > 0 && position <= 4
                  ? AppColors.teal
                  : position >= 18
                      ? AppColors.danger
                      : AppColors.ratingBlue;
              return InkWell(
                key: Key('clubCard-${club.id}'),
                onTap: () => context.push(AppRoutes.clubDetails(club.id)),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: index.isOdd ? AppColors.panelAlt : AppColors.navy,
                    border: Border(
                      left: BorderSide(color: positionColor, width: 3),
                      bottom: const BorderSide(color: AppColors.slate),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${GameFormatters.compactCurrency(club.clubValue)} value · ${recordByClub[club.id]?.points ?? 0} pts',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text(
                          position == 0 ? '—' : '$position',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: positionColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          '${squadSizes[club.id] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 58,
                        child: Text(
                          GameFormatters.compactCurrency(club.budget),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FixturesTab extends StatelessWidget {
  const _FixturesTab({
    required this.fixtures,
    required this.clubNames,
    required this.currentWeek,
  });

  final List<LeagueFixture> fixtures;
  final Map<String, String> clubNames;
  final int currentWeek;

  @override
  Widget build(BuildContext context) {
    final sorted = [...fixtures]..sort((a, b) => a.week.compareTo(b.week));
    final weeks =
        sorted.map((fixture) => fixture.week).toSet().take(4).toList();
    return ListView(
      key: const Key('leagueFixturesTab'),
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (weeks.isEmpty)
          const _EmptyState(
            icon: Icons.event_busy_outlined,
            message: 'No remaining league fixtures this season.',
          ),
        for (final week in weeks) ...[
          _WeekHeading(
              week: week,
              label: week == currentWeek ? 'THIS WEEK' : 'UPCOMING'),
          Column(
            children: [
              for (final fixture
                  in sorted.where((fixture) => fixture.week == week))
                _FixtureRow(fixture: fixture, clubNames: clubNames),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _ResultsTab extends StatelessWidget {
  const _ResultsTab({required this.results, required this.clubNames});

  final List<MatchResult> results;
  final Map<String, String> clubNames;

  @override
  Widget build(BuildContext context) {
    final sorted = [...results]..sort((a, b) => b.week.compareTo(a.week));
    final weeks = sorted.map((result) => result.week).toSet().take(5).toList();
    return ListView(
      key: const Key('leagueResultsTab'),
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (weeks.isEmpty)
          const _EmptyState(
            icon: Icons.scoreboard_outlined,
            message:
                'No results yet. Advance one week to play the first round.',
          ),
        for (final week in weeks) ...[
          _WeekHeading(week: week, label: 'ROUND COMPLETE'),
          Column(
            children: [
              for (final result
                  in sorted.where((result) => result.week == week))
                _ResultRow(result: result, clubNames: clubNames),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _WeekHeading extends StatelessWidget {
  const _WeekHeading({required this.week, required this.label});
  final int week;
  final String label;

  @override
  Widget build(BuildContext context) => CompactSectionBar(
        title: 'Week $week',
        trailing: label,
      );
}

class _FixtureRow extends StatelessWidget {
  const _FixtureRow({required this.fixture, required this.clubNames});
  final LeagueFixture fixture;
  final Map<String, String> clubNames;

  @override
  Widget build(BuildContext context) => Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: AppColors.navy,
          border: Border(bottom: BorderSide(color: AppColors.slate)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(clubNames[fixture.homeClubId] ?? 'Home',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 34,
              height: 42,
              alignment: Alignment.center,
              color: AppColors.slate.withValues(alpha: 0.7),
              child: const Text('vs',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  )),
            ),
            Expanded(
              child: Text(clubNames[fixture.awayClubId] ?? 'Away',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result, required this.clubNames});
  final MatchResult result;
  final Map<String, String> clubNames;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('matchResult-${result.id}'),
          onTap: () => context.push(AppRoutes.matchDetails(result.id)),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              border: Border(bottom: BorderSide(color: AppColors.slate)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(clubNames[result.homeClubId] ?? 'Home',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 9),
                  width: 48,
                  height: 44,
                  alignment: Alignment.center,
                  color: AppColors.teal.withValues(alpha: 0.14),
                  child: Text('${result.homeGoals} – ${result.awayGoals}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      )),
                ),
                Expanded(
                  child: Text(clubNames[result.awayClubId] ?? 'Away',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => SectionPlaceholder(
        icon: icon,
        title: icon == Icons.event_busy_outlined
            ? 'No remaining fixtures'
            : 'No results yet',
        message: message,
      );
}
