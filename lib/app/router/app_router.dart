import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/game_controller.dart';
import '../../features/clubs/presentation/club_detail_screen.dart';
import '../../features/clubs/presentation/clubs_screen.dart';
import '../../features/game_shell/presentation/game_shell_screen.dart';
import '../../features/main_menu/presentation/main_menu_screen.dart';
import '../../features/matches/presentation/match_report_screen.dart';
import '../../features/leagues/presentation/league_history_screen.dart';
import '../../features/new_game/presentation/new_game_screen.dart';
import '../../features/office/presentation/office_management_screen.dart';
import '../../features/staff/presentation/staff_screen.dart';
import '../../features/players/presentation/player_detail_screen.dart';
import '../../features/events/presentation/agency_event_screen.dart';
import '../../features/finance/presentation/finance_screen.dart';
import '../../features/transfers/presentation/world_transfers_screen.dart';

abstract final class AppRoutes {
  static const mainMenu = '/';
  static const newGame = '/new-game';
  static const game = '/game';
  static const clubs = '/game/clubs';
  static const players = '/game/players';
  static const matches = '/game/matches';
  static const facilities = '/game/facilities';
  static const staff = '/game/staff';
  static const events = '/game/events';
  static const finance = '/game/finance';
  static const transfers = '/game/transfers';
  static const leagues = '/game/leagues';

  static String clubDetails(String clubId) => '$clubs/$clubId';
  static String playerDetails(String playerId) => '$players/$playerId';
  static String matchDetails(String matchId) => '$matches/$matchId';
  static String eventDetails(String eventId) => '$events/$eventId';
  static String leagueHistory(String leagueId) => '$leagues/$leagueId/history';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.mainMenu,
    redirect: (context, state) {
      final hasActiveGame = ref.read(gameControllerProvider) != null;
      if (state.matchedLocation.startsWith(AppRoutes.game) && !hasActiveGame) {
        return AppRoutes.mainMenu;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.mainMenu,
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.newGame,
        builder: (context, state) => const NewGameScreen(),
      ),
      GoRoute(
        path: AppRoutes.game,
        builder: (context, state) => const GameShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.clubs,
        builder: (context, state) => const ClubsScreen(),
      ),
      GoRoute(
        path: AppRoutes.facilities,
        builder: (context, state) => const FacilitiesManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.staff,
        builder: (context, state) => const StaffManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.finance,
        builder: (context, state) => const FinancePage(),
      ),
      GoRoute(
        path: '${AppRoutes.clubs}/:clubId',
        builder: (context, state) => ClubDetailScreen(
          clubId: state.pathParameters['clubId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.players}/:playerId',
        builder: (context, state) => PlayerDetailScreen(
          playerId: state.pathParameters['playerId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.matches}/:matchId',
        builder: (context, state) => MatchReportScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.events}/:eventId',
        builder: (context, state) => AgencyEventScreen(
          eventId: state.pathParameters['eventId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.transfers,
        builder: (context, state) => const WorldTransfersScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.leagues}/:leagueId/history',
        builder: (context, state) => LeagueHistoryScreen(
          leagueId: state.pathParameters['leagueId']!,
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
