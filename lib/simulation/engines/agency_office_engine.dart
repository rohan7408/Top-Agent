import '../../domain/models/contract.dart';
import '../../domain/models/agency_transaction.dart';
import '../../domain/models/game_email.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/player.dart';
import '../../domain/services/scout_candidate_generator.dart';
import '../../domain/services/talent_generator.dart';
import '../../domain/services/talent_pool_policy.dart';

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
    this.talentPoolPolicy = const TalentPoolPolicy(),
  });

  final TalentGenerator talentGenerator;
  final ScoutCandidateGenerator candidateGenerator;
  final TalentPoolPolicy talentPoolPolicy;

  AgencyOfficeWeekResult processWeek(
    GameState game, {
    required int nextSeason,
    required int nextWeek,
    required int seed,
  }) {
    final cleanedGame = talentPoolPolicy.clean(game);
    final hired = cleanedGame.hiredScouts;
    final payroll = hired.fold<double>(0, (sum, scout) => sum + scout.salary);
    final commission = _weeklySalaryCommission(cleanedGame);
    var players = cleanedGame.players;
    var emails = cleanedGame.emails;
    var discoveries = 0;
    var availableCount = players
        .where(
          (player) =>
              player.clubId == null &&
              player.agentId == null &&
              !player.isRetired &&
              !player.isRecruited,
        )
        .length;
    final maximumTalentPool = talentPoolPolicy.capacityFor(cleanedGame);
    final absoluteWeek = ((nextSeason - 1) * 50) + nextWeek;
    final transactions = [
      ...cleanedGame.agencyTransactions,
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
      final interval = (22 - (scout.ability ~/ 8)).clamp(10, 18);
      if ((absoluteWeek + _stableHash(scout.id)) % interval != 0) continue;
      final talent = talentGenerator
          .generateForScout(
            count: 1,
            scoutAbility: scout.ability,
            scoutedByScoutId: scout.id,
            maximumAbility: cleanedGame.office.scoutingRatingCap,
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
      ...cleanedGame.scouts,
      ...candidateGenerator.replenish(
        existing: cleanedGame.scouts,
        reputation: cleanedGame.agent.reputation,
        seed: seed ^ 0x57AFF,
        idPrefix: 'scout-s$nextSeason-w$nextWeek',
        officeLevel: cleanedGame.office.level,
      ),
    ];

    return AgencyOfficeWeekResult(
      state: cleanedGame.copyWith(
        agent: cleanedGame.agent.copyWith(
          money: cleanedGame.agent.money + commission - payroll,
          totalSalaryCommissionEarned:
              cleanedGame.agent.totalSalaryCommissionEarned + commission,
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
        .toList(growable: false);
    final representedIds = represented.map((player) => player.id).toSet();
    final latestContracts = <String, Contract>{};
    for (final contract in game.contracts) {
      if (!representedIds.contains(contract.playerId) ||
          contract.endSeason < game.currentSeason) {
        continue;
      }
      final current = latestContracts[contract.playerId];
      if (current == null || contract.startSeason >= current.startSeason) {
        latestContracts[contract.playerId] = contract;
      }
    }
    return represented.fold<double>(
      0,
      (sum, player) {
        final contract = latestContracts[player.id];
        if (contract == null) return sum;
        return sum + (player.salary * contract.salaryCommissionRate);
      },
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
