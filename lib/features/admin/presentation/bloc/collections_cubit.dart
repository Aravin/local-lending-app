import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_daily_collection_sheet.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';
import 'package:local_lending_app/features/repayments/domain/usecases/record_collection.dart';

class CollectionsState extends Equatable {
  const CollectionsState({
    this.loading = true,
    this.entries = const [],
    this.collecting = false,
    this.errorMessage,
    this.infoMessage,
  });

  final bool loading;
  final List<CollectionEntry> entries;
  final bool collecting;
  final String? errorMessage;
  final String? infoMessage;

  CollectionsState copyWith({
    bool? loading,
    List<CollectionEntry>? entries,
    bool? collecting,
    String? errorMessage,
    String? infoMessage,
  }) {
    return CollectionsState(
      loading: loading ?? this.loading,
      entries: entries ?? this.entries,
      collecting: collecting ?? this.collecting,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    entries,
    collecting,
    errorMessage,
    infoMessage,
  ];
}

class CollectionsCubit extends Cubit<CollectionsState> {
  CollectionsCubit({
    required this._getDailyCollectionSheet,
    required this._recordCollection,
  }) : super(const CollectionsState());

  final GetDailyCollectionSheet _getDailyCollectionSheet;
  final RecordCollection _recordCollection;

  Future<void> load(DateTime date) async {
    emit(state.copyWith(loading: true));
    final result = await _getDailyCollectionSheet(date);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (entries) => emit(state.copyWith(loading: false, entries: entries)),
    );
  }

  Future<void> collect({
    required String loanId,
    required int installmentNumber,
    required double amount,
    required double collectedAmount,
    required PaymentMethod method,
  }) async {
    if (state.collecting) return;
    emit(state.copyWith(collecting: true));
    final amountPaise = (amount * 100).round();
    final collectedPaise = (collectedAmount * 100).round();
    final idempotencyKey =
        'collection_${loanId}_${installmentNumber}_${amountPaise}_'
        '$collectedPaise';
    final result = await _recordCollection(
      RecordCollectionParams(
        loanId: loanId,
        installmentNumber: installmentNumber,
        amountRupees: amount,
        method: method,
        idempotencyKey: idempotencyKey,
      ),
    );
    if (isClosed) return;
    await result.fold<Future<void>>(
      (failure) async => emit(
        state.copyWith(collecting: false, errorMessage: failure.message),
      ),
      (_) async {
        emit(state.copyWith(collecting: false));
        await load(DateTime.now());
      },
    );
  }
}
