import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../domain/models/agency_office.dart';
import '../../../domain/models/scout.dart';
import '../../../domain/models/training_ground.dart';

class OfficeScreen extends ConsumerWidget {
  const OfficeScreen({super.key});

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
      key: const Key('agencyOfficeScreen'),
      children: [
        CompactSectionBar(
          title: 'Office Level ${game.office.level}',
          trailing:
              'CLIENTS ${game.representedPlayers.length}/${game.office.clientCapacity}',
          accent: AppColors.teal,
        ),
        _OfficeMetrics(
          clientCount: game.representedPlayers.length,
          office: game.office,
          scoutCount: hired.length,
        ),
        _UpgradeStrip(
          office: game.office,
          reputation: game.agent.reputation,
          onUpgrade: game.office.canUpgrade
              ? () => _confirmUpgrade(context, ref, game.office)
              : null,
        ),
        CompactSectionBar(
          title: 'Training Ground Level ${game.trainingGround.level}',
          trailing:
              'INTAKE ${game.trainingGround.weeksUntilIntake(game.currentAbsoluteWeek)}W',
          accent: AppColors.amber,
        ),
        _TrainingGroundStrip(
          ground: game.trainingGround,
          reputation: game.agent.reputation,
          onUpgrade: game.trainingGround.canUpgrade
              ? () => _confirmTrainingGroundUpgrade(
                    context,
                    ref,
                    game.trainingGround,
                  )
              : null,
        ),
        Expanded(
          child: ListView(
            key: const Key('officeManagementList'),
            padding: const EdgeInsets.only(bottom: 14),
            children: [
              CompactSectionBar(
                title: 'Your scouts',
                trailing:
                    '${hired.length}/${game.office.scoutCapacity} · ${GameFormatters.compactCurrency(payroll)}/WK',
                accent: AppColors.ratingBlue,
              ),
              const CompactTableHeader(
                identityLabel: 'SCOUT',
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
                const _EmptyRow('New scout candidates arrive next week')
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
                        actionColor: _candidateColor(
                          scout: candidates[index],
                          reputation: game.agent.reputation,
                          isFull: hired.length >= game.office.scoutCapacity,
                        ),
                        onAction: hired.length >= game.office.scoutCapacity ||
                                game.agent.reputation <
                                    candidates[index].requiredReputation
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
      ScoutActionResult.officeFull => 'Upgrade the Office for another scout.',
      ScoutActionResult.reputationTooLow =>
        '${scout.name} requires ${scout.requiredReputation} reputation.',
      ScoutActionResult.notAvailable ||
      ScoutActionResult.scoutNotFound ||
      ScoutActionResult.notEmployed ||
      ScoutActionResult.noActiveGame =>
        'Scout action could not be completed.',
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
          : 'Scout action could not be completed.',
    );
  }

  Future<void> _confirmUpgrade(
    BuildContext context,
    WidgetRef ref,
    AgencyOffice office,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Upgrade to Office Level ${office.level + 1}?'),
        content: Text(
          '${GameFormatters.compactCurrency(office.nextUpgradeMoneyCost)} and ${office.nextUpgradeReputationCost} reputation will be deducted. Money may go negative.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Upgrade Office'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = ref.read(gameControllerProvider.notifier).upgradeOffice();
    final message = switch (result) {
      OfficeUpgradeResult.success => 'Office upgraded.',
      OfficeUpgradeResult.reputationTooLow =>
        'Requires ${office.nextUpgradeReputationRequirement} reputation.',
      OfficeUpgradeResult.maximumLevel => 'Office is already at maximum level.',
      OfficeUpgradeResult.noActiveGame => 'Office could not be upgraded.',
    };
    _message(context, message);
  }

  Future<void> _confirmTrainingGroundUpgrade(
    BuildContext context,
    WidgetRef ref,
    TrainingGround ground,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Upgrade Training Ground to Level ${ground.level + 1}?'),
        content: Text(
          '${GameFormatters.compactCurrency(ground.nextUpgradeMoneyCost)} and ${ground.nextUpgradeReputationCost} reputation will be deducted. The facility produces stronger internal prospects; scouts are not involved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Upgrade Ground'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result =
        ref.read(gameControllerProvider.notifier).upgradeTrainingGround();
    final message = switch (result) {
      TrainingGroundUpgradeResult.success => 'Training Ground upgraded.',
      TrainingGroundUpgradeResult.reputationTooLow =>
        'Requires ${ground.nextUpgradeReputationRequirement} reputation.',
      TrainingGroundUpgradeResult.maximumLevel =>
        'Training Ground is already at maximum level.',
      TrainingGroundUpgradeResult.noActiveGame =>
        'Training Ground could not be upgraded.',
    };
    _message(context, message);
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OfficeMetrics extends StatelessWidget {
  const _OfficeMetrics({
    required this.clientCount,
    required this.office,
    required this.scoutCount,
  });

  final int clientCount;
  final AgencyOffice office;
  final int scoutCount;

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        color: AppColors.navy,
        child: Row(
          children: [
            _Metric(
                label: 'CLIENTS',
                value: '$clientCount/${office.clientCapacity}'),
            _Metric(
                label: 'SCOUTS', value: '$scoutCount/${office.scoutCapacity}'),
            _Metric(
              label: 'SALARY CUT',
              value: '${(office.salaryCommissionRate * 100).round()}%',
            ),
            _Metric(
              label: 'AGENT FEE',
              value: '${(office.agentFeeRate * 100).round()}%',
            ),
          ],
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppColors.slate)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 6.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      );
}

class _UpgradeStrip extends StatelessWidget {
  const _UpgradeStrip({
    required this.office,
    required this.reputation,
    required this.onUpgrade,
  });

  final AgencyOffice office;
  final int reputation;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (!office.canUpgrade) {
      return const CompactInfoRow(
        label: 'Office progression',
        value: 'MAXIMUM LEVEL',
        valueColor: AppColors.teal,
        height: 38,
      );
    }
    final unlocked = reputation >= office.nextUpgradeReputationRequirement;
    final next = office.upgrade();
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: AppColors.panelAlt,
        border: Border(bottom: BorderSide(color: AppColors.slate)),
      ),
      padding: const EdgeInsets.only(left: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEVEL ${next.level} · ${next.clientCapacity} CLIENTS · ${next.scoutCapacity} SCOUTS',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.paper,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${GameFormatters.compactCurrency(office.nextUpgradeMoneyCost)} · requires ${office.nextUpgradeReputationRequirement} REP · costs ${office.nextUpgradeReputationCost} REP',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7.5,
                    color: unlocked ? AppColors.muted : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 82,
            height: double.infinity,
            child: Material(
              color: unlocked
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : AppColors.slate.withValues(alpha: 0.35),
              child: InkWell(
                key: const Key('upgradeOfficeButton'),
                onTap: unlocked ? onUpgrade : null,
                child: Center(
                  child: Text(
                    unlocked ? 'UPGRADE' : 'LOCKED',
                    style: TextStyle(
                      color: unlocked ? AppColors.teal : AppColors.muted,
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
}

class _TrainingGroundStrip extends StatelessWidget {
  const _TrainingGroundStrip({
    required this.ground,
    required this.reputation,
    required this.onUpgrade,
  });

  final TrainingGround ground;
  final int reputation;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final unlocked = ground.canUpgrade &&
        reputation >= ground.nextUpgradeReputationRequirement;
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 11),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        border: Border(bottom: BorderSide(color: AppColors.slate)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INTERNAL INTAKE · OVR ${ground.minimumAbility}-${ground.maximumAbility} · EVERY ${ground.intakeIntervalWeeks}W',
                  style: const TextStyle(
                    color: AppColors.paper,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ground.canUpgrade
                      ? '${GameFormatters.compactCurrency(ground.nextUpgradeMoneyCost)} · requires ${ground.nextUpgradeReputationRequirement} REP · costs ${ground.nextUpgradeReputationCost} REP'
                      : 'Maximum facility level',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ground.canUpgrade && !unlocked
                        ? AppColors.danger
                        : AppColors.muted,
                    fontSize: 7.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 82,
            height: double.infinity,
            child: Material(
              color: unlocked
                  ? AppColors.amber.withValues(alpha: 0.14)
                  : AppColors.slate.withValues(alpha: 0.28),
              child: InkWell(
                key: const Key('upgradeTrainingGroundButton'),
                onTap: unlocked ? onUpgrade : null,
                child: Center(
                  child: Text(
                    !ground.canUpgrade
                        ? 'MAX'
                        : unlocked
                            ? 'UPGRADE'
                            : 'LOCKED',
                    style: TextStyle(
                      color: unlocked ? AppColors.amber : AppColors.muted,
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
                        fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    candidate
                        ? currentReputation < scout.requiredReputation
                            ? 'Requires ${scout.requiredReputation} REP'
                            : 'Sign ${GameFormatters.compactCurrency(scout.signingCost)}'
                        : 'External talent discovery',
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
                      '${candidate ? 'hire' : 'dismiss'}ScoutButton-${scout.id}'),
                  onTap: onAction,
                  child: Center(
                    child: Text(
                      actionLabel,
                      style: TextStyle(
                        color: onAction == null ? AppColors.muted : actionColor,
                        fontSize: 7,
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
        child: Center(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.muted, fontSize: 9),
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
  return 'HIRE';
}

Color _candidateColor({
  required Scout scout,
  required int reputation,
  required bool isFull,
}) {
  if (isFull || reputation < scout.requiredReputation) return AppColors.muted;
  return AppColors.teal;
}
