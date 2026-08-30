import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:local_lending_app/core/data/lending_mock_store.dart';
import 'package:local_lending_app/features/loans/data/models/loan_model.dart';
import 'package:local_lending_app/features/repayments/data/models/collection_entry_model.dart';
import 'package:local_lending_app/features/repayments/data/models/repayment_record_model.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';

abstract class RepaymentRemoteDataSource {
  Future<RepaymentRecordModel> makeRepayment(MakeRepaymentParams params);

  Future<List<RepaymentRecordModel>> getRepaymentHistory({
    String? loanId,
    String? borrowerId,
  });

  Future<RepaymentRecordModel> recordCollection(RecordCollectionParams params);

  Future<List<CollectionEntryModel>> getDailyCollectionSheet(DateTime date);
}

class RepaymentMockDataSource implements RepaymentRemoteDataSource {
  RepaymentMockDataSource(this._store);

  final LendingMockStore _store;

  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 180));

  @override
  Future<RepaymentRecordModel> makeRepayment(MakeRepaymentParams params) async {
    await _wait();
    return RepaymentRecordModel.fromEntity(
      _store.applyPayment(
        loanId: params.loanId,
        borrowerId: params.borrowerId,
        amountRupees: params.amountRupees,
        method: params.method,
        notes: params.notes,
        installmentNumber: params.installmentNumber,
      ),
    );
  }

  @override
  Future<List<RepaymentRecordModel>> getRepaymentHistory({
    String? loanId,
    String? borrowerId,
  }) async {
    await _wait();
    return _store.repayments
        .where(
          (record) =>
              (loanId == null || record.loanId == loanId) &&
              (borrowerId == null || record.borrowerId == borrowerId),
        )
        .map(RepaymentRecordModel.fromEntity)
        .toList();
  }

  @override
  Future<RepaymentRecordModel> recordCollection(
    RecordCollectionParams params,
  ) async {
    await _wait();
    final loan = _store.getLoan(params.loanId);
    return RepaymentRecordModel.fromEntity(
      _store.applyPayment(
        loanId: params.loanId,
        borrowerId: loan.borrowerId,
        amountRupees: params.amountRupees,
        method: params.method,
        notes: params.notes,
        installmentNumber: params.installmentNumber,
      ),
    );
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
}

class RepaymentFirestoreDataSource implements RepaymentRemoteDataSource {
  RepaymentFirestoreDataSource(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _repayments =>
      _firestore.collection('repayments');
  CollectionReference<Map<String, dynamic>> get _loans =>
      _firestore.collection('loans');

  @override
  Future<RepaymentRecordModel> makeRepayment(MakeRepaymentParams _) {
    return Future.error(
      UnsupportedError(
        'Borrower payments require a configured payment gateway.',
      ),
    );
  }

  @override
  Future<List<RepaymentRecordModel>> getRepaymentHistory({
    String? loanId,
    String? borrowerId,
  }) async {
    Query<Map<String, dynamic>> query = _repayments.orderBy(
      'paidAt',
      descending: true,
    );
    if (loanId != null) {
      query = query.where('loanId', isEqualTo: loanId);
    }
    if (borrowerId != null) {
      query = query.where('borrowerId', isEqualTo: borrowerId);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => RepaymentRecordModel.fromJson({...doc.data(), 'id': doc.id}),
        )
        .toList();
  }

  @override
  Future<RepaymentRecordModel> recordCollection(RecordCollectionParams params) {
    return _recordPayment(
      loanId: params.loanId,
      amountRupees: params.amountRupees,
      method: params.method.name,
      notes: params.notes,
      installmentNumber: params.installmentNumber,
      idempotencyKey: params.idempotencyKey,
    );
  }

  @override
  Future<List<CollectionEntryModel>> getDailyCollectionSheet(
    DateTime date,
  ) async {
    final snapshot = await _loans.get();
    final entries = <CollectionEntryModel>[];
    for (final doc in snapshot.docs) {
      final loan = LoanModel.fromJson({...doc.data(), 'id': doc.id}).toEntity();
      if (!loan.status.isOpen) continue;
      for (final installment in loan.schedule.installments) {
        final isDueDate =
            installment.dueDate.year == date.year &&
            installment.dueDate.month == date.month &&
            installment.dueDate.day == date.day;
        if (!isDueDate || installment.isSettled) continue;
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

  Future<RepaymentRecordModel> _recordPayment({
    required String loanId,
    required double amountRupees,
    required String method,
    String? notes,
    int? installmentNumber,
    String? idempotencyKey,
  }) async {
    final result = await _functions.httpsCallable('recordRepayment').call({
      'loanId': loanId,
      'amountRupees': amountRupees,
      'method': method,
      'notes': notes,
      'installmentNumber': installmentNumber,
      'idempotencyKey': idempotencyKey,
    });
    final data = result.data;
    if (data is! Map) {
      throw StateError('Invalid repayment response');
    }
    return RepaymentRecordModel.fromJson(Map<String, dynamic>.from(data));
  }
}
