import 'dart:math';

import '../../domain/models/contract.dart';
import '../../domain/models/agency_transaction.dart';
import '../../domain/models/game_email.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/services/scout_candidate_generator.dart';
import '../../domain/services/talent_generator.dart';

class AgencyOfficeWeekResult {
  const AgencyOfficeWeekResult({
    required this.state,
    required this.scoutPayroll,
    required this.salaryCommission,
    required this.talentsDiscovered,
  });

  final GameState state;
  final double scoutPayroll;
  final double salaryCommission;
  final int talentsDiscovered;
}

class AgencyOfficeEngine {
  const AgencyOfficeEngine({
    this.talentGenerator = const TalentGenerator(),
    this.candidateGenerator = const ScoutCandidateGenerator(),
  });

  final TalentGenerator talentGenerator;
  final ScoutCandidateGenerator candidateGenerator;

  AgencyOfficeWeekResult processWeek(
    GameState game, {
    required int nextSeason,
    required int nextWeek,
    required int seed,
  }) {
    final hired = game.hiredScouts;
    final payroll = hired.fold<double>(0, (sum, scout) => sum + scout.salary);
    final commission = _weeklySalaryCommission(game);
    var players = game.players;
    var emails = game.emails;
    var discoveries = 0;
    var availableCount = game.availableTalents.length;
    final maximumTalentPool = max(6, game.office.clientCapacity * 2);
    final absoluteWeek = ((nextSeason - 1) * 50) + nextWeek;
    final transactions = [
      ...game.agencyTransactions,
      if (commission > 0)
        AgencyTransaction(
          id: 'transaction-commission-s$nextSeason-w$nextWeek',
          type: AgencyTransactionType.salaryCommission,
          amount: commission,
          description: 'Weekly client salary commission',
          season: nextSeason,
          week: nextWeek,
        ),
      if (payroll > 0)
        AgencyTransaction(
          id: 'transaction-scout-payroll-s$nextSeason-w$nextWeek',
          type: AgencyTransactionType.scoutPayroll,
          amount: -payroll,
          description:
              'Weekly payroll for ${hired.length} scout${hired.length == 1 ? '' : 's'}',
          season: nextSeason,
          week: nextWeek,
        ),
    ];

    for (final scout in hired) {
      if (availableCount >= maximumTalentPool) break;
      final interval = max(3, 9 - (scout.ability ~/ 12));
      if ((absoluteWeek + _stableHash(scout.id)) % interval != 0) continue;
      final talent = talentGenerator
          .generateForScout(
            count: 1,
            scoutAbility: scout.ability,
            seed: seed ^ _stableHash(scout.id),
            idPrefix: 'scouted-s$nextSeason-w$nextWeek-${scout.id}',
          )
          .single;
      players = [...players, talent];
      emails = [
        GameEmail(
          id: 'email-scout-s$nextSeason-w$nextWeek-${talent.id}',
          type: GameEmailType.world,
          subject: 'New talent: ${talent.name}',
          body:
              '${scout.name} found a ${talent.age}-year-old ${talent.position.label.toLowerCase()} rated ${talent.ability} with ${talent.potential} potential.',
          season: nextSeason,
          week: nextWeek,
          playerId: talent.id,
        ),
        ...emails,
      ];
      discoveries++;
      availableCount++;
    }

    final refreshedScouts = [
      ...game.scouts,
      ...candidateGenerator.replenish(
        existing: game.scouts,
        reputation: game.agent.reputation,
        seed: seed ^ 0x57AFF,
        idPrefix: 'scout-s$nextSeason-w$nextWeek',
      ),
    ];

    return AgencyOfficeWeekResult(
      state: game.copyWith(
        agent: game.agent.copyWith(
          money: game.agent.money + commission - payroll,
        ),
        players: players,
        scouts: refreshedScouts,
        emails: emails,
        agencyTransactions: transactions,
      ),
      scoutPayroll: payroll,
      salaryCommission: commission,
      talentsDiscovered: discoveries,
    );
  }

  double _weeklySalaryCommission(GameState game) {
    final represented = game.representedPlayers
        .where((player) => player.clubId != null && player.salary > 0)
        .map((player) => player.id)
        .toSet();
    final latestContracts = <String, Contract>{};
    for (final contract in game.contracts) {
      if (!represented.contains(contract.playerId) ||
          contract.endSeason < game.currentSeason) {
        continue;
      }
      final current = latestContracts[contract.playerId];
      if (current == null || contract.startSeason >= current.startSeason) {
        latestContracts[contract.playerId] = contract;
      }
    }
    return latestContracts.values.fold<double>(
      0,
      (sum, contract) => sum + contract.weeklySalaryCommission,
    );
  }

  static int _stableHash(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7FFFFFFF;
    }
    return hash;
  }
}
