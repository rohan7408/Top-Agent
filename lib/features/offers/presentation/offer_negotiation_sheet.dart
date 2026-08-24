import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../core/widgets/compact_data_table.dart';
import '../../../domain/models/club_offer.dart';

Future<void> showPlayerOffersSheet(
  BuildContext context, {
  required String playerId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.midnight,
    builder: (context) => _PlayerOffersSheet(playerId: playerId),
  );
}

Future<void> showOfferNegotiationSheet(
  BuildContext context, {
  required String offerId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.midnight,
    builder: (context) => _OfferNegotiationSheet(offerId: offerId),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 38,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.muted.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _PlayerOffersSheet extends ConsumerWidget {
  const _PlayerOffersSheet({required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) return const SizedBox.shrink();
    final player =
        game.players.where((item) => item.id == playerId).firstOrNull;
    if (player == null) return const SizedBox.shrink();
    final offers = game.pendingOffersForPlayer(playerId);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 10),
            Text(
              player.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${offers.length} ACTIVE CLUB ${offers.length == 1 ? 'OFFER' : 'OFFERS'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.amber,
                    fontSize: 8,
                  ),
            ),
            const SizedBox(height: 10),
            if (offers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'No active offers remain.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    final club = game.clubById(offer.clubId)!;
                    return Material(
                      color: index.isOdd ? AppColors.panelAlt : AppColors.navy,
                      child: InkWell(
                        key: Key('reviewOfferButton-${offer.id}'),
                        onTap: () => _reviewOffer(context, offer.id),
                        child: Container(
                          height: 58,
                          padding: const EdgeInsets.only(left: 10, right: 6),
                          decoration: const BoxDecoration(
                            border: Border(
                              left:
                                  BorderSide(color: AppColors.amber, width: 2),
                              bottom: BorderSide(color: AppColors.divider),
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
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _offerSummary(offer),
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
                              const Text(
                                'REVIEW',
                                style: TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reviewOffer(BuildContext context, String offerId) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!navigator.mounted) return;
    await showOfferNegotiationSheet(
      navigator.context,
      offerId: offerId,
    );
  }
}

class _OfferNegotiationSheet extends ConsumerStatefulWidget {
  const _OfferNegotiationSheet({required this.offerId});

  final String offerId;

  @override
  ConsumerState<_OfferNegotiationSheet> createState() =>
      _OfferNegotiationSheetState();
}

class _OfferNegotiationSheetState
    extends ConsumerState<_OfferNegotiationSheet> {
  double? _weeklySalary;
  double? _agentFee;
  int? _contractLength;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final offer = game?.offerById(widget.offerId);
    if (game == null || offer == null) return const SizedBox.shrink();
    if (!_initialized) {
      _weeklySalary = offer.weeklySalary;
      _agentFee = offer.agentFee;
      _contractLength = offer.contractLength;
      _initialized = true;
    }
    final player = game.players.firstWhere((item) => item.id == offer.playerId);
    final club = game.clubById(offer.clubId)!;
    final remainingAttempts = 3 - offer.negotiationRounds;
    final salaryOptions = _moneyOptions(offer.weeklySalary);
    final feeOptions = _moneyOptions(offer.agentFee);
    final lengthOptions = _contractOptions(offer.contractLength);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 10),
              Text(
                '${club.name} → ${player.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                'ORIGINAL · ${_offerSummary(offer)}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (offer.isMarketMove) ...[
                const SizedBox(height: 4),
                const Text(
                  'DECIDE THIS WEEK · OFFER EXPIRES WHEN THE WEEK ADVANCES',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const CompactSectionBar(
                title: 'Counter proposal',
                trailing: 'CLUB CAN ACCEPT OR REJECT',
                accent: AppColors.amber,
              ),
              const SizedBox(height: 10),
              _TermOptionStrip<double>(
                key: const Key('negotiationSalaryOptions'),
                label: 'Weekly salary',
                options: salaryOptions,
                selected: _weeklySalary!,
                valueLabel: GameFormatters.compactCurrency,
                onSelected: (value) => setState(() => _weeklySalary = value),
              ),
              const SizedBox(height: 8),
              _TermOptionStrip<double>(
                key: const Key('negotiationFeeOptions'),
                label: 'Agency fee',
                options: feeOptions,
                selected: _agentFee!,
                valueLabel: GameFormatters.compactCurrency,
                onSelected: (value) => setState(() => _agentFee = value),
              ),
              const SizedBox(height: 8),
              _TermOptionStrip<int>(
                key: const Key('negotiationLengthOptions'),
                label: 'Contract length',
                options: lengthOptions,
                selected: _contractLength!,
                valueLabel: (years) =>
                    '$years ${years == 1 ? 'year' : 'years'}',
                onSelected: (value) => setState(() => _contractLength = value),
              ),
              const SizedBox(height: 6),
              Text(
                '$remainingAttempts ${remainingAttempts == 1 ? 'counter' : 'counters'} remaining before the club withdraws.',
                style: const TextStyle(color: AppColors.muted, fontSize: 8),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: Key('declineOfferButton-${offer.id}'),
                      onPressed: () => _decline(offer.id),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      key: Key('acceptOfferButton-${offer.id}'),
                      onPressed: () => _acceptOriginal(offer.id, club.name),
                      child: const Text('Accept original'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: Key('submitCounterOfferButton-${offer.id}'),
                onPressed: () => _submitCounter(offer.id, club.name),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: const Text('Send counter proposal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _decline(String offerId) {
    ref.read(gameControllerProvider.notifier).declineOffer(offerId);
    _showOfferToast(
      context,
      message: 'Offer declined.',
      tone: _OfferToastTone.rejected,
    );
    Navigator.of(context).pop();
  }

  void _acceptOriginal(String offerId, String clubName) {
    final result =
        ref.read(gameControllerProvider.notifier).acceptOffer(offerId);
    if (result != DealActionResult.success) {
      _showOfferToast(
        context,
        message: 'This offer expired or the transfer is not eligible.',
        tone: _OfferToastTone.error,
      );
      return;
    }
    _showOfferToast(
      context,
      message: '$clubName deal completed.',
      tone: _OfferToastTone.accepted,
    );
    Navigator.of(context).pop();
  }

  void _submitCounter(String offerId, String clubName) {
    if (_weeklySalary == null || _agentFee == null || _contractLength == null) {
      return;
    }
    final result = ref.read(gameControllerProvider.notifier).negotiateOffer(
          offerId: offerId,
          weeklySalary: _weeklySalary!,
          agentFee: _agentFee!,
          contractLength: _contractLength!,
        );
    final message = switch (result.status) {
      OfferNegotiationActionStatus.accepted =>
        '$clubName accepted the counter proposal. Deal completed.',
      OfferNegotiationActionStatus.rejected =>
        '$clubName rejected these terms. Revise the proposal or accept the original offer.',
      OfferNegotiationActionStatus.withdrawn =>
        '$clubName rejected the third counter and withdrew its offer.',
      OfferNegotiationActionStatus.invalid ||
      OfferNegotiationActionStatus.noActiveGame =>
        'The counter proposal could not be sent.',
    };
    if (result.status == OfferNegotiationActionStatus.accepted ||
        result.status == OfferNegotiationActionStatus.withdrawn) {
      _showOfferToast(
        context,
        message: message,
        tone: result.status == OfferNegotiationActionStatus.accepted
            ? _OfferToastTone.accepted
            : _OfferToastTone.error,
      );
      Navigator.of(context).pop();
      return;
    }
    _showOfferToast(
      context,
      message: message,
      tone: result.status == OfferNegotiationActionStatus.rejected
          ? _OfferToastTone.rejected
          : _OfferToastTone.error,
    );
  }

  List<double> _moneyOptions(double offered) {
    final step = switch (offered) {
      < 10000 => 1000.0,
      < 50000 => 5000.0,
      < 250000 => 10000.0,
      < 1000000 => 50000.0,
      _ => 100000.0,
    };
    final nextStep = ((offered ~/ step) + 1) * step;
    return [offered, nextStep, nextStep + step];
  }

  List<int> _contractOptions(int offered) {
    final options = <int>[offered];
    for (var difference = 1; options.length < 3; difference++) {
      final higher = offered + difference;
      if (higher <= 5) options.add(higher);
      if (options.length == 3) break;
      final lower = offered - difference;
      if (lower >= 1) options.add(lower);
    }
    return options;
  }
}

enum _OfferToastTone { accepted, rejected, error }

void _showOfferToast(
  BuildContext context, {
  required String message,
  required _OfferToastTone tone,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  final color = switch (tone) {
    _OfferToastTone.accepted => AppColors.teal,
    _OfferToastTone.rejected => AppColors.amber,
    _OfferToastTone.error => AppColors.danger,
  };
  final icon = switch (tone) {
    _OfferToastTone.accepted => Icons.check_circle_outline_rounded,
    _OfferToastTone.rejected => Icons.cancel_outlined,
    _OfferToastTone.error => Icons.error_outline_rounded,
  };
  entry = OverlayEntry(
    builder: (overlayContext) => Positioned(
      left: 14,
      right: 14,
      bottom: MediaQuery.paddingOf(overlayContext).bottom + 18,
      child: IgnorePointer(
        child: Material(
          key: const Key('offerFeedbackToast'),
          color: AppColors.panel,
          elevation: 12,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.paper,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  unawaited(
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (entry.mounted) entry.remove();
    }),
  );
}

String _offerSummary(ClubOffer offer) {
  final move = switch (offer.type) {
    ClubOfferType.freeAgent => 'FREE AGENT',
    ClubOfferType.transfer =>
      'TRANSFER ${GameFormatters.compactCurrency(offer.transferFee)}',
    ClubOfferType.loan =>
      'LOAN FEE ${GameFormatters.compactCurrency(offer.transferFee)}',
  };
  return '$move · ${GameFormatters.compactCurrency(offer.weeklySalary)}/wk · ${offer.contractLength}y · Agency fee ${GameFormatters.compactCurrency(offer.agentFee)}';
}

class _TermOptionStrip<T extends num> extends StatelessWidget {
  const _TermOptionStrip({
    required this.label,
    required this.options,
    required this.selected,
    required this.valueLabel,
    required this.onSelected,
    super.key,
  });

  final String label;
  final List<T> options;
  final T selected;
  final String Function(T value) valueLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 5),
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 8,
                    letterSpacing: 0.7,
                  ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (context, index) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == selected;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label:
                      '$label ${valueLabel(option)}${index == 0 ? ', club offer' : ''}',
                  child: Material(
                    color: isSelected
                        ? AppColors.teal.withValues(alpha: 0.20)
                        : AppColors.navy,
                    child: InkWell(
                      key: Key('${key.toString()}-option-$index'),
                      onTap: () => onSelected(option),
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        width: 112,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                isSelected ? AppColors.teal : AppColors.slate,
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    valueLabel(option),
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.paper
                                          : AppColors.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    index == 0 ? 'CLUB OFFER' : 'COUNTER',
                                    style: TextStyle(
                                      color: index == 0
                                          ? AppColors.amber
                                          : AppColors.muted,
                                      fontSize: 6.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                color: AppColors.teal,
                                size: 15,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
}
