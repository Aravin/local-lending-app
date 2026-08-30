import 'package:equatable/equatable.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';

class PortfolioStats extends Equatable {
  const PortfolioStats({
    required this.totalDisbursedRupees,
    required this.totalCollectedRupees,
    required this.totalOutstandingRupees,
    required this.overdueRatio,
    required this.activeLoanCount,
    required this.overdueCount,
    required this.loansByFrequency,
    required this.dueTodayRupees,
    required this.dueTodayCount,
    required this.pendingApplicationCount,
  });

  final double totalDisbursedRupees;
  final double totalCollectedRupees;
  final double totalOutstandingRupees;
  final double overdueRatio;
  final int activeLoanCount;
  final int overdueCount;
  final Map<RepaymentFrequency, int> loansByFrequency;
  final double dueTodayRupees;
  final int dueTodayCount;
  final int pendingApplicationCount;

  double get collectionRate {
    if (totalDisbursedRupees <= 0) return 0;
    return totalCollectedRupees / totalDisbursedRupees;
  }

  @override
  List<Object?> get props => [
    totalDisbursedRupees,
    totalCollectedRupees,
    totalOutstandingRupees,
    overdueRatio,
    activeLoanCount,
    overdueCount,
    loansByFrequency,
    dueTodayRupees,
    dueTodayCount,
    pendingApplicationCount,
  ];
}
