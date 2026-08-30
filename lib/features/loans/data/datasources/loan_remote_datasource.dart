import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_lending_app/core/data/lending_mock_store.dart';
import 'package:local_lending_app/features/admin/data/models/kyc_profile_model.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/loans/data/models/loan_application_model.dart';
import 'package:local_lending_app/features/loans/data/models/loan_model.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

abstract class LoanRemoteDataSource {
  Future<List<LoanModel>> getBorrowerLoans(String borrowerId);

  Future<LoanModel> getLoanDetails(String loanId);

  Future<LoanApplicationModel> applyForLoan(ApplyForLoanParams params);

  Future<List<LoanApplicationModel>> getLoanApplications({
    DateTime? requestedAfter,
  });

  Future<List<LoanApplicationModel>> getBorrowerApplications(String borrowerId);

  Future<List<LoanModel>> getAllLoans();
}

class LoanMockDataSource implements LoanRemoteDataSource {
  LoanMockDataSource(this._store);

  final LendingMockStore _store;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 180));

  @override
  Future<List<LoanModel>> getBorrowerLoans(String borrowerId) async {
    await _wait();
    return _store
        .getBorrowerLoans(borrowerId)
        .map(LoanModel.fromEntity)
        .toList();
  }

  @override
  Future<LoanModel> getLoanDetails(String loanId) async {
    await _wait();
    return LoanModel.fromEntity(_store.getLoan(loanId));
  }

  @override
  Future<LoanApplicationModel> applyForLoan(ApplyForLoanParams params) async {
    await _wait();
    return LoanApplicationModel.fromEntity(_store.applyForLoan(params));
  }

  @override
  Future<List<LoanApplicationModel>> getLoanApplications({
    DateTime? requestedAfter,
  }) async {
    await _wait();
    return _store.applications
        .where(
          (app) =>
              requestedAfter == null ||
              !app.requestedAt.isBefore(requestedAfter),
        )
        .map(LoanApplicationModel.fromEntity)
        .toList();
  }

  @override
  Future<List<LoanApplicationModel>> getBorrowerApplications(
    String borrowerId,
  ) async {
    await _wait();
    final apps = _store.getBorrowerApplications(borrowerId)
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return apps.map(LoanApplicationModel.fromEntity).toList();
  }

  @override
  Future<List<LoanModel>> getAllLoans() async {
    await _wait();
    return _store.getAllLoans().map(LoanModel.fromEntity).toList();
  }
}

class LoanFirestoreDataSource implements LoanRemoteDataSource {
  LoanFirestoreDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _loans =>
      _firestore.collection('loans');

  CollectionReference<Map<String, dynamic>> get _applications =>
      _firestore.collection('loan_applications');

  @override
  Future<List<LoanModel>> getBorrowerLoans(String borrowerId) async {
    final snapshot = await _loans
        .where('borrowerId', isEqualTo: borrowerId)
        .get();
    return snapshot.docs
        .map((doc) => LoanModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<LoanModel> getLoanDetails(String loanId) async {
    final doc = await _loans.doc(loanId).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      throw StateError('Loan $loanId not found');
    }
    return LoanModel.fromJson({...data, 'id': doc.id});
  }

  @override
  Future<LoanApplicationModel> applyForLoan(ApplyForLoanParams params) async {
    await _requireVerifiedKyc(params.borrowerId);
    final created = LoanApplication(
      id: _applications.doc().id,
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
    final model = LoanApplicationModel.fromEntity(created);
    await _applications.doc(created.id).set(model.toJson());
    return model;
  }

  @override
  Future<List<LoanApplicationModel>> getLoanApplications({
    DateTime? requestedAfter,
  }) async {
    Query<Map<String, dynamic>> query = _applications.orderBy(
      'requestedAt',
      descending: true,
    );
    if (requestedAfter != null) {
      query = query.where(
        'requestedAt',
        isGreaterThanOrEqualTo: requestedAfter.toIso8601String(),
      );
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => LoanApplicationModel.fromJson({...doc.data(), 'id': doc.id}),
        )
        .toList();
  }

  @override
  Future<List<LoanApplicationModel>> getBorrowerApplications(
    String borrowerId,
  ) async {
    final snapshot = await _applications
        .where('borrowerId', isEqualTo: borrowerId)
        .get();
    final apps = snapshot.docs
        .map(
          (doc) => LoanApplicationModel.fromJson({...doc.data(), 'id': doc.id}),
        )
        .toList();
    apps.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return apps;
  }

  @override
  Future<List<LoanModel>> getAllLoans() async {
    final snapshot = await _loans.get();
    return snapshot.docs
        .map((doc) => LoanModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<void> _requireVerifiedKyc(String userId) async {
    final doc = await _firestore.collection('kyc').doc(userId).get();
    final data = doc.data();
    if (data == null) {
      throw StateError(KycProfile.lendingRequirementMessage);
    }
    final profile = KycProfileModel.fromJson({
      ...data,
      'userId': userId,
    }).toEntity().resolved();
    if (!profile.allowsLending()) {
      throw StateError(KycProfile.lendingRequirementMessage);
    }
  }
}
