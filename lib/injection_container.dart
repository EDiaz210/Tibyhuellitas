import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/network/network_info.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/reset_password.dart';
import 'features/auth/domain/usecases/sign_in.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/sign_up.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

/// Configure all dependencies for the application
Future<void> configureDependencies() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Register Supabase Client as singleton
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // Register connectivity service
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // Register NetworkInfo
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<Connectivity>()),
  );

  // Register Auth Remote Data Source
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Register Auth Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  // Register Use Cases
  getIt.registerLazySingleton<SignIn>(
    () => SignIn(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignUp>(
    () => SignUp(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<ResetPassword>(
    () => ResetPassword(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignOut>(
    () => SignOut(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(getIt<AuthRepository>()),
  );

  // Register Auth BLoC
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      signIn: getIt<SignIn>(),
      signUp: getIt<SignUp>(),
      resetPassword: getIt<ResetPassword>(),
      signOut: getIt<SignOut>(),
      getCurrentUser: getIt<GetCurrentUser>(),
    ),
  );

  // Initialize auth services (if available)
  try {
    _setupAuthDependencies();
  } catch (e) {
    print('Error setting up auth dependencies: $e');
  }
}

/// Setup auth-related dependencies
void _setupAuthDependencies() {
  // Auth dependencies will be injected here when needed
  // This is handled through the injectable package configuration
}
