import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../application/game_controller.dart';
import '../../../core/formatters/game_formatters.dart';
import '../../../domain/services/season_calendar.dart';
import '../../email/presentation/email_screen.dart';
import '../../more/presentation/more_screen.dart';
import '../../my_players/presentation/my_players_screen.dart';
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
    MoreScreen(),
  ];

  int _selectedIndex = 0;
  bool _isSimulating = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    if (game == null) {
      return const Scaffold(body: Center(child: Text('No active career.')));
    }
    final transferWindow =
        const SeasonCalendar().transferWindowForWeek(game.currentWeek);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _CareerStatusHeader(
                agentName: game.agent.name,
                agencyName: game.agent.agencyName,
                money: game.agent.money,
                weeklyBalance: game.currentWeekAgencyBalance,
                week: game.currentWeek,
                year: game.currentYear,
                reputation: game.agent.reputation,
                transferWindow: transferWindow,
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _AgencyNavigationBar(
          selectedIndex: _selectedIndex,
          isSimulating: _isSimulating,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() => _selectedIndex = index);
          },
          onNextWeek: _simulateOneWeek,
        ),
      ),
    );
  }

  Future<void> _simulateOneWeek() async {
    if (_isSimulating) return;
    HapticFeedback.mediumImpact();
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
}

class _CareerStatusHeader extends StatelessWidget {
  const _CareerStatusHeader({
    required this.agentName,
    required this.agencyName,
    required this.money,
    required this.weeklyBalance,
    required this.week,
    required this.year,
    required this.reputation,
    required this.transferWindow,
  });

  final String agentName;
  final String agencyName;
  final double money;
  final double weeklyBalance;
  final int week;
  final int year;
  final int reputation;
  final TransferWindowStatus? transferWindow;

  @override
  Widget build(BuildContext context) {
    final transferLabel = transferWindow == null
        ? 'No'
        : '${transferWindow!.elapsedWeeks}/${transferWindow!.totalWeeks}';
    return Container(
      key: const Key('careerStatusHeader'),
      height: AppSizes.statusHeader,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.content,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: transferWindow == null
            ? AppColors.navy
            : AppColors.transferWindowPanel,
        border: Border(
          bottom: BorderSide(
            color: transferWindow == null
                ? AppColors.divider
                : AppColors.transferWindowBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
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
                _StatusLine(label: 'Week', value: '$week/$year'),
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
          Container(width: 1, height: 48, color: AppColors.divider),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _IdentityLine(label: 'Agent', value: agentName),
                _IdentityLine(
                  label: 'Agency',
                  value: agencyName.toUpperCase(),
                ),
                _IdentityLine(
                  key: const Key('simulationStatus-Reputation'),
                  label: 'REP',
                  value: _compactCount(reputation),
                  valueColor:
                      reputation < 0 ? AppColors.danger : AppColors.teal,
                ),
              ],
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
  Widget build(BuildContext context) => SizedBox(
        key: Key('simulationStatus-$label'),
        height: 18,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                '$label:',
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                      fontFamily: AppType.bodyFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      );
}

class _IdentityLine extends StatelessWidget {
  const _IdentityLine({
    required this.label,
    required this.value,
    this.valueColor = AppColors.paper,
    super.key,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 18,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$label ',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      );
}

class _AgencyNavigationBar extends StatelessWidget {
  const _AgencyNavigationBar({
    required this.selectedIndex,
    required this.isSimulating,
    required this.onDestinationSelected,
    required this.onNextWeek,
  });

  final int selectedIndex;
  final bool isSimulating;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: SizedBox(
          key: const Key('agencyNavigationBar'),
          height: AppSizes.navigationShell,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: AppSizes.navigationBar,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavigationItem(
                          key: const Key('playersNavigationButton'),
                          label: 'Players',
                          icon: Icons.groups_2_outlined,
                          selectedIcon: Icons.groups_2_rounded,
                          selected: selectedIndex == 0,
                          onTap: () => onDestinationSelected(0),
                        ),
                      ),
                      Expanded(
                        child: _NavigationItem(
                          key: const Key('talentsNavigationButton'),
                          label: 'Talents',
                          icon: Icons.travel_explore_outlined,
                          selectedIcon: Icons.travel_explore_rounded,
                          selected: selectedIndex == 1,
                          onTap: () => onDestinationSelected(1),
                        ),
                      ),
                      const SizedBox(width: 72),
                      Expanded(
                        child: _NavigationItem(
                          key: const Key('emailNavigationButton'),
                          label: 'Email',
                          icon: Icons.mail_outline_rounded,
                          selectedIcon: Icons.mail_rounded,
                          selected: selectedIndex == 2,
                          onTap: () => onDestinationSelected(2),
                        ),
                      ),
                      Expanded(
                        child: _NavigationItem(
                          key: const Key('moreNavigationButton'),
                          label: 'More',
                          icon: Icons.grid_view_outlined,
                          selectedIcon: Icons.grid_view_rounded,
                          selected: selectedIndex == 3,
                          onTap: () => onDestinationSelected(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: _NextWeekButton(
                  isSimulating: isSimulating,
                  onPressed: onNextWeek,
                ),
              ),
            ],
          ),
        ),
      );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '$label tab',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.standard,
                  width: selected ? 24 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.teal : Colors.transparent,
                    borderRadius: AppRadii.small,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.standard,
                  width: 32,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.teal.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: AppRadii.small,
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 19,
                    color: selected ? AppColors.teal : AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.paper : AppColors.muted,
                    fontSize: 9.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _NextWeekButton extends StatelessWidget {
  const _NextWeekButton({
    required this.isSimulating,
    required this.onPressed,
  });

  final bool isSimulating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: !isSimulating,
        label: isSimulating ? 'Simulating next week' : 'Advance one week',
        child: Material(
          key: const Key('nextWeekButton'),
          color: isSimulating ? AppColors.slate : AppColors.teal,
          shadowColor: AppColors.shadow,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.amber, width: 1.5),
          ),
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isSimulating ? null : onPressed,
            child: SizedBox(
              width: AppSizes.nextWeekButton,
              height: AppSizes.nextWeekButton,
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.quick,
                child: isSimulating
                    ? const Center(
                        key: ValueKey('simulating'),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.paper,
                          ),
                        ),
                      )
                    : const Column(
                        key: ValueKey('nextWeek'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '+',
                            style: TextStyle(
                              color: AppColors.midnight,
                              fontSize: 20,
                              height: 0.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'WEEK',
                            style: TextStyle(
                              color: AppColors.midnight,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
}

String _signedCurrency(double value) =>
    '${value > 0 ? '+' : ''}${GameFormatters.compactCurrency(value)}';

String _compactCount(int value) {
  if (value.abs() >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  if (value.abs() >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return '$value';
}
