import 'package:equatable/equatable.dart';

class DelinquencyBucket extends Equatable {
  const DelinquencyBucket({
    required this.label,
    required this.minDays,
    required this.loanCount,
    required this.amountRupees,
    this.maxDays,
  });

  final String label;
  final int minDays;
  final int? maxDays;
  final int loanCount;
  final double amountRupees;

  @override
  List<Object?> get props => [label, minDays, maxDays, loanCount, amountRupees];
}

class TrendPoint extends Equatable {
  const TrendPoint({required this.label, required this.amountRupees});

  final String label;
  final double amountRupees;

  @override
  List<Object?> get props => [label, amountRupees];
}

class PortfolioReport extends Equatable {
  const PortfolioReport({
    required this.buckets,
    required this.disbursementTrend,
    required this.collectionTrend,
  });

  final List<DelinquencyBucket> buckets;
  final List<TrendPoint> disbursementTrend;
  final List<TrendPoint> collectionTrend;

  @override
  List<Object?> get props => [buckets, disbursementTrend, collectionTrend];
}
