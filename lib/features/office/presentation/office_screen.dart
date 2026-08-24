import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../domain/models/agency_office.dart';
import '../../../domain/models/training_ground.dart';

class FacilitiesScreen extends ConsumerWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();
    return ListView(
      key: const Key('agencyFacilitiesScreen'),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        CompactSectionBar(
          title: 'Office Level ${game.office.level}',
          trailing:
              '${game.representedPlayers.length}/${game.office.clientCapacity} CLIENTS',
          accent: AppColors.teal,
        ),
        _FacilityArtwork(
          key: const Key('officeFacilityArtwork'),
          assetPath: 'assets/images/facilities/office.png',
          semanticLabel: 'Top Agent agency headquarters',
          caption: 'AGENCY HEADQUARTERS',
          level: game.office.level,
          accent: AppColors.teal,
        ),
        _MetricRow(
          metrics: [
            (
              'CLIENTS',
              '${game.representedPlayers.length}/${game.office.clientCapacity}'
            ),
            ('STAFF CAP', '${game.office.scoutCapacity}'),
            (
              'SALARY CUT',
              '${(game.office.salaryCommissionRate * 100).round()}%'
            ),
            ('AGENT FEE', '${(game.office.agentFeeRate * 100).round()}%'),
          ],
          accent: AppColors.teal,
        ),
        _OfficeUpgradeRow(
          office: game.office,
          reputation: game.agent.reputation,
          onUpgrade: () => _confirmOfficeUpgrade(context, ref, game.office),
        ),
        const SizedBox(height: 10),
        CompactSectionBar(
          title: 'Training Ground Level ${game.trainingGround.level}',
          trailing:
              'NEXT INTAKE ${game.trainingGround.weeksUntilIntake(game.currentAbsoluteWeek)}W',
          accent: AppColors.amber,
        ),
        _FacilityArtwork(
          key: const Key('trainingGroundFacilityArtwork'),
          assetPath: 'assets/images/facilities/training_ground.png',
          semanticLabel: 'Top Agent youth training ground',
          caption: 'YOUTH DEVELOPMENT BASE',
          level: game.trainingGround.level,
          accent: AppColors.amber,
        ),
        _MetricRow(
          metrics: [
            ('MIN OVR', '${game.trainingGround.minimumAbility}'),
            ('MAX OVR', '${game.trainingGround.maximumAbility}'),
            ('INTAKE', '${game.trainingGround.intakeIntervalWeeks}W'),
            ('SOURCE', 'INTERNAL'),
          ],
          accent: AppColors.amber,
        ),
        _GroundUpgradeRow(
          ground: game.trainingGround,
          reputation: game.agent.reputation,
          onUpgrade: () => _confirmGroundUpgrade(
            context,
            ref,
            game.trainingGround,
          ),
        ),
        const CompactInfoRow(
          label: 'Talent policy',
          value: 'AGES 16-19 · POOL EXPIRES AFTER 21',
          valueColor: AppColors.muted,
          height: 38,
        ),
      ],
    );
  }

  Future<void> _confirmOfficeUpgrade(
    BuildContext context,
    WidgetRef ref,
    AgencyOffice office,
  ) async {
    if (!office.canUpgrade) return;
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
    _message(
      context,
      switch (result) {
        OfficeUpgradeResult.success => 'Office upgraded.',
        OfficeUpgradeResult.reputationTooLow =>
          'Requires ${office.nextUpgradeReputationRequirement} reputation.',
        OfficeUpgradeResult.maximumLevel =>
          'Office is already at maximum level.',
        OfficeUpgradeResult.noActiveGame => 'Office could not be upgraded.',
      },
    );
  }

  Future<void> _confirmGroundUpgrade(
    BuildContext context,
    WidgetRef ref,
    TrainingGround ground,
  ) async {
    if (!ground.canUpgrade) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Upgrade Training Ground to Level ${ground.level + 1}?'),
        content: Text(
          '${GameFormatters.compactCurrency(ground.nextUpgradeMoneyCost)} and ${ground.nextUpgradeReputationCost} reputation will be deducted. This improves internal prospect quality.',
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
    _message(
      context,
      switch (result) {
        TrainingGroundUpgradeResult.success => 'Training Ground upgraded.',
        TrainingGroundUpgradeResult.reputationTooLow =>
          'Requires ${ground.nextUpgradeReputationRequirement} reputation.',
        TrainingGroundUpgradeResult.maximumLevel =>
          'Training Ground is already at maximum level.',
        TrainingGroundUpgradeResult.noActiveGame =>
          'Training Ground could not be upgraded.',
      },
    );
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FacilityArtwork extends StatelessWidget {
  const _FacilityArtwork({
    required this.assetPath,
    required this.semanticLabel,
    required this.caption,
    required this.level,
    required this.accent,
    super.key,
  });

  final String assetPath;
  final String semanticLabel;
  final String caption;
  final int level;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 174,
      margin: const EdgeInsets.fromLTRB(10, 8, 10, 9),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.panel, AppColors.navy],
        ),
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            left: 8,
            right: 8,
            top: 7,
            bottom: 13,
            child: Semantics(
              image: true,
              label: semanticLabel,
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                cacheWidth: 1200,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.midnight.withValues(alpha: 0.88),
                border: Border.all(color: accent.withValues(alpha: 0.7)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'LEVEL $level',
                  style: TextStyle(
                    color: accent,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 27,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.midnight.withValues(alpha: 0.88),
                border: Border(top: BorderSide(color: accent, width: 1.5)),
              ),
              child: Text(
                caption,
                style: TextStyle(
                  color: accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.75,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metrics, required this.accent});

  final List<(String, String)> metrics;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        color: AppColors.navy,
        child: Row(
          children: [
            for (final metric in metrics)
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.slate)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.$1,
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        metric.$2,
                        maxLines: 1,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}

class _OfficeUpgradeRow extends StatelessWidget {
  const _OfficeUpgradeRow({
    required this.office,
    required this.reputation,
    required this.onUpgrade,
  });

  final AgencyOffice office;
  final int reputation;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (!office.canUpgrade) {
      return const CompactInfoRow(
        label: 'Office progression',
        value: 'MAXIMUM LEVEL',
        valueColor: AppColors.teal,
        height: 42,
      );
    }
    final next = office.upgrade();
    return _FacilityUpgradeRow(
      key: const Key('upgradeOfficeButton'),
      accent: AppColors.teal,
      title:
          'LEVEL ${next.level} · ${next.clientCapacity} CLIENTS · ${next.scoutCapacity} STAFF',
      detail:
          '${GameFormatters.compactCurrency(office.nextUpgradeMoneyCost)} · ${office.nextUpgradeReputationRequirement} REP REQUIRED · -${office.nextUpgradeReputationCost} REP',
      enabled: reputation >= office.nextUpgradeReputationRequirement,
      onTap: onUpgrade,
    );
  }
}

class _GroundUpgradeRow extends StatelessWidget {
  const _GroundUpgradeRow({
    required this.ground,
    required this.reputation,
    required this.onUpgrade,
  });

  final TrainingGround ground;
  final int reputation;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (!ground.canUpgrade) {
      return const CompactInfoRow(
        label: 'Training Ground progression',
        value: 'MAXIMUM LEVEL',
        valueColor: AppColors.amber,
        height: 42,
      );
    }
    final next = ground.upgrade();
    return _FacilityUpgradeRow(
      key: const Key('upgradeTrainingGroundButton'),
      accent: AppColors.amber,
      title:
          'LEVEL ${next.level} · OVR ${next.minimumAbility}-${next.maximumAbility} · ${next.intakeIntervalWeeks}W',
      detail:
          '${GameFormatters.compactCurrency(ground.nextUpgradeMoneyCost)} · ${ground.nextUpgradeReputationRequirement} REP REQUIRED · -${ground.nextUpgradeReputationCost} REP',
      enabled: reputation >= ground.nextUpgradeReputationRequirement,
      onTap: onUpgrade,
    );
  }
}

class _FacilityUpgradeRow extends StatelessWidget {
  const _FacilityUpgradeRow({
    required this.accent,
    required this.title,
    required this.detail,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final Color accent;
  final String title;
  final String detail;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        padding: const EdgeInsets.only(left: 11),
        decoration: const BoxDecoration(
          color: AppColors.panelAlt,
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
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8,
                      color: enabled ? AppColors.muted : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 82,
              height: double.infinity,
              child: Material(
                color: enabled
                    ? accent.withValues(alpha: 0.15)
                    : AppColors.slate.withValues(alpha: 0.35),
                child: InkWell(
                  onTap: enabled ? onTap : null,
                  child: Center(
                    child: Text(
                      enabled ? 'UPGRADE' : 'LOCKED',
                      style: TextStyle(
                        color: enabled ? accent : AppColors.muted,
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
