import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../core/widgets/section_placeholder.dart';
import '../../../domain/models/club_offer.dart';
import '../../../domain/models/player.dart';

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
          identityLabel: 'PLAYER / CLUB',
          trailing: const [
            CompactColumnLabel('AGE', width: 28),
            CompactColumnLabel('OVR', width: 38),
            CompactColumnLabel('POT', width: 38),
            CompactColumnLabel('ACTION', width: 58),
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
                  : game.clubById(player.clubId!)?.name ?? 'Unknown club';
              final injury = game.activeInjuryForPlayer(player.id);
              return _PlayerRow(
                player: player,
                clubName: clubName,
                availabilityLabel: injury == null
                    ? 'Fatigue ${player.fatigue.round()}%'
                    : game.injuryAvailabilityLabel(injury),
                isInjured: injury != null,
                isAlternate: index.isOdd,
                pendingOfferCount:
                    game.pendingOffersForPlayer(player.id).length,
                onOpen: () => context.push(AppRoutes.playerDetails(player.id)),
                onSuggest: () => _suggestPlayer(context, ref, player),
              );
            },
          ),
        ),
      ],
    );
  }

  void _suggestPlayer(BuildContext context, WidgetRef ref, Player player) {
    final result =
        ref.read(gameControllerProvider.notifier).suggestPlayer(player.id);
    final canShowOffers = result.status == SuggestionStatus.success ||
        result.status == SuggestionStatus.alreadySuggested;
    if (canShowOffers) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.navy,
        builder: (context) => _PlayerOffersSheet(playerId: player.id),
      );
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
  Widget build(BuildContext context) {
    return Container(
      height: 37,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      color: AppColors.navy,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$playerCount ${playerCount == 1 ? 'PLAYER' : 'PLAYERS'} REPRESENTED',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.teal,
                  ),
            ),
          ),
          Text(
            'PORTFOLIO  ${GameFormatters.compactCurrency(portfolioValue)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.amber,
                  fontSize: 8,
                ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.clubName,
    required this.pendingOfferCount,
    required this.availabilityLabel,
    required this.isInjured,
    required this.isAlternate,
    required this.onOpen,
    required this.onSuggest,
  });

  final Player player;
  final String clubName;
  final int pendingOfferCount;
  final String availabilityLabel;
  final bool isInjured;
  final bool isAlternate;
  final VoidCallback onOpen;
  final VoidCallback onSuggest;

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
    return Material(
      key: Key('representedPlayerCard-${player.id}'),
      color: isAlternate ? AppColors.panelAlt : AppColors.navy,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          height: 59,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.slate)),
          ),
          child: Row(
            children: [
              Container(width: 3, color: railColor),
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
                      '$clubName  ·  $availabilityLabel  ·  ${GameFormatters.compactCurrency(player.value)}',
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
              ),
              CompactRatingCell(
                value: player.potential,
                color: AppColors.teal,
                emphasized: true,
              ),
              SizedBox(
                width: 58,
                child: TextButton(
                  key: Key('suggestPlayerButton-${player.id}'),
                  onPressed: canSuggest ? onSuggest : null,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    disabledForegroundColor: AppColors.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    pendingOfferCount > 0
                        ? '$pendingOfferCount OFFER${pendingOfferCount == 1 ? '' : 'S'}'
                        : canSuggest
                            ? 'SUGGEST'
                            : player.isRetired
                                ? 'RETIRED'
                                : 'SIGNED',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
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

class _PlayerOffersSheet extends ConsumerWidget {
  const _PlayerOffersSheet({required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();
    final player = game.players.firstWhere((player) => player.id == playerId);
    final offers = game.pendingOffersForPlayer(playerId);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Offers for ${player.name}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${offers.length} active club ${offers.length == 1 ? 'offer' : 'offers'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 14),
            if (offers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No active offers remain.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: offers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _OfferRow(offer: offers[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OfferRow extends ConsumerWidget {
  const _OfferRow({required this.offer});

  final ClubOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider)!;
    final club = game.clubById(offer.clubId)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(club.name,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Text('${offer.contractLength} years'),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${GameFormatters.compactCurrency(offer.weeklySalary)}/wk',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  'Fee ${GameFormatters.compactCurrency(offer.agentFee)}',
                  style: const TextStyle(color: AppColors.amber),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${(offer.salaryCommissionRate * 100).round()}% salary commission · ${GameFormatters.compactCurrency(offer.weeklySalary * offer.salaryCommissionRate)}/wk agency income',
                style: const TextStyle(color: AppColors.muted, fontSize: 9),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(gameControllerProvider.notifier)
                        .declineOffer(offer.id),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    key: Key('acceptOfferButton-${offer.id}'),
                    onPressed: () {
                      final result = ref
                          .read(gameControllerProvider.notifier)
                          .acceptOffer(offer.id);
                      if (result == DealActionResult.success) {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(context).pop();
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text('${club.name} deal completed.')),
                        );
                      }
                    },
                    child: const Text('Suggest deal'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
