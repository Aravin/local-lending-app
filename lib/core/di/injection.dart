import 'package:get_it/get_it.dart';
import 'package:local_lending_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:local_lending_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:local_lending_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';

final GetIt getIt = GetIt.instance;

/// Registers all dependencies — call once in main() before runApp().
///
/// Registration order matters — dependencies must be registered
/// before anything that depends on them.
void configureDependencies() {
  _registerCore();
  _registerAuth();
}

void _registerCore() {
  // Core infrastructure
}

void _registerAuth() {
  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt()),
  );

  // Bloc / Cubits
  getIt.registerFactory<AuthCubit>(() => AuthCubit(authRepository: getIt()));
}
