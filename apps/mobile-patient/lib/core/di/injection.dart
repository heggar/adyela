import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../routing/app_router.dart';

// Services imports (to be created)
// import '../../features/auth/data/datasources/auth_remote_datasource.dart';
// import '../../features/auth/data/repositories/auth_repository_impl.dart';
// import '../../features/auth/domain/repositories/auth_repository.dart';
// import '../../features/auth/domain/usecases/login_usecase.dart';
// import '../../features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

/// Configure dependency injection
Future<void> configureDependencies() async {
  // External dependencies
  await _registerExternal();

  // Core dependencies
  _registerCore();

  // Data sources
  _registerDataSources();

  // Repositories
  _registerRepositories();

  // Use cases
  _registerUseCases();

  // BLoCs
  _registerBlocs();
}

/// Register external dependencies (SharedPreferences, Dio, etc.)
Future<void> _registerExternal() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Hive boxes
  final authBox = await Hive.openBox<String>(AppConfig.authBoxName);
  getIt.registerLazySingleton<Box<String>>(
    () => authBox,
    instanceName: AppConfig.authBoxName,
  );

  final userBox = await Hive.openBox(AppConfig.userBoxName);
  getIt.registerLazySingleton<Box>(
    () => userBox,
    instanceName: AppConfig.userBoxName,
  );

  final settingsBox = await Hive.openBox(AppConfig.settingsBoxName);
  getIt.registerLazySingleton<Box>(
    () => settingsBox,
    instanceName: AppConfig.settingsBoxName,
  );

  final cacheBox = await Hive.openBox(AppConfig.cacheBoxName);
  getIt.registerLazySingleton<Box>(
    () => cacheBox,
    instanceName: AppConfig.cacheBoxName,
  );

  // Dio HTTP client
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl + AppConfig.apiPrefix,
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests
        final authBox = getIt<Box<String>>(instanceName: AppConfig.authBoxName);
        final token = authBox.get(AppConfig.authTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 unauthorized - refresh token
        if (error.response?.statusCode == 401) {
          // TODO: Implement token refresh logic
        }
        return handler.next(error);
      },
    ),
  );

  // Add logging interceptor in debug mode
  if (AppConfig.appVersion.contains('dev') || AppConfig.appVersion.contains('debug')) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
    ));
  }

  getIt.registerLazySingleton<Dio>(() => dio);
}

/// Register core dependencies (router, theme, etc.)
void _registerCore() {
  // Router
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());
}

/// Register data sources
void _registerDataSources() {
  // TODO: Register remote and local data sources
  // Example:
  // getIt.registerLazySingleton<AuthRemoteDataSource>(
  //   () => AuthRemoteDataSourceImpl(dio: getIt()),
  // );
}

/// Register repositories
void _registerRepositories() {
  // TODO: Register repository implementations
  // Example:
  // getIt.registerLazySingleton<AuthRepository>(
  //   () => AuthRepositoryImpl(
  //     remoteDataSource: getIt(),
  //     localDataSource: getIt(),
  //   ),
  // );
}

/// Register use cases
void _registerUseCases() {
  // TODO: Register use cases
  // Example:
  // getIt.registerLazySingleton(() => LoginUseCase(repository: getIt()));
  // getIt.registerLazySingleton(() => LogoutUseCase(repository: getIt()));
}

/// Register BLoCs
void _registerBlocs() {
  // TODO: Register BLoCs as factories (not singletons)
  // Example:
  // getIt.registerFactory(
  //   () => AuthBloc(
  //     loginUseCase: getIt(),
  //     logoutUseCase: getIt(),
  //   ),
  // );
}
