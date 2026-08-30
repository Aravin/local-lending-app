import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/core/utils/emi_calculator.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';

class CalculateEmiParams extends Equatable {
  const CalculateEmiParams({
    required this.principalRupees,
    required this.annualInterestRatePercent,
    required this.frequency,
    required this.tenure,
    required this.disbursementDate,
    this.skipSundays = false,
  });

  final double principalRupees;
  final double annualInterestRatePercent;
  final RepaymentFrequency frequency;
  final int tenure;
  final DateTime disbursementDate;
  final bool skipSundays;

  @override
  List<Object?> get props => [
    principalRupees,
    annualInterestRatePercent,
    frequency,
    tenure,
    disbursementDate,
    skipSundays,
  ];
}

class CalculateEmi {
  const CalculateEmi();

  Either<Failure, RepaymentSchedule> call(CalculateEmiParams params) {
    try {
      final schedule = EmiCalculator.calculate(
        principalRupees: params.principalRupees,
        annualInterestRatePercent: params.annualInterestRatePercent,
        frequency: params.frequency,
        tenure: params.tenure,
        disbursementDate: params.disbursementDate,
        skipSundays: params.skipSundays,
      );
      return Right(schedule);
    } catch (error) {
      return Left(ValidationFailure(error.toString()));
    }
  }
}
