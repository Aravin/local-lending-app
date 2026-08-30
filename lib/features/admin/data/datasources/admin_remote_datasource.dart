import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:local_lending_app/core/data/lending_mock_store.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/core/utils/disbursement_policy.dart';
import 'package:local_lending_app/core/utils/emi_calculator.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/features/admin/data/models/customer_profile_model.dart';
import 'package:local_lending_app/features/admin/data/models/kyc_profile_model.dart';
import 'package:local_lending_app/features/admin/domain/entities/delinquency_bucket.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/portfolio_stats.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/loans/data/models/loan_application_model.dart';
import 'package:local_lending_app/features/loans/data/models/loan_model.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/repayments/data/models/collection_entry_model.dart';
import 'package:local_lending_app/features/repayments/data/models/repayment_record_model.dart';

abstract class AdminRemoteDataSource {
  Future<PortfolioStats> getPortfolioMetrics();

  Future<List<CollectionEntryModel>> getDailyCollectionSheet(DateTime date);

  Future<LoanApplicationModel> updateLoanStatus(UpdateLoanStatusParams params);

  Future<List<CustomerProfileModel>> getCustomers({String? query});

  Future<LoanModel> createLoanForUser(CreateLoanParams params);

  Future<PortfolioReport> getPortfolioReport();

  Future<KycProfileModel> getKycProfile(String userId);

  Future<List<KycProfileModel>> getKycProfiles();

  Future<KycProfileModel> submitKyc(KycProfile profile);

  Future<String> uploadKycDocument({
    required String userId,
    required String documentType,
    required String localPath,
  });

  Future<Uint8List> getKycDocument(String path);

  Future<KycProfileModel> reviewKyc(ReviewKycParams params);
}

class AdminMockDataSource implements AdminRemoteDataSource {
  AdminMockDataSource(this._store);

  final LendingMockStore _store;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 180));

  @override
  Future<PortfolioStats> getPortfolioMetrics() async {
    await _wait();
    return _store.portfolioStats();
  }

  @override
  Future<List<CollectionEntryModel>> getDailyCollectionSheet(
    DateTime date,
  ) async {
    await _wait();
    return _store
        .collectionSheet(date)
        .map(CollectionEntryModel.fromEntity)
        .toList();
  }

  @override
  Future<LoanApplicationModel> updateLoanStatus(
    UpdateLoanStatusParams params,
  ) async {
    await _wait();
    return LoanApplicationModel.fromEntity(_store.updateApplication(params));
  }

  @override
  Future<List<CustomerProfileModel>> getCustomers({String? query}) async {
    await _wait();
    final needle = query?.trim().toLowerCase() ?? '';
    return _store.customers
        .where((customer) {
          if (needle.isEmpty) return true;
          return customer.name.toLowerCase().contains(needle) ||
              customer.phone.toLowerCase().contains(needle) ||
              customer.email.toLowerCase().contains(needle);
        })
        .map(CustomerProfileModel.fromEntity)
        .toList();
  }

  @override
  Future<LoanModel> createLoanForUser(CreateLoanParams params) async {
    await _wait();
    return LoanModel.fromEntity(_store.createLoan(params));
  }

  @override
  Future<PortfolioReport> getPortfolioReport() async {
    await _wait();
    return _store.portfolioReport();
  }

  @override
  Future<KycProfileModel> getKycProfile(String userId) async {
    await _wait();
    return KycProfileModel.fromEntity(_store.getKyc(userId));
  }

  @override
  Future<List<KycProfileModel>> getKycProfiles() async {
    await _wait();
    return _store.listKyc().map(KycProfileModel.fromEntity).toList();
  }

  @override
  Future<KycProfileModel> submitKyc(KycProfile profile) async {
    await _wait();
    return KycProfileModel.fromEntity(_store.saveKyc(profile));
  }

  @override
  Future<String> uploadKycDocument({
    required String userId,
    required String documentType,
    required String localPath,
  }) async {
    await _wait();
    return 'mock://kyc/$userId/$documentType';
  }

  @override
  Future<Uint8List> getKycDocument(String path) {
    throw UnsupportedError('KYC document preview is unavailable in mock mode.');
  }

  @override
  Future<KycProfileModel> reviewKyc(ReviewKycParams params) async {
    await _wait();
    return KycProfileModel.fromEntity(_store.reviewKyc(params));
  }
}

class AdminFirestoreDataSource implements AdminRemoteDataSource {
  AdminFirestoreDataSource(this._firestore, this._storage, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  @override
  Future<PortfolioStats> getPortfolioMetrics() async {
    final results = await Future.wait([
      _allLoans(),
      _firestore.collection('loan_applications').get(),
    ]);
    final loans = results[0] as List<Loan>;
    final applications = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final open = loans.where((loan) => loan.status.isOpen).toList();
    final overdueCount = open
        .where((loan) => loan.status == LoanStatus.overdue)
        .length;
    final todaySheet = _collectionSheetFromLoans(loans, DateTime.now());
    final byFrequency = <RepaymentFrequency, int>{};
    for (final frequency in RepaymentFrequency.values) {
      byFrequency[frequency] = open
          .where((loan) => loan.frequency == frequency)
          .length;
    }
    return PortfolioStats(
      totalDisbursedRupees: loans.fold(
        0,
        (total, loan) => total + loan.principalRupees,
      ),
      totalCollectedRupees: loans.fold(
        0,
        (total, loan) => total + loan.totalPaidRupees,
      ),
      totalOutstandingRupees: open.fold(
        0,
        (total, loan) => total + loan.outstandingRupees,
      ),
      overdueRatio: open.isEmpty ? 0 : overdueCount / open.length,
      activeLoanCount: open.length,
      overdueCount: overdueCount,
      loansByFrequency: byFrequency,
      dueTodayRupees: todaySheet.fold(
        0,
        (total, entry) => total + entry.toEntity().outstandingRupees,
      ),
      dueTodayCount: todaySheet.length,
      pendingApplicationCount: applications.docs
          .map(
            (doc) =>
                LoanApplicationModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .where((application) => application.status == LoanStatus.pending.name)
          .length,
    );
  }

  @override
  Future<List<CollectionEntryModel>> getDailyCollectionSheet(
    DateTime date,
  ) async {
    return _collectionSheetFromLoans(await _allLoans(), date);
  }

  @override
  Future<LoanApplicationModel> updateLoanStatus(UpdateLoanStatusParams params) {
    final applicationRef = _firestore
        .collection('loan_applications')
        .doc(params.applicationId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(applicationRef);
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw StateError('Application ${params.applicationId} not found');
      }
      final current = LoanApplicationModel.fromJson({
        ...data,
        'id': snapshot.id,
      }).toEntity();
      if (!DisbursementPolicy.isAllowedTransition(
        current.status,
        params.status,
      )) {
        throw StateError(
          'Cannot change loan status from ${current.status.name} to ${params.status.name}',
        );
      }

      if (params.status == LoanStatus.fundIssue) {
        if (!current.canReportDisbursementIssue()) {
          throw StateError(
            'The fund-confirmation window has closed for ${params.applicationId}',
          );
        }
        final reportedAt = DateTime.now();
        final updated = current.copyWith(
          status: LoanStatus.fundIssue,
          disbursementIssueReportedAt: reportedAt,
          disbursementIssueReason: params.issueReason,
        );
        final model = LoanApplicationModel.fromEntity(updated);
        DocumentReference<Map<String, dynamic>>? loanRef;
        DocumentSnapshot<Map<String, dynamic>>? loanSnap;
        if (current.loanId != null) {
          loanRef = _firestore.collection('loans').doc(current.loanId);
          loanSnap = await transaction.get(loanRef);
        }
        transaction.set(applicationRef, model.toJson());
        if (loanRef != null && loanSnap != null && loanSnap.exists) {
          final loan = LoanModel.fromJson({
            ...loanSnap.data()!,
            'id': loanSnap.id,
          }).toEntity();
          transaction.set(
            loanRef,
            LoanModel.fromEntity(
              loan.copyWith(
                status: LoanStatus.fundIssue,
                disbursementIssueReportedAt: reportedAt,
                disbursementIssueReason: params.issueReason,
              ),
            ).toJson(),
          );
        }
        return model;
      }

      if (params.status == LoanStatus.disbursed) {
        final disbursementDate = params.disbursementDate ?? DateTime.now();
        final loanId =
            current.loanId ?? _firestore.collection('loans').doc().id;
        final loanRef = _firestore.collection('loans').doc(loanId);
        final loanSnap = await transaction.get(loanRef);
        final principal =
            current.counterOfferPrincipalRupees ??
            current.requestedAmountRupees;
        final Loan loan;
        if (loanSnap.exists && loanSnap.data() != null) {
          final existing = LoanModel.fromJson({
            ...loanSnap.data()!,
            'id': loanSnap.id,
          }).toEntity();
          loan = existing.copyWith(
            status: LoanStatus.disbursed,
            disbursementDate: disbursementDate,
            schedule: EmiCalculator.calculate(
              principalRupees: existing.principalRupees,
              annualInterestRatePercent: existing.annualInterestRatePercent,
              frequency: existing.frequency,
              tenure: existing.tenure,
              disbursementDate: disbursementDate,
              skipSundays: existing.frequency == RepaymentFrequency.daily,
            ),
            clearDisbursementIssue: true,
          );
        } else {
          loan = _buildLoan(
            id: loanId,
            borrowerId: current.borrowerId,
            borrowerName: current.borrowerName,
            borrowerPhone: current.borrowerPhone,
            principalRupees: principal,
            annualInterestRatePercent: current.annualInterestRatePercent,
            tenure: current.tenure,
            frequency: current.frequency,
            disbursementDate: disbursementDate,
            purpose: current.purpose,
            appliedAt: current.requestedAt,
            status: LoanStatus.disbursed,
            applicationId: current.id,
          );
        }
        final updated = current.copyWith(
          status: LoanStatus.disbursed,
          loanId: loan.id,
          disbursementDate: disbursementDate,
          clearDisbursementIssue: true,
        );
        final model = LoanApplicationModel.fromEntity(updated);
        transaction.set(applicationRef, model.toJson());
        transaction.set(loanRef, LoanModel.fromEntity(loan).toJson());
        return model;
      }

      final updated = current.copyWith(
        status: params.status,
        reviewedAt: DateTime.now(),
        rejectionReason: params.rejectionReason,
        counterOfferPrincipalRupees: params.counterOfferPrincipalRupees,
      );
      final model = LoanApplicationModel.fromEntity(updated);
      transaction.set(applicationRef, model.toJson());
      return model;
    });
  }

  @override
  Future<List<CustomerProfileModel>> getCustomers({String? query}) async {
    final results = await Future.wait([
      _firestore.collection('customers').get(),
      _allLoans(),
    ]);
    final snapshot = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final loans = results[1] as List<Loan>;
    final models = snapshot.docs.map((doc) {
      final stored = CustomerProfileModel.fromJson({
        ...doc.data(),
        'id': doc.id,
      });
      final owned = loans.where((loan) => loan.borrowerId == doc.id).toList();
      final active = owned.where((loan) => loan.status.isOpen).toList();
      final totalDue = owned.fold<double>(
        0,
        (total, loan) => total + loan.schedule.totalRepayableRupees,
      );
      final totalPaid = owned.fold<double>(
        0,
        (total, loan) => total + loan.totalPaidRupees,
      );
      return stored.copyWith(
        activeLoansCount: active.length,
        lifetimeRepaymentRate: totalDue == 0 ? 1 : totalPaid / totalDue,
        outstandingRupees: active.fold(
          0,
          (total, loan) => total + loan.outstandingRupees,
        ),
        riskTier: active.any((loan) => loan.status == LoanStatus.overdue)
            ? RiskTier.medium.name
            : stored.riskTier,
      );
    }).toList();
    final needle = query?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return models;
    return models
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(needle) ||
              customer.phone.toLowerCase().contains(needle) ||
              customer.email.toLowerCase().contains(needle),
        )
        .toList();
  }

  @override
  Future<LoanModel> createLoanForUser(CreateLoanParams params) async {
    final ref = _firestore.collection('loans').doc();
    final loan = _buildLoan(
      id: ref.id,
      borrowerId: params.borrowerId,
      borrowerName: params.borrowerName,
      borrowerPhone: params.borrowerPhone,
      principalRupees: params.principalRupees,
      annualInterestRatePercent: params.annualInterestRatePercent,
      tenure: params.tenure,
      frequency: params.frequency,
      disbursementDate: params.disbursementDate,
      purpose: params.purpose,
      appliedAt: DateTime.now(),
    );
    final model = LoanModel.fromEntity(loan);
    await ref.set(model.toJson());
    return model;
  }

  @override
  Future<PortfolioReport> getPortfolioReport() async {
    final results = await Future.wait([
      _allLoans(),
      _firestore.collection('repayments').get(),
    ]);
    final loans = results[0] as List<Loan>;
    final repaymentSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final repayments = repaymentSnapshot.docs
        .map(
          (doc) => RepaymentRecordModel.fromJson({
            ...doc.data(),
            'id': doc.id,
          }).toEntity(),
        )
        .toList();
    final today = DateTime.now();
    var count1 = 0, amount1 = 0.0;
    var count2 = 0, amount2 = 0.0;
    var count3 = 0, amount3 = 0.0;
    for (final loan in loans.where((loan) => loan.status.isOpen)) {
      for (final installment in loan.schedule.installments) {
        if (installment.status != InstallmentStatus.overdue) continue;
        final days = AppDateUtils.daysDifference(installment.dueDate, today);
        if (days <= 7) {
          count1++;
          amount1 += installment.outstandingRupees;
        } else if (days <= 30) {
          count2++;
          amount2 += installment.outstandingRupees;
        } else {
          count3++;
          amount3 += installment.outstandingRupees;
        }
      }
    }
    return PortfolioReport(
      buckets: [
        DelinquencyBucket(
          label: '1-7 days',
          minDays: 1,
          maxDays: 7,
          loanCount: count1,
          amountRupees: amount1,
        ),
        DelinquencyBucket(
          label: '8-30 days',
          minDays: 8,
          maxDays: 30,
          loanCount: count2,
          amountRupees: amount2,
        ),
        DelinquencyBucket(
          label: '30+ days',
          minDays: 31,
          loanCount: count3,
          amountRupees: amount3,
        ),
      ],
      disbursementTrend: _monthlyTrend(
        today: today,
        events: [
          for (final loan in loans)
            if (loan.disbursementDate != null)
              (date: loan.disbursementDate!, amount: loan.principalRupees),
        ],
      ),
      collectionTrend: _monthlyTrend(
        today: today,
        events: [
          for (final repayment in repayments)
            (date: repayment.paidAt, amount: repayment.amountRupees),
        ],
      ),
    );
  }

  @override
  Future<KycProfileModel> getKycProfile(String userId) async {
    final doc = await _firestore.collection('kyc').doc(userId).get();
    final data = doc.data();
    if (data == null) {
      return KycProfileModel(userId: userId, fullName: '', status: 'pending');
    }
    return KycProfileModel.fromJson({...data, 'userId': userId});
  }

  @override
  Future<List<KycProfileModel>> getKycProfiles() async {
    final snapshot = await _firestore.collection('kyc').get();
    return snapshot.docs
        .map(
          (doc) => KycProfileModel.fromJson({...doc.data(), 'userId': doc.id}),
        )
        .toList();
  }

  @override
  Future<KycProfileModel> submitKyc(KycProfile profile) async {
    final result = await _functions.httpsCallable('submitKyc').call({
      'fullName': profile.fullName,
      'aadhaarNumber': profile.aadhaarNumber,
      'panNumber': profile.panNumber,
      'address': profile.address,
      'idProofPath': profile.idProofPath,
      'addressProofPath': profile.addressProofPath,
    });
    final data = result.data;
    if (data is! Map) {
      throw StateError('Invalid KYC submission response');
    }
    return KycProfileModel.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<String> uploadKycDocument({
    required String userId,
    required String documentType,
    required String localPath,
  }) async {
    final extension = localPath.contains('.')
        ? localPath.split('.').last.toLowerCase()
        : 'jpg';
    final uploadedAt = DateTime.now().microsecondsSinceEpoch;
    final ref = _storage.ref(
      'kyc/$userId/$documentType-$uploadedAt.$extension',
    );
    await ref.putFile(File(localPath));
    return ref.fullPath;
  }

  @override
  Future<Uint8List> getKycDocument(String path) async {
    final bytes = await _storage.ref(path).getData(10 * 1024 * 1024);
    if (bytes == null) {
      throw StateError('KYC document $path is empty');
    }
    return bytes;
  }

  @override
  Future<KycProfileModel> reviewKyc(ReviewKycParams params) {
    final kycRef = _firestore.collection('kyc').doc(params.userId);
    final customerRef = _firestore.collection('customers').doc(params.userId);
    return _firestore.runTransaction((transaction) async {
      final kycSnapshot = await transaction.get(kycRef);
      final data = kycSnapshot.data();
      if (!kycSnapshot.exists || data == null) {
        throw StateError('KYC profile ${params.userId} not found');
      }
      final entity = KycProfileModel.fromJson({
        ...data,
        'userId': params.userId,
      }).toEntity();
      if (entity.status != KycStatus.submitted) {
        throw StateError('Only submitted KYC profiles can be reviewed');
      }
      final now = DateTime.now();
      final updated = entity.copyWith(
        status: params.status,
        verifiedAt: params.status == KycStatus.verified
            ? now
            : entity.verifiedAt,
        rejectionReason: params.rejectionReason,
        clearRejectionReason: params.status == KycStatus.verified,
      );
      final model = KycProfileModel.fromEntity(updated);
      final customerSnapshot = await transaction.get(customerRef);
      transaction.set(kycRef, model.toJson());
      transaction.set(
        customerRef,
        customerSnapshot.exists
            ? {'kycStatus': params.status.name}
            : {
                'id': params.userId,
                'name': entity.fullName,
                'phone': '',
                'email': '',
                'activeLoansCount': 0,
                'lifetimeRepaymentRate': 1.0,
                'riskTier': RiskTier.low.name,
                'kycStatus': params.status.name,
                'outstandingRupees': 0.0,
              },
        SetOptions(merge: true),
      );
      return model;
    });
  }

  Future<List<Loan>> _allLoans() async {
    final snapshot = await _firestore.collection('loans').get();
    return snapshot.docs
        .map(
          (doc) => LoanModel.fromJson({...doc.data(), 'id': doc.id}).toEntity(),
        )
        .toList();
  }

  List<CollectionEntryModel> _collectionSheetFromLoans(
    List<Loan> loans,
    DateTime date,
  ) {
    final entries = <CollectionEntryModel>[];
    for (final loan in loans.where((item) => item.status.isCollectable)) {
      for (final installment in loan.schedule.installments) {
        if (!AppDateUtils.isSameDay(installment.dueDate, date) ||
            installment.isSettled) {
          continue;
        }
        entries.add(
          CollectionEntryModel(
            id: '${loan.id}-${installment.installmentNumber}',
            loanId: loan.id,
            borrowerId: loan.borrowerId,
            borrowerName: loan.borrowerName,
            borrowerPhone: loan.borrowerPhone,
            dueAmountRupees: installment.amountRupees,
            dueDate: installment.dueDate,
            status: installment.hasPartialPayment ? 'partial' : 'due',
            frequency: loan.frequency.name,
            installmentNumber: installment.installmentNumber,
            collectedAmountRupees: installment.paidAmountRupees,
          ),
        );
      }
    }
    return entries;
  }

  Loan _buildLoan({
    required String id,
    required String borrowerId,
    required String borrowerName,
    required String? borrowerPhone,
    required double principalRupees,
    required double annualInterestRatePercent,
    required int tenure,
    required RepaymentFrequency frequency,
    required DateTime disbursementDate,
    required LoanPurpose purpose,
    required DateTime appliedAt,
    LoanStatus status = LoanStatus.active,
    String? applicationId,
  }) {
    final schedule = EmiCalculator.calculate(
      principalRupees: principalRupees,
      annualInterestRatePercent: annualInterestRatePercent,
      frequency: frequency,
      tenure: tenure,
      disbursementDate: disbursementDate,
      skipSundays: frequency == RepaymentFrequency.daily,
    );
    return Loan(
      id: id,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
      purpose: purpose,
      status: status,
      principalRupees: principalRupees,
      annualInterestRatePercent: annualInterestRatePercent,
      frequency: frequency,
      tenure: tenure,
      appliedAt: appliedAt,
      disbursementDate: disbursementDate,
      schedule: schedule,
      applicationId: applicationId,
    );
  }

  List<TrendPoint> _monthlyTrend({
    required DateTime today,
    required List<({DateTime date, double amount})> events,
  }) {
    return [
      for (var offset = 5; offset >= 0; offset--)
        _trendPoint(today: today, offset: offset, events: events),
    ];
  }

  TrendPoint _trendPoint({
    required DateTime today,
    required int offset,
    required List<({DateTime date, double amount})> events,
  }) {
    final month = DateTime(today.year, today.month - offset);
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return TrendPoint(
      label: labels[month.month - 1],
      amountRupees: events
          .where(
            (event) =>
                event.date.year == month.year &&
                event.date.month == month.month,
          )
          .fold(0, (total, event) => total + event.amount),
    );
  }
}
