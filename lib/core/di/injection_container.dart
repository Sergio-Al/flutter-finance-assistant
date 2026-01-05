import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_finance_assistant/core/sync/connectivity_service.dart';
import 'package:flutter_finance_assistant/core/sync/sync_manager.dart';
import 'package:flutter_finance_assistant/core/sync/sync_queue_processor.dart';
import 'package:flutter_finance_assistant/core/sync/sync_repository.dart';
import 'package:flutter_finance_assistant/core/sync/sync_status_notifier.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/budget_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/category_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/firebase_service.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/user_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/account_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/recurring_rule_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/receipt_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/repositories/auth_repository_impl.dart';
import 'package:flutter_finance_assistant/data/repositories/budget_repository_impl.dart';
import 'package:flutter_finance_assistant/data/repositories/category_repository_impl.dart';
import 'package:flutter_finance_assistant/data/repositories/sync_repository_impl.dart';
import 'package:flutter_finance_assistant/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_finance_assistant/data/repositories/user_repository_impl.dart';
import 'package:flutter_finance_assistant/domain/repositories/auth_repository.dart';
import 'package:flutter_finance_assistant/domain/repositories/budget_repository.dart';
import 'package:flutter_finance_assistant/domain/repositories/category_repository.dart';
import 'package:flutter_finance_assistant/domain/repositories/transaction_repository.dart';
import 'package:flutter_finance_assistant/domain/repositories/user_repository.dart';
import 'package:flutter_finance_assistant/domain/usecases/auth/auth_usecases.dart';
import 'package:flutter_finance_assistant/domain/usecases/budget/budget_usecases.dart';
import 'package:flutter_finance_assistant/domain/usecases/category/category_usecases.dart';
import 'package:flutter_finance_assistant/domain/usecases/transaction/transaction_usecases.dart';
import 'package:flutter_finance_assistant/domain/usecases/user/user_usecases.dart';
import 'package:flutter_finance_assistant/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/budget/budget_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/category/category_bloc.dart';
import 'package:flutter_finance_assistant/presentation/bloc/sync/sync_bloc_exports.dart';
import 'package:flutter_finance_assistant/presentation/bloc/transaction/transaction_bloc.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // ═══════════════════════════════════════════════════════════════════════════
  // Core - External Dependencies
  // ═══════════════════════════════════════════════════════════════════════════

  // SharedPreferences (required for sync timestamps)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ═══════════════════════════════════════════════════════════════════════════
  // Core - Database & Services
  // ═══════════════════════════════════════════════════════════════════════════

  // Local Drift Database (singleton - lazy initialization)
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Firebase Service (shared across all remote datasources)
  sl.registerLazySingleton<FirebaseService>(() => FirebaseService());

  // Connectivity Service (for monitoring network state)
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  // ═══════════════════════════════════════════════════════════════════════════
  // Data Sources - Remote
  // ═══════════════════════════════════════════════════════════════════════════

  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => AccountRemoteDataSourceImpl(firebaseService: sl()),
  );

  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(firebaseService: sl()),
  );

  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(firebaseService: sl()),
  );

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firebaseService: sl()),
  );

  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(firebaseService: sl()),
  );

  sl.registerLazySingleton<RecurringRuleRemoteDataSource>(
    () => RecurringRuleRemoteDataSourceImpl(firebaseService: sl()),
  );

  sl.registerLazySingleton<ReceiptRemoteDataSource>(
    () => ReceiptRemoteDataSourceImpl(firebaseService: sl()),
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

  // Transaction Repository (offline-first with Drift + Firestore sync)
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      database: sl(),
      remoteDataSource: sl<TransactionRemoteDataSource>(),
    ),
  );

  // Sync Repository (bridges local and remote for sync operations)
  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(
      database: sl(),
      firebaseService: sl(),
      accountRemoteDataSource: sl(),
      categoryRemoteDataSource: sl(),
      transactionRemoteDataSource: sl(),
      budgetRemoteDataSource: sl(),
      recurringRuleRemoteDataSource: sl(),
      receiptRemoteDataSource: sl(),
      prefs: sl(),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Sync Infrastructure
  // ═══════════════════════════════════════════════════════════════════════════

  // Sync Status Notifier (for UI updates)
  sl.registerLazySingleton<SyncStatusNotifier>(() => SyncStatusNotifier());

  // Sync Queue Processor (processes individual sync items)
  sl.registerLazySingleton<SyncQueueProcessor>(
    () => SyncQueueProcessor(syncRepository: sl()),
  );

  // Sync Manager (central coordination of sync operations)
  sl.registerLazySingleton<SyncManager>(
    () => SyncManager(
      connectivityService: sl(),
      queueProcessor: sl(),
      statusNotifier: sl(),
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
  // Use Cases - Transaction
  // ═══════════════════════════════════════════════════════════════════════════

  sl.registerLazySingleton(() => CreateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsByDateRangeUseCase(sl()));
  sl.registerLazySingleton(() => GetSpendingSummaryUseCase(sl()));
  sl.registerLazySingleton(() => WatchRecentTransactionsUseCase(sl()));

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

  sl.registerFactory(
    () => TransactionBloc(
      createTransaction: sl(),
      getTransactionsByDateRange: sl(),
      getSpendingSummary: sl(),
      watchRecentTransactions: sl(),
    ),
  );

  sl.registerFactory(
    () => SyncBloc(syncManager: sl(), connectivityService: sl()),
  );
}
