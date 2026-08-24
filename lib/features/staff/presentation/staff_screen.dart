import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../core/widgets/compact_page_chrome.dart';
import '../../../domain/models/scout.dart';

class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          toolbarHeight: 46,
          titleSpacing: 0,
          title: const CompactPageTitle(
            title: 'Staff',
            eyebrow: 'Scouting department',
            accent: AppColors.ratingBlue,
          ),
        ),
        body: const SafeArea(top: false, child: StaffScreen()),
      );
}

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();
    final hired = game.hiredScouts.toList(growable: true)
      ..sort((a, b) => b.ability.compareTo(a.ability));
    final candidates = game.scouts
        .where((scout) => scout.isCandidate)
        .toList(growable: true)
      ..sort((a, b) => b.ability.compareTo(a.ability));
    final payroll = hired.fold<double>(0, (sum, scout) => sum + scout.salary);

    return Column(
      key: const Key('agencyStaffScreen'),
      children: [
        CompactSectionBar(
          title: 'Scouting staff',
          trailing:
              '${hired.length}/${game.office.scoutCapacity} · ${GameFormatters.compactCurrency(payroll)}/WK',
          accent: AppColors.ratingBlue,
        ),
        Expanded(
          child: ListView(
            key: const Key('staffManagementList'),
            padding: const EdgeInsets.only(bottom: 14),
            children: [
              const CompactTableHeader(
                identityLabel: 'YOUR SCOUTS',
                trailing: [
                  CompactColumnLabel('OVR', width: 44),
                  CompactColumnLabel('PAY', width: 58),
                  CompactColumnLabel('', width: 52),
                ],
              ),
              if (hired.isEmpty)
                const _EmptyRow('No scouts hired · choose a candidate below')
              else
                for (var index = 0; index < hired.length; index++)
                  _ScoutRow(
                    scout: hired[index],
                    alternate: index.isOdd,
                    actionLabel: 'FIRE',
                    actionColor: AppColors.danger,
                    onAction: () => _confirmDismiss(context, ref, hired[index]),
                  ),
              CompactSectionBar(
                title: 'Available scouts',
                trailing: '${candidates.length} CANDIDATES',
                accent: AppColors.amber,
              ),
              const CompactTableHeader(
                identityLabel: 'SCOUT / ACCESS',
                trailing: [
                  CompactColumnLabel('OVR', width: 44),
                  CompactColumnLabel('PAY', width: 58),
                  CompactColumnLabel('', width: 52),
                ],
              ),
              if (candidates.isEmpty)
                const _EmptyRow('New candidates arrive through the network')
              else
                Column(
                  key: const Key('scoutCandidateList'),
                  children: [
                    for (var index = 0; index < candidates.length; index++)
                      _ScoutRow(
                        scout: candidates[index],
                        alternate: index.isOdd,
                        actionLabel: _candidateAction(
                          scout: candidates[index],
                          reputation: game.agent.reputation,
                          isFull: hired.length >= game.office.scoutCapacity,
                        ),
                        actionColor: AppColors.teal,
                        onAction: hired.length >= game.office.scoutCapacity ||
                                game.agent.reputation <
                                    candidates[index].requiredReputation ||
                                !candidates[index].trustsAgencyEnough
                            ? null
                            : () => _hire(context, ref, candidates[index]),
                        candidate: true,
                        currentReputation: game.agent.reputation,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _hire(BuildContext context, WidgetRef ref, Scout scout) {
    final result =
        ref.read(gameControllerProvider.notifier).hireScout(scout.id);
    final message = switch (result) {
      ScoutActionResult.success =>
        '${scout.name} hired · ${GameFormatters.compactCurrency(scout.signingCost)}',
      ScoutActionResult.officeFull =>
        'Upgrade Facilities for another staff slot.',
      ScoutActionResult.reputationTooLow =>
        '${scout.name} requires ${scout.requiredReputation} reputation.',
      ScoutActionResult.trustTooLow =>
        '${scout.name} is not ready to join. Build reputation, improve Facilities, and maintain the relationship.',
      ScoutActionResult.notAvailable ||
      ScoutActionResult.scoutNotFound ||
      ScoutActionResult.notEmployed ||
      ScoutActionResult.noActiveGame =>
        'Staff action could not be completed.',
    };
    _message(context, message);
  }

  Future<void> _confirmDismiss(
    BuildContext context,
    WidgetRef ref,
    Scout scout,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dismiss scout?'),
        content: Text('${scout.name} will leave the agency immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result =
        ref.read(gameControllerProvider.notifier).dismissScout(scout.id);
    _message(
      context,
      result == ScoutActionResult.success
          ? '${scout.name} dismissed.'
          : 'Staff action could not be completed.',
    );
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ScoutRow extends StatelessWidget {
  const _ScoutRow({
    required this.scout,
    required this.alternate,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
    this.candidate = false,
    this.currentReputation = 0,
  });

  final Scout scout;
  final bool alternate;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback? onAction;
  final bool candidate;
  final int currentReputation;

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: alternate ? AppColors.panelAlt : AppColors.navy,
          border: const Border(
            left: BorderSide(color: AppColors.ratingBlue, width: 3),
            bottom: BorderSide(color: AppColors.slate),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 32,
              child: CompactPositionBadge(label: 'SCT'),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scout.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    candidate
                        ? currentReputation < scout.requiredReputation
                            ? 'Trust ${scout.agencyTrust} · Requires ${scout.requiredReputation} REP'
                            : !scout.trustsAgencyEnough
                                ? 'Trust ${scout.agencyTrust} · Build relationship'
                                : 'Trust ${scout.agencyTrust} · Sign ${GameFormatters.compactCurrency(scout.signingCost)}'
                        : 'Trust ${scout.agencyTrust} · ${scout.weeksWithAgency} weeks',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: candidate &&
                              currentReputation < scout.requiredReputation
                          ? AppColors.danger
                          : AppColors.muted,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            CompactRatingCell(
              value: scout.ability,
              width: 44,
              color: compactRatingColor(scout.ability),
            ),
            SizedBox(
              width: 58,
              child: Text(
                GameFormatters.compactCurrency(scout.salary),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(
              width: 52,
              height: double.infinity,
              child: Material(
                color: onAction == null
                    ? AppColors.slate.withValues(alpha: 0.35)
                    : actionColor.withValues(alpha: 0.15),
                child: InkWell(
                  key: Key(
                    '${candidate ? 'hire' : 'dismiss'}ScoutButton-${scout.id}',
                  ),
                  onTap: onAction,
                  child: Center(
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: onAction == null ? AppColors.muted : actionColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              message,
              textAlign: TextAlign.left,
              style: const TextStyle(color: AppColors.muted, fontSize: 9),
            ),
          ),
        ),
      );
}

String _candidateAction({
  required Scout scout,
  required int reputation,
  required bool isFull,
}) {
  if (isFull) return 'FULL';
  if (reputation < scout.requiredReputation) return 'LOCKED';
  if (!scout.trustsAgencyEnough) return 'WAIT';
  return 'HIRE';
}
