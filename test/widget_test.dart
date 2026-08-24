import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_agent/app/app.dart';
import 'package:football_agent/app/theme/app_colors.dart';
import 'package:football_agent/application/persistence_providers.dart';
import 'package:football_agent/domain/services/game_factory.dart';
import 'package:football_agent/domain/models/agency_event.dart';
import 'package:football_agent/domain/models/contract.dart';
import 'package:football_agent/domain/models/game_state.dart';
import 'package:football_agent/domain/models/player_match_performance.dart';
import 'package:football_agent/domain/models/player_season_stats.dart';
import 'package:football_agent/domain/models/transfer_record.dart';
import 'package:football_agent/simulation/engines/random_event_engine.dart';
import 'package:football_agent/simulation/engines/transfer_market_engine.dart';
import 'package:football_agent/simulation/game_engine.dart';

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
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('My Players'), findsNothing);
    expect(find.byKey(const Key('clubsButton')), findsNothing);
    expect(find.byKey(const Key('saveAndExitButton')), findsNothing);
    expect(find.byKey(const Key('careerStatusHeader')), findsOneWidget);
    expect(find.byKey(const Key('agencyNavigationBar')), findsOneWidget);
    expect(find.text('Your roster is empty'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Your roster is empty')).textAlign,
      TextAlign.left,
    );
    expect(
      tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(const Key('simulationStatus-Week')),
                  matching: find.byType(Text),
                )
                .last,
          )
          .data,
      '1/2025',
    );
    expect(
      tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(
                    const Key('simulationStatus-Transfer Season'),
                  ),
                  matching: find.byType(Text),
                )
                .last,
          )
          .data,
      'No',
    );
    final moneyStatus = find.byKey(const Key('simulationStatus-Money'));
    final moneyValue =
        find.descendant(of: moneyStatus, matching: find.byType(Text)).last;
    expect(tester.widget<Text>(moneyValue).style?.fontSize, 12);
    final weekValue = find
        .descendant(
          of: find.byKey(const Key('simulationStatus-Week')),
          matching: find.byType(Text),
        )
        .last;
    final transferValue = find
        .descendant(
          of: find.byKey(const Key('simulationStatus-Transfer Season')),
          matching: find.byType(Text),
        )
        .last;
    expect(
      tester.getTopLeft(moneyValue).dx,
      closeTo(tester.getTopLeft(weekValue).dx, 0.1),
    );
    expect(
      tester.getTopLeft(moneyValue).dx,
      closeTo(tester.getTopLeft(transferValue).dx, 0.1),
    );
    final nextWeekControl = tester.widget<Material>(
      find.byKey(const Key('nextWeekButton')),
    );
    expect(nextWeekControl.shape, isA<CircleBorder>());
    final playersX =
        tester.getCenter(find.byKey(const Key('playersNavigationButton'))).dx;
    final talentsX =
        tester.getCenter(find.byKey(const Key('talentsNavigationButton'))).dx;
    final nextWeekX =
        tester.getCenter(find.byKey(const Key('nextWeekButton'))).dx;
    final emailX =
        tester.getCenter(find.byKey(const Key('emailNavigationButton'))).dx;
    final moreX =
        tester.getCenter(find.byKey(const Key('moreNavigationButton'))).dx;
    expect(playersX, lessThan(talentsX));
    expect(talentsX, lessThan(nextWeekX));
    expect(nextWeekX, lessThan(emailX));
    expect(emailX, lessThan(moreX));

    await tester.tap(find.text('Talents'));
    await tester.pumpAndSettle();

    expect(find.text('Premier League · 20 clubs'), findsOneWidget);
    expect(find.text('0/3 CLIENTS'), findsOneWidget);
    final firstTalentRow = find
        .descendant(
          of: find.byKey(const Key('talentList')),
          matching: find.byType(InkWell),
        )
        .first;
    final firstTalentTexts = find.descendant(
      of: firstTalentRow,
      matching: find.byType(Text),
    );
    expect(
      tester.getTopLeft(find.text('SCOUTED PLAYER')).dx,
      closeTo(tester.getTopLeft(firstTalentTexts.at(1)).dx, 0.1),
    );

    await tester.tap(
      firstTalentRow,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Career'));
    await tester.pumpAndSettle();
    expect(find.text('Recruit player'), findsOneWidget);
    await tester.tap(find.text('Recruit player'));
    await tester.pumpAndSettle();
    expect(find.textContaining('joined your agency.'), findsOneWidget);
    expect(find.text('Suggest player'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1/3 CLIENTS'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clearTalentPoolButton')));
    await tester.pumpAndSettle();
    expect(find.text('Clear talent pool?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmClearTalentPoolButton')));
    await tester.pumpAndSettle();
    expect(find.text('Talent pool empty'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Talent pool empty')).textAlign,
      TextAlign.left,
    );
    expect(find.text('1/3 CLIENTS'), findsOneWidget);

    await tester.tap(find.text('Players'));
    await tester.pumpAndSettle();

    expect(find.text('1 PLAYER REPRESENTED'), findsOneWidget);
    expect(find.text('ACTION'), findsNothing);
    expect(find.text('SUGGEST'), findsNothing);

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
    expect(find.widgetWithText(Tab, 'Training'), findsNothing);
    expect(find.widgetWithText(Tab, 'Stats'), findsNothing);
    expect(find.text('Form'), findsNothing);
    expect(find.text('Career'), findsOneWidget);
    expect(find.text('Season'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Contract'), findsNothing);
    expect(find.byKey(const Key('playerOverviewTab')), findsOneWidget);
    expect(find.byKey(const Key('playerRatingsPanel')), findsOneWidget);
    expect(find.byKey(const Key('playerAchievementsPanel')), findsOneWidget);
    expect(find.text('Attacking'), findsOneWidget);
    expect(find.text('Defending'), findsOneWidget);
    expect(find.text('Technical'), findsOneWidget);
    expect(find.text('Mental'), findsOneWidget);
    expect(find.text('Physical'), findsOneWidget);
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('Agency trust'), findsOneWidget);
    expect(find.text('Character'), findsOneWidget);
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
    await tester.tap(find.widgetWithText(Tab, 'Career'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('playerCareerTab')), findsOneWidget);
    expect(find.text('CLUB CAREER'), findsOneWidget);
    expect(find.text('Suggest player'), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Season'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('playerSeasonsTab')), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Career'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suggest player'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ACTIVE CLUB'), findsOneWidget);
    expect(find.text('REVIEW'), findsWidgets);

    await tester.tap(find.text('REVIEW').first);
    await tester.pumpAndSettle();
    expect(find.text('COUNTER PROPOSAL'), findsOneWidget);
    expect(find.byKey(const Key('negotiationSalaryOptions')), findsOneWidget);
    expect(find.byKey(const Key('negotiationFeeOptions')), findsOneWidget);
    expect(find.byKey(const Key('negotiationLengthOptions')), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('CLUB OFFER'), findsNWidgets(3));
    expect(find.text('COUNTER'), findsNWidgets(6));
    expect(find.text('Accept original'), findsOneWidget);
    expect(find.text('Send counter proposal'), findsOneWidget);
    await tester.tap(find.text('Accept original'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offerFeedbackToast')), findsOneWidget);
    expect(find.textContaining('deal completed'), findsOneWidget);
    expect(find.text('No active offers remain.'), findsNothing);
    expect(find.text('COUNTER PROPOSAL'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('offerFeedbackToast')), findsNothing);
    expect(find.text('Ask for transfer list'), findsNothing);
    expect(find.text('Ask for loan list'), findsNothing);
    expect(find.text('Window closed'), findsNWidgets(2));
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('ACTION'), findsNothing);
    expect(find.text('SIGNED'), findsNothing);

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inboxList')), findsOneWidget);
    expect(find.text('AGENCY UPDATES'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('moreScreen')), findsOneWidget);
    expect(find.byKey(const Key('moreFinanceButton')), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Finance')).textAlign,
      TextAlign.left,
    );
    await tester.tap(find.byKey(const Key('moreFinanceButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agencyFinanceScreen')), findsOneWidget);
    expect(find.byKey(const Key('agencyTransactionList')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moreWorldTransfersButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recentTransfersHalf')), findsOneWidget);
    expect(find.byKey(const Key('allTimeTransfersHalf')), findsOneWidget);
    final recentRect = tester.getRect(
      find.byKey(const Key('recentTransfersHalf')),
    );
    final recordsRect = tester.getRect(
      find.byKey(const Key('allTimeTransfersHalf')),
    );
    expect(recentRect.top, lessThan(recordsRect.top));
    expect(
        (recentRect.height - recordsRect.height).abs(), lessThanOrEqualTo(1));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moreFacilitiesButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agencyFacilitiesScreen')), findsOneWidget);
    expect(find.byKey(const Key('officeFacilityArtwork')), findsOneWidget);
    expect(
      find.byKey(const Key('trainingGroundFacilityArtwork')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('upgradeOfficeButton')), findsOneWidget);
    expect(
      find.byKey(const Key('upgradeTrainingGroundButton')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('scoutCandidateList')), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moreStaffButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agencyStaffScreen')), findsOneWidget);
    expect(find.byKey(const Key('scoutCandidateList')), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('staffManagementList')),
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
    expect(find.text('2/2025'), findsOneWidget);

    await tester.tap(find.byKey(const Key('moreClubsButton')));
    await tester.pumpAndSettle();

    expect(find.text('Premier League'), findsOneWidget);
    expect(find.byKey(const Key('leagueTableTab')), findsOneWidget);
    expect(find.byKey(const Key('leagueHistoryButton')), findsOneWidget);
    await tester.tap(find.byKey(const Key('leagueHistoryButton')));
    await tester.pumpAndSettle();
    expect(find.text('No completed seasons yet'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
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

  testWidgets('short Android phone keeps player overview readable and tappable',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = InMemoryGameSaveRepository();
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final prospect = base.availableTalents.first;
    await repository.save(
      base.copyWith(
        players: [
          for (final player in base.players)
            player.id == prospect.id
                ? player.copyWith(
                    agentId: base.agent.id,
                    isRecruited: true,
                  )
                : player,
        ],
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
    await tester.tap(find.byKey(const Key('continueGameButton')));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('representedPlayerList')),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('playerOverviewTab')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('playerOverviewTab')),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
    expect(tester.getSize(find.byType(TabBar).first).height, 44);
    expect(
      tester.getSize(find.byKey(const Key('endRepresentationButton'))).height,
      44,
    );
    expect(tester.takeException(), isNull);
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
    expect(find.text('6/2025'), findsOneWidget);
    expect(find.byKey(const Key('saveAndExitButton')), findsNothing);
    expect(find.byKey(const Key('clubsButton')), findsNothing);
  });

  testWidgets('world transfers separate recent order from record-fee order',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = InMemoryGameSaveRepository();
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final fromClub = base.clubs.first;
    final toClub = base.clubs[1];
    final player = base.players.firstWhere(
      (candidate) => candidate.clubId == fromClub.id,
    );
    await repository.save(
      base.copyWith(
        transfers: [
          TransferRecord(
            id: 'older-record-fee',
            playerId: player.id,
            fromClubId: fromClub.id,
            toClubId: toClub.id,
            fee: 104272167.71,
            season: 1,
            week: 4,
          ),
          TransferRecord(
            id: 'newer-lower-fee',
            playerId: player.id,
            fromClubId: toClub.id,
            toClubId: fromClub.id,
            fee: 20000000,
            season: 2,
            week: 9,
          ),
          ...List.generate(
            23,
            (index) => TransferRecord(
              id: 'extra-transfer-$index',
              playerId: player.id,
              fromClubId: fromClub.id,
              toClubId: toClub.id,
              fee: (1000000 + index).toDouble(),
              season: 0,
              week: index + 1,
            ),
          ),
        ],
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
    await tester.tap(find.byKey(const Key('continueGameButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('moreWorldTransfersButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recentTransferList')), findsOneWidget);
    expect(find.byKey(const Key('allTimeTransferList')), findsOneWidget);
    expect(
      tester
          .widget<ListView>(find.byKey(const Key('recentTransferList')))
          .semanticChildCount,
      20,
    );
    expect(
      tester
          .widget<ListView>(find.byKey(const Key('allTimeTransferList')))
          .semanticChildCount,
      20,
    );
    final recentNew = tester.getTopLeft(
      find.byKey(const Key('recentTransferRow-newer-lower-fee')),
    );
    final recentOld = tester.getTopLeft(
      find.byKey(const Key('recentTransferRow-older-record-fee')),
    );
    final recordOld = tester.getTopLeft(
      find.byKey(const Key('recordTransferRow-older-record-fee')),
    );
    final recordNew = tester.getTopLeft(
      find.byKey(const Key('recordTransferRow-newer-lower-fee')),
    );
    expect(recentNew.dy, lessThan(recentOld.dy));
    expect(recordOld.dy, lessThan(recordNew.dy));
    final recentRecordRow = find.byKey(
      const Key('recentTransferRow-older-record-fee'),
    );
    expect(
      find.descendant(
        of: recentRecordRow,
        matching: find.byKey(const Key('transferFee-older-record-fee')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: recentRecordRow, matching: find.text('£104.3m')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: recentRecordRow, matching: find.text('TRANSFER')),
      findsOneWidget,
    );
  });

  testWidgets('player Career keeps history and Season shows current year only',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = InMemoryGameSaveRepository();
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final simulated = const GameEngine().simulateOneWeek(base).state;
    final appearance = simulated.playerPerformances.first;
    final previousClubId = appearance.clubId;
    final newClub = simulated.clubs.firstWhere(
      (club) => club.id != previousClubId,
    );
    final movedPlayer = simulated.players.firstWhere(
      (player) => player.id == appearance.playerId,
    );
    final representedPlayers = simulated.players.map((player) {
      if (player.id != appearance.playerId) return player;
      return player.copyWith(
        agentId: simulated.agent.id,
        isRecruited: true,
        clubId: newClub.id,
      );
    }).toList(growable: false);
    final oldAppearance = PlayerMatchPerformance(
      id: 'old-${appearance.id}',
      matchId: 'old-${appearance.matchId}',
      leagueId: appearance.leagueId,
      playerId: appearance.playerId,
      clubId: appearance.clubId,
      week: 49,
      season: 0,
      started: true,
      minutes: 90,
      goals: 9,
      assists: 3,
      cleanSheet: false,
      yellowCards: 0,
      redCards: 0,
      rating: 7.2,
    );
    final oldStats = PlayerSeasonStats(
      playerId: appearance.playerId,
      clubId: appearance.clubId,
      leagueId: appearance.leagueId,
      season: 0,
      overall: 70,
      marketValue: 11000000,
      appearances: 14,
      starts: 12,
      minutes: 1080,
      goals: 9,
      assists: 3,
      totalRating: 100.8,
    );
    await repository.save(
      simulated.copyWith(
        players: representedPlayers,
        playerPerformances: [
          ...simulated.playerPerformances,
          oldAppearance,
        ],
        playerSeasonStats: [
          ...simulated.playerSeasonStats,
          PlayerSeasonStats(
            playerId: appearance.playerId,
            clubId: newClub.id,
            leagueId: newClub.leagueId,
            season: simulated.currentSeason,
            overall: movedPlayer.ability,
            marketValue: movedPlayer.value * 1.25,
          ),
          oldStats,
        ],
        transfers: [
          TransferRecord(
            id: 'same-season-career-move',
            playerId: appearance.playerId,
            fromClubId: previousClubId,
            toClubId: newClub.id,
            fee: movedPlayer.value * 1.25,
            season: simulated.currentSeason,
            week: simulated.currentWeek,
          ),
        ],
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
    await tester.tap(find.byKey(const Key('continueGameButton')));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byKey(const Key('representedPlayerList')),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(Tab, 'Career'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('playerCareerTab')), findsOneWidget);
    expect(find.text('CLUB CAREER'), findsOneWidget);
    expect(find.text('YEAR'), findsOneWidget);
    expect(find.text('24/25'), findsOneWidget);
    expect(find.text('£11.0m'), findsOneWidget);
    expect(find.byKey(const Key('playerCareerTotals')), findsOneWidget);
    final newClubRow = tester.getTopLeft(
      find.byKey(
        Key('playerCareerRow-${simulated.currentSeason}-${newClub.id}'),
      ),
    );
    final previousClubRow = tester.getTopLeft(
      find.byKey(
        Key('playerCareerRow-${simulated.currentSeason}-$previousClubId'),
      ),
    );
    expect(newClubRow.dy, lessThan(previousClubRow.dy));

    await tester.tap(find.widgetWithText(Tab, 'Season'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('playerSeasonsTab')), findsOneWidget);
    expect(find.text('ALL APPEARANCES · 1'), findsOneWidget);
    expect(find.text('W1'), findsOneWidget);
    expect(find.text('W49'), findsNothing);
  });

  testWidgets('player Career shows a current club season with zero games',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = InMemoryGameSaveRepository();
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final player = base.playersForClub(base.clubs.first.id).first;
    final current = base.copyWith(
      agent: base.agent.copyWith(currentSeason: 3, currentWeek: 10),
      contracts: [
        Contract(
          id: 'zero-career-contract',
          playerId: player.id,
          clubId: player.clubId!,
          salary: player.salary,
          agentFee: 0,
          contractLength: 4,
          startSeason: 1,
          endSeason: 5,
          startWeek: 1,
        ),
      ],
    );
    await repository.save(
      current.copyWith(
        players: base.players
            .map(
              (candidate) => candidate.id == player.id
                  ? candidate.copyWith(
                      agentId: current.agent.id,
                      isRecruited: true,
                    )
                  : candidate,
            )
            .toList(growable: false),
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
    await tester.tap(find.byKey(const Key('continueGameButton')));
    await tester.pumpAndSettle();
    expect(find.text('PLAYER / STATUS'), findsOneWidget);
    expect(find.text('AGE'), findsOneWidget);
    expect(find.text('OVR'), findsOneWidget);
    expect(find.text('PTS'), findsOneWidget);
    expect(find.text('EXP'), findsOneWidget);
    await tester.tap(find.byKey(Key('representedPlayerCard-${player.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Career'));
    await tester.pumpAndSettle();

    for (final season in [1, 2, 3]) {
      final row = find.byKey(
        Key('playerCareerRow-$season-${player.clubId}'),
      );
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('0')),
        findsNWidgets(4),
      );
    }
    expect(find.text('3 SEASONS'), findsOneWidget);
  });

  testWidgets('pending agency event opens as a protected full page',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = InMemoryGameSaveRepository();
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    final weekEight = base.copyWith(
      agent: base.agent.copyWith(currentWeek: 8),
    );
    final generated = const RandomEventEngine().processWeek(
      weekEight,
      season: 1,
      week: 8,
      seed: 42,
      forceType: AgencyEventType.officeRepair,
    );
    final event = generated.state.pendingAgencyEvents.single;
    await repository.save(generated.state);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(repository),
        ],
        child: const FootballAgentApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueGameButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('agencyEventRow-${event.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('agencyEventPage')), findsOneWidget);
    expect(find.text('Office equipment failure'), findsOneWidget);
    expect(find.byKey(const Key('agencyEventChoice-repair')), findsOneWidget);
    expect(find.textContaining('Decide later'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agencyEventPage')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byKey(const Key('agencyEventChoice-postpone')));
    await tester.pumpAndSettle();
    expect(find.text('DECISION RECORDED'), findsOneWidget);
    expect(find.byKey(const Key('agencyEventReturnButton')), findsOneWidget);

    await tester.tap(find.byKey(const Key('agencyEventReturnButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agencyEventPage')), findsNothing);
    expect(find.text('DECISION HISTORY'), findsNothing);
    expect(find.byKey(Key('agencyEventRow-${event.id}')), findsNothing);
  });

  testWidgets('player list offer count opens offer review from Career',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = InMemoryGameSaveRepository();
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 24),
    );
    final player = base.playersForClub(base.clubs.first.id).first;
    final contract = Contract(
      id: 'widget-transfer-contract',
      playerId: player.id,
      clubId: player.clubId!,
      salary: player.salary,
      agentFee: 0,
      contractLength: 4,
      startSeason: 1,
      endSeason: 5,
      startWeek: 1,
    );
    final listed = base.copyWith(
      agent: base.agent.copyWith(currentSeason: 2, currentWeek: 20),
      players: [
        for (final candidate in base.players)
          candidate.id == player.id
              ? candidate.copyWith(
                  agentId: base.agent.id,
                  isRecruited: true,
                  isTransferListed: true,
                )
              : candidate,
      ],
      contracts: [contract],
    );
    final offered = const TransferMarketEngine().processWeek(listed, seed: 4);
    final offerCount = offered.pendingOffersForPlayer(player.id).length;
    expect(offerCount, greaterThan(0));
    await repository.save(offered);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(repository),
        ],
        child: const FootballAgentApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueGameButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(Key('playerOfferCount-${player.id}')), findsOneWidget);
    expect(
      find.text('$offerCount ${offerCount == 1 ? 'OFFER' : 'OFFERS'}'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(Key('representedPlayerCard-${player.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Career'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(Key('careerReviewOffersButton-${player.id}')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(Key('careerReviewOffersButton-${player.id}')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ACTIVE CLUB'), findsOneWidget);
    await tester.tap(find.text('REVIEW').first);
    await tester.pumpAndSettle();
    expect(
      find.text('DECIDE THIS WEEK · OFFER EXPIRES WHEN THE WEEK ADVANCES'),
      findsOneWidget,
    );
    await tester.tap(find.text('Accept original'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('offerFeedbackToast')), findsOneWidget);
    expect(find.textContaining('deal completed'), findsOneWidget);
    expect(find.text('No active offers remain.'), findsNothing);
    expect(find.textContaining('ACTIVE CLUB'), findsNothing);
    expect(find.byKey(const Key('playerCareerTab')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('failed event uses failure semantics instead of success green',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = InMemoryGameSaveRepository();
    final base = const GameFactory().createNewGame(
      agentName: 'Alex Morgan',
      agencyName: 'North Star Sports',
      agentAge: 34,
      createdAt: DateTime.utc(2026, 8, 23, 12),
    );
    AgencyEventResolution? failure;
    GameState? pendingFailureState;
    for (var week = 4; week <= 50 && failure == null; week++) {
      final weekState = base.copyWith(
        agent: base.agent.copyWith(currentWeek: week),
      );
      final generated = const RandomEventEngine().processWeek(
        weekState,
        season: 1,
        week: week,
        seed: week,
        forceType: AgencyEventType.officeRepair,
      );
      final resolution = const RandomEventEngine().resolve(
        generated.state,
        eventId: generated.state.pendingAgencyEvents.single.id,
        choiceId: 'temporary',
      )!;
      if (!resolution.succeeded) {
        failure = resolution;
        pendingFailureState = generated.state;
      }
    }
    expect(failure, isNotNull);
    await repository.save(pendingFailureState!);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameSaveRepositoryProvider.overrideWithValue(repository),
        ],
        child: const FootballAgentApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continueGameButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(Key('agencyEventRow-${failure!.event.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agencyEventChoice-temporary')));
    await tester.pumpAndSettle();

    final failureLabel = tester.widget<Text>(find.text('OUTCOME FAILED'));
    expect(failureLabel.style?.color, AppColors.danger);
    expect(find.text('OUTCOME SUCCESSFUL'), findsNothing);
    expect(
      find.byKey(const Key('agencyEventReturnButton')),
      findsOneWidget,
    );
    expect(
      tester.widget(find.byKey(const Key('agencyEventReturnButton'))),
      isA<OutlinedButton>(),
    );
  });
}
