import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../domain/models/club.dart';
import '../../../domain/models/club_manager.dart';
import '../../../domain/models/club_season_record.dart';
import '../../../domain/models/contract_event.dart';
import '../../../domain/models/league_fixture.dart';
import '../../../domain/models/match_result.dart';
import '../../../domain/models/player.dart';
import '../../../domain/models/player_season_stats.dart';
import '../../../domain/models/transfer_record.dart';
import '../../../domain/services/squad_analysis_service.dart';

class ClubDetailScreen extends ConsumerWidget {
  const ClubDetailScreen({required this.clubId, super.key});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final club = game?.clubById(clubId);
    if (game == null || club == null) {
      return const Scaffold(
        body: Center(child: Text('Club not found.')),
      );
    }

    final players = game.playersForClub(club.id)
      ..sort((first, second) {
        final positionComparison =
            first.position.index.compareTo(second.position.index);
        if (positionComparison != 0) return positionComparison;
        return second.ability.compareTo(first.ability);
      });
    final leagueName = game.leagueById(club.leagueId)?.name ?? 'Unknown league';
    final record = game.currentRecordForClub(club.id);
    final recentResults = game.resultsForClub(club.id).take(5).toList();
    final clubNames = {for (final club in game.clubs) club.id: club.name};
    final clubStats = game.playerSeasonStats
        .where((stats) =>
            stats.clubId == club.id && stats.season == game.currentSeason)
        .toList();
    final tableIndex =
        game.currentStandings.indexWhere((item) => item.clubId == club.id);
    final manager = game.managerForClub(club.id);
    final transferPriority = const SquadAnalysisService()
        .prioritiesForClub(club, game.players)
        .first;
    final playerNames = {
      for (final player in game.players) player.id: player.name
    };
    final expiringPlayers = players
        .where((player) =>
            player.contractEndSeason != null &&
            player.contractEndSeason! <= game.currentSeason + 1)
        .toList(growable: true)
      ..sort((first, second) =>
          first.contractEndSeason!.compareTo(second.contractEndSeason!));
    final injuryLabels = {
      for (final player in players)
        if (game.activeInjuryForPlayer(player.id) case final injury?)
          player.id: game.injuryAvailabilityLabel(injury),
    };

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 50,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                club.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              Text(
                '$leagueName · ${tableIndex < 0 ? 'UNRANKED' : '#${tableIndex + 1}'}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.teal,
                      fontSize: 7,
                    ),
              ),
            ],
          ),
          bottom: const TabBar(
            labelPadding: EdgeInsets.zero,
            labelStyle: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Squad'),
              Tab(text: 'Stats'),
              Tab(text: 'Finance'),
              Tab(text: 'Schedule'),
            ],
          ),
        ),
        body: Column(
          children: [
            _ClubHeader(
              club: club,
              playerCount: players.length,
              points: record?.points ?? 0,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(
                    club: club,
                    players: players,
                    leagueName: leagueName,
                    record: record,
                    recentResults: recentResults,
                    clubNames: clubNames,
                    managerName: manager?.name ?? 'Vacant',
                    managerProfile: manager == null
                        ? '—'
                        : '${manager.tacticalStyle.label} · ${manager.ability}',
                    managerRotation:
                        manager == null ? '—' : '${manager.rotation}/99',
                    transferPriority:
                        '${transferPriority.position.shortLabel} · ${transferPriority.playerCount} players',
                  ),
                  _SquadTab(
                    players: players,
                    injuryLabels: injuryLabels,
                    stats: clubStats,
                  ),
                  _ClubStatsTab(
                    record: record,
                    stats: clubStats,
                    players: players,
                    leaguePosition: tableIndex < 0 ? 0 : tableIndex + 1,
                  ),
                  _FinanceTab(
                    club: club,
                    transfers: game.transfersForClub(club.id),
                    contractEvents: game.contractEventsForClub(club.id),
                    expiringPlayers: expiringPlayers,
                    playerNames: playerNames,
                    clubNames: clubNames,
                    seasonLabel: game.seasonLabel,
                  ),
                  _ScheduleTab(
                    clubId: club.id,
                    currentWeek: game.currentWeek,
                    fixtures: game.fixtures
                        .where((fixture) =>
                            fixture.season == game.currentSeason &&
                            (fixture.homeClubId == club.id ||
                                fixture.awayClubId == club.id))
                        .toList(),
                    results: game.resultsForClub(club.id).toList(),
                    clubNames: clubNames,
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

class _ClubHeader extends StatelessWidget {
  const _ClubHeader({
    required this.club,
    required this.playerCount,
    required this.points,
  });

  final Club club;
  final int playerCount;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        border: Border(bottom: BorderSide(color: AppColors.slate)),
      ),
      child: Row(
        children: [
          _HeaderMetric(label: 'SQUAD', value: '$playerCount'),
          _HeaderMetric(label: 'POINTS', value: '$points'),
          _HeaderMetric(
            label: 'BUDGET',
            value: GameFormatters.compactCurrency(club.budget),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 8,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.club,
    required this.players,
    required this.leagueName,
    required this.record,
    required this.recentResults,
    required this.clubNames,
    required this.managerName,
    required this.managerProfile,
    required this.managerRotation,
    required this.transferPriority,
  });

  final Club club;
  final List<Player> players;
  final String leagueName;
  final ClubSeasonRecord? record;
  final List<MatchResult> recentResults;
  final Map<String, String> clubNames;
  final String managerName;
  final String managerProfile;
  final String managerRotation;
  final String transferPriority;

  @override
  Widget build(BuildContext context) {
    final averageAge = players.isEmpty
        ? 0
        : players.map((player) => player.age).reduce((a, b) => a + b) /
            players.length;
    final averageAbility = players.isEmpty
        ? 0
        : players.map((player) => player.ability).reduce((a, b) => a + b) /
            players.length;
    final highestValue = players.isEmpty
        ? 0.0
        : players.map((player) => player.value).reduce((a, b) => a > b ? a : b);

    return Column(
      key: const Key('clubOverviewTab'),
      children: [
        const CompactSectionBar(title: 'Club snapshot'),
        CompactInfoRow(label: 'Competition', value: leagueName),
        CompactInfoRow(
          label: 'League record',
          value:
              '${record?.won ?? 0}W  ${record?.drawn ?? 0}D  ${record?.lost ?? 0}L  ·  ${record?.points ?? 0} pts',
        ),
        CompactInfoRow(
          label: 'Manager',
          value: '$managerName  ·  $managerProfile',
        ),
        CompactInfoRow(
          label: 'Squad profile',
          value:
              '${averageAge.toStringAsFixed(1)} avg age  ·  ${averageAbility.toStringAsFixed(1)} avg OVR',
        ),
        CompactInfoRow(
          label: 'Rotation / recruitment',
          value: '$managerRotation  ·  $transferPriority',
        ),
        CompactInfoRow(
          label: 'Most valuable player',
          value: GameFormatters.compactCurrency(highestValue),
          valueColor: AppColors.amber,
        ),
        CompactSectionBar(
          title: 'Recent results',
          trailing: recentResults.isEmpty ? 'NO MATCHES' : 'LAST 5',
        ),
        Expanded(
          child: recentResults.isEmpty
              ? Center(
                  child: Text(
                    'Advance one week to begin the season.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final result in recentResults)
                      _ResultRow(result: result, clubNames: clubNames),
                  ],
                ),
        ),
        const CompactSectionBar(title: 'Club scale'),
        CompactInfoRow(
          label: 'Club valuation',
          value: GameFormatters.compactCurrency(club.clubValue),
        ),
        CompactInfoRow(
          label: 'Squad valuation',
          value: GameFormatters.compactCurrency(club.squadValue),
        ),
        CompactInfoRow(
          label: 'Transfer budget',
          value: GameFormatters.compactCurrency(club.budget),
          valueColor: AppColors.teal,
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result, required this.clubNames});

  final MatchResult result;
  final Map<String, String> clubNames;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.matchDetails(result.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  clubNames[result.homeClubId] ?? 'Home',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.slate,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${result.homeGoals}  –  ${result.awayGoals}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Text(
                  clubNames[result.awayClubId] ?? 'Away',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquadTab extends StatelessWidget {
  const _SquadTab({
    required this.players,
    required this.injuryLabels,
    required this.stats,
  });

  final List<Player> players;
  final Map<String, String> injuryLabels;
  final List<PlayerSeasonStats> stats;

  @override
  Widget build(BuildContext context) {
    final statsByPlayer = {for (final item in stats) item.playerId: item};
    return Column(
      key: const Key('clubSquadTab'),
      children: [
        CompactTableHeader(
          identityLabel: 'PLAYER / STATUS',
          trailing: const [
            CompactColumnLabel('APP', width: 32),
            CompactColumnLabel('OVR', width: 38),
            CompactColumnLabel('POT', width: 38),
          ],
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: players.length,
            itemBuilder: (context, index) => _SquadPlayerCard(
              player: players[index],
              appearances: statsByPlayer[players[index].id]?.appearances ?? 0,
              availability: injuryLabels[players[index].id] ??
                  'Fatigue ${players[index].fatigue.round()}%',
              isInjured: injuryLabels.containsKey(players[index].id),
              isAlternate: index.isOdd,
              onTap: () =>
                  context.push(AppRoutes.playerDetails(players[index].id)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SquadPlayerCard extends StatelessWidget {
  const _SquadPlayerCard({
    required this.player,
    required this.appearances,
    required this.availability,
    required this.isInjured,
    required this.isAlternate,
    required this.onTap,
  });

  final Player player;
  final int appearances;
  final String availability;
  final bool isInjured;
  final bool isAlternate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAlternate ? AppColors.panelAlt : AppColors.navy,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.slate)),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                color: isInjured ? AppColors.danger : AppColors.teal,
              ),
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
                      '${player.age} yrs  ·  $availability  ·  ${GameFormatters.compactCurrency(player.salary)}/wk',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                isInjured ? AppColors.danger : AppColors.muted,
                            fontSize: 9,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$appearances',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ClubStatsTab extends StatelessWidget {
  const _ClubStatsTab({
    required this.record,
    required this.stats,
    required this.players,
    required this.leaguePosition,
  });

  final ClubSeasonRecord? record;
  final List<PlayerSeasonStats> stats;
  final List<Player> players;
  final int leaguePosition;

  @override
  Widget build(BuildContext context) {
    final statsByPlayer = {for (final item in stats) item.playerId: item};
    final rankedScorers = [...stats]..sort((a, b) {
        final goals = b.goals.compareTo(a.goals);
        return goals != 0 ? goals : b.assists.compareTo(a.assists);
      });
    final rankedCreators = [...stats]..sort((a, b) {
        final assists = b.assists.compareTo(a.assists);
        return assists != 0 ? assists : b.goals.compareTo(a.goals);
      });
    final topScorer = rankedScorers.firstOrNull;
    final topCreator = rankedCreators.firstOrNull;
    final scorerName = players
            .where((player) => player.id == topScorer?.playerId)
            .firstOrNull
            ?.name ??
        '—';
    final creatorName = players
            .where((player) => player.id == topCreator?.playerId)
            .firstOrNull
            ?.name ??
        '—';
    final appearances =
        stats.fold<int>(0, (sum, item) => sum + item.appearances);
    final totalRating =
        stats.fold<double>(0, (sum, item) => sum + item.totalRating);
    final averageRating = appearances == 0 ? 0 : totalRating / appearances;

    final output = [...players]..sort((a, b) {
        final first = statsByPlayer[a.id];
        final second = statsByPlayer[b.id];
        final goals = (second?.goals ?? 0).compareTo(first?.goals ?? 0);
        if (goals != 0) return goals;
        return (second?.assists ?? 0).compareTo(first?.assists ?? 0);
      });

    return Column(
      key: const Key('clubStatsTab'),
      children: [
        const CompactSectionBar(title: 'League performance'),
        CompactInfoRow(
          label: 'Position / points',
          value:
              '${leaguePosition == 0 ? '—' : '#$leaguePosition'}  ·  ${record?.points ?? 0} pts',
          height: 30,
        ),
        CompactInfoRow(
          label: 'Record',
          value:
              '${record?.won ?? 0}W  ${record?.drawn ?? 0}D  ${record?.lost ?? 0}L',
          height: 30,
        ),
        CompactInfoRow(
          label: 'Goals for / against',
          value: '${record?.goalsFor ?? 0} / ${record?.goalsAgainst ?? 0}',
          height: 30,
        ),
        CompactInfoRow(
          label: 'Goal difference / clean sheets',
          value:
              '${(record?.goalDifference ?? 0) > 0 ? '+' : ''}${record?.goalDifference ?? 0}  ·  ${record?.cleanSheets ?? 0}',
          height: 30,
        ),
        const CompactSectionBar(title: 'Squad leaders'),
        CompactInfoRow(
          label: 'Top scorer',
          value: '$scorerName  ·  ${topScorer?.goals ?? 0} goals',
          height: 30,
          valueColor: AppColors.amber,
        ),
        CompactInfoRow(
          label: 'Top creator',
          value: '$creatorName  ·  ${topCreator?.assists ?? 0} assists',
          height: 30,
        ),
        CompactInfoRow(
          label: 'Average rating / players used',
          value:
              '${averageRating == 0 ? '—' : averageRating.toStringAsFixed(2)}  ·  ${statsByPlayer.length}',
          height: 30,
        ),
        CompactTableHeader(
          identityLabel: 'PLAYER OUTPUT',
          trailing: const [
            CompactColumnLabel('APP', width: 32),
            CompactColumnLabel('G', width: 26),
            CompactColumnLabel('A', width: 26),
            CompactColumnLabel('RAT', width: 40),
          ],
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: output.length,
            itemBuilder: (context, index) => _PlayerOutputRow(
              player: output[index],
              stats: statsByPlayer[output[index].id],
              isAlternate: index.isOdd,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerOutputRow extends StatelessWidget {
  const _PlayerOutputRow({
    required this.player,
    required this.stats,
    required this.isAlternate,
  });

  final Player player;
  final PlayerSeasonStats? stats;
  final bool isAlternate;

  @override
  Widget build(BuildContext context) {
    final rating = stats == null || stats!.appearances == 0
        ? null
        : stats!.totalRating / stats!.appearances;
    return Material(
      color: isAlternate ? AppColors.panelAlt : AppColors.navy,
      child: InkWell(
        onTap: () => context.push(AppRoutes.playerDetails(player.id)),
        child: Container(
          height: 39,
          padding: const EdgeInsets.only(left: 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.slate)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${player.name}  ${player.position.shortLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _OutputNumber('${stats?.appearances ?? 0}', width: 32),
              _OutputNumber('${stats?.goals ?? 0}', width: 26),
              _OutputNumber('${stats?.assists ?? 0}', width: 26),
              _OutputNumber(
                rating == null ? '—' : rating.toStringAsFixed(1),
                width: 40,
                color: rating == null ? AppColors.muted : AppColors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutputNumber extends StatelessWidget {
  const _OutputNumber(this.value, {required this.width, this.color});

  final String value;
  final double width;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color ?? AppColors.paper,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _FinanceTab extends StatelessWidget {
  const _FinanceTab({
    required this.club,
    required this.transfers,
    required this.contractEvents,
    required this.expiringPlayers,
    required this.playerNames,
    required this.clubNames,
    required this.seasonLabel,
  });

  final Club club;
  final List<TransferRecord> transfers;
  final List<ContractEvent> contractEvents;
  final List<Player> expiringPlayers;
  final Map<String, String> playerNames;
  final Map<String, String> clubNames;
  final String Function(int season) seasonLabel;

  @override
  Widget build(BuildContext context) {
    final seasonWages = club.totalSalary * 50;
    final budgetToSquadRatio =
        club.squadValue == 0 ? 0.0 : (club.budget / club.squadValue) * 100;
    final wageCover =
        club.totalSalary <= 0 ? 0.0 : club.balance / club.totalSalary;
    final transferSpend = transfers
        .where((item) => item.toClubId == club.id)
        .fold<double>(0, (sum, item) => sum + item.fee);
    final transferIncome = transfers
        .where((item) => item.fromClubId == club.id)
        .fold<double>(0, (sum, item) => sum + item.fee);
    final transferRows = transfers.take(8).map((item) {
      final isIncoming = item.toClubId == club.id;
      final otherClubId = isIncoming ? item.fromClubId : item.toClubId;
      return (
        '${isIncoming ? 'IN' : 'OUT'} · ${playerNames[item.playerId] ?? 'Unknown player'}',
        '${clubNames[otherClubId] ?? 'Unknown'} · ${GameFormatters.compactCurrency(item.fee)}',
      );
    }).toList(growable: false);
    final contractRows = contractEvents
        .where((item) =>
            item.type == ContractEventType.renewed ||
            item.type == ContractEventType.expired)
        .take(8)
        .map((item) {
      final playerName = playerNames[item.playerId] ?? 'Unknown player';
      return switch (item.type) {
        ContractEventType.renewed => (
            'RENEWED · $playerName',
            '${GameFormatters.compactCurrency(item.weeklySalary)}/wk · ${item.endSeason == null ? '—' : seasonLabel(item.endSeason!)}'
          ),
        ContractEventType.expired => (
            'EXPIRED · $playerName',
            '${seasonLabel(item.season)} · ${GameFormatters.compactCurrency(item.weeklySalary)}/wk'
          ),
        ContractEventType.signed => ('SIGNED · $playerName', '—'),
      };
    }).toList(growable: false);
    final expiryRows = expiringPlayers
        .take(8)
        .map((player) => (
              player.name,
              'Expires ${seasonLabel(player.contractEndSeason!)} · ${GameFormatters.compactCurrency(player.salary)}/wk',
            ))
        .toList(growable: false);

    return ListView(
      key: const Key('clubFinanceTab'),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        const CompactSectionBar(title: 'Financial position'),
        _FinanceMetricStrip(
          items: [
            ('CASH', GameFormatters.compactCurrency(club.balance)),
            ('CLUB VALUE', GameFormatters.compactCurrency(club.clubValue)),
            ('SQUAD', GameFormatters.compactCurrency(club.squadValue)),
            ('BUDGET', GameFormatters.compactCurrency(club.budget)),
          ],
        ),
        CompactInfoRow(
          label: 'Weekly wage bill',
          value: GameFormatters.compactCurrency(club.totalSalary),
          height: 31,
        ),
        CompactInfoRow(
          label: '50-week wages / wage cover',
          value:
              '${GameFormatters.compactCurrency(seasonWages)}  ·  ${wageCover.toStringAsFixed(1)} weeks',
          height: 31,
        ),
        CompactInfoRow(
          label: 'Budget as share of squad value',
          value: '${budgetToSquadRatio.toStringAsFixed(1)}%',
          valueColor: AppColors.teal,
          height: 31,
        ),
        const CompactSectionBar(title: 'Transfers in / out'),
        CompactInfoRow(
          label: 'Spent / received',
          value:
              '${GameFormatters.compactCurrency(transferSpend)}  /  ${GameFormatters.compactCurrency(transferIncome)}',
          height: 31,
        ),
        CompactInfoRow(
          label: 'Net spend',
          value: GameFormatters.compactCurrency(transferSpend - transferIncome),
          valueColor: transferSpend > transferIncome
              ? AppColors.danger
              : AppColors.teal,
          height: 31,
        ),
        if (transferRows.isEmpty)
          const _EmptyFinanceLine('No completed transfers yet.')
        else
          for (final row in transferRows)
            CompactInfoRow(label: row.$1, value: row.$2, height: 33),
        const CompactSectionBar(
          title: 'Contracts expiring',
          accent: AppColors.amber,
        ),
        if (expiryRows.isEmpty)
          const _EmptyFinanceLine('No contracts expire this or next season.')
        else
          for (final row in expiryRows)
            CompactInfoRow(label: row.$1, value: row.$2, height: 33),
        const CompactSectionBar(title: 'Renewals / expiry'),
        if (contractRows.isEmpty)
          const _EmptyFinanceLine('No renewal or expiry activity yet.')
        else
          for (final row in contractRows)
            CompactInfoRow(label: row.$1, value: row.$2, height: 33),
      ],
    );
  }
}

class _FinanceMetricStrip extends StatelessWidget {
  const _FinanceMetricStrip({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        decoration: const BoxDecoration(
          color: AppColors.navy,
          border: Border(bottom: BorderSide(color: AppColors.slate)),
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[index].$1,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.muted,
                              fontSize: 7,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[index].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: index == items.length - 1
                                  ? AppColors.teal
                                  : AppColors.paper,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              if (index != items.length - 1)
                const VerticalDivider(width: 1, thickness: 1),
            ],
          ],
        ),
      );
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab({
    required this.clubId,
    required this.currentWeek,
    required this.fixtures,
    required this.results,
    required this.clubNames,
  });

  final String clubId;
  final int currentWeek;
  final List<LeagueFixture> fixtures;
  final List<MatchResult> results;
  final Map<String, String> clubNames;

  @override
  Widget build(BuildContext context) {
    final upcoming = fixtures
        .where((fixture) => fixture.week >= currentWeek)
        .toList()
      ..sort((a, b) => a.week.compareTo(b.week));
    final completed = [...results]..sort((a, b) => b.week.compareTo(a.week));
    return ListView(
      key: const Key('clubScheduleTab'),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        CompactSectionBar(
          title: 'Upcoming fixtures',
          trailing: '${upcoming.length} REMAINING',
        ),
        if (upcoming.isEmpty)
          const _EmptyFinanceLine('No remaining fixtures this season.')
        else
          for (var index = 0; index < upcoming.length; index++)
            _ClubFixtureRow(
              fixture: upcoming[index],
              clubId: clubId,
              clubNames: clubNames,
              isAlternate: index.isOdd,
            ),
        CompactSectionBar(
          title: 'Completed matches',
          trailing: '${completed.length} PLAYED',
        ),
        if (completed.isEmpty)
          const _EmptyFinanceLine('No matches played yet.')
        else
          for (var index = 0; index < completed.length; index++)
            _ClubResultRow(
              result: completed[index],
              clubId: clubId,
              clubNames: clubNames,
              isAlternate: index.isOdd,
            ),
      ],
    );
  }
}

class _ClubFixtureRow extends StatelessWidget {
  const _ClubFixtureRow({
    required this.fixture,
    required this.clubId,
    required this.clubNames,
    required this.isAlternate,
  });

  final LeagueFixture fixture;
  final String clubId;
  final Map<String, String> clubNames;
  final bool isAlternate;

  @override
  Widget build(BuildContext context) {
    final isHome = fixture.homeClubId == clubId;
    final opponentId = isHome ? fixture.awayClubId : fixture.homeClubId;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isAlternate ? AppColors.panelAlt : AppColors.navy,
        border: const Border(bottom: BorderSide(color: AppColors.slate)),
      ),
      padding: const EdgeInsets.only(left: 11),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              'W${fixture.week}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 8,
                  ),
            ),
          ),
          Container(
            width: 25,
            height: double.infinity,
            alignment: Alignment.center,
            color: (isHome ? AppColors.teal : AppColors.ratingBlue)
                .withValues(alpha: 0.16),
            child: Text(
              isHome ? 'H' : 'A',
              style: TextStyle(
                color: isHome ? AppColors.teal : AppColors.ratingBlue,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              clubNames[opponentId] ?? 'Unknown club',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11),
            child: Text('—', style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

class _ClubResultRow extends StatelessWidget {
  const _ClubResultRow({
    required this.result,
    required this.clubId,
    required this.clubNames,
    required this.isAlternate,
  });

  final MatchResult result;
  final String clubId;
  final Map<String, String> clubNames;
  final bool isAlternate;

  @override
  Widget build(BuildContext context) {
    final isHome = result.homeClubId == clubId;
    final opponentId = isHome ? result.awayClubId : result.homeClubId;
    final clubGoals = isHome ? result.homeGoals : result.awayGoals;
    final opponentGoals = isHome ? result.awayGoals : result.homeGoals;
    final outcomeColor = clubGoals > opponentGoals
        ? AppColors.teal
        : clubGoals < opponentGoals
            ? AppColors.danger
            : AppColors.amber;
    return Material(
      color: isAlternate ? AppColors.panelAlt : AppColors.navy,
      child: InkWell(
        onTap: () => context.push(AppRoutes.matchDetails(result.id)),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.slate)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  'W${result.week}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 8,
                      ),
                ),
              ),
              SizedBox(
                width: 25,
                child: Text(
                  isHome ? 'H' : 'A',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  clubNames[opponentId] ?? 'Unknown club',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 50,
                height: double.infinity,
                alignment: Alignment.center,
                color: outcomeColor.withValues(alpha: 0.18),
                child: Text(
                  '$clubGoals–$opponentGoals',
                  style: TextStyle(
                    color: outcomeColor,
                    fontSize: 12,
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
}

class _EmptyFinanceLine extends StatelessWidget {
  const _EmptyFinanceLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.slate)),
        ),
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.muted),
        ),
      );
}
