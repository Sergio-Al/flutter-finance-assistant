import 'package:get_it/get_it.dart';

import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/budget_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/category_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/user_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/repositories/auth_repository_impl.dart';
import 'package:flutter_finance_assistant/data/repositories/budget_repository_impl.dart';
import 'package:flutter_finance_assistant/data/repositories/category_repository_impl.dart';
import 'package:flutter_finance_assistant/data/repositories/user_repository_impl.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';
import 'package:flutter_finance_assistant/domain/repositories/category_repository.dart';
import 'package:flutter_finance_assistant/domain/repositories/user_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/auth/auth_usecases.dart';
import 'package:flutter_finance_assistant/domain/usecases/budget/budget_usecases.dart';
import 'package:flutter_finance_assistant/domain/usecases/category/category_usecases.dart';
import 'package:flutter_finance_assistant/domain/usecases/user/user_usecases.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/category/category_bloc.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // ═══════════════════════════════════════════════════════════════════════════
  // Core - Database & Services
  // ═══════════════════════════════════════════════════════════════════════════

  // Local Drift Database (singleton - lazy initialization)
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Firebase Service (shared across all remote datasources)
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService());

  // ═══════════════════════════════════════════════════════════════════════════
  // Data Sources - Remote
  // ═══════════════════════════════════════════════════════════════════════════

  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(firebaseService: sl()),
  );

  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(firebaseService: sl()),
  );

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firebaseService: sl()),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Repositories
  // ═══════════════════════════════════════════════════════════════════════════

  // Firebase Auth Repository (requires Firebase to be initialized in main.dart)
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());

  // User Repository (offline-first with Drift + Firestore sync)
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      database: sl(),
      remoteDataSource: sl<UserRemoteDataSource>(),
      firebaseService: sl(),
    ),
  );

  // Budget Repository (offline-first with Drift + Firestore sync)
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(database: sl(), remoteDataSource: sl()),
  );

  // Category Repository (offline-first with Drift + Firestore sync)
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      database: sl(),
      remoteDataSource: sl(),
      userRepository: sl(),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Use Cases - Auth
  // ═══════════════════════════════════════════════════════════════════════════

  sl.registerLazySingleton(() => SignInWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => RegisterWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithAppleUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserIdUseCase(sl()));
  sl.registerLazySingleton(() => IsAuthenticatedUseCase(sl()));
  sl.registerLazySingleton(() => WatchAuthStateUseCase(sl()));
  sl.registerLazySingleton(() => SendPasswordResetEmailUseCase(sl()));
  sl.registerLazySingleton(() => SendEmailVerificationUseCase(sl()));
  sl.registerLazySingleton(() => IsEmailVerifiedUseCase(sl()));
  sl.registerLazySingleton(() => IsBiometricAvailableUseCase(sl()));
  sl.registerLazySingleton(() => AuthenticateWithBiometricsUseCase(sl()));

  // ═══════════════════════════════════════════════════════════════════════════
  // Use Cases - User
  // ═══════════════════════════════════════════════════════════════════════════

  sl.registerLazySingleton(() => EnsureUserExistsUseCase(sl()));

  // ═══════════════════════════════════════════════════════════════════════════
  // Use Cases - Budget
  // ═══════════════════════════════════════════════════════════════════════════

  sl.registerLazySingleton(() => CreateBudgetUseCase(sl()));
  sl.registerLazySingleton(() => GetBudgetsUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveBudgetsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBudgetUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBudgetUseCase(sl()));
  sl.registerLazySingleton(() => GetBudgetSummaryUseCase(sl()));
  sl.registerLazySingleton(() => CheckBudgetStatusUseCase(sl()));
  sl.registerLazySingleton(() => WatchBudgetsUseCase(sl()));

  // Use Case Composition - Budgets with Relations
  sl.registerLazySingleton(
    () => GetBudgetsWithRelationsUseCase(
      budgetRepository: sl(),
      categoryRepository: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => WatchBudgetsWithRelationsUseCase(
      budgetRepository: sl(),
      categoryRepository: sl(),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Use Cases - Category
  // ═══════════════════════════════════════════════════════════════════════════

  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesByTypeUseCase(sl()));
  sl.registerLazySingleton(() => GetExpenseCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetIncomeCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => CreateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCategoryUseCase(sl()));
  sl.registerLazySingleton(() => SearchCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => WatchCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => InitializeDefaultCategoriesUseCase(sl()));

  // ═══════════════════════════════════════════════════════════════════════════
  // BLoCs
  // ═══════════════════════════════════════════════════════════════════════════

  sl.registerFactory(
    () => AuthBloc(
      signInWithEmail: sl(),
      registerWithEmail: sl(),
      signInWithGoogle: sl(),
      signInWithApple: sl(),
      signOut: sl(),
      getCurrentUserId: sl(),
      isAuthenticated: sl(),
      watchAuthState: sl(),
      sendPasswordResetEmail: sl(),
      sendEmailVerification: sl(),
      isEmailVerified: sl(),
      isBiometricAvailable: sl(),
      authenticateWithBiometrics: sl(),
      ensureUserExists: sl(),
    ),
  );

  sl.registerFactory(
    () => BudgetBloc(
      createBudget: sl(),
      getBudgetsWithRelations: sl(),
      getActiveBudgets: sl(),
      updateBudget: sl(),
      deleteBudget: sl(),
      getBudgetSummary: sl(),
      checkBudgetStatus: sl(),
      watchBudgetsWithRelations: sl(),
    ),
  );

  sl.registerFactory(
    () => CategoryBloc(
      getCategories: sl(),
      getCategoriesByType: sl(),
      getExpenseCategories: sl(),
      getIncomeCategories: sl(),
      createCategory: sl(),
      updateCategory: sl(),
      searchCategories: sl(),
      watchCategories: sl(),
      initializeDefaults: sl(),
    ),
  );
}
