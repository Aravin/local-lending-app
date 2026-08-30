import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_borrower_applications.dart';

class LoanApplicationsState extends Equatable {
  const LoanApplicationsState({
    this.loading = true,
    this.applications = const [],
    this.errorMessage,
  });

  final bool loading;
  final List<LoanApplication> applications;
  final String? errorMessage;

  LoanApplicationsState copyWith({
    bool? loading,
    List<LoanApplication>? applications,
    String? errorMessage,
  }) {
    return LoanApplicationsState(
      loading: loading ?? this.loading,
      applications: applications ?? this.applications,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [loading, applications, errorMessage];
}

class LoanApplicationsCubit extends Cubit<LoanApplicationsState> {
  LoanApplicationsCubit({required this.getBorrowerApplications})
    : super(const LoanApplicationsState());

  final GetBorrowerApplications getBorrowerApplications;

  Future<void> load(String borrowerId) async {
    emit(state.copyWith(loading: true));
    final result = await getBorrowerApplications(borrowerId);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (applications) =>
          emit(state.copyWith(loading: false, applications: applications)),
    );
  }
}
