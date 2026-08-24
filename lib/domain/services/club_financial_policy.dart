import 'dart:math';

import '../models/club.dart';
import '../models/game_state.dart';
import 'club_transfer_strategy.dart';

class ClubFinancialPolicy {
  const ClubFinancialPolicy({
    required this.minimumCashReserve,
    required this.availableTransferFunds,
    required this.weeklyWageCeiling,
    required this.wageHeadroom,
    required this.maxOfferWage,
    required this.financialStress,
    required this.minimumRunwayWeeks,
  });

  final double minimumCashReserve;
  final double availableTransferFunds;
  final double weeklyWageCeiling;
  final double wageHeadroom;
  final double maxOfferWage;
  final double financialStress;
  final double minimumRunwayWeeks;

  bool canFund({
    required Club club,
    required double fee,
    required double weeklyWage,
  }) {
    if (fee < 0 || weeklyWage < 0) return false;
    if (fee > availableTransferFunds || weeklyWage > maxOfferWage) {
      return false;
    }
    final projectedPayroll = club.totalSalary + weeklyWage;
    if (projectedPayroll > weeklyWageCeiling) return false;
    final postDealBalance = club.balance - fee;
    final runway = postDealBalance / max(1, projectedPayroll);
    return runway >= minimumRunwayWeeks;
  }
}

class ClubFinancialPolicyService {
  const ClubFinancialPolicyService();

  ClubFinancialPolicy forClub({
    required GameState game,
    required Club club,
    required ClubTransferStrategy strategy,
  }) {
    final reserveWeeks = 18 - (strategy.ambition * 4);
    final minimumCashReserve = max(
      club.totalSalary * reserveWeeks,
      club.clubValue * 0.008,
    ).toDouble();
    final availableTransferFunds = max(
      0,
      min(club.budget, club.balance - minimumCashReserve),
    ).toDouble();
    final scaleCapacity = (club.clubValue / 50) *
        (0.07 + strategy.prestige * 0.025 + strategy.ambition * 0.025);
    final weeklyWageCeiling = max(
      club.totalSalary * 1.06,
      scaleCapacity,
    ).toDouble();
    final wageHeadroom =
        max(0, weeklyWageCeiling - club.totalSalary).toDouble();
    final roster = game.playersForClub(club.id);
    final highestWage = roster.isEmpty
        ? 0.0
        : roster.map((player) => player.salary).reduce(max);
    final wageStructureLimit = max(
      highestWage * (1.08 + strategy.ambition * 0.30),
      weeklyWageCeiling * (0.07 + strategy.ambition * 0.035),
    ).toDouble();
    final maxOfferWage = min(wageHeadroom, wageStructureLimit).toDouble();
    final runway = club.balance / max(1, club.totalSalary);
    final runwayStress = ((18 - runway) / 18).clamp(0.0, 1.0);
    final budgetStress = club.budget <= 0
        ? 1.0
        : (1 - availableTransferFunds / club.budget).clamp(0.0, 1.0);
    final financialStress =
        (runwayStress * 0.60 + budgetStress * 0.40).clamp(0.0, 1.0);

    return ClubFinancialPolicy(
      minimumCashReserve: minimumCashReserve,
      availableTransferFunds: availableTransferFunds,
      weeklyWageCeiling: weeklyWageCeiling,
      wageHeadroom: wageHeadroom,
      maxOfferWage: maxOfferWage,
      financialStress: financialStress,
      minimumRunwayWeeks: 12,
    );
  }
}
