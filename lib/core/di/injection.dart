import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

/// Registers all dependencies — call once in main() before runApp().
///
/// Registration order matters — dependencies must be registered
/// before anything that depends on them.
void configureDependencies() {
  _registerCore();
  // Feature registrations added as features are built:
  // _registerAuth();
  // _registerLoans();
  // _registerRepayments();
  // _registerAdmin();
}

void _registerCore() {
  // TODO: Register Dio client, Firebase instances, secure storage
  // getIt.registerLazySingleton<DioClient>(() => DioClient());
}
