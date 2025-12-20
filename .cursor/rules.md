# Finance Assistant - Development Rules

This document defines the rules, patterns, and conventions that must be followed when developing this application.

---

## 1. Architecture Rules

### 1.1 Clean Architecture Layers

The application follows **Clean Architecture** with strict layer separation:

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION (depends on: Domain)                          │
│  - Screens, Widgets, BLoC                                   │
├─────────────────────────────────────────────────────────────┤
│  DOMAIN (depends on: Nothing)                               │
│  - Entities, UseCases, Repository Interfaces                │
├─────────────────────────────────────────────────────────────┤
│  DATA (depends on: Domain)                                  │
│  - Models, Repository Implementations, DataSources          │
└─────────────────────────────────────────────────────────────┘
```

**Rules:**
- ❌ Domain layer MUST NOT import from Data or Presentation
- ❌ Presentation layer MUST NOT import directly from Data
- ✅ Data layer implements interfaces defined in Domain
- ✅ Presentation layer uses Domain entities and usecases
- ✅ Dependencies flow inward (Presentation → Domain ← Data)

### 1.2 Dependency Injection

- Use **GetIt** for service locator pattern
- Register all dependencies in `lib/core/di/injection_container.dart`
- Use abstract classes/interfaces for all services
- Inject dependencies through constructors

```dart
// ✅ Good
class TransactionRepository {
  final TransactionLocalDataSource _localDataSource;
  final TransactionRemoteDataSource _remoteDataSource;
  
  TransactionRepository(this._localDataSource, this._remoteDataSource);
}

// ❌ Bad - Direct instantiation
class TransactionRepository {
  final _localDataSource = TransactionLocalDataSource();
}
```

---

## 2. State Management Rules (BLoC)

### 2.1 BLoC Structure

Every feature should have:
```
feature/
├── bloc/
│   ├── feature_bloc.dart      # BLoC class
│   ├── feature_event.dart     # Events
│   ├── feature_state.dart     # States
│   └── feature_bloc.g.dart    # Generated (if using freezed)
```

### 2.2 Event Naming Convention

```dart
// ✅ Use past tense or descriptive names
sealed class TransactionEvent {
  const TransactionEvent();
}

class TransactionLoadRequested extends TransactionEvent {}
class TransactionAdded extends TransactionEvent {
  final Transaction transaction;
}
class TransactionDeleted extends TransactionEvent {
  final String id;
}

// ❌ Bad - Imperative names
class LoadTransactions extends TransactionEvent {} 
```

### 2.3 State Naming Convention

```dart
// ✅ Use status-based or descriptive names
sealed class TransactionState {
  const TransactionState();
}

class TransactionInitial extends TransactionState {}
class TransactionLoading extends TransactionState {}
class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
}
class TransactionError extends TransactionState {
  final String message;
}
```

### 2.4 BLoC Rules

- One BLoC per feature/screen
- BLoCs should only emit States, never call UI methods
- Use `Transformers` for debouncing/throttling
- Always handle loading, success, and error states
- Use `emit.forEach` for stream subscriptions

```dart
// ✅ Good BLoC pattern
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactions _getTransactions;
  
  TransactionBloc(this._getTransactions) : super(TransactionInitial()) {
    on<TransactionLoadRequested>(_onLoadRequested);
  }
  
  Future<void> _onLoadRequested(
    TransactionLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    final result = await _getTransactions();
    result.fold(
      (failure) => emit(TransactionError(failure.message)),
      (transactions) => emit(TransactionLoaded(transactions)),
    );
  }
}
```

---

## 3. Data Layer Rules

### 3.1 Models vs Entities

| Aspect | Entity (Domain) | Model (Data) |
|--------|-----------------|--------------|
| Location | `lib/domain/entities/` | `lib/data/models/` |
| Purpose | Business logic representation | Data transfer/storage |
| Dependencies | None (pure Dart) | Can use packages (json, drift) |
| Serialization | No | Yes (toJson, fromJson) |

```dart
// Entity (Domain) - Pure Dart
class Transaction {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  
  const Transaction({...});
}

// Model (Data) - With serialization
@JsonSerializable()
class TransactionModel {
  final String id;
  final double amount;
  final String categoryId;
  final DateTime date;
  
  TransactionModel({...});
  
  factory TransactionModel.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
  
  // Convert to Entity
  Transaction toEntity() => Transaction(...);
  
  // Create from Entity
  factory TransactionModel.fromEntity(Transaction entity) => ...;
}
```

### 3.2 Repository Pattern

```dart
// Domain - Interface
abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions();
  Future<Either<Failure, void>> addTransaction(Transaction transaction);
}

// Data - Implementation
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource _local;
  final TransactionRemoteDataSource _remote;
  
  @override
  Future<Either<Failure, List<Transaction>>> getTransactions() async {
    try {
      // Offline-first: read from local
      final models = await _local.getTransactions();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
```

### 3.3 DataSource Naming

```dart
// Local DataSource
abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<void> cacheTransaction(TransactionModel transaction);
}

// Remote DataSource
abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> fetchTransactions();
  Future<void> uploadTransaction(TransactionModel transaction);
}
```

### 3.4 Use Case Composition

When data from multiple domains needs to be combined (e.g., Budget with Category), use **Use Case Composition** instead of joining at the repository level:

```dart
// ✅ Good - Use Case Composition
class GetBudgetsWithRelationsUseCase {
  final BudgetRepository budgetRepository;
  final CategoryRepository categoryRepository;

  GetBudgetsWithRelationsUseCase({
    required this.budgetRepository,
    required this.categoryRepository,
  });

  Future<Either<Failure, List<Budget>>> call(Params params) async {
    // Step 1: Fetch budgets
    final budgetsResult = await budgetRepository.getBudgets(params.userId);
    
    return budgetsResult.fold(
      (failure) => Left(failure),
      (budgets) async {
        // Step 2: Fetch categories
        final categoriesResult = await categoryRepository.getCategories(params.userId);
        
        return categoriesResult.fold(
          (failure) => Right(budgets), // Graceful degradation
          (categories) {
            // Step 3: Compose with O(1) lookup
            final categoryMap = {for (final c in categories) c.id: c};
            final composedBudgets = budgets.map((b) {
              final category = categoryMap[b.categoryId];
              return category != null ? b.copyWith(category: category) : b;
            }).toList();
            return Right(composedBudgets);
          },
        );
      },
    );
  }
}

// ❌ Avoid - Repository-level joins across domains
class BudgetRepositoryImpl {
  final CategoryRepository _categoryRepo; // Coupling between repositories
  
  Future<List<Budget>> getBudgets() async {
    final budgets = await _local.getBudgets();
    final categories = await _categoryRepo.getCategories(); // Bad!
    // ...
  }
}
```

**When to Use Each Pattern:**
| Pattern | Use When |
|---------|----------|
| Repository Join | Simple 1-to-1 relations within same bounded context |
| **Use Case Composition** | Multiple aggregates, complex relations, cross-domain data |

---

## 4. Presentation Layer Rules

### 4.1 Screen Structure

```dart
class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FeatureBloc>()..add(FeatureLoadRequested()),
      child: const _FeatureView(),
    );
  }
}

class _FeatureView extends StatelessWidget {
  const _FeatureView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureBloc, FeatureState>(
      builder: (context, state) {
        return switch (state) {
          FeatureInitial() => const SizedBox.shrink(),
          FeatureLoading() => const LoadingWidget(),
          FeatureLoaded(:final data) => _buildContent(data),
          FeatureError(:final message) => ErrorWidget(message),
        };
      },
    );
  }
}
```

### 4.2 Widget Rules

- Prefer `const` constructors when possible
- Extract widgets with 50+ lines into separate files
- Use private widgets (prefix `_`) for screen-specific components
- Place reusable widgets in `lib/presentation/widgets/`

```dart
// ✅ Good - Small, focused widget
class BalanceCard extends StatelessWidget {
  final double balance;
  const BalanceCard({super.key, required this.balance});
  // ...
}

// ❌ Bad - Too many responsibilities
class DashboardContent extends StatelessWidget {
  // 500 lines of mixed concerns
}
```

### 4.3 Theme Usage

Always use theme instead of hardcoded values:

```dart
// ✅ Good
Text(
  'Hello',
  style: Theme.of(context).textTheme.titleLarge,
)

Container(
  color: Theme.of(context).colorScheme.surface,
)

// ❌ Bad
Text(
  'Hello',
  style: TextStyle(fontSize: 24, color: Colors.black),
)
```

---

## 5. Naming Conventions

### 5.1 Files

| Type | Convention | Example |
|------|------------|---------|
| Screens | `feature_screen.dart` | `dashboard_screen.dart` |
| Widgets | `widget_name.dart` | `balance_card.dart` |
| BLoC | `feature_bloc.dart` | `transaction_bloc.dart` |
| Models | `feature_model.dart` | `transaction_model.dart` |
| Entities | `feature.dart` | `transaction.dart` |
| UseCases | `action_feature.dart` | `get_transactions.dart` |
| Repositories | `feature_repository.dart` | `transaction_repository.dart` |

### 5.2 Classes

| Type | Convention | Example |
|------|------------|---------|
| Screens | `FeatureScreen` | `DashboardScreen` |
| BLoC | `FeatureBloc` | `TransactionBloc` |
| Events | `FeatureEventName` | `TransactionLoadRequested` |
| States | `FeatureStateName` | `TransactionLoaded` |
| Models | `FeatureModel` | `TransactionModel` |
| Entities | `Feature` | `Transaction` |
| UseCases | `ActionFeature` | `GetTransactions` |

### 5.3 Variables & Methods

```dart
// Variables - camelCase
final transactionList = <Transaction>[];
final isLoading = false;

// Private - prefix with underscore
final _localDataSource = LocalDataSource();

// Methods - camelCase, verb-first
void loadTransactions() {}
Future<void> saveTransaction() async {}
bool isValidAmount(double amount) {}

// Boolean - is/has/can/should prefix
bool isActive;
bool hasError;
bool canSubmit;
```

---

## 6. Error Handling

### 6.1 Failure Classes

```dart
// Base failure
abstract class Failure {
  final String message;
  const Failure(this.message);
}

// Specific failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
```

### 6.2 Either Pattern

Use `dartz` package for functional error handling:

```dart
Future<Either<Failure, Transaction>> getTransaction(String id) async {
  try {
    final result = await _dataSource.getTransaction(id);
    return Right(result.toEntity());
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  }
}
```

---

## 7. Testing Rules

### 7.1 Test File Location

Mirror the `lib/` structure in `test/`:
```
test/
├── data/
│   └── repositories/
│       └── transaction_repository_test.dart
├── domain/
│   └── usecases/
│       └── get_transactions_test.dart
└── presentation/
    └── bloc/
        └── transaction_bloc_test.dart
```

### 7.2 Test Naming

```dart
void main() {
  group('TransactionBloc', () {
    test('emits [Loading, Loaded] when load is successful', () {});
    test('emits [Loading, Error] when load fails', () {});
  });
}
```

---

## 8. Constants Usage

### 8.1 Always Use Constants

```dart
// ✅ Good - Use defined constants
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';

final timeout = AppConstants.apiTimeoutSeconds;
final currency = AppConstants.defaultCurrency;

// ❌ Bad - Magic numbers/strings
final timeout = 30;
final currency = 'USD';
```

### 8.2 Database Constants

```dart
// ✅ Good - Use table/column constants
import 'package:flutter_finance_assistant/core/constants/database_constants.dart';

final tableName = TransactionsTable.tableName;
final amountColumn = TransactionsTable.colAmount;
```

---

## 9. Import Organization

Order imports as follows:

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

// 4. Project imports - Core
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';

// 5. Project imports - Feature
import 'package:flutter_finance_assistant/presentation/screens/dashboard/dashboard_screen.dart';

// 6. Relative imports (same feature only)
import 'widgets/balance_card.dart';
```

---

## 10. Git Commit Rules

### 10.1 Commit Message Format

```
type(scope): subject

body (optional)

footer (optional)
```

### 10.2 Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Formatting (no code change) |
| `refactor` | Code restructuring |
| `test` | Adding tests |
| `chore` | Maintenance tasks |

### 10.3 Examples

```
feat(transactions): add transaction list screen

fix(dashboard): resolve balance calculation error

docs(readme): update installation instructions

refactor(bloc): migrate to sealed classes for states
```
