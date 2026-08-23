import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../domain/services/season_calendar.dart';
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
            week: game.currentWeek,
            year: game.currentYear,
            money: game.agent.money,
            weeklyBalance: game.currentWeekAgencyBalance,
            reputation: game.agent.reputation,
            transferWindow:
                const SeasonCalendar().transferWindowForWeek(game.currentWeek),
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
    final summary =
        ref.read(gameControllerProvider.notifier).simulateNextWeek();
    if (!mounted) return;
    setState(() => _isSimulating = false);
    final eventId = summary?.newAgencyEventId;
    if (eventId != null) {
      await context.push(AppRoutes.eventDetails(eventId));
    }
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
    required this.week,
    required this.year,
    required this.money,
    required this.weeklyBalance,
    required this.reputation,
    required this.transferWindow,
    required this.isSimulating,
    required this.onNextWeek,
  });

  final int week;
  final int year;
  final double money;
  final double weeklyBalance;
  final int reputation;
  final TransferWindowStatus? transferWindow;
  final bool isSimulating;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    final transferLabel = transferWindow == null
        ? 'No'
        : '${transferWindow!.elapsedWeeks}/${transferWindow!.totalWeeks}';
    return Container(
      height: 56,
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusLine(
                  label: 'Money',
                  value:
                      '${GameFormatters.compactCurrency(money)} / ${_signedCurrency(weeklyBalance)}',
                  valueColor:
                      weeklyBalance < 0 ? AppColors.danger : AppColors.teal,
                ),
                _StatusLine(
                  label: 'Week',
                  value: '$week/$year  ·  REP ${_compactCount(reputation)}',
                ),
                _StatusLine(
                  label: 'Transfer Season',
                  value: transferLabel,
                  valueColor: transferWindow == null
                      ? AppColors.muted
                      : AppColors.amber,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 124,
            height: 38,
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
                              fontSize: 9.5,
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
                              fontSize: 10.5,
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
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.label,
    required this.value,
    this.valueColor = AppColors.paper,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Text.rich(
        key: Key('simulationStatus-$label'),
        TextSpan(
          text: '$label: ',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
                fontSize: 10,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}

String _signedCurrency(double value) =>
    '${value > 0 ? '+' : ''}${GameFormatters.compactCurrency(value)}';

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return '$value';
}
