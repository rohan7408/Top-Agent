import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../core/widgets/section_placeholder.dart';
import '../../../domain/models/club_offer.dart';
import '../../../domain/models/game_email.dart';
import '../../../domain/models/game_state.dart';

class EmailScreen extends ConsumerWidget {
  const EmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();
    final offers = game.offers
        .where((offer) => offer.status == ClubOfferStatus.pending)
        .toList(growable: false);
    final emails = game.emails
        .where((email) => _isAgencyRelevant(game, email))
        .toList(growable: false);
    final unreadCount = emails.where((email) => !email.isRead).length;

    if (offers.isEmpty && emails.isEmpty) {
      return const SectionPlaceholder(
        icon: Icons.mark_email_unread_outlined,
        title: 'Inbox clear',
        message: 'Client offers and agency updates appear here.',
      );
    }

    return Column(
      children: [
        _InboxSummary(
          unreadCount: unreadCount,
          actionCount: offers.length,
          totalCount: emails.length,
        ),
        Expanded(
          child: ListView(
            key: const Key('inboxList'),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              if (offers.isNotEmpty) ...[
                CompactSectionBar(
                  title: 'Action required',
                  trailing: '${offers.length} OFFERS',
                  accent: AppColors.amber,
                ),
                for (var index = 0; index < offers.length; index++)
                  _OfferRow(
                    offer: offers[index],
                    isAlternate: index.isOdd,
                    playerName: game.players
                        .firstWhere(
                            (player) => player.id == offers[index].playerId)
                        .name,
                    clubName: game.clubById(offers[index].clubId)!.name,
                  ),
              ],
              if (emails.isNotEmpty) ...[
                CompactSectionBar(
                  title: 'Agency updates',
                  trailing: '$unreadCount UNREAD',
                ),
                for (var index = 0; index < emails.length; index++)
                  _EmailRow(
                    email: emails[index],
                    isAlternate: index.isOdd,
                    seasonLabel: game.seasonLabel(emails[index].season),
                    onTap: () {
                      final email = emails[index];
                      ref
                          .read(gameControllerProvider.notifier)
                          .markEmailRead(email.id);
                      _showEmail(
                          context, email, game.seasonLabel(email.season));
                    },
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _isAgencyRelevant(GameState game, GameEmail email) {
    if (email.playerId == null) return true;
    final player = game.players
        .where((candidate) => candidate.id == email.playerId)
        .firstOrNull;
    if (player == null) return false;
    if (player.agentId == game.agent.id || player.isRecruited) return true;
    return email.id.startsWith('email-scout-') ||
        email.id.startsWith('email-academy-');
  }

  void _showEmail(
    BuildContext context,
    GameEmail email,
    String seasonLabel,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.navy,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email.subject,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '$seasonLabel · Week ${email.week}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(email.body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxSummary extends StatelessWidget {
  const _InboxSummary({
    required this.unreadCount,
    required this.actionCount,
    required this.totalCount,
  });

  final int unreadCount;
  final int actionCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: AppColors.navy,
        child: Row(
          children: [
            _InboxCount(value: '$unreadCount', label: 'UNREAD'),
            const VerticalDivider(width: 18, indent: 8, endIndent: 8),
            _InboxCount(value: '$actionCount', label: 'ACTIONS'),
            const Spacer(),
            Text(
              '$totalCount MESSAGES',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 8,
                  ),
            ),
          ],
        ),
      );
}

class _InboxCount extends StatelessWidget {
  const _InboxCount({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          text: '$value ',
          style: const TextStyle(
            color: AppColors.teal,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
          children: [
            TextSpan(
              text: label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 7,
                  ),
            ),
          ],
        ),
      );
}

class _OfferRow extends ConsumerWidget {
  const _OfferRow({
    required this.offer,
    required this.isAlternate,
    required this.playerName,
    required this.clubName,
  });

  final ClubOffer offer;
  final bool isAlternate;
  final String playerName;
  final String clubName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: isAlternate ? AppColors.panelAlt : AppColors.navy,
        border: const Border(
          left: BorderSide(color: AppColors.amber, width: 3),
          bottom: BorderSide(color: AppColors.slate),
        ),
      ),
      padding: const EdgeInsets.only(left: 8, right: 4),
      child: Row(
        children: [
          const Icon(Icons.description_outlined,
              color: AppColors.amber, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$clubName → $playerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  '${GameFormatters.compactCurrency(offer.weeklySalary)}/wk · ${offer.contractLength}y · Fee ${GameFormatters.compactCurrency(offer.agentFee)} · ${(offer.salaryCommissionRate * 100).round()}% cut',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted, fontSize: 9),
                ),
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tooltip: 'Decline',
            onPressed: () => ref
                .read(gameControllerProvider.notifier)
                .declineOffer(offer.id),
            icon: const Icon(Icons.close_rounded,
                color: AppColors.danger, size: 19),
          ),
          IconButton.filled(
            key: Key('inboxAcceptOfferButton-${offer.id}'),
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            tooltip: 'Suggest deal',
            onPressed: () {
              final result = ref
                  .read(gameControllerProvider.notifier)
                  .acceptOffer(offer.id);
              if (result == DealActionResult.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$playerName signed for $clubName.')),
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class _EmailRow extends StatelessWidget {
  const _EmailRow({
    required this.email,
    required this.isAlternate,
    required this.seasonLabel,
    required this.onTap,
  });
  final GameEmail email;
  final bool isAlternate;
  final String seasonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (email.type) {
      GameEmailType.transfer => Icons.swap_horiz_rounded,
      GameEmailType.contract => Icons.edit_document,
      GameEmailType.finance => Icons.account_balance_wallet_outlined,
      GameEmailType.world => Icons.public_rounded,
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 53,
        decoration: BoxDecoration(
          color: isAlternate ? AppColors.panelAlt : AppColors.navy,
          border: Border(
            left: BorderSide(
              color: email.isRead ? Colors.transparent : AppColors.teal,
              width: 3,
            ),
            bottom: const BorderSide(color: AppColors.slate),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(icon,
                color: email.isRead ? AppColors.muted : AppColors.teal,
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              email.isRead ? FontWeight.w500 : FontWeight.w800,
                        ),
                  ),
                  Text(
                    '$seasonLabel W${email.week} · ${email.body}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (!email.isRead)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: CircleAvatar(radius: 3, backgroundColor: AppColors.teal),
              ),
          ],
        ),
      ),
    );
  }
}
