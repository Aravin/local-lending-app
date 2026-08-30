import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:local_lending_app/core/data/lending_mock_store.dart';
import 'package:local_lending_app/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:local_lending_app/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/domain/usecases/create_loan_for_user.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_customers.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_daily_collection_sheet.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_kyc_profiles.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_portfolio_metrics.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_portfolio_report.dart';
import 'package:local_lending_app/features/admin/domain/usecases/review_kyc.dart';
import 'package:local_lending_app/features/admin/domain/usecases/update_loan_status.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/collections_cubit.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/create_loan_cubit.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/customers_cubit.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/kyc_review_cubit.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/loan_approvals_cubit.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/reports_cubit.dart';
import 'package:local_lending_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:local_lending_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:local_lending_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/dashboard/presentation/bloc/borrower_dashboard_cubit.dart';
import 'package:local_lending_app/features/kyc/presentation/bloc/kyc_cubit.dart';
import 'package:local_lending_app/features/loans/data/datasources/loan_remote_datasource.dart';
import 'package:local_lending_app/features/loans/data/repositories/loan_repository_impl.dart';
import 'package:local_lending_app/features/loans/domain/repositories/loan_repository.dart';
import 'package:local_lending_app/features/loans/domain/usecases/apply_for_loan.dart';
import 'package:local_lending_app/features/loans/domain/usecases/calculate_emi.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_borrower_applications.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_borrower_loans.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_loan_applications.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_loan_details.dart';
import 'package:local_lending_app/features/loans/presentation/bloc/apply_loan_cubit.dart';
import 'package:local_lending_app/features/loans/presentation/bloc/loan_applications_cubit.dart';
import 'package:local_lending_app/features/repayments/data/datasources/repayment_remote_datasource.dart';
import 'package:local_lending_app/features/repayments/data/repositories/repayment_repository_impl.dart';
import 'package:local_lending_app/features/repayments/domain/repositories/repayment_repository.dart';
import 'package:local_lending_app/features/repayments/domain/usecases/get_repayment_history.dart';
import 'package:local_lending_app/features/repayments/domain/usecases/make_repayment.dart';
import 'package:local_lending_app/features/repayments/domain/usecases/record_collection.dart';
import 'package:local_lending_app/features/repayments/presentation/bloc/history_cubit.dart';
import 'package:local_lending_app/features/repayments/presentation/bloc/payment_cubit.dart';

final GetIt getIt = GetIt.instance;

enum LendingDataMode { mock, firebase }

/// Registers all dependencies — call once in main() before runApp().
void configureDependencies({bool useMocks = true}) {
  _registerCore(useMocks: useMocks);
  _registerAuth();
  _registerLending(useMocks: useMocks);
}

void _registerCore({required bool useMocks}) {
  getIt.registerSingleton(
    useMocks ? LendingDataMode.mock : LendingDataMode.firebase,
  );
  getIt.registerLazySingleton<LendingMockStore>(LendingMockStore.new);
}

void _registerAuth() {
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl.new,
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerFactory<AuthCubit>(() => AuthCubit(authRepository: getIt()));
}

void _registerLending({required bool useMocks}) {
  if (useMocks) {
    getIt.registerLazySingleton<LoanRemoteDataSource>(
      () => LoanMockDataSource(getIt()),
    );
    getIt.registerLazySingleton<RepaymentRemoteDataSource>(
      () => RepaymentMockDataSource(getIt()),
    );
    getIt.registerLazySingleton<AdminRemoteDataSource>(
      () => AdminMockDataSource(getIt()),
    );
  } else {
    getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
    getIt.registerLazySingleton<FirebaseFunctions>(
      () => FirebaseFunctions.instanceFor(region: 'asia-south1'),
    );
    getIt.registerLazySingleton<FirebaseStorage>(
      () => FirebaseStorage.instanceFor(
        bucket: 'gs://cape-finance-kyc-265372728533',
      ),
    );
    getIt.registerLazySingleton<LoanRemoteDataSource>(
      () => LoanFirestoreDataSource(getIt()),
    );
    getIt.registerLazySingleton<RepaymentRemoteDataSource>(
      () => RepaymentFirestoreDataSource(getIt(), getIt()),
    );
    getIt.registerLazySingleton<AdminRemoteDataSource>(
      () => AdminFirestoreDataSource(getIt(), getIt(), getIt()),
    );
  }

  getIt.registerLazySingleton<LoanRepository>(
    () => LoanRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<RepaymentRepository>(
    () => RepaymentRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: getIt()),
  );

  getIt.registerFactory(() => GetBorrowerLoans(getIt()));
  getIt.registerFactory(() => GetBorrowerApplications(getIt()));
  getIt.registerFactory(() => GetLoanDetails(getIt()));
  getIt.registerFactory(() => ApplyForLoan(getIt()));
  getIt.registerFactory(CalculateEmi.new);
  getIt.registerFactory(() => GetLoanApplications(getIt()));
  getIt.registerFactory(() => MakeRepayment(getIt()));
  getIt.registerFactory(() => GetRepaymentHistory(getIt()));
  getIt.registerFactory(() => RecordCollection(getIt()));
  getIt.registerFactory(() => GetPortfolioMetrics(getIt()));
  getIt.registerFactory(() => GetDailyCollectionSheet(getIt()));
  getIt.registerFactory(() => UpdateLoanStatus(getIt()));
  getIt.registerFactory(() => GetCustomers(getIt()));
  getIt.registerFactory(() => CreateLoanForUser(getIt()));
  getIt.registerFactory(() => GetPortfolioReport(getIt()));
  getIt.registerFactory(() => GetKycProfiles(getIt()));
  getIt.registerFactory(() => ReviewKyc(getIt()));

  getIt.registerFactory(
    () => BorrowerDashboardCubit(
      getBorrowerLoans: getIt(),
      getBorrowerApplications: getIt(),
      getRepaymentHistory: getIt(),
      adminRepository: getIt(),
    ),
  );
  getIt.registerFactory(
    () => ApplyLoanCubit(applyForLoan: getIt(), calculateEmi: getIt()),
  );
  getIt.registerFactory(
    () => LoanApplicationsCubit(getBorrowerApplications: getIt()),
  );
  getIt.registerFactory(
    () => PaymentCubit(getBorrowerLoans: getIt(), makeRepayment: getIt()),
  );
  getIt.registerFactory(
    () => HistoryCubit(getBorrowerLoans: getIt(), getRepaymentHistory: getIt()),
  );
  getIt.registerFactory(() => KycCubit(adminRepository: getIt()));
  getIt.registerFactory(
    () => AdminDashboardCubit(getPortfolioMetrics: getIt()),
  );
  getIt.registerFactory(() => CustomersCubit(getCustomers: getIt()));
  getIt.registerFactory(
    () => LoanApprovalsCubit(
      getLoanApplications: getIt(),
      updateLoanStatus: getIt(),
    ),
  );
  getIt.registerFactory(
    () => KycReviewCubit(getKycProfiles: getIt(), reviewKyc: getIt()),
  );
  getIt.registerFactory(
    () => CreateLoanCubit(getCustomers: getIt(), createLoanForUser: getIt()),
  );
  getIt.registerFactory(
    () => CollectionsCubit(
      getDailyCollectionSheet: getIt(),
      recordCollection: getIt(),
    ),
  );
  getIt.registerFactory(() => ReportsCubit(getPortfolioReport: getIt()));
}
