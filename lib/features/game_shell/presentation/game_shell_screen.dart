import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../email/presentation/email_screen.dart';
import '../../finance/presentation/finance_screen.dart';
import '../../my_players/presentation/my_players_screen.dart';
import '../../more/presentation/more_screen.dart';
import '../../talents/presentation/talents_screen.dart';

class GameShellScreen extends ConsumerStatefulWidget {
  const GameShellScreen({super.key});

  @override
  ConsumerState<GameShellScreen> createState() => _GameShellScreenState();
}

class _GameShellScreenState extends ConsumerState<GameShellScreen> {
  static const _pages = [
    MyPlayersScreen(),
    TalentsScreen(),
    EmailScreen(),
    FinanceScreen(),
    MoreScreen(),
  ];

  static const _titles = [
    'My Players',
    'Talents',
    'Email',
    'Finance',
    'More',
  ];

  int _selectedIndex = 0;
  bool _isSimulating = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) {
      return const Scaffold(body: Center(child: Text('No active career.')));
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        titleSpacing: 14,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.midnight, AppColors.navy],
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_selectedIndex],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              game.agent.agencyName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.teal,
                    fontSize: 7,
                    letterSpacing: 1,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('clubsButton'),
            tooltip: 'Browse clubs',
            onPressed: () => context.push(AppRoutes.clubs),
            icon: const Icon(Icons.stadium_outlined, size: 21),
          ),
          IconButton(
            key: const Key('saveAndExitButton'),
            tooltip: 'Save and return to main menu',
            onPressed: () => _saveAndExit(context),
            icon: const Icon(Icons.logout_rounded, size: 20),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SimulationBar(
            season: game.seasonLabel(game.currentSeason),
            week: game.currentWeek,
            money: game.agent.money,
            reputation: game.agent.reputation,
            isSimulating: _isSimulating,
            onNextWeek: _simulateOneWeek,
          ),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.groups_2_outlined),
                selectedIcon: Icon(Icons.groups_2_rounded),
                label: 'Players',
              ),
              NavigationDestination(
                icon: Icon(Icons.travel_explore_outlined),
                selectedIcon: Icon(Icons.travel_explore_rounded),
                label: 'Talents',
              ),
              NavigationDestination(
                icon: Icon(Icons.mail_outline_rounded),
                selectedIcon: Icon(Icons.mail_rounded),
                label: 'Email',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Finance',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'More',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _simulateOneWeek() async {
    if (_isSimulating) return;
    HapticFeedback.selectionClick();
    setState(() => _isSimulating = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    ref.read(gameControllerProvider.notifier).simulateNextWeek();
    if (mounted) setState(() => _isSimulating = false);
  }

  Future<void> _saveAndExit(BuildContext context) async {
    final controller = ref.read(gameControllerProvider.notifier);
    final saved = await controller.saveNow();
    if (!context.mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Career could not be saved. Stay in the game and retry.'),
        ),
      );
      return;
    }
    controller.clearGame();
    context.go(AppRoutes.mainMenu);
  }
}

class _SimulationBar extends StatelessWidget {
  const _SimulationBar({
    required this.season,
    required this.week,
    required this.money,
    required this.reputation,
    required this.isSimulating,
    required this.onNextWeek,
  });

  final String season;
  final int week;
  final double money;
  final int reputation;
  final bool isSimulating;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        padding: const EdgeInsets.fromLTRB(11, 5, 7, 5),
        decoration: const BoxDecoration(
          color: AppColors.panelAlt,
          border: Border(
            top: BorderSide(color: AppColors.slate),
            bottom: BorderSide(color: AppColors.slate),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 104,
              child: Text(
                '$season  ·  W$week',
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.paper,
                      fontSize: 8,
                      letterSpacing: 0.35,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                '${GameFormatters.compactCurrency(money)}  ·  REP ${_compactCount(reputation)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 112,
              height: 34,
              child: FilledButton(
                key: const Key('nextWeekButton'),
                onPressed: isSimulating ? null : onNextWeek,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: isSimulating
                      ? const Row(
                          key: ValueKey('simulating'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'SIMULATING',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          key: ValueKey('nextWeek'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'NEXT WEEK',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_rounded, size: 15),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      );
}

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return '$value';
}
