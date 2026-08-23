import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../application/persistence_providers.dart';
import '../../../core/widgets/agency_mark.dart';
import '../../../core/widgets/football_backdrop.dart';
import '../../../domain/models/saved_career_summary.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  bool _isLoadingCareer = false;

  Future<void> _continueCareer() async {
    setState(() => _isLoadingCareer = true);
    final result =
        await ref.read(gameControllerProvider.notifier).loadLatestGame();
    if (!mounted) return;
    setState(() => _isLoadingCareer = false);
    if (result == LoadGameResult.success) {
      context.go(AppRoutes.game);
      return;
    }
    final message = switch (result) {
      LoadGameResult.noSave => 'No saved career was found.',
      LoadGameResult.invalidSave =>
        'This saved career is damaged or from an incompatible version.',
      LoadGameResult.failed => 'The saved career could not be loaded.',
      LoadGameResult.success => '',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final savedCareer = ref.watch(savedCareerSummaryProvider);
    final summary = savedCareer.asData?.value;

    return Scaffold(
      body: FootballBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AgencyMark(size: 60),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'BUILD THE\nCAREERS.',
                      style: textTheme.displayLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scout talent. Shape deals. Grow your agency from the touchline.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 42),
                    ElevatedButton.icon(
                      key: const Key('newGameButton'),
                      onPressed: () => context.go(AppRoutes.newGame),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New game'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('continueGameButton'),
                      onPressed: summary == null || _isLoadingCareer
                          ? null
                          : _continueCareer,
                      icon: _isLoadingCareer
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _isLoadingCareer ? 'Loading career…' : 'Continue game',
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SaveSummaryLine(
                      summary: summary,
                      isLoading: savedCareer.isLoading,
                      hasError: savedCareer.hasError,
                      onRetry: () => ref.invalidate(savedCareerSummaryProvider),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '50 WEEKS · ONE SEASON',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveSummaryLine extends StatelessWidget {
  const _SaveSummaryLine({
    required this.summary,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  final SavedCareerSummary? summary;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final career = summary;
    if (isLoading) {
      return const Text(
        'Checking local save…',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 10),
      );
    }
    if (hasError) {
      return TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 15),
        label: const Text('Retry save check'),
      );
    }
    if (career == null) {
      return const Text(
        'No career saved on this device.',
        key: Key('noSavedCareerLabel'),
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, fontSize: 10),
      );
    }
    return Container(
      key: const Key('savedCareerSummary'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.slate),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.save_rounded, size: 16, color: AppColors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${career.agencyName} · ${career.agentName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${career.seasonLabel} · W${career.currentWeek}',
            style: const TextStyle(
              color: AppColors.amber,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
