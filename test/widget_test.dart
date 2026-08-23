import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/app/app.dart';
import 'package:football_agent/application/persistence_providers.dart';
import 'package:football_agent/domain/services/game_factory.dart';

import 'helpers/in_memory_game_save_repository.dart';

void main() {
  testWidgets('new career flow creates game state and opens game shell',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            InMemoryGameSaveRepository(),
          ),
        ],
        child: const FootballAgentApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Continue game'), findsOneWidget);

    await tester.tap(find.byKey(const Key('newGameButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('agentNameField')), 'Alex Morgan');
    await tester.enterText(
        find.byKey(const Key('agencyNameField')), 'North Star Sports');
    await tester.enterText(find.byKey(const Key('agentAgeField')), '34');
    await tester.tap(find.byKey(const Key('startCareerButton')));
    await tester.pumpAndSettle();

    expect(find.text('NORTH STAR SPORTS'), findsOneWidget);
    expect(find.text('My Players'), findsOneWidget);
    expect(find.text('Your roster is empty'), findsOneWidget);
    expect(find.text('2025/2026  ·  W1'), findsOneWidget);

    await tester.tap(find.text('Talents'));
    await tester.pumpAndSettle();

    expect(find.text('Premier League · 20 clubs'), findsOneWidget);
    expect(find.text('0/3 CLIENTS'), findsOneWidget);

    await tester.tap(find.byTooltip('Recruit player').first);
    await tester.pumpAndSettle();
    expect(find.text('1/3 CLIENTS'), findsOneWidget);
    expect(find.textContaining('joined your agency.'), findsOneWidget);

    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();

    expect(find.text('1 PLAYER REPRESENTED'), findsOneWidget);
    expect(find.text('SUGGEST'), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('representedPlayerList')),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Form'), findsNothing);
    expect(find.text('Career'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Contract'), findsNothing);
    expect(find.byKey(const Key('playerOverviewTab')), findsOneWidget);
    expect(find.byKey(const Key('playerRatingsPanel')), findsOneWidget);
    expect(find.text('Attacking'), findsOneWidget);
    expect(find.text('Defending'), findsOneWidget);
    expect(find.text('Technical'), findsOneWidget);
    expect(find.text('Mental'), findsOneWidget);
    expect(find.text('Physical'), findsOneWidget);
    expect(find.text('Speed'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('playerOverviewTab')),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('playerOverviewTab')),
        matching: find.byType(Card),
      ),
      findsNothing,
    );
    await tester.tap(find.widgetWithText(Tab, 'Training'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('playerTrainingTab')), findsOneWidget);
    expect(find.byKey(const Key('trainingProgressRail')), findsOneWidget);
    await tester.tap(find.byKey(const Key('trainingFocus-technical')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('playerTrainingTab')), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Stats'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('playerStatsTab')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('playerStatsTab')),
        matching: find.byType(Scrollable),
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(Tab, 'Overview'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.pumpAndSettle();

    await tester.tap(find.text('SUGGEST'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Offers for'), findsOneWidget);
    expect(find.text('Suggest deal'), findsWidgets);

    await tester.ensureVisible(find.text('Suggest deal').first);
    await tester.tap(find.text('Suggest deal').first);
    await tester.pumpAndSettle();
    expect(find.text('SIGNED'), findsOneWidget);

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inboxList')), findsOneWidget);
    expect(find.text('AGENCY UPDATES'), findsOneWidget);

    await tester.tap(find.text('Finance'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agencyFinanceScreen')), findsOneWidget);
    expect(find.byKey(const Key('agencyTransactionList')), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('moreScreen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('moreOfficeButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agencyOfficeScreen')), findsOneWidget);
    expect(find.byKey(const Key('scoutCandidateList')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('officeManagementList')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    final availableHireButton = find.byWidgetPredicate(
      (widget) =>
          widget is InkWell &&
          widget.onTap != null &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
                'hireScoutButton-',
              ),
    );
    await tester.ensureVisible(availableHireButton.first);
    await tester.tap(availableHireButton.first);
    await tester.pumpAndSettle();
    expect(find.textContaining('hired ·'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nextWeekButton')));
    await tester.pumpAndSettle();
    expect(find.text('2025/2026  ·  W2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clubsButton')));
    await tester.pumpAndSettle();

    expect(find.text('Premier League'), findsOneWidget);
    expect(find.byKey(const Key('leagueTableTab')), findsOneWidget);
    await tester.tap(find.text('Fixtures'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('leagueFixturesTab')), findsOneWidget);

    await tester.tap(find.text('Results'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('leagueResultsTab')), findsOneWidget);

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('leagueResultsTab')),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('matchReportScoreboard')), findsOneWidget);
    expect(find.byKey(const Key('matchReportSummary')), findsOneWidget);
    expect(find.byKey(const Key('playerOfTheMatchRow')), findsOneWidget);
    expect(find.byKey(const Key('matchTeamRatingsList')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leaders'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('leagueLeadersTab')), findsOneWidget);
    expect(
      find.byKey(const Key('leaderboardMetricDropdown')),
      findsOneWidget,
    );
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clubs'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clubsList')), findsOneWidget);

    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('clubsList')),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Squad'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);

    await tester.tap(find.text('Squad'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clubSquadTab')), findsOneWidget);

    await tester.tap(find.text('Finance'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clubFinanceTab')), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clubStatsTab')), findsOneWidget);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('clubScheduleTab')), findsOneWidget);
  });

  testWidgets('new career form validates required fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(
            InMemoryGameSaveRepository(),
          ),
        ],
        child: const FootballAgentApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('newGameButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('startCareerButton')));
    await tester.pump();

    expect(find.text('Enter an agent name.'), findsOneWidget);
    expect(find.text('Enter an agency name.'), findsOneWidget);
    expect(find.text('Enter your age.'), findsOneWidget);
  });

  testWidgets('Continue game loads the saved career from the main menu',
      (tester) async {
    final repository = InMemoryGameSaveRepository();
    final savedGame = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    await repository.save(
      savedGame.copyWith(
        agent: savedGame.agent.copyWith(currentWeek: 6),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(repository),
        ],
        child: const FootballAgentApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('savedCareerSummary')), findsOneWidget);
    expect(find.text('North Star Sports · Alex Morgan'), findsOneWidget);
    expect(find.text('2025/2026 · W6'), findsOneWidget);

    await tester.tap(find.byKey(const Key('continueGameButton')));
    await tester.pumpAndSettle();

    expect(find.text('NORTH STAR SPORTS'), findsOneWidget);
    expect(find.text('2025/2026  ·  W6'), findsOneWidget);

    await tester.tap(find.byKey(const Key('saveAndExitButton')));
    await tester.pumpAndSettle();
    expect(find.text('BUILD THE\nCAREERS.'), findsOneWidget);
    expect(find.byKey(const Key('savedCareerSummary')), findsOneWidget);
    expect(find.text('2025/2026 · W6'), findsOneWidget);
  });
}
