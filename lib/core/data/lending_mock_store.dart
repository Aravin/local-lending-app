import 'package:intl/intl.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/core/utils/emi_calculator.dart';
import 'package:local_lending_app/core/utils/payment_allocator.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/delinquency_bucket.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/portfolio_stats.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';

/// In-memory lending ledger used by mock datasources for offline development.
class LendingMockStore {
  LendingMockStore() {
    _seed();
  }

  final List<Loan> loans = [];
  final List<LoanApplication> applications = [];
  final List<RepaymentRecord> repayments = [];
  final List<CustomerProfile> customers = [];
  final Map<String, KycProfile> kycByUserId = {};

  int _seq = 100;

  String _nextId(String prefix) {
    _seq += 1;
    return '$prefix-$_seq';
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _seed() {
    customers.addAll(const [
      CustomerProfile(
        id: 'cust-priya',
        name: 'Priya Sharma',
        phone: '+91 98765 11101',
        email: 'priya.sharma@example.com',
        activeLoansCount: 1,
        lifetimeRepaymentRate: 0.92,
        riskTier: RiskTier.low,
        kycStatus: KycStatus.verified,
        outstandingRupees: 5000,
        address: '12, Gandhi Street, Chennai',
      ),
      CustomerProfile(
        id: 'cust-ramesh',
        name: 'Ramesh Kumar',
        phone: '+91 98765 22202',
        email: 'ramesh.kumar@example.com',
        activeLoansCount: 1,
        lifetimeRepaymentRate: 0.71,
        riskTier: RiskTier.medium,
        kycStatus: KycStatus.verified,
        outstandingRupees: 4200,
        address: '88, Market Road, Madurai',
      ),
      CustomerProfile(
        id: 'cust-anjali',
        name: 'Anjali Devi',
        phone: '+91 98765 33303',
        email: 'anjali.devi@example.com',
        activeLoansCount: 1,
        lifetimeRepaymentRate: 0.88,
        riskTier: RiskTier.low,
        kycStatus: KycStatus.submitted,
        outstandingRupees: 18000,
        address: '4, Lake View, Coimbatore',
      ),
      CustomerProfile(
        id: 'cust-suresh',
        name: 'Suresh Patel',
        phone: '+91 98765 44404',
        email: 'suresh.patel@example.com',
        activeLoansCount: 0,
        lifetimeRepaymentRate: 1,
        riskTier: RiskTier.low,
        kycStatus: KycStatus.verified,
        address: '21, Silk Street, Kanchipuram',
      ),
    ]);

    for (final customer in customers) {
      final submittedAt = customer.kycStatus == KycStatus.pending
          ? null
          : _today.subtract(const Duration(days: 20));
      final verifiedAt = switch (customer.id) {
        'cust-priya' => _today.subtract(const Duration(days: 20)),
        'cust-ramesh' => _today.subtract(const Duration(days: 400)),
        'cust-suresh' => _today.subtract(const Duration(days: 330)),
        _ => null,
      };
      kycByUserId[customer.id] = KycProfile(
        userId: customer.id,
        fullName: customer.name,
        status: customer.kycStatus,
        aadhaarNumber: 'XXXX-XXXX-${customer.id.hashCode.abs() % 9000 + 1000}',
        panNumber: 'ABCDE${customer.id.hashCode.abs() % 9000 + 1000}F',
        address: customer.address,
        idProofUploaded: customer.kycStatus != KycStatus.pending,
        addressProofUploaded: customer.kycStatus == KycStatus.verified,
        submittedAt: submittedAt,
        verifiedAt: customer.kycStatus == KycStatus.verified
            ? verifiedAt
            : null,
      ).resolved(_today);
    }

    loans.add(
      _buildLoan(
        id: 'loan-weekly-priya',
        customer: customers[0],
        purpose: LoanPurpose.business,
        principal: 15000,
        rate: 24,
        frequency: RepaymentFrequency.weekly,
        tenure: 12,
        paidCount: 8,
        overdueCount: 0,
      ),
    );
    loans.add(
      _buildLoan(
        id: 'loan-daily-ramesh',
        customer: customers[1],
        purpose: LoanPurpose.personal,
        principal: 7000,
        rate: 18,
        frequency: RepaymentFrequency.daily,
        tenure: 30,
        paidCount: 18,
        overdueCount: 2,
      ),
    );
    loans.add(
      _buildLoan(
        id: 'loan-monthly-anjali',
        customer: customers[2],
        purpose: LoanPurpose.education,
        principal: 40000,
        rate: 16,
        frequency: RepaymentFrequency.monthly,
        tenure: 6,
        paidCount: 2,
        overdueCount: 0,
      ),
    );
    loans.add(
      _buildLoan(
        id: 'loan-biweekly-closed',
        customer: customers[3],
        purpose: LoanPurpose.emergency,
        principal: 8000,
        rate: 20,
        frequency: RepaymentFrequency.biweekly,
        tenure: 8,
        paidCount: 8,
        overdueCount: 0,
        closed: true,
      ),
    );

    applications.addAll([
      LoanApplication(
        id: 'app-pending-1',
        borrowerId: customers[3].id,
        borrowerName: customers[3].name,
        borrowerPhone: customers[3].phone,
        purpose: LoanPurpose.business,
        requestedAmountRupees: 25000,
        frequency: RepaymentFrequency.weekly,
        tenure: 16,
        requestedAt: _today.subtract(const Duration(days: 1)),
        status: LoanStatus.pending,
        notes: 'Inventory restock for festival season',
      ),
      LoanApplication(
        id: 'app-pending-2',
        borrowerId: customers[1].id,
        borrowerName: customers[1].name,
        borrowerPhone: customers[1].phone,
        purpose: LoanPurpose.emergency,
        requestedAmountRupees: 10000,
        frequency: RepaymentFrequency.daily,
        tenure: 21,
        requestedAt: _today.subtract(const Duration(hours: 8)),
        status: LoanStatus.pending,
      ),
      LoanApplication(
        id: 'app-pending-3',
        borrowerId: customers[2].id,
        borrowerName: customers[2].name,
        borrowerPhone: customers[2].phone,
        purpose: LoanPurpose.education,
        requestedAmountRupees: 15000,
        frequency: RepaymentFrequency.monthly,
        tenure: 4,
        requestedAt: _today.subtract(const Duration(days: 3)),
        status: LoanStatus.pending,
      ),
    ]);

    _refreshCustomerAggregates();
  }

  Loan _buildLoan({
    required String id,
    required CustomerProfile customer,
    required LoanPurpose purpose,
    required double principal,
    required double rate,
    required RepaymentFrequency frequency,
    required int tenure,
    required int paidCount,
    required int overdueCount,
    bool closed = false,
  }) {
    final periodDays = switch (frequency) {
      RepaymentFrequency.daily => 1,
      RepaymentFrequency.weekly => 7,
      RepaymentFrequency.biweekly => 14,
      RepaymentFrequency.monthly => 30,
    };
    final disbursement = _today.subtract(
      Duration(days: periodDays * paidCount),
    );
    var schedule = EmiCalculator.calculate(
      principalRupees: principal,
      annualInterestRatePercent: rate,
      frequency: frequency,
      tenure: tenure,
      disbursementDate: disbursement,
      skipSundays: frequency == RepaymentFrequency.daily,
    );

    final updated = <RepaymentInstallment>[];
    for (final installment in schedule.installments) {
      if (installment.installmentNumber <= paidCount) {
        updated.add(
          installment.copyWith(
            paidAmountRupees: installment.amountRupees,
            status: InstallmentStatus.paid,
            paidDate: installment.dueDate,
          ),
        );
        repayments.add(
          RepaymentRecord(
            id: 'pay-$id-${installment.installmentNumber}',
            loanId: id,
            borrowerId: customer.id,
            installmentNumber: installment.installmentNumber,
            amountRupees: installment.amountRupees,
            method: PaymentMethod.upi,
            paidAt: installment.dueDate,
            reference:
                'UPI${id.hashCode.abs()}${installment.installmentNumber}',
          ),
        );
      } else if (installment.installmentNumber <= paidCount + overdueCount) {
        updated.add(installment.copyWith(status: InstallmentStatus.overdue));
      } else {
        updated.add(installment);
      }
    }
    schedule = RepaymentSchedule(
      principalRupees: schedule.principalRupees,
      annualInterestRatePercent: schedule.annualInterestRatePercent,
      frequency: schedule.frequency,
      tenure: schedule.tenure,
      disbursementDate: schedule.disbursementDate,
      installmentAmountRupees: schedule.installmentAmountRupees,
      totalRepayableRupees: schedule.totalRepayableRupees,
      totalInterestRupees: schedule.totalInterestRupees,
      installments: updated,
    );

    final status = closed
        ? LoanStatus.closed
        : (overdueCount > 0 ? LoanStatus.overdue : LoanStatus.active);

    return Loan(
      id: id,
      borrowerId: customer.id,
      borrowerName: customer.name,
      borrowerPhone: customer.phone,
      purpose: purpose,
      status: status,
      principalRupees: principal,
      annualInterestRatePercent: rate,
      frequency: frequency,
      tenure: tenure,
      appliedAt: disbursement.subtract(const Duration(days: 2)),
      disbursementDate: disbursement,
      closedDate: closed ? _today.subtract(const Duration(days: 3)) : null,
      schedule: schedule,
    );
  }

  List<Loan> getBorrowerLoans(String borrowerId) {
    return loans.where((loan) => loan.borrowerId == borrowerId).toList();
  }

  List<LoanApplication> getBorrowerApplications(String borrowerId) {
    return applications
        .where((application) => application.borrowerId == borrowerId)
        .toList();
  }

  Loan getLoan(String loanId) {
    return loans.firstWhere((loan) => loan.id == loanId);
  }

  LoanApplication applyForLoan(ApplyForLoanParams params) {
    final application = LoanApplication(
      id: _nextId('app'),
      borrowerId: params.borrowerId,
      borrowerName: params.borrowerName,
      borrowerPhone: params.borrowerPhone,
      purpose: params.purpose,
      requestedAmountRupees: params.amountRupees,
      frequency: params.frequency,
      tenure: params.tenure,
      requestedAt: DateTime.now(),
      status: LoanStatus.pending,
      annualInterestRatePercent: params.annualInterestRatePercent,
    );
    applications.insert(0, application);
    return application;
  }

  RepaymentRecord applyPayment({
    required String loanId,
    required String borrowerId,
    required double amountRupees,
    required PaymentMethod method,
    String? notes,
    int? installmentNumber,
  }) {
    final index = loans.indexWhere((loan) => loan.id == loanId);
    if (index < 0) {
      throw StateError('Loan $loanId not found');
    }
    final paidAt = DateTime.now();
    final allocation = allocatePayment(
      loan: loans[index],
      amountRupees: amountRupees,
      paidAt: paidAt,
      installmentNumber: installmentNumber,
      notes: notes,
    );
    loans[index] = allocation.loan;

    final record = RepaymentRecord(
      id: _nextId('pay'),
      loanId: loanId,
      borrowerId: borrowerId,
      installmentNumber: allocation.firstInstallmentNumber,
      amountRupees: amountRupees,
      method: method,
      paidAt: paidAt,
      reference: 'SIM${DateTime.now().millisecondsSinceEpoch}',
      isPartial: allocation.isPartial,
      notes: notes,
    );
    repayments.insert(0, record);
    _refreshCustomerAggregates();
    return record;
  }

  LoanApplication updateApplication(UpdateLoanStatusParams params) {
    final index = applications.indexWhere((a) => a.id == params.applicationId);
    if (index < 0) {
      throw StateError('Application ${params.applicationId} not found');
    }
    final application = applications[index].copyWith(
      status: params.status,
      reviewedAt: DateTime.now(),
      rejectionReason: params.rejectionReason,
      counterOfferPrincipalRupees: params.counterOfferPrincipalRupees,
    );
    applications[index] = application;

    if (params.status == LoanStatus.approved) {
      final principal =
          params.counterOfferPrincipalRupees ??
          application.requestedAmountRupees;
      final loan = _disburse(
        borrowerId: application.borrowerId,
        borrowerName: application.borrowerName,
        borrowerPhone: application.borrowerPhone,
        purpose: application.purpose,
        principal: principal,
        rate: application.annualInterestRatePercent,
        frequency: application.frequency,
        tenure: application.tenure,
        disbursementDate: _today,
      );
      loans.insert(0, loan);
    }
    return application;
  }

  Loan createLoan(CreateLoanParams params) {
    final loan = _disburse(
      borrowerId: params.borrowerId,
      borrowerName: params.borrowerName,
      borrowerPhone: params.borrowerPhone,
      purpose: params.purpose,
      principal: params.principalRupees,
      rate: params.annualInterestRatePercent,
      frequency: params.frequency,
      tenure: params.tenure,
      disbursementDate: params.disbursementDate,
    );
    loans.insert(0, loan);
    _ensureCustomer(params);
    _refreshCustomerAggregates();
    return loan;
  }

  Loan _disburse({
    required String borrowerId,
    required String borrowerName,
    required String? borrowerPhone,
    required LoanPurpose purpose,
    required double principal,
    required double rate,
    required RepaymentFrequency frequency,
    required int tenure,
    required DateTime disbursementDate,
  }) {
    final schedule = EmiCalculator.calculate(
      principalRupees: principal,
      annualInterestRatePercent: rate,
      frequency: frequency,
      tenure: tenure,
      disbursementDate: disbursementDate,
      skipSundays: frequency == RepaymentFrequency.daily,
    );
    return Loan(
      id: _nextId('loan'),
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
      purpose: purpose,
      status: LoanStatus.active,
      principalRupees: principal,
      annualInterestRatePercent: rate,
      frequency: frequency,
      tenure: tenure,
      appliedAt: DateTime.now(),
      disbursementDate: disbursementDate,
      schedule: schedule,
    );
  }

  void _ensureCustomer(CreateLoanParams params) {
    if (customers.any((c) => c.id == params.borrowerId)) return;
    customers.add(
      CustomerProfile(
        id: params.borrowerId,
        name: params.borrowerName,
        phone: params.borrowerPhone ?? '',
        email: '',
        activeLoansCount: 1,
        lifetimeRepaymentRate: 1,
        riskTier: RiskTier.low,
        kycStatus: KycStatus.pending,
      ),
    );
  }

  List<CollectionEntry> collectionSheet(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final entries = <CollectionEntry>[];
    for (final loan in loans.where((l) => l.status.isOpen)) {
      for (final installment in loan.schedule.installments) {
        if (!AppDateUtils.isSameDay(installment.dueDate, day)) continue;
        if (installment.isSettled) continue;
        entries.add(
          CollectionEntry(
            id: '${loan.id}-${installment.installmentNumber}',
            loanId: loan.id,
            borrowerId: loan.borrowerId,
            borrowerName: loan.borrowerName,
            borrowerPhone: loan.borrowerPhone,
            dueAmountRupees: installment.amountRupees,
            dueDate: installment.dueDate,
            status: installment.status == InstallmentStatus.partial
                ? CollectionStatus.partial
                : CollectionStatus.due,
            frequency: loan.frequency,
            installmentNumber: installment.installmentNumber,
            collectedAmountRupees: installment.paidAmountRupees,
          ),
        );
      }
    }
    return entries;
  }

  PortfolioStats portfolioStats() {
    final open = loans.where((l) => l.status.isOpen).toList();
    final disbursed = loans.fold<double>(0, (s, l) => s + l.principalRupees);
    final collected = loans.fold<double>(0, (s, l) => s + l.totalPaidRupees);
    final outstanding = open.fold<double>(0, (s, l) => s + l.outstandingRupees);
    final overdue = loans.where((l) => l.status == LoanStatus.overdue).length;
    final byFreq = <RepaymentFrequency, int>{};
    for (final frequency in RepaymentFrequency.values) {
      byFreq[frequency] = open.where((l) => l.frequency == frequency).length;
    }
    final sheet = collectionSheet(_today);
    final dueToday = sheet.fold<double>(0, (s, e) => s + e.dueAmountRupees);
    return PortfolioStats(
      totalDisbursedRupees: disbursed,
      totalCollectedRupees: collected,
      totalOutstandingRupees: outstanding,
      overdueRatio: open.isEmpty ? 0 : overdue / open.length,
      activeLoanCount: open.length,
      overdueCount: overdue,
      loansByFrequency: byFreq,
      dueTodayRupees: dueToday,
      dueTodayCount: sheet.length,
      pendingApplicationCount: applications
          .where((a) => a.status == LoanStatus.pending)
          .length,
    );
  }

  PortfolioReport portfolioReport() {
    var d1 = 0, a1 = 0.0, d2 = 0, a2 = 0.0, d3 = 0, a3 = 0.0;
    for (final loan in loans.where((l) => l.status.isOpen)) {
      for (final installment in loan.schedule.installments) {
        if (installment.status != InstallmentStatus.overdue) continue;
        final days = AppDateUtils.daysDifference(installment.dueDate, _today);
        if (days <= 7) {
          d1 += 1;
          a1 += installment.outstandingRupees;
        } else if (days <= 30) {
          d2 += 1;
          a2 += installment.outstandingRupees;
        } else {
          d3 += 1;
          a3 += installment.outstandingRupees;
        }
      }
    }
    return PortfolioReport(
      buckets: [
        DelinquencyBucket(
          label: '1–7 days',
          minDays: 1,
          maxDays: 7,
          loanCount: d1,
          amountRupees: a1,
        ),
        DelinquencyBucket(
          label: '8–30 days',
          minDays: 8,
          maxDays: 30,
          loanCount: d2,
          amountRupees: a2,
        ),
        DelinquencyBucket(
          label: '30+ days',
          minDays: 31,
          loanCount: d3,
          amountRupees: a3,
        ),
      ],
      disbursementTrend: _monthlyTrend(
        events: [
          for (final loan in loans)
            if (loan.disbursementDate != null)
              (date: loan.disbursementDate!, amount: loan.principalRupees),
        ],
      ),
      collectionTrend: _monthlyTrend(
        events: [
          for (final record in repayments)
            (date: record.paidAt, amount: record.amountRupees),
        ],
      ),
    );
  }

  List<TrendPoint> _monthlyTrend({
    required List<({DateTime date, double amount})> events,
    int months = 6,
  }) {
    final points = <TrendPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(_today.year, _today.month - i, 1);
      final amount = events
          .where(
            (event) =>
                event.date.year == monthDate.year &&
                event.date.month == monthDate.month,
          )
          .fold<double>(0, (sum, event) => sum + event.amount);
      points.add(
        TrendPoint(
          label: DateFormat.MMM().format(monthDate),
          amountRupees: amount,
        ),
      );
    }
    return points;
  }

  KycProfile getKyc(String userId) {
    return (kycByUserId[userId] ??
            KycProfile(userId: userId, fullName: '', status: KycStatus.pending))
        .resolved();
  }

  List<KycProfile> listKyc() {
    return kycByUserId.values.map((profile) => profile.resolved()).toList();
  }

  KycProfile saveKyc(KycProfile profile) {
    final saved = profile.copyWith(
      status: KycStatus.submitted,
      submittedAt: DateTime.now(),
    );
    kycByUserId[profile.userId] = saved;
    _syncCustomerKyc(profile.userId, KycStatus.submitted);
    return saved;
  }

  KycProfile reviewKyc(ReviewKycParams params) {
    final current = getKyc(params.userId);
    final now = DateTime.now();
    final updated = current.copyWith(
      status: params.status,
      verifiedAt: params.status == KycStatus.verified
          ? now
          : current.verifiedAt,
      rejectionReason: params.rejectionReason,
    );
    kycByUserId[params.userId] = updated;
    _syncCustomerKyc(params.userId, params.status);
    return updated;
  }

  void _syncCustomerKyc(String userId, KycStatus status) {
    final index = customers.indexWhere((customer) => customer.id == userId);
    if (index < 0) return;
    customers[index] = customers[index].copyWith(kycStatus: status);
  }

  void _refreshCustomerAggregates() {
    for (var i = 0; i < customers.length; i++) {
      final customer = customers[i];
      final owned = loans.where((l) => l.borrowerId == customer.id).toList();
      final open = owned.where((l) => l.status.isOpen).toList();
      final repayable = owned.fold<double>(
        0,
        (s, l) => s + l.schedule.totalRepayableRupees,
      );
      final paid = owned.fold<double>(0, (s, l) => s + l.totalPaidRupees);
      customers[i] = CustomerProfile(
        id: customer.id,
        name: customer.name,
        phone: customer.phone,
        email: customer.email,
        activeLoansCount: open.length,
        lifetimeRepaymentRate: repayable <= 0 ? 1 : paid / repayable,
        riskTier: open.any((l) => l.status == LoanStatus.overdue)
            ? RiskTier.medium
            : customer.riskTier,
        kycStatus:
            (kycByUserId[customer.id]?.resolved().status) ?? customer.kycStatus,
        outstandingRupees: open.fold<double>(
          0,
          (s, l) => s + l.outstandingRupees,
        ),
        address: customer.address,
      );
    }
  }
}
