import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_page_chrome.dart';
import '../../../core/widgets/section_placeholder.dart';
import '../../../domain/models/agency_event.dart';
import '../../../domain/models/game_state.dart';

class AgencyEventScreen extends ConsumerStatefulWidget {
  const AgencyEventScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<AgencyEventScreen> createState() => _AgencyEventScreenState();
}

class _AgencyEventScreenState extends ConsumerState<AgencyEventScreen> {
  bool _isResolving = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final event = game?.agencyEventById(widget.eventId);
    if (game == null || event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const CompactPageTitle(title: 'Agency event'),
        ),
        body: const SectionPlaceholder(
          icon: Icons.event_busy_outlined,
          title: 'Event unavailable',
          message: 'This event is no longer available in the current career.',
        ),
      );
    }
    final pending = event.status == AgencyEventStatus.pending;
    final accent = _categoryColor(event.category);
    final outcomeAccent = _outcomeColor(event.outcome);
    return PopScope<void>(
      canPop: !pending,
      child: Scaffold(
        key: const Key('agencyEventPage'),
        appBar: AppBar(
          toolbarHeight: 50,
          automaticallyImplyLeading: !pending,
          title: CompactPageTitle(
            title: 'Agency event',
            eyebrow: _categoryLabel(event.category),
            accent: accent,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  key: const Key('agencyEventPageList'),
                  padding: EdgeInsets.zero,
                  children: [
                    _EventMasthead(event: event, game: game, accent: accent),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                      child: Text(
                        event.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.paper,
                              height: 1.4,
                            ),
                      ),
                    ),
                    if (_subjectLines(game, event).isNotEmpty)
                      _SubjectStrip(lines: _subjectLines(game, event)),
                    if (pending) ...[
                      _SectionLabel(
                        label: 'Your decision',
                        trailing: '${event.choices.length} OPTIONS · AUTOSAVE',
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
                        child: Column(
                          children: [
                            for (final choice in event.choices)
                              _ChoiceRow(
                                choice: choice,
                                enabled: !_isResolving,
                                onTap: () => _resolve(choice.id),
                              ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _SectionLabel(
                        label: 'Outcome',
                        accent: outcomeAccent,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 7, 10, 12),
                        child: _ResolutionPanel(event: event),
                      ),
                    ],
                  ],
                ),
              ),
              if (!pending)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.panelAlt,
                    border: Border(top: BorderSide(color: AppColors.slate)),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
                  child: OutlinedButton.icon(
                    key: const Key('agencyEventReturnButton'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.paper,
                      side: const BorderSide(color: AppColors.slate),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 17),
                    label: const Text('RETURN TO AGENCY'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _resolve(String choiceId) {
    if (_isResolving) return;
    setState(() => _isResolving = true);
    final result = ref
        .read(gameControllerProvider.notifier)
        .resolveAgencyEvent(widget.eventId, choiceId);
    if (!mounted) return;
    setState(() => _isResolving = false);
    if (result.status != AgencyEventActionStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This decision could not be recorded.')),
      );
    }
  }
}

class _EventMasthead extends StatelessWidget {
  const _EventMasthead({
    required this.event,
    required this.game,
    required this.accent,
  });

  final AgencyEvent event;
  final GameState game;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.panelAlt,
          border: Border(
            left: BorderSide(color: accent, width: 4),
            bottom: const BorderSide(color: AppColors.slate),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                border: Border.all(color: accent.withValues(alpha: 0.65)),
                borderRadius: BorderRadius.circular(7),
              ),
              child:
                  Icon(_categoryIcon(event.category), color: accent, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${game.seasonLabel(event.season)} · Week ${event.week} · ${event.status.name.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 9,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SubjectStrip extends StatelessWidget {
  const _SubjectStrip({required this.lines});

  final List<(String, String)> lines;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.navy,
          border: Border.all(color: AppColors.slate),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          children: [
            for (var index = 0; index < lines.length; index++)
              Container(
                height: 31,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  border: index == lines.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(color: AppColors.slate),
                        ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 57,
                      child: Text(
                        lines[index].$1.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.muted,
                              fontSize: 8,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        lines[index].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.paper,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    this.trailing,
    this.accent = AppColors.teal,
  });

  final String label;
  final String? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        color: AppColors.midnight,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accent,
                      letterSpacing: 1.1,
                    ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  trailing!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 8,
                      ),
                ),
              ),
            ],
          ],
        ),
      );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.choice,
    required this.enabled,
    required this.onTap,
  });

  final AgencyEventChoice choice;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: AppColors.panelAlt,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            key: Key('agencyEventChoice-${choice.id}'),
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              constraints: BoxConstraints(
                minHeight: choice.isUncertain ? 76 : 61,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.slate),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 7, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                choice.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (choice.isUncertain)
                              Text(
                                '${(choice.successChance * 100).round()}% SUCCESS',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.amber,
                                      fontSize: 8,
                                    ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        if (choice.isUncertain) ...[
                          _OutcomePreviewLine(
                            label: 'SUCCESS',
                            value: _successImpact(choice),
                            color: AppColors.teal,
                          ),
                          const SizedBox(height: 2),
                          _OutcomePreviewLine(
                            label: 'FAILURE',
                            value: _failureImpact(choice),
                            color: AppColors.danger,
                          ),
                        ] else
                          Text(
                            _successImpact(choice),
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
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.teal, size: 19),
                ],
              ),
            ),
          ),
        ),
      );
}

class _OutcomePreviewLine extends StatelessWidget {
  const _OutcomePreviewLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 43,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 8,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 8.5,
                  ),
            ),
          ),
        ],
      );
}

class _ResolutionPanel extends StatelessWidget {
  const _ResolutionPanel({required this.event});

  final AgencyEvent event;

  @override
  Widget build(BuildContext context) {
    final outcome = event.outcome;
    final accent = _outcomeColor(outcome);
    final label = switch (outcome) {
      AgencyEventOutcome.succeeded => 'OUTCOME SUCCESSFUL',
      AgencyEventOutcome.failed => 'OUTCOME FAILED',
      AgencyEventOutcome.recorded => 'DECISION RECORDED',
      AgencyEventOutcome.expired => 'EVENT EXPIRED',
      AgencyEventOutcome.pending => 'DECISION PENDING',
    };
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.panelAlt,
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _outcomeIcon(outcome),
                color: accent,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: accent,
                      letterSpacing: 1.1,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            event.outcomeSummary ?? 'Decision completed.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (outcome != AgencyEventOutcome.expired) ...[
            const SizedBox(height: 9),
            Text(
              _resolvedImpact(event),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: outcome == AgencyEventOutcome.failed
                        ? AppColors.danger
                        : AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

List<(String, String)> _subjectLines(GameState game, AgencyEvent event) {
  final lines = <(String, String)>[];
  if (event.playerId != null) {
    final player = game.players
        .where((candidate) => candidate.id == event.playerId)
        .firstOrNull;
    if (player != null) {
      lines.add(('Player', player.name));
      lines.add(('Trust', '${player.agentTrust}'));
    }
  }
  if (event.clubId != null) {
    final club = game.clubById(event.clubId!);
    if (club != null) {
      lines.add(('Club', club.name));
      lines.add((
        'Club relation',
        '${game.clubAgencyRelationshipScore(club.id)}',
      ));
    }
  }
  if (event.scoutId != null) {
    final scout = game.scouts
        .where((candidate) => candidate.id == event.scoutId)
        .firstOrNull;
    if (scout != null) {
      lines.add(('Scout', scout.name));
      lines.add(('Trust', '${scout.agencyTrust}'));
    }
  }
  return lines;
}

String _successImpact(AgencyEventChoice choice) {
  final parts = <String>[];
  if (choice.moneyImpact != 0) parts.add(_signedMoney(choice.moneyImpact));
  if (choice.reputationImpact != 0) {
    parts.add('${_signedNumber(choice.reputationImpact)} REP');
  }
  if (choice.fatigueImpact != 0) {
    parts.add('${_signedNumber(choice.fatigueImpact)} fatigue');
  }
  if (choice.trustImpact != 0) {
    parts.add('${_signedNumber(choice.trustImpact)} trust');
  }
  if (choice.clubRelationshipImpact != 0) {
    parts.add('${_signedNumber(choice.clubRelationshipImpact)} club');
  }
  return parts.isEmpty ? choice.detail : parts.join(' · ');
}

String _failureImpact(AgencyEventChoice choice) {
  final parts = <String>[];
  if (choice.failureMoneyImpact != 0) {
    parts.add(_signedMoney(choice.failureMoneyImpact));
  }
  if (choice.failureReputationImpact != 0) {
    parts.add('${_signedNumber(choice.failureReputationImpact)} REP');
  }
  if (choice.failureFatigueImpact != 0) {
    parts.add('${_signedNumber(choice.failureFatigueImpact)} fatigue');
  }
  if (choice.failureTrustImpact != 0) {
    parts.add('${_signedNumber(choice.failureTrustImpact)} trust');
  }
  if (choice.failureClubRelationshipImpact != 0) {
    parts.add('${_signedNumber(choice.failureClubRelationshipImpact)} club');
  }
  return parts.isEmpty ? 'No reward' : parts.join(' · ');
}

String _resolvedImpact(AgencyEvent event) {
  final parts = <String>[];
  if (event.resolvedMoneyImpact != 0) {
    parts.add(_signedMoney(event.resolvedMoneyImpact));
  }
  if (event.resolvedReputationImpact != 0) {
    parts.add('${_signedNumber(event.resolvedReputationImpact)} REP');
  }
  if (event.resolvedFatigueImpact != 0) {
    parts.add('${_signedNumber(event.resolvedFatigueImpact)} fatigue');
  }
  if (event.resolvedTrustImpact != 0) {
    parts.add('${_signedNumber(event.resolvedTrustImpact)} trust');
  }
  if (event.resolvedClubRelationshipImpact != 0) {
    parts.add('${_signedNumber(event.resolvedClubRelationshipImpact)} club');
  }
  return parts.isEmpty ? 'No balance or reputation change' : parts.join(' · ');
}

String _signedMoney(double value) =>
    '${value > 0 ? '+' : ''}${GameFormatters.compactCurrency(value)}';

String _signedNumber(num value) => '${value > 0 ? '+' : ''}${value.round()}';

String _categoryLabel(AgencyEventCategory category) => switch (category) {
      AgencyEventCategory.commercial => 'Commercial',
      AgencyEventCategory.media => 'Media',
      AgencyEventCategory.discipline => 'Discipline',
      AgencyEventCategory.career => 'Career',
      AgencyEventCategory.welfare => 'Player welfare',
      AgencyEventCategory.agency => 'Agency operations',
      AgencyEventCategory.finance => 'Agency finance',
    };

Color _categoryColor(AgencyEventCategory category) => switch (category) {
      AgencyEventCategory.commercial => AppColors.amber,
      AgencyEventCategory.media => AppColors.ratingBlue,
      AgencyEventCategory.discipline => AppColors.danger,
      AgencyEventCategory.career => AppColors.ratingBlue,
      AgencyEventCategory.welfare => AppColors.teal,
      AgencyEventCategory.agency => AppColors.muted,
      AgencyEventCategory.finance => AppColors.teal,
    };

IconData _categoryIcon(AgencyEventCategory category) => switch (category) {
      AgencyEventCategory.commercial => Icons.handshake_outlined,
      AgencyEventCategory.media => Icons.campaign_outlined,
      AgencyEventCategory.discipline => Icons.gavel_outlined,
      AgencyEventCategory.career => Icons.swap_horiz_rounded,
      AgencyEventCategory.welfare => Icons.favorite_border_rounded,
      AgencyEventCategory.agency => Icons.business_center_outlined,
      AgencyEventCategory.finance => Icons.account_balance_outlined,
    };

Color _outcomeColor(AgencyEventOutcome outcome) => switch (outcome) {
      AgencyEventOutcome.succeeded => AppColors.teal,
      AgencyEventOutcome.failed => AppColors.danger,
      AgencyEventOutcome.recorded => AppColors.ratingBlue,
      AgencyEventOutcome.expired => AppColors.muted,
      AgencyEventOutcome.pending => AppColors.amber,
    };

IconData _outcomeIcon(AgencyEventOutcome outcome) => switch (outcome) {
      AgencyEventOutcome.succeeded => Icons.check_circle_outline_rounded,
      AgencyEventOutcome.failed => Icons.cancel_outlined,
      AgencyEventOutcome.recorded => Icons.task_alt_rounded,
      AgencyEventOutcome.expired => Icons.timer_off_outlined,
      AgencyEventOutcome.pending => Icons.priority_high_rounded,
    };
