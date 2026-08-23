import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'persistence_providers.dart';
import '../domain/models/game_state.dart';
import '../domain/models/agency_transaction.dart';
import '../domain/models/club_offer.dart';
import '../domain/models/game_email.dart';
import '../domain/models/scout.dart';
import '../domain/models/player_training_plan.dart';
import '../domain/services/game_factory.dart';
import '../domain/services/game_balance.dart';
import '../domain/repositories/game_save_repository.dart';
import '../simulation/engines/deal_engine.dart';
import '../simulation/engines/offer_engine.dart';
import '../simulation/game_engine.dart';

final gameFactoryProvider = Provider<GameFactory>((ref) => const GameFactory());
final offerEngineProvider = Provider<OfferEngine>((ref) => const OfferEngine());
final dealEngineProvider = Provider<DealEngine>((ref) => const DealEngine());
final gameEngineProvider = Provider<GameEngine>((ref) => const GameEngine());

final gameControllerProvider =
    NotifierProvider<GameController, GameState?>(GameController.new);

enum RecruitmentResult {
  success,
  noActiveGame,
  playerNotFound,
  playerUnavailable,
  officeFull,
}

enum SuggestionStatus {
  success,
  noActiveGame,
  playerUnavailable,
  alreadySuggested,
  noClubInterest,
}

class SuggestionResult {
  const SuggestionResult(this.status, {this.offerCount = 0});

  final SuggestionStatus status;
  final int offerCount;
}

enum DealActionResult {
  success,
  invalidOffer,
  noActiveGame,
}

enum ScoutActionResult {
  success,
  noActiveGame,
  scoutNotFound,
  notAvailable,
  officeFull,
  reputationTooLow,
  notEmployed,
}

enum OfficeUpgradeResult {
  success,
  noActiveGame,
  maximumLevel,
  reputationTooLow,
}

enum TrainingGroundUpgradeResult {
  success,
  noActiveGame,
  maximumLevel,
  reputationTooLow,
}

enum RepresentationActionResult {
  success,
  noActiveGame,
  playerNotFound,
  notRepresented,
}

enum LoadGameResult {
  success,
  noSave,
  invalidSave,
  failed,
}

enum TrainingPlanActionResult {
  success,
  noActiveGame,
  playerNotFound,
  notRepresented,
  unavailable,
}

class GameController extends Notifier<GameState?> {
  Future<void> _saveQueue = Future<void>.value();
  Object? _lastSaveError;

  @override
  GameState? build() => null;

  void startNewGame({
    required String agentName,
    required String agencyName,
    required int agentAge,
  }) {
    state = ref.read(gameFactoryProvider).createNewGame(
          agentName: agentName,
          agencyName: agencyName,
          agentAge: agentAge,
        );
    _scheduleAutoSave();
  }

  RecruitmentResult recruitPlayer(String playerId) {
    final currentGame = state;
    if (currentGame == null) return RecruitmentResult.noActiveGame;

    final playerIndex = currentGame.players.indexWhere(
      (player) => player.id == playerId,
    );
    if (playerIndex == -1) return RecruitmentResult.playerNotFound;

    final player = currentGame.players[playerIndex];
    final isAvailable = player.clubId == null &&
        player.agentId == null &&
        !player.isRecruited &&
        !player.isRetired;
    if (!isAvailable) return RecruitmentResult.playerUnavailable;
    if (currentGame.isAgencyAtClientCapacity) {
      return RecruitmentResult.officeFull;
    }

    final updatedPlayers = [...currentGame.players];
    updatedPlayers[playerIndex] = player.copyWith(
      agentId: currentGame.agent.id,
      isRecruited: true,
    );
    state = currentGame.copyWith(
      players: updatedPlayers,
      trainingPlans: [
        ...currentGame.trainingPlans,
        if (!currentGame.trainingPlans
            .any((plan) => plan.playerId == player.id))
          PlayerTrainingPlan(playerId: player.id),
      ],
    );
    _scheduleAutoSave();
    return RecruitmentResult.success;
  }

  SuggestionResult suggestPlayer(String playerId) {
    final currentGame = state;
    if (currentGame == null) {
      return const SuggestionResult(SuggestionStatus.noActiveGame);
    }

    final playerIndex = currentGame.players.indexWhere(
      (player) => player.id == playerId,
    );
    if (playerIndex == -1) {
      return const SuggestionResult(SuggestionStatus.playerUnavailable);
    }

    final player = currentGame.players[playerIndex];
    if (player.agentId != currentGame.agent.id ||
        player.clubId != null ||
        player.isRetired) {
      return const SuggestionResult(SuggestionStatus.playerUnavailable);
    }
    if (currentGame.pendingOffersForPlayer(playerId).isNotEmpty) {
      return SuggestionResult(
        SuggestionStatus.alreadySuggested,
        offerCount: currentGame.pendingOffersForPlayer(playerId).length,
      );
    }

    final offers = ref.read(offerEngineProvider).generateOffers(
          game: currentGame,
          player: player,
        );
    if (offers.isEmpty) {
      return const SuggestionResult(SuggestionStatus.noClubInterest);
    }

    state = currentGame.copyWith(offers: [...currentGame.offers, ...offers]);
    _scheduleAutoSave();
    return SuggestionResult(
      SuggestionStatus.success,
      offerCount: offers.length,
    );
  }

  DealActionResult acceptOffer(String offerId) {
    final currentGame = state;
    if (currentGame == null) return DealActionResult.noActiveGame;
    final updatedGame =
        ref.read(dealEngineProvider).acceptOffer(currentGame, offerId);
    if (updatedGame == null) return DealActionResult.invalidOffer;
    state = updatedGame;
    _scheduleAutoSave();
    return DealActionResult.success;
  }

  DealActionResult declineOffer(String offerId) {
    final currentGame = state;
    if (currentGame == null) return DealActionResult.noActiveGame;
    final updatedGame =
        ref.read(dealEngineProvider).declineOffer(currentGame, offerId);
    if (updatedGame == null) return DealActionResult.invalidOffer;
    state = updatedGame;
    _scheduleAutoSave();
    return DealActionResult.success;
  }

  ScoutActionResult hireScout(String scoutId) {
    final currentGame = state;
    if (currentGame == null) return ScoutActionResult.noActiveGame;
    final index = currentGame.scouts.indexWhere((scout) => scout.id == scoutId);
    if (index == -1) return ScoutActionResult.scoutNotFound;

    final candidate = currentGame.scouts[index];
    if (!candidate.isCandidate) return ScoutActionResult.notAvailable;
    if (currentGame.hiredScouts.length >= currentGame.office.scoutCapacity) {
      return ScoutActionResult.officeFull;
    }
    if (currentGame.agent.reputation < candidate.requiredReputation) {
      return ScoutActionResult.reputationTooLow;
    }

    final updatedScouts = [...currentGame.scouts];
    updatedScouts[index] = candidate.copyWith(agencyId: currentGame.agent.id);
    state = currentGame.copyWith(
      agent: currentGame.agent.copyWith(
        money: currentGame.agent.money - candidate.signingCost,
      ),
      scouts: updatedScouts,
      agencyTransactions: [
        ...currentGame.agencyTransactions,
        AgencyTransaction(
          id: 'transaction-scout-hire-s${currentGame.currentSeason}-w${currentGame.currentWeek}-${candidate.id}',
          type: AgencyTransactionType.scoutSigning,
          amount: -candidate.signingCost,
          description: '${candidate.name} signing cost',
          season: currentGame.currentSeason,
          week: currentGame.currentWeek,
        ),
      ],
      emails: [
        GameEmail(
          id: 'email-scout-hire-s${currentGame.currentSeason}-w${currentGame.currentWeek}-${candidate.id}',
          type: GameEmailType.finance,
          subject: '${candidate.name} joins the agency',
          body:
              '${candidate.name} joins as a scout rated ${candidate.ability}. The four-week signing cost has been paid.',
          season: currentGame.currentSeason,
          week: currentGame.currentWeek,
        ),
        ...currentGame.emails,
      ],
    );
    _scheduleAutoSave();
    return ScoutActionResult.success;
  }

  ScoutActionResult dismissScout(String scoutId) {
    final currentGame = state;
    if (currentGame == null) return ScoutActionResult.noActiveGame;
    final index = currentGame.scouts.indexWhere((scout) => scout.id == scoutId);
    if (index == -1) return ScoutActionResult.scoutNotFound;

    final scout = currentGame.scouts[index];
    if (scout.agencyId != currentGame.agent.id) {
      return ScoutActionResult.notEmployed;
    }
    final updatedScouts = [...currentGame.scouts];
    updatedScouts[index] = scout.copyWith(
      agencyId: Scout.candidatePoolAgencyId,
    );
    state = currentGame.copyWith(
      scouts: updatedScouts,
      emails: [
        GameEmail(
          id: 'email-scout-dismiss-s${currentGame.currentSeason}-w${currentGame.currentWeek}-${scout.id}',
          type: GameEmailType.finance,
          subject: '${scout.name} leaves the agency',
          body: '${scout.name} has left the scouting team.',
          season: currentGame.currentSeason,
          week: currentGame.currentWeek,
        ),
        ...currentGame.emails,
      ],
    );
    _scheduleAutoSave();
    return ScoutActionResult.success;
  }

  OfficeUpgradeResult upgradeOffice() {
    final currentGame = state;
    if (currentGame == null) return OfficeUpgradeResult.noActiveGame;
    final office = currentGame.office;
    if (!office.canUpgrade) return OfficeUpgradeResult.maximumLevel;
    if (currentGame.agent.reputation <
        office.nextUpgradeReputationRequirement) {
      return OfficeUpgradeResult.reputationTooLow;
    }

    final upgraded = office.upgrade();
    state = currentGame.copyWith(
      office: upgraded,
      agent: currentGame.agent.copyWith(
        money: currentGame.agent.money - office.nextUpgradeMoneyCost,
        reputation:
            currentGame.agent.reputation - office.nextUpgradeReputationCost,
      ),
      emails: [
        GameEmail(
          id: 'email-office-upgrade-s${currentGame.currentSeason}-w${currentGame.currentWeek}-l${upgraded.level}',
          type: GameEmailType.finance,
          subject: 'Office upgraded to Level ${upgraded.level}',
          body:
              'The agency now supports ${upgraded.clientCapacity} clients and ${upgraded.scoutCapacity} scouts.',
          season: currentGame.currentSeason,
          week: currentGame.currentWeek,
        ),
        ...currentGame.emails,
      ],
      agencyTransactions: [
        ...currentGame.agencyTransactions,
        AgencyTransaction(
          id: 'transaction-office-upgrade-s${currentGame.currentSeason}-w${currentGame.currentWeek}-l${upgraded.level}',
          type: AgencyTransactionType.officeUpgrade,
          amount: -office.nextUpgradeMoneyCost,
          description: 'Office upgraded to Level ${upgraded.level}',
          season: currentGame.currentSeason,
          week: currentGame.currentWeek,
        ),
      ],
    );
    _scheduleAutoSave();
    return OfficeUpgradeResult.success;
  }

  TrainingGroundUpgradeResult upgradeTrainingGround() {
    final currentGame = state;
    if (currentGame == null) {
      return TrainingGroundUpgradeResult.noActiveGame;
    }
    final ground = currentGame.trainingGround;
    if (!ground.canUpgrade) {
      return TrainingGroundUpgradeResult.maximumLevel;
    }
    if (currentGame.agent.reputation <
        ground.nextUpgradeReputationRequirement) {
      return TrainingGroundUpgradeResult.reputationTooLow;
    }

    final upgraded = ground.upgrade();
    state = currentGame.copyWith(
      trainingGround: upgraded,
      agent: currentGame.agent.copyWith(
        money: currentGame.agent.money - ground.nextUpgradeMoneyCost,
        reputation:
            currentGame.agent.reputation - ground.nextUpgradeReputationCost,
      ),
      agencyTransactions: [
        ...currentGame.agencyTransactions,
        AgencyTransaction(
          id: 'transaction-ground-upgrade-s${currentGame.currentSeason}-w${currentGame.currentWeek}-l${upgraded.level}',
          type: AgencyTransactionType.trainingGroundUpgrade,
          amount: -ground.nextUpgradeMoneyCost,
          description: 'Training Ground upgraded to Level ${upgraded.level}',
          season: currentGame.currentSeason,
          week: currentGame.currentWeek,
        ),
      ],
      emails: [
        GameEmail(
          id: 'email-ground-upgrade-s${currentGame.currentSeason}-w${currentGame.currentWeek}-l${upgraded.level}',
          type: GameEmailType.finance,
          subject: 'Training Ground reaches Level ${upgraded.level}',
          body:
              'Internal prospects now arrive every ${upgraded.intakeIntervalWeeks} weeks with an expected ability of ${upgraded.minimumAbility}-${upgraded.maximumAbility}.',
          season: currentGame.currentSeason,
          week: currentGame.currentWeek,
        ),
        ...currentGame.emails,
      ],
    );
    _scheduleAutoSave();
    return TrainingGroundUpgradeResult.success;
  }

  double? representationTerminationCost(String playerId) {
    final currentGame = state;
    final player = currentGame?.players
        .where((candidate) => candidate.id == playerId)
        .firstOrNull;
    if (player == null) return null;
    return const GameBalance().representationTerminationCost(
      weeklySalary: player.salary,
      marketValue: player.value,
    );
  }

  RepresentationActionResult endRepresentation(String playerId) {
    final currentGame = state;
    if (currentGame == null) {
      return RepresentationActionResult.noActiveGame;
    }
    final index = currentGame.players.indexWhere(
      (player) => player.id == playerId,
    );
    if (index == -1) return RepresentationActionResult.playerNotFound;
    final player = currentGame.players[index];
    if (player.agentId != currentGame.agent.id || !player.isRecruited) {
      return RepresentationActionResult.notRepresented;
    }

    final cost = const GameBalance().representationTerminationCost(
      weeklySalary: player.salary,
      marketValue: player.value,
    );
    final players = [...currentGame.players];
    players[index] = player.copyWith(clearAgentId: true);
    state = currentGame.copyWith(
      agent: currentGame.agent.copyWith(
        money: currentGame.agent.money - cost,
        reputation: currentGame.agent.reputation - 2,
      ),
      players: players,
      offers: currentGame.offers
          .map((offer) => offer.playerId == playerId &&
                  offer.status == ClubOfferStatus.pending
              ? offer.copyWith(status: ClubOfferStatus.declined)
              : offer)
          .toList(growable: false),
      trainingPlans: currentGame.trainingPlans
          .where((plan) => plan.playerId != playerId)
          .toList(growable: false),
      agencyTransactions: [
        ...currentGame.agencyTransactions,
        AgencyTransaction(
          id: 'transaction-end-representation-s${currentGame.currentSeason}-w${currentGame.currentWeek}-${player.id}',
          type: AgencyTransactionType.representationTermination,
          amount: -cost,
          description: 'Ended representation of ${player.name}',
          season: currentGame.currentSeason,
          week: currentGame.currentWeek,
        ),
      ],
      emails: [
        GameEmail(
          id: 'email-end-representation-s${currentGame.currentSeason}-w${currentGame.currentWeek}-${player.id}',
          type: GameEmailType.finance,
          subject: '${player.name} leaves the agency',
          body:
              'Representation ended for a ${cost.toStringAsFixed(0)} settlement and 2 reputation. Existing club and contract status are unchanged.',
          season: currentGame.currentSeason,
          week: currentGame.currentWeek,
          playerId: player.id,
          clubId: player.clubId,
        ),
        ...currentGame.emails,
      ],
    );
    _scheduleAutoSave();
    return RepresentationActionResult.success;
  }

  TrainingPlanActionResult updateTrainingPlan(
    String playerId, {
    TrainingFocus? focus,
    TrainingIntensity? intensity,
  }) {
    final currentGame = state;
    if (currentGame == null) return TrainingPlanActionResult.noActiveGame;
    final player = currentGame.players
        .where((candidate) => candidate.id == playerId)
        .firstOrNull;
    if (player == null) return TrainingPlanActionResult.playerNotFound;
    if (player.agentId != currentGame.agent.id || !player.isRecruited) {
      return TrainingPlanActionResult.notRepresented;
    }
    if (player.isRetired) return TrainingPlanActionResult.unavailable;

    final currentPlan = currentGame.trainingPlanForPlayer(playerId);
    final updatedPlan = currentPlan.copyWith(
      focus: focus,
      intensity: intensity,
    );
    state = currentGame.copyWith(
      trainingPlans: [
        ...currentGame.trainingPlans.where((plan) => plan.playerId != playerId),
        updatedPlan,
      ],
    );
    _scheduleAutoSave();
    return TrainingPlanActionResult.success;
  }

  WeekSimulationSummary? simulateNextWeek() {
    final currentGame = state;
    if (currentGame == null) return null;
    final result = ref.read(gameEngineProvider).simulateOneWeek(currentGame);
    state = result.state;
    _scheduleAutoSave();
    return result.summary;
  }

  void markEmailRead(String emailId) {
    final currentGame = state;
    if (currentGame == null) return;
    state = currentGame.copyWith(
      emails: currentGame.emails
          .map((email) =>
              email.id == emailId ? email.copyWith(isRead: true) : email)
          .toList(growable: false),
    );
    _scheduleAutoSave();
  }

  Future<LoadGameResult> loadLatestGame() async {
    await _saveQueue;
    try {
      final loaded = await ref.read(gameSaveRepositoryProvider).loadLatest();
      if (loaded == null) return LoadGameResult.noSave;
      state = loaded;
      return LoadGameResult.success;
    } on FormatException {
      return LoadGameResult.invalidSave;
    } on IncompatibleSaveException {
      return LoadGameResult.invalidSave;
    } catch (_) {
      return LoadGameResult.failed;
    }
  }

  Future<bool> saveNow() async {
    if (state == null) return false;
    _scheduleAutoSave();
    await _saveQueue;
    return _lastSaveError == null;
  }

  Future<void> waitForPendingSaves() => _saveQueue;

  void _scheduleAutoSave() {
    final snapshot = state;
    if (snapshot == null) return;
    _saveQueue = _saveQueue.then((_) => _writeSnapshot(snapshot));
  }

  Future<void> _writeSnapshot(GameState snapshot) async {
    try {
      await ref.read(gameSaveRepositoryProvider).save(snapshot);
      _lastSaveError = null;
      ref.invalidate(savedCareerSummaryProvider);
    } catch (error) {
      _lastSaveError = error;
    }
  }

  void clearGame() => state = null;
}
