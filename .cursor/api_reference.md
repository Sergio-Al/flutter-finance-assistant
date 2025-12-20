# Finance Assistant - API Reference

Quick reference for commonly used classes, methods, and patterns in the codebase.

---

## Table of Contents
- [Core Constants](#core-constants)
- [Data Models](#data-models)
- [Drift Database](#drift-database)
- [DAOs (Data Access Objects)](#daos-data-access-objects)
- [Remote Datasources](#remote-datasources)
- [Sync Repository](#sync-repository)
- [Theme System](#theme-system)
- [Reusable Widgets](#reusable-widgets)
- [Error Handling](#error-handling)
- [Domain Entities](#domain-entities)
- [Repository Interfaces](#repository-interfaces)
- [Repository Implementations](#repository-implementations)
- [Use Cases](#use-cases)
- [Auth BLoC](#auth-bloc)
- [Budget BLoC](#budget-bloc)
- [Category BLoC](#category-bloc)
- [CategorySelector Widget](#categoryselector-widget)
- [IconConstants](#iconconstants)
- [IconPicker Widgets](#iconpicker-widgets)
- [CreateCategorySheet](#createcategorysheet)
- [EnsureUserExistsUseCase](#ensureuserexistsusecase)
- [Use Case Composition](#use-case-composition)
- [Dependency Injection](#dependency-injection)
- [Navigation System](#navigation-system)

---

## Core Constants

### AppConstants
**Location**: `lib/core/constants/app_constants.dart`

```dart
// App Info
AppConstants.appName           // 'Finance Assistant'
AppConstants.appVersion        // '1.0.0'

// API Configuration
AppConstants.apiTimeoutSeconds // 30
AppConstants.apiRetryAttempts  // 3

// AI Services
AppConstants.geminiModel       // 'gemini-pro'
AppConstants.openAiModel       // 'gpt-4'
AppConstants.aiMaxTokens       // 2048
AppConstants.aiTemperature     // 0.7

// Firebase Collections
AppConstants.usersCollection
AppConstants.transactionsCollection
AppConstants.accountsCollection
AppConstants.budgetsCollection
AppConstants.categoriesCollection

// Storage Keys
AppConstants.themeKey
AppConstants.currencyKey
AppConstants.biometricEnabledKey

// Validation
AppConstants.maxTransactionAmount  // 999999999.99
AppConstants.minTransactionAmount  // 0.01
AppConstants.maxDescriptionLength  // 500

// Date Formats
AppConstants.dateFormat        // 'dd/MM/yyyy'
AppConstants.dateTimeFormat    // 'dd/MM/yyyy HH:mm'

// Currency
AppConstants.defaultCurrency       // 'USD'
AppConstants.defaultCurrencySymbol // '$'
```

### Database Constants
**Location**: `lib/core/constants/database_constants.dart`

```dart
// Table Names
TableNames.users
TableNames.accounts
TableNames.categories
TableNames.transactions
TableNames.budgets
TableNames.recurringRules

// Sync Status
SyncStatus.synced
SyncStatus.pending
SyncStatus.failed
SyncStatus.syncing
SyncStatus.conflict

// Transaction Types
TransactionsTable.typeExpense   // 'expense'
TransactionsTable.typeIncome    // 'income'
TransactionsTable.typeTransfer  // 'transfer'

// Account Types
AccountsTable.typeCash
AccountsTable.typeBankAccount
AccountsTable.typeCreditCard
AccountsTable.typeSavings

// Budget Periods
BudgetsTable.periodDaily
BudgetsTable.periodWeekly
BudgetsTable.periodMonthly
BudgetsTable.periodYearly
```

---

## Data Models

**Location**: `lib/data/models/`

Data models handle JSON serialization and conversion between domain entities and external data sources (Firestore, APIs).

### Model Common Methods
All models include these methods:

```dart
// JSON Serialization (via json_serializable)
factory Model.fromJson(Map<String, dynamic> json)
Map<String, dynamic> toJson()

// Domain Entity Conversion
Entity toEntity()
factory Model.fromEntity(Entity entity)

// Firestore Conversion
Map<String, dynamic> toFirestore()
factory Model.fromFirestore(Map<String, dynamic> data, String id)
```

### Available Models

| Model | Entity | File |
|-------|--------|------|
| `UserModel` | `User` | `user_model.dart` |
| `AccountModel` | `Account` | `account_model.dart` |
| `CategoryModel` | `Category` | `category_model.dart` |
| `TransactionModel` | `Transaction` | `transaction_model.dart` |
| `BudgetModel` | `Budget` | `budget_model.dart` |
| `RecurringRuleModel` | `RecurringRule` | `recurring_rule_model.dart` |
| `ReceiptModel` | `Receipt` | `receipt_model.dart` |
| `ChatMessageModel` | `ChatMessage` | `chat_message_model.dart` |
| `ChatSessionModel` | `ChatSession` | `chat_message_model.dart` |

### Import
```dart
import 'package:flutter_finance_assistant/data/models/models.dart';
```

---

## Drift Database

**Location**: `lib/data/datasources/local/`

### AppDatabase
**File**: `app_database.dart`

```dart
// Get database instance (singleton pattern with DI)
final db = AppDatabase();

// Access DAOs
db.usersDao
db.accountsDao
db.categoriesDao
db.transactionsDao
db.budgetsDao
db.recurringRulesDao
db.receiptsDao
db.chatDao
db.syncQueueDao

// Close database
await db.close();
```

### Database Tables
**File**: `tables/tables.dart`

| Table | Purpose |
|-------|---------|
| `Users` | User profiles and preferences |
| `Accounts` | Bank accounts, wallets, cards |
| `Categories` | Transaction categories |
| `Transactions` | All financial transactions |
| `Budgets` | Budget limits per category/period |
| `RecurringRules` | Recurring transaction definitions |
| `Receipts` | OCR-scanned receipt data |
| `ReceiptItems` | Individual items from receipts |
| `ChatMessages` | AI conversation messages |
| `ChatSessions` | Chat conversation sessions |
| `SyncQueue` | Offline sync queue |

### Common Column Conventions
```dart
// All tables have these columns:
id              // TEXT PRIMARY KEY
createdAt       // INTEGER (Unix timestamp)
updatedAt       // INTEGER (Unix timestamp)
syncStatus      // TEXT ('synced', 'pending', 'failed')

// User-owned tables also have:
userId          // TEXT (foreign key to Users)
```

---

## DAOs (Data Access Objects)

**Location**: `lib/data/datasources/local/daos/`

### Import
```dart
import 'package:flutter_finance_assistant/data/datasources/local/daos/daos.dart';
```

### UsersDao
```dart
// CRUD
Future<User?> getUserById(String id)
Future<List<User>> getAllUsers()
Future<void> insertUser(UsersCompanion user)
Future<void> updateUser(UsersCompanion user)
Future<void> deleteUser(String id)

// Reactive
Stream<User?> watchUser(String id)

// Sync
Future<void> updateSyncStatus(String id, String status)
Future<List<User>> getPendingSync()
```

### AccountsDao
```dart
// CRUD
Future<Account?> getAccountById(String id)
Future<List<Account>> getAllAccounts()
Future<List<Account>> getAccountsByUser(String userId)
Future<void> insertAccount(AccountsCompanion account)
Future<void> updateAccount(AccountsCompanion account)
Future<void> deleteAccount(String id)

// Queries
Future<List<Account>> getActiveAccounts(String userId)
Future<List<Account>> getAccountsByType(String userId, String type)
Future<double> getTotalBalance(String userId)

// Reactive
Stream<List<Account>> watchAccountsByUser(String userId)
Stream<double> watchTotalBalance(String userId)

// Sync
Future<void> updateSyncStatus(String id, String status)
Future<List<Account>> getPendingSync()
```

### CategoriesDao
```dart
// CRUD
Future<Category?> getCategoryById(String id)
Future<List<Category>> getAllCategories()
Future<List<Category>> getCategoriesByUser(String? userId)
Future<void> insertCategory(CategoriesCompanion category)
Future<void> updateCategory(CategoriesCompanion category)
Future<void> deleteCategory(String id)

// Queries
Future<List<Category>> getCategoriesByType(String? userId, String type)
Future<List<Category>> getSystemCategories()
Future<List<Category>> getUserCategories(String userId)

// Reactive
Stream<List<Category>> watchCategories(String? userId)

// Sync
Future<void> updateSyncStatus(String id, String status)
Future<List<Category>> getPendingSync()
```

### TransactionsDao
```dart
// CRUD
Future<Transaction?> getTransactionById(String id)
Future<List<Transaction>> getAllTransactions()
Future<List<Transaction>> getTransactionsByUser(String userId)
Future<void> insertTransaction(TransactionsCompanion transaction)
Future<void> updateTransaction(TransactionsCompanion transaction)
Future<void> deleteTransaction(String id)

// Filtering
Future<List<Transaction>> getTransactionsByType(String userId, String type)
Future<List<Transaction>> getTransactionsByCategory(String userId, String categoryId)
Future<List<Transaction>> getTransactionsByAccount(String userId, String accountId)
Future<List<Transaction>> getTransactionsByDateRange(String userId, DateTime start, DateTime end)
Future<List<Transaction>> searchTransactions(String userId, String query)

// Analytics
Future<double> getTotalByType(String userId, String type, DateTime start, DateTime end)
Future<List<Transaction>> getRecentTransactions(String userId, int limit)

// Reactive
Stream<List<Transaction>> watchTransactionsByUser(String userId)
Stream<List<Transaction>> watchRecentTransactions(String userId, int limit)

// Sync
Future<void> updateSyncStatus(String id, String status)
Future<List<Transaction>> getPendingSync()
```

### BudgetsDao
```dart
// CRUD
Future<Budget?> getBudgetById(String id)
Future<List<Budget>> getAllBudgets()
Future<List<Budget>> getBudgetsByUser(String userId)
Future<void> insertBudget(BudgetsCompanion budget)
Future<void> updateBudget(BudgetsCompanion budget)
Future<void> deleteBudget(String id)

// Queries
Future<List<Budget>> getActiveBudgets(String userId)
Future<Budget?> getBudgetByCategory(String userId, String categoryId)
Future<List<Budget>> getExceededBudgets(String userId)

// Updates
Future<void> updateSpentAmount(String id, double amount)
Future<void> addSpending(String id, double amount)

// Reactive
Stream<List<Budget>> watchActiveBudgets(String userId)

// Sync
Future<void> updateSyncStatus(String id, String status)
Future<List<Budget>> getPendingSync()
```

### RecurringRulesDao
```dart
// CRUD
Future<RecurringRule?> getRuleById(String id)
Future<List<RecurringRule>> getAllRules()
Future<List<RecurringRule>> getRulesByUser(String userId)
Future<void> insertRule(RecurringRulesCompanion rule)
Future<void> updateRule(RecurringRulesCompanion rule)
Future<void> deleteRule(String id)

// Queries
Future<List<RecurringRule>> getActiveRules(String userId)
Future<List<RecurringRule>> getDueRules(DateTime date)

// Updates
Future<void> updateLastExecuted(String id, DateTime date)
Future<void> updateNextExecution(String id, DateTime date)

// Reactive
Stream<List<RecurringRule>> watchActiveRules(String userId)

// Sync
Future<void> updateSyncStatus(String id, String status)
Future<List<RecurringRule>> getPendingSync()
```

### ReceiptsDao
```dart
// CRUD
Future<Receipt?> getReceiptById(String id)
Future<List<Receipt>> getAllReceipts()
Future<List<Receipt>> getReceiptsByUser(String userId)
Future<void> insertReceipt(ReceiptsCompanion receipt)
Future<void> updateReceipt(ReceiptsCompanion receipt)
Future<void> deleteReceipt(String id)

// Receipt Items
Future<List<ReceiptItem>> getReceiptItems(String receiptId)
Future<void> insertReceiptItem(ReceiptItemsCompanion item)
Future<void> deleteReceiptItems(String receiptId)

// Queries
Future<List<Receipt>> getUnprocessedReceipts(String userId)
Future<List<Receipt>> getReceiptsByDateRange(String userId, DateTime start, DateTime end)
Future<Receipt?> getReceiptByTransaction(String transactionId)

// Reactive
Stream<List<Receipt>> watchReceiptsByUser(String userId)

// Sync
Future<void> updateSyncStatus(String id, String status)
Future<List<Receipt>> getPendingSync()
```

### ChatDao
```dart
// Sessions
Future<ChatSession?> getSessionById(String id)
Future<List<ChatSession>> getSessionsByUser(String userId)
Future<void> insertSession(ChatSessionsCompanion session)
Future<void> updateSession(ChatSessionsCompanion session)
Future<void> deleteSession(String id)

// Messages
Future<ChatMessage?> getMessageById(String id)
Future<List<ChatMessage>> getMessagesBySession(String sessionId)
Future<void> insertMessage(ChatMessagesCompanion message)
Future<void> deleteMessage(String id)
Future<void> deleteMessagesBySession(String sessionId)

// Queries
Future<List<ChatSession>> getRecentSessions(String userId, int limit)
Future<List<ChatMessage>> getRecentMessages(String sessionId, int limit)
Future<int> getMessageCount(String sessionId)

// Reactive
Stream<List<ChatSession>> watchSessionsByUser(String userId)
Stream<List<ChatMessage>> watchMessagesBySession(String sessionId)

// Sync
Future<void> updateSessionSyncStatus(String id, String status)
Future<void> updateMessageSyncStatus(String id, String status)
Future<List<ChatSession>> getPendingSessionSync()
Future<List<ChatMessage>> getPendingMessageSync()
```

### SyncQueueDao
```dart
// Queue Management
Future<void> enqueue(SyncQueueCompanion item)
Future<void> enqueueOperation(String tableName, String recordId, String operation)
Future<List<SyncQueueEntry>> getPendingItems()
Future<List<SyncQueueEntry>> getPendingItemsByTable(String tableName)
Future<void> markAsProcessing(String id)
Future<void> markAsCompleted(String id)
Future<void> markAsFailed(String id, String error)

// Queries
Future<SyncQueueEntry?> getItem(String id)
Future<int> getPendingCount()
Future<List<SyncQueueEntry>> getFailedItems()
Future<bool> hasUnsyncedChanges()

// Cleanup
Future<void> removeCompletedItems()
Future<void> removeOldItems(Duration maxAge)
Future<void> clearQueue()

// Reactive
Stream<int> watchPendingCount()
Stream<List<SyncQueueEntry>> watchPendingItems()
```

---

## Remote Datasources

**Location**: `lib/data/datasources/remote/`

Remote datasources handle all Firebase Firestore operations. Each datasource provides abstract interface + concrete implementation.

### Import
```dart
import 'package:flutter_finance_assistant/data/datasources/remote/remote.dart';
```

### FirebaseService
**File**: `firebase_service.dart`

Core service providing shared Firebase functionality for all remote datasources.

```dart
class FirebaseService {
  // Authentication
  String? get currentUserId          // Current user's UID or null
  bool get isAuthenticated           // Whether user is logged in
  String get requireUserId           // Get UID or throw AuthenticationException

  // Collection References (user subcollections)
  CollectionReference usersCollection
  CollectionReference accountsCollection(String userId)
  CollectionReference categoriesCollection(String userId)
  CollectionReference transactionsCollection(String userId)
  CollectionReference budgetsCollection(String userId)
  CollectionReference recurringRulesCollection(String userId)
  CollectionReference receiptsCollection(String userId)
  CollectionReference chatSessionsCollection(String userId)
  CollectionReference chatMessagesCollection(String userId, String sessionId)

  // Batch Operations
  WriteBatch batch()
  Future<T> runTransaction<T>(handler)

  // Error Handling
  Future<T> handleFirestoreOperation<T>(operation, {operationName})
}
```

### AccountRemoteDataSource
**File**: `account_remote_datasource.dart`

```dart
// CRUD
Future<List<AccountModel>> getAccounts(String userId)
Future<AccountModel?> getAccountById(String userId, String accountId)
Future<AccountModel> createAccount(String userId, AccountModel account)
Future<AccountModel> updateAccount(String userId, AccountModel account)
Future<void> deleteAccount(String userId, String accountId)

// Streaming
Stream<List<AccountModel>> watchAccounts(String userId)
Stream<AccountModel?> watchAccount(String userId, String accountId)

// Queries
Future<List<AccountModel>> getActiveAccounts(String userId)
Future<List<AccountModel>> getAccountsByType(String userId, String type)

// Balance
Future<void> updateBalance(String userId, String accountId, double newBalance)

// Batch
Future<void> batchUpdateAccounts(String userId, List<AccountModel> accounts)
```

### CategoryRemoteDataSource
**File**: `category_remote_datasource.dart`

```dart
// CRUD
Future<List<CategoryModel>> getCategories(String userId)
Future<CategoryModel?> getCategoryById(String userId, String categoryId)
Future<CategoryModel> createCategory(String userId, CategoryModel category)
Future<CategoryModel> updateCategory(String userId, CategoryModel category)
Future<void> deleteCategory(String userId, String categoryId)

// Streaming
Stream<List<CategoryModel>> watchCategories(String userId)

// Queries
Future<List<CategoryModel>> getCategoriesByType(String userId, String type)
Future<List<CategoryModel>> getSubcategories(String userId, String parentId)
```

### TransactionRemoteDataSource
**File**: `transaction_remote_datasource.dart`

```dart
// CRUD
Future<List<TransactionModel>> getTransactions(String userId)
Future<TransactionModel?> getTransactionById(String userId, String transactionId)
Future<TransactionModel> createTransaction(String userId, TransactionModel transaction)
Future<TransactionModel> updateTransaction(String userId, TransactionModel transaction)
Future<void> deleteTransaction(String userId, String transactionId)

// Streaming
Stream<List<TransactionModel>> watchTransactions(String userId)
Stream<List<TransactionModel>> watchRecentTransactions(String userId, {int limit})

// Queries
Future<List<TransactionModel>> getTransactionsByDateRange(userId, startDate, endDate)
Future<List<TransactionModel>> getTransactionsByCategory(userId, categoryId)
Future<List<TransactionModel>> getTransactionsByAccount(userId, accountId)
Future<List<TransactionModel>> getTransactionsByType(userId, type)

// Batch
Future<void> batchCreateTransactions(userId, List<TransactionModel>)
Future<void> batchDeleteTransactions(userId, List<String> transactionIds)
```

### BudgetRemoteDataSource
**File**: `budget_remote_datasource.dart`

```dart
// CRUD
Future<List<BudgetModel>> getBudgets(String userId)
Future<BudgetModel?> getBudgetById(String userId, String budgetId)
Future<BudgetModel> createBudget(String userId, BudgetModel budget)
Future<BudgetModel> updateBudget(String userId, BudgetModel budget)
Future<void> deleteBudget(String userId, String budgetId)

// Streaming
Stream<List<BudgetModel>> watchBudgets(String userId)
Stream<List<BudgetModel>> watchActiveBudgets(String userId)

// Queries
Future<List<BudgetModel>> getActiveBudgets(String userId)
Future<BudgetModel?> getBudgetByCategory(userId, categoryId)

// Spending
Future<void> updateSpentAmount(userId, budgetId, double amount)
Future<void> addSpending(userId, budgetId, double amount)
```

### RecurringRuleRemoteDataSource
**File**: `recurring_rule_remote_datasource.dart`

```dart
// CRUD
Future<List<RecurringRuleModel>> getRules(String userId)
Future<RecurringRuleModel?> getRuleById(String userId, String ruleId)
Future<RecurringRuleModel> createRule(String userId, RecurringRuleModel rule)
Future<RecurringRuleModel> updateRule(String userId, RecurringRuleModel rule)
Future<void> deleteRule(String userId, String ruleId)

// Streaming
Stream<List<RecurringRuleModel>> watchRules(String userId)

// Queries
Future<List<RecurringRuleModel>> getActiveRules(String userId)
Future<List<RecurringRuleModel>> getDueRules(String userId, DateTime date)

// Updates
Future<void> updateLastExecuted(userId, ruleId, DateTime date)
Future<void> updateNextExecution(userId, ruleId, DateTime date)
Future<void> deactivateRule(String userId, String ruleId)

// Batch
Future<void> batchUpdateNextExecution(userId, Map<String, DateTime> ruleNextDates)
```

### ReceiptRemoteDataSource
**File**: `receipt_remote_datasource.dart`

```dart
// CRUD
Future<List<ReceiptModel>> getReceipts(String userId)
Future<ReceiptModel?> getReceiptById(String userId, String receiptId)
Future<ReceiptModel> createReceipt(String userId, ReceiptModel receipt)
Future<ReceiptModel> updateReceipt(String userId, ReceiptModel receipt)
Future<void> deleteReceipt(String userId, String receiptId)

// Streaming
Stream<List<ReceiptModel>> watchReceipts(String userId)

// Queries
Future<List<ReceiptModel>> getUnprocessedReceipts(String userId)
Future<ReceiptModel?> getReceiptByTransaction(userId, transactionId)

// Image Upload
Future<String> uploadReceiptImage(userId, receiptId, imagePath)
Future<void> deleteReceiptImage(String imageUrl)

// OCR Results
Future<void> updateOcrResults(userId, receiptId, ocrData)
Future<void> linkToTransaction(userId, receiptId, transactionId)
```

### ChatRemoteDataSource
**File**: `chat_remote_datasource.dart`

```dart
// Sessions
Future<List<ChatSessionModel>> getSessions(String userId)
Future<ChatSessionModel?> getSessionById(userId, sessionId)
Future<ChatSessionModel> createSession(userId, ChatSessionModel)
Future<ChatSessionModel> updateSession(userId, ChatSessionModel)
Future<void> deleteSession(userId, sessionId)

// Messages
Future<List<ChatMessageModel>> getMessages(userId, sessionId)
Future<ChatMessageModel> addMessage(userId, sessionId, ChatMessageModel)
Future<void> deleteMessage(userId, sessionId, messageId)

// Streaming
Stream<List<ChatSessionModel>> watchSessions(String userId)
Stream<List<ChatMessageModel>> watchMessages(userId, sessionId)
```

---

## Sync Repository

**Location**: `lib/data/repositories/sync_repository_impl.dart`

### SyncRepositoryImpl
Bridges local Drift database (DAOs) with Firebase Firestore (remote datasources) for offline-first sync functionality.

### Constructor Dependencies
```dart
SyncRepositoryImpl({
  required AppDatabase database,
  required FirebaseService firebaseService,
  required AccountRemoteDataSource accountRemoteDataSource,
  required CategoryRemoteDataSource categoryRemoteDataSource,
  required TransactionRemoteDataSource transactionRemoteDataSource,
  required BudgetRemoteDataSource budgetRemoteDataSource,
  required RecurringRuleRemoteDataSource recurringRuleRemoteDataSource,
  required ReceiptRemoteDataSource receiptRemoteDataSource,
  required SharedPreferences prefs,
})
```

### Sync Queue Operations
```dart
// Queue Statistics
Future<int> getPendingItemCount()
Future<int> getFailedItemCount()

// Queue Items
Future<List<SyncQueueItem>> getPendingItems({int? limit})
Future<List<SyncQueueItem>> getItemsByTable(String tableName)

// Queue Management
Future<void> addToQueue({tableName, recordId, operation, payload})
Future<void> markItemProcessed(String itemId)
Future<void> incrementRetryCount(String itemId, String errorMessage)
Future<void> resetFailedItems()
Future<void> clearQueue()
```

### Remote (Firestore) Operations
```dart
// Push/Pull
Future<void> pushToRemote({tableName, recordId, data, isNew})
Future<void> deleteFromRemote({tableName, recordId})
Future<Map<String, dynamic>?> fetchFromRemote({tableName, recordId})
Future<List<Map<String, dynamic>>> pullChangesFromRemote({tableName, lastSyncTime})

// Conflict Detection
Future<bool> checkRemoteConflict({tableName, recordId, localUpdatedAt})
```

### Local (Drift) Operations
```dart
// CRUD
Future<void> updateLocal({tableName, recordId, data})
Future<void> deleteLocal({tableName, recordId})

// Sync Status
Future<void> updateLocalSyncStatus({tableName, recordId, status})
Future<List<Map<String, dynamic>>> getLocalPendingRecords(String tableName)

// Sync Time Tracking (SharedPreferences)
Future<DateTime?> getLastSyncTime(String tableName)
Future<void> updateLastSyncTime(String tableName, DateTime time)
```

### Supported Tables
The repository handles these tables:
- `accounts` - Financial accounts
- `categories` - Transaction categories
- `transactions` - Financial transactions
- `budgets` - Budget limits
- `recurring_rules` - Recurring transaction schedules
- `receipts` - OCR receipt data

### Usage Example
```dart
// Get pending sync items
final pendingItems = await syncRepository.getPendingItems(limit: 50);

// Process each item
for (final item in pendingItems) {
  try {
    await syncRepository.pushToRemote(
      tableName: item.tableName,
      recordId: item.recordId,
      data: jsonDecode(item.payload),
      isNew: item.operation == 'create',
    );
    await syncRepository.markItemProcessed(item.id);
    await syncRepository.updateLocalSyncStatus(
      tableName: item.tableName,
      recordId: item.recordId,
      status: SyncStatus.synced,
    );
  } catch (e) {
    await syncRepository.incrementRetryCount(item.id, e.toString());
  }
}

// Pull remote changes
final lastSync = await syncRepository.getLastSyncTime('accounts');
final remoteChanges = await syncRepository.pullChangesFromRemote(
  tableName: 'accounts',
  lastSyncTime: lastSync,
);
for (final change in remoteChanges) {
  await syncRepository.updateLocal(
    tableName: 'accounts',
    recordId: change['id'],
    data: change,
  );
}
await syncRepository.updateLastSyncTime('accounts', DateTime.now());
```

---

## Theme System

### AppTheme
**Location**: `lib/core/themes/app_theme.dart`

```dart
// Get theme data
AppTheme.lightTheme  // ThemeData for light mode
AppTheme.darkTheme   // ThemeData for dark mode

// Primary Colors
AppTheme.primaryLight    // Color(0xFF2E7D6F)
AppTheme.primaryDark     // Color(0xFF4DB6A4)

// Status Colors
AppTheme.success         // Color(0xFF4CAF50) - Green
AppTheme.warning         // Color(0xFFFFC107) - Amber
AppTheme.error           // Color(0xFFE53935) - Red
AppTheme.info            // Color(0xFF2196F3) - Blue

// Transaction Colors
AppTheme.income          // Color(0xFF52B788) - Green
AppTheme.expense         // Color(0xFFEF5350) - Red
AppTheme.transfer        // Color(0xFF42A5F5) - Blue

// Helper Methods
AppTheme.getChartColor(int index)              // Get color for charts
AppTheme.getTransactionColor(String type)      // Get color by type
AppTheme.getBudgetStatusColor(double percent)  // Get status color
```

### Theme Access in Widgets

```dart
// In build method
final theme = Theme.of(context);
final isDark = theme.brightness == Brightness.dark;
final colorScheme = theme.colorScheme;
final textTheme = theme.textTheme;

// Text styles
textTheme.displayLarge
textTheme.headlineMedium
textTheme.titleLarge
textTheme.bodyMedium
textTheme.labelSmall

// Colors
colorScheme.primary
colorScheme.secondary
colorScheme.surface
colorScheme.error
colorScheme.onPrimary
colorScheme.onSurface
```

---

## Reusable Widgets

### GlassCard
**Location**: `lib/presentation/widgets/glass_card.dart`

```dart
GlassCard(
  child: Widget,              // Required - content
  padding: EdgeInsets?,       // Default: EdgeInsets.all(16)
  height: double?,            // Optional fixed height
  width: double?,             // Optional fixed width
  onTap: VoidCallback?,       // Optional tap handler
  isDashed: bool,             // Default: false - dashed border
  borderRadius: BorderRadius?, // Default: circular(16)
)
```

### Dashboard Widgets
**Location**: `lib/presentation/screens/dashboard/widgets/`

```dart
// AI Search Bar
AiSearchBar(
  controller: TextEditingController?,
  onSubmitted: ValueChanged<String>?,
  onVoiceTap: VoidCallback?,
)

// Balance Card
BalanceCard(
  balance: double,
  changeAmount: double,
  changePercent: double,
  isPositive: bool,
  onTap: VoidCallback?,
)

// Budget Card
BudgetCard(
  spent: double,
  total: double,
  savingsMessage: String?,
  onTap: VoidCallback?,
)

// Anomaly Alert
AnomalyAlertCard(
  title: String,
  description: String,
  amount: double,
  merchant: String,
  actionText: String,
  onActionTap: VoidCallback?,
)

// Recent Transactions
RecentTransactionsCard(
  transactions: List<TransactionItem>?,
  onSeeAllTap: VoidCallback?,
)

// Categories Progress
CategoriesProgressCard(
  categories: List<CategoryBudget>?,
  onMoreTap: VoidCallback?,
)
```

---

## Route Names

```dart
RouteNames.splash           // '/'
RouteNames.onboarding       // '/onboarding'
RouteNames.login            // '/login'
RouteNames.register         // '/register'
RouteNames.home             // '/home'
RouteNames.dashboard        // '/dashboard'
RouteNames.transactions     // '/transactions'
RouteNames.addTransaction   // '/add-transaction'
RouteNames.analytics        // '/analytics'
RouteNames.chat             // '/chat'
RouteNames.settings         // '/settings'
RouteNames.budgets          // '/budgets'
RouteNames.receiptScanner   // '/receipt-scanner'
```

---

## Messages

### Error Messages
```dart
ErrorMessages.networkError
ErrorMessages.serverError
ErrorMessages.authError
ErrorMessages.transactionFailed
ErrorMessages.aiServiceUnavailable
ErrorMessages.ocrFailed
ErrorMessages.budgetExceeded
```

### Success Messages
```dart
SuccessMessages.transactionAdded
SuccessMessages.transactionDeleted
SuccessMessages.budgetCreated
SuccessMessages.receiptScanned
SuccessMessages.dataExported
```

---

## Asset Paths

```dart
// Images
AssetPaths.logoPath           // 'assets/images/logo.png'
AssetPaths.emptyState         // 'assets/images/empty_state.png'

// Animations (Lottie)
AssetPaths.loadingAnimation   // 'assets/animations/loading.json'
AssetPaths.successAnimation   // 'assets/animations/success.json'

// ML Models
AssetPaths.categorizationModel // 'assets/models/categorization_model.tflite'
```

---

## Default Categories

```dart
// Expense Categories (from DefaultCategories)
'Food & Dining'      // icon: restaurant, color: 0xFFFF6B6B
'Transportation'     // icon: directions_car, color: 0xFF4ECDC4
'Shopping'           // icon: shopping_bag, color: 0xFFFFE66D
'Entertainment'      // icon: movie, color: 0xFF95E1D3
'Bills & Utilities'  // icon: receipt_long, color: 0xFFF38181
'Health & Medical'   // icon: medical_services, color: 0xFFAA96DA
'Groceries'          // icon: local_grocery_store, color: 0xFF80ED99

// Income Categories
'Salary'             // icon: work, color: 0xFF52B788
'Freelance'          // icon: computer, color: 0xFF3D5A80
'Investments'        // icon: trending_up, color: 0xFF06D6A0
```

---

## Common Imports

```dart
// Core
import 'package:flutter_finance_assistant/core/constants/app_constants.dart';
import 'package:flutter_finance_assistant/core/constants/database_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';

// Presentation
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';
import 'package:flutter_finance_assistant/presentation/screens/dashboard/dashboard.dart';

// State Management
import 'package:flutter_bloc/flutter_bloc.dart';

// Functional Programming
import 'package:dartz/dartz.dart';

// Errors
import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/core/errors/exceptions.dart';

// Domain
import 'package:flutter_finance_assistant/domain/entities/entities.dart';
import 'package:flutter_finance_assistant/domain/repositories/repositories.dart';

// Data - Models
import 'package:flutter_finance_assistant/data/models/models.dart';

// Data - Local (Drift)
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/local/daos/daos.dart';

// Data - Remote (Firebase)
import 'package:flutter_finance_assistant/data/datasources/remote/remote.dart';

// Sync
import 'package:flutter_finance_assistant/core/sync/sync.dart';
```

---

## Error Handling

### Failures (for Either<Failure, T>)
**Location**: `lib/core/errors/failures.dart`

```dart
// Base class
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic originalError;
}

// Server/Network
ServerFailure(message:, statusCode:)
NetworkFailure()                  // 'No internet connection'
TimeoutFailure()                  // 'Request timed out'

// Cache/Local
CacheFailure()                    // 'Failed to access local storage'
DatabaseFailure(message:)

// Authentication
AuthenticationFailure()           // 'Authentication required'
InvalidCredentialsFailure()       // 'Invalid email or password'
EmailAlreadyInUseFailure()        // 'This email is already registered'
WeakPasswordFailure()             // 'Password is too weak'
AccountDisabledFailure()
TooManyRequestsFailure()
BiometricFailure()

// Validation
ValidationFailure(message:, fieldErrors:)
NotFoundFailure(resourceType:, resourceId:)
PermissionFailure()

// Sync
SyncFailure(message:, failedCount:, totalCount:)
ConflictFailure(localVersion:, remoteVersion:)

// AI/ML
AIServiceFailure(message:, model:)
OCRFailure()
MLModelFailure(message:, modelName:)

// Storage
UploadFailure(message:, fileName:)
DownloadFailure(message:, fileName:)

// Generic
UnexpectedFailure()
CancelledFailure()
```

### Exceptions (for data layer)
**Location**: `lib/core/errors/exceptions.dart`

```dart
ServerException(message:, statusCode:, data:)
NetworkException([message])
TimeoutException([message, duration])
CacheException([message])
DatabaseException(message, [query])
AuthenticationException([message])
InvalidCredentialsException([message])
ValidationException(message, [fieldErrors])
NotFoundException(message, [resourceType, resourceId])
SyncException(message, [failedCount])
ConflictException(message, [localData, remoteData])
AIServiceException(message, [model])
OCRException([message])
UploadException(message, [fileName])
DownloadException(message, [fileName])
```

---

## Domain Entities

**Location**: `lib/domain/entities/`

### User
```dart
User(
  id: String,
  email: String,
  displayName: String?,
  photoUrl: String?,
  preferences: UserPreferences,
  createdAt: DateTime,
  updatedAt: DateTime,
)

UserPreferences(
  currency: String,           // Default: 'USD'
  locale: String,             // Default: 'en_US'
  themeMode: ThemeMode,       // system, light, dark
  biometricEnabled: bool,
  notificationsEnabled: bool,
  budgetAlertThreshold: double, // Default: 0.8 (80%)
)
```

### Account
```dart
Account(
  id: String,
  userId: String,
  name: String,
  type: AccountType,          // cash, bankAccount, creditCard, savings, investment, other
  currency: String,
  balance: double,
  icon: String,
  color: int,
  isActive: bool,
  includeInTotal: bool,
  creditLimit: double?,       // For credit cards
)
```

### Transaction
```dart
Transaction(
  id: String,
  userId: String,
  accountId: String,
  categoryId: String,
  type: TransactionType,      // expense, income, transfer
  amount: double,
  currency: String,
  description: String,
  note: String?,
  date: DateTime,
  receiptId: String?,
  toAccountId: String?,       // For transfers
  isRecurring: bool,
  recurringRuleId: String?,
  tags: List<String>,
  location: TransactionLocation?,
)

TransactionLocation(
  latitude: double,
  longitude: double,
  address: String?,
)
```

### Budget
```dart
Budget(
  id: String,
  userId: String,
  categoryId: String?,
  name: String,
  amount: double,
  spentAmount: double,
  period: BudgetPeriod,       // daily, weekly, monthly, yearly
  startDate: DateTime,
  endDate: DateTime?,
  isActive: bool,
  rollover: bool,
  alertThreshold: double,
  alertsEnabled: bool,
)
```

### Category
```dart
Category(
  id: String,
  userId: String?,
  name: String,
  icon: String,
  color: int,
  type: TransactionType,
  isSystem: bool,
  parentId: String?,
  order: int,
)
```

### ChatMessage
```dart
ChatMessage(
  id: String,
  sessionId: String,
  role: MessageRole,          // user, assistant, system
  content: String,
  timestamp: DateTime,
  metadata: MessageMetadata?,
)

MessageMetadata(
  model: String?,
  tokensUsed: int?,
  processingTimeMs: int?,
  attachments: List<String>?,
  referencedTransactions: List<String>?,
)
```

---

## Repository Interfaces

**Location**: `lib/domain/repositories/`

All repositories return `Future<Either<Failure, T>>` for error handling.

### TransactionRepository
```dart
// CRUD
getTransactionById(String id)
getAllTransactions(String userId)
createTransaction(Transaction transaction)
updateTransaction(Transaction transaction)
deleteTransaction(String id)

// Filtering
getTransactionsByType(userId, TransactionType type)
getTransactionsByCategory(userId, categoryId)
getTransactionsByDateRange(userId, startDate, endDate)
getTransactionsByAccount(userId, accountId)
searchTransactions(userId, query)

// Analytics
getTotalSpent(userId, startDate, endDate)
getTotalIncome(userId, startDate, endDate)
getSpendingByCategory(userId, startDate, endDate)
getDailySpending(userId, month)
getMonthlySpending(userId, year)

// Streaming
Stream<Either<Failure, List<Transaction>>> watchTransactions(userId)
```

### BudgetRepository
```dart
getActiveBudgets(userId)
getExceededBudgets(userId)
updateSpentAmount(budgetId, amount)
addSpending(budgetId, amount)
recalculateSpentAmount(budgetId)
rolloverBudget(budgetId)
```

### AccountRepository
```dart
getActiveAccounts(userId)
getAccountsByType(userId, AccountType)
updateBalance(accountId, newBalance)
adjustBalance(accountId, adjustment)
getTotalBalance(userId)
getNetWorth(userId)
Stream<Either<Failure, List<Account>>> watchAccounts(userId)
```

### AuthRepository
```dart
signInWithEmail(email, password)
signUpWithEmail(email, password, displayName)
signInWithGoogle()
signInWithApple()
signOut()
resetPassword(email)
getCurrentUser()
Stream<User?> watchAuthState()
enableBiometric()
authenticateWithBiometric()
```

### ChatRepository
```dart
sendMessage(sessionId, content)
Stream<String> streamResponse(sessionId, content)
getConversationContext(sessionId, messageCount)
```

### ReceiptRepository
```dart
uploadReceiptImage(imagePath)
processReceiptOcr(receiptId)
createTransactionFromReceipt(receiptId)
linkToTransaction(receiptId, transactionId)
```
---

## Repository Implementations

**Location**: `lib/data/repositories/`

All repository implementations follow the **offline-first** pattern:
1. Write to local Drift database first
2. Queue changes in `sync_queue` table via SyncQueueDao
3. Return immediately for responsive UI
4. Background sync pushes to Firebase Firestore

### Common Pattern

```dart
class ExampleRepositoryImpl implements ExampleRepository {
  final AppDatabase _database;
  final ExampleRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Entity>> createEntity(Entity entity) async {
    try {
      // 1. Save locally
      await _database.exampleDao.insertEntity(_entityToCompanion(entity));
      
      // 2. Queue for sync
      await _database.syncQueueDao.enqueueCreate(
        tableName: 'examples',
        recordId: entity.id,
        data: EntityModel.fromEntity(entity).toJson().toString(),
      );
      
      return Right(entity);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message, originalError: e));
    }
  }
}
```

### AccountRepositoryImpl (~450 lines)
```dart
// CRUD with sync queue
getAccounts(userId)
getAccountById(accountId)
createAccount(account)
updateAccount(account)
deleteAccount(accountId)

// Filtering
getActiveAccounts(userId)
getAccountsByType(userId, AccountType)

// Balance Operations
updateBalance(accountId, newBalance)
adjustBalance(accountId, adjustment)
recalculateBalance(accountId)

// Analytics
getTotalBalance(userId)
getNetWorth(userId)

// Streams
watchAccounts(userId)
watchAccountById(accountId)

// Sync
syncFromRemote(userId)
syncToRemote(userId)
```

### AuthRepositoryImpl (~550 lines)
```dart
// Firebase Auth
signInWithEmail(email, password)
signUpWithEmail(email, password, displayName)
signInWithGoogle()
signOut()
resetPassword(email)
updatePassword(currentPassword, newPassword)

// User State
getCurrentUser()
isAuthenticated()
watchAuthState()

// Biometric Auth
isBiometricAvailable()
enableBiometric(userId)
disableBiometric(userId)
authenticateWithBiometric()
```

### BudgetRepositoryImpl (~600 lines)
```dart
// CRUD
getBudgets(userId)
getBudgetById(budgetId)
createBudget(budget)
updateBudget(budget)
deleteBudget(budgetId)

// Period-based
getActiveBudgets(userId)
getBudgetsByPeriod(userId, BudgetPeriod)
getCurrentPeriodBudgets(userId)

// Spending
updateSpentAmount(budgetId, amount)
addSpending(budgetId, amount)
recalculateSpentAmount(budgetId)

// Analytics
getExceededBudgets(userId)
getBudgetUtilization(budgetId)
getBudgetsNearLimit(userId, thresholdPercent)

// Alerts
checkBudgetAlerts(userId)

// Streams
watchBudgets(userId)
watchActiveBudgets(userId)

// Sync
syncFromRemote(userId)
syncToRemote(userId)
```

### CategoryRepositoryImpl (~600 lines)
```dart
// CRUD
getCategories(userId)
getCategoryById(categoryId)
createCategory(category)
updateCategory(category)
deleteCategory(categoryId)

// Filtering
getCategoriesByType(userId, TransactionType)
getSystemCategories()
getUserCategories(userId)
getRootCategories(userId)
getSubcategories(userId, parentId)

// Initialization
initializeDefaultCategories(userId)

// Utilities
getCategoryIcon(categoryId)
getCategoryColor(categoryId)
searchCategories(userId, query)
isCategoryInUse(categoryId)

// Streams
watchCategories(userId)

// Sync
syncFromRemote(userId)
syncToRemote(userId)
```

### ChatRepositoryImpl (~1000 lines)
```dart
// Sessions
getSessions(userId)
getSessionById(sessionId)
createSession(session)
updateSession(session)
deleteSession(sessionId)
getActiveSession(userId)

// Messages
getMessages(sessionId)
getMessageById(messageId)
addMessage(message)
updateMessage(message)
deleteMessage(messageId)

// AI Integration (Gemini)
sendMessage(sessionId, content)           // Generates AI response
streamResponse(sessionId, content)        // Streaming response
getConversationContext(sessionId, limit)  // Get context for AI

// Analytics
getMessageCount(sessionId)
getSessionDuration(sessionId)
searchMessages(userId, query)

// Streams
watchSessions(userId)
watchMessages(sessionId)

// Sync
syncFromRemote(userId)
syncToRemote(userId)
```

### ReceiptRepositoryImpl (~1230 lines)
```dart
// CRUD
getReceipts(userId)
getReceiptById(receiptId)
createReceipt(receipt)
updateReceipt(receipt)
deleteReceipt(receiptId)

// Image Operations
uploadReceiptImage(userId, imagePath)
deleteReceiptImage(imageUrl)
getReceiptImageUrl(receiptId)

// OCR Processing (ML Kit)
processReceiptOcr(receiptId)       // Full OCR pipeline
extractTextFromImage(imagePath)    // Raw text extraction

// Text Parsing Helpers (internal)
_extractMerchantName(text)
_extractTotalAmount(text)
_extractTaxAmount(text)
_extractDate(text)
_extractLineItems(text)

// Transaction Linking
linkToTransaction(receiptId, transactionId)
unlinkFromTransaction(receiptId)
getReceiptByTransaction(transactionId)

// Filtering
getUnprocessedReceipts(userId)
getReceiptsByDateRange(userId, start, end)
searchByMerchant(userId, merchantName)

// Streams
watchReceipts(userId)

// Sync
syncFromRemote(userId)
syncToRemote(userId)
```

### RecurringRuleRepositoryImpl (~650 lines)
```dart
// CRUD
getRecurringRules(userId)
getRecurringRuleById(ruleId)
createRecurringRule(rule)
updateRecurringRule(rule)
deleteRecurringRule(ruleId)

// Filtering
getActiveRules(userId)
getInactiveRules(userId)
getCompletedRules(userId)
getRulesByFrequency(userId, RecurringFrequency)
getDueRules(userId)
getRulesDueInRange(userId, startDate, endDate)

// Rule Management
activateRule(ruleId)
deactivateRule(ruleId)
skipNextOccurrence(ruleId)

// Processing
processRule(ruleId)               // Creates transaction, updates next date
processAllDueRules(userId)        // Batch process all due rules
updateNextDate(ruleId)
incrementOccurrenceCount(ruleId)

// Projections
getProjectedTransactions(userId, startDate, endDate)
getProjectedIncome(userId, startDate, endDate)
getProjectedExpenses(userId, startDate, endDate)

// Streams
watchRecurringRules(userId)
watchDueRules(userId)

// Sync
syncFromRemote(userId)
syncToRemote(userId)
```

### TransactionRepositoryImpl (~995 lines)
```dart
// CRUD
getTransactions(accountId)
getTransactionById(transactionId)
createTransaction(transaction)
updateTransaction(transaction)
deleteTransaction(transactionId)

// Filtering
getTransactionsByType(accountId, TransactionType)
getTransactionsByCategory(accountId, categoryId)
getTransactionsByDateRange(accountId, startDate, endDate)
getTransactionsByMonth(accountId, year, month)
getRecentTransactions(accountId, limit)
getAllUserTransactions(userId, startDate?, endDate?, limit?)

// Search & Advanced Filter
searchTransactions(accountId, query)
getFilteredTransactions(
  accountId,
  type?, categoryId?, startDate?, endDate?,
  minAmount?, maxAmount?, tags?, limit?, offset?
)

// Aggregations
getTotalSpent(accountId, startDate, endDate)
getTotalIncome(accountId, startDate, endDate)
getSpendingByCategory(accountId, startDate, endDate)
getDailySpending(accountId, startDate, endDate)
getMonthlySpending(accountId, year)
getTransactionCountByCategory(accountId, startDate, endDate)

// Recurring
getRecurringTransactions(accountId)
getTransactionsByRecurringRule(recurringId)

// Streams
watchTransactions(accountId)
watchRecentTransactions(accountId, limit)

// Sync
syncFromRemote(userId)
syncToRemote(userId)
syncFromRemoteIncremental(userId, lastSyncTime)
```

### UserRepositoryImpl (~450 lines)
```dart
// User Operations
getCurrentUser()
getUserById(userId)
createUser(user)
updateUser(user)
deleteUser(userId)

// Preferences
updatePreferences(
  userId,
  preferredCurrency?,
  biometricEnabled?,
  themePreference?
)

// Streams
watchCurrentUser()

// Sync
syncFromRemote(userId)
syncToRemote(userId)
```

---

### Conversion Helpers Pattern

All repository implementations include these private helpers:

```dart
// Entry to Entity (Drift → Domain)
Entity _entryToEntity(EntityEntry entry) { ... }

// Entity to Companion (Domain → Drift)
EntitiesCompanion _entityToCompanion(Entity entity) { ... }

// Model to Companion (Remote → Drift)
EntitiesCompanion _modelToCompanion(EntityModel model, {String syncStatus}) { ... }
```
---

## Use Cases

### Base UseCase Classes
**Location**: `lib/domain/usecases/usecase.dart`

```dart
// Use case with parameters
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Use case without parameters
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

// Stream use case with parameters (for watching data)
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

// Stream use case without parameters
abstract class StreamUseCaseNoParams<Type> {
  Stream<Either<Failure, Type>> call();
}
```

### Auth Use Cases (20 total)
**Location**: `lib/domain/usecases/auth/`

```dart
// Sign In
SignInWithEmailUseCase(authRepo)
  call(SignInWithEmailParams({email, password})) → Either<Failure, String>

SignInWithGoogleUseCase(authRepo)
  call() → Either<Failure, String>

SignInWithAppleUseCase(authRepo)
  call() → Either<Failure, String>

// Register
RegisterWithEmailUseCase(authRepo)
  call(RegisterParams({email, password, displayName?})) → Either<Failure, String>

// Sign Out
SignOutUseCase(authRepo)
  call() → Either<Failure, void>

// Auth State
GetCurrentUserIdUseCase(authRepo)
  call() → Either<Failure, String?>

IsAuthenticatedUseCase(authRepo)
  call() → Either<Failure, bool>

WatchAuthStateUseCase(authRepo)
  call() → Stream<Either<Failure, String?>>

// Password Management
SendPasswordResetEmailUseCase(authRepo)
  call(email) → Either<Failure, void>

UpdatePasswordUseCase(authRepo)
  call(UpdatePasswordParams({currentPassword, newPassword})) → Either<Failure, void>

ConfirmPasswordResetUseCase(authRepo)
  call(ConfirmPasswordResetParams({code, newPassword})) → Either<Failure, void>

// Email Verification
SendEmailVerificationUseCase(authRepo)
  call() → Either<Failure, void>

IsEmailVerifiedUseCase(authRepo)
  call() → Either<Failure, bool>

ReloadUserUseCase(authRepo)
  call() → Either<Failure, void>

// Account Management
UpdateEmailUseCase(authRepo)
  call(UpdateEmailParams({newEmail, password})) → Either<Failure, void>

DeleteAccountUseCase(authRepo)
  call(password) → Either<Failure, void>

ReauthenticateUseCase(authRepo)
  call(password) → Either<Failure, void>

// Biometrics
IsBiometricAvailableUseCase(authRepo)
  call() → Either<Failure, bool>

AuthenticateWithBiometricsUseCase(authRepo)
  call() → Either<Failure, bool>

GetAvailableBiometricsUseCase(authRepo)
  call() → Either<Failure, List<BiometricType>>
```

### Transaction Use Cases (5 total)
**Location**: `lib/domain/usecases/transaction/`

```dart
CreateTransactionUseCase(transactionRepo)
  call(CreateTransactionParams) → Either<Failure, Transaction>

GetTransactionsByDateRangeUseCase(transactionRepo)
  call(DateRangeParams({accountId, startDate, endDate})) → Either<Failure, List<Transaction>>

GetSpendingSummaryUseCase(transactionRepo)
  call(SpendingSummaryParams({accountId, startDate, endDate})) → Either<Failure, SpendingSummary>

WatchRecentTransactionsUseCase(transactionRepo)
  call(WatchTransactionsParams({accountId, limit})) → Stream<Either<Failure, List<Transaction>>>
```

### Account Use Cases (7 total)
**Location**: `lib/domain/usecases/account/`

```dart
CreateAccountUseCase(accountRepo)
  call(CreateAccountParams) → Either<Failure, Account>

DeleteAccountUseCase(accountRepo)
  call(accountId) → Either<Failure, void>

GetAccountsUseCase(accountRepo)
  call(userId?) → Either<Failure, List<Account>>

GetNetWorthUseCase(accountRepo)
  call(userId) → Either<Failure, double>

UpdateAccountBalanceUseCase(accountRepo)
  call(UpdateBalanceParams({accountId, newBalance})) → Either<Failure, void>

WatchAccountsUseCase(accountRepo)
  call(userId?) → Stream<Either<Failure, List<Account>>>
```

### Budget Use Cases (7 total)
**Location**: `lib/domain/usecases/budget/`

```dart
CreateBudgetUseCase(budgetRepo)
  call(CreateBudgetParams) → Either<Failure, Budget>

GetBudgetsUseCase(budgetRepo)
  call(GetBudgetsParams({userId?, categoryId?, period?})) → Either<Failure, List<Budget>>

GetBudgetSummaryUseCase(budgetRepo)
  call(BudgetSummaryParams({userId, startDate, endDate})) → Either<Failure, BudgetSummary>

UpdateBudgetUseCase(budgetRepo)
  call(budget) → Either<Failure, void>

WatchBudgetsUseCase(budgetRepo)
  call(userId?) → Stream<Either<Failure, List<Budget>>>

CheckBudgetStatusUseCase(budgetRepo)
  call(CheckBudgetParams({budgetId, currentSpending})) → Either<Failure, BudgetStatus>
```

### Category Use Cases (6 total)
**Location**: `lib/domain/usecases/category/`

```dart
CreateCategoryUseCase(categoryRepo)
  call(CreateCategoryParams) → Either<Failure, Category>

GetCategoriesUseCase(categoryRepo)
  call(GetCategoriesParams({userId?, type?})) → Either<Failure, List<Category>>

UpdateCategoryUseCase(categoryRepo)
  call(category) → Either<Failure, void>

SearchCategoriesUseCase(categoryRepo)
  call(SearchCategoriesParams({query, type?})) → Either<Failure, List<Category>>

InitializeDefaultCategoriesUseCase(categoryRepo)
  call(userId) → Either<Failure, void>
```

### Receipt Use Cases (7 total)
**Location**: `lib/domain/usecases/receipt/`

```dart
ScanReceiptUseCase(receiptRepo)
  call(imagePath) → Either<Failure, Receipt>

ProcessReceiptOcrUseCase(receiptRepo)
  call(imageBytes) → Either<Failure, OcrResult>

GetReceiptsUseCase(receiptRepo)
  call(GetReceiptsParams({userId?, transactionId?})) → Either<Failure, List<Receipt>>

LinkReceiptToTransactionUseCase(receiptRepo)
  call(LinkReceiptParams({receiptId, transactionId})) → Either<Failure, void>

DeleteReceiptUseCase(receiptRepo)
  call(receiptId) → Either<Failure, void>
```

### Chat Use Cases (56 total)
**Location**: `lib/domain/usecases/chat/`

```dart
// Message Operations
SendChatMessageUseCase(chatRepo)
  call(SendMessageParams({sessionId, content, role})) → Either<Failure, ChatMessage>

StreamChatResponseUseCase(chatRepo)
  call(StreamParams({sessionId, prompt})) → Stream<Either<Failure, String>>

// Session Operations
CreateChatSessionUseCase(chatRepo)
  call(CreateSessionParams({userId, title?})) → Either<Failure, ChatSession>

GetChatSessionUseCase(chatRepo)
  call(sessionId) → Either<Failure, ChatSession?>

GetAllChatSessionsUseCase(chatRepo)
  call(userId) → Either<Failure, List<ChatSession>>

UpdateChatSessionUseCase(chatRepo)
  call(session) → Either<Failure, void>

DeleteChatSessionUseCase(chatRepo)
  call(sessionId) → Either<Failure, void>

// Watch Operations
WatchChatMessagesUseCase(chatRepo)
  call(sessionId) → Stream<Either<Failure, List<ChatMessage>>>

WatchChatSessionsUseCase(chatRepo)
  call(userId) → Stream<Either<Failure, List<ChatSession>>>

WatchUnreadCountUseCase(chatRepo)
  call(userId) → Stream<Either<Failure, int>>

// Search
SearchChatMessagesUseCase(chatRepo)
  call(SearchMessagesParams({userId, query})) → Either<Failure, List<ChatMessage>>

// Analytics
GetChatStatsUseCase(chatRepo)
  call(userId) → Either<Failure, ChatStats>

GetMostUsedPromptsUseCase(chatRepo)
  call(GetMostUsedParams({userId, limit})) → Either<Failure, List<PromptUsage>>

ExportChatHistoryUseCase(chatRepo)
  call(ExportParams({userId, format})) → Either<Failure, String>

ClearChatHistoryUseCase(chatRepo)
  call(ClearHistoryParams({userId, beforeDate?})) → Either<Failure, void>
```

---

## Auth BLoC

### Events
**Location**: `lib/presentation/bloc/auth/auth_event.dart`

```dart
AuthCheckRequested()           // Check current auth state on app start
AuthSignInWithEmailRequested({email, password})
AuthRegisterRequested({email, password, displayName?})
AuthSignInWithGoogleRequested()
AuthSignInWithAppleRequested()
AuthSignOutRequested()
AuthPasswordResetRequested({email})
AuthSendVerificationRequested()
AuthDeleteAccountRequested({password})
AuthReauthenticateRequested({password})
AuthBiometricRequested()
```

### States
**Location**: `lib/presentation/bloc/auth/auth_state.dart`

```dart
AuthInitial()                  // Before any action
AuthLoading()                  // Processing auth action
AuthAuthenticated({userId})    // User is signed in
AuthUnauthenticated()          // User is signed out
AuthError({errorType, customMessage?})
AuthPasswordResetSent()        // Reset email sent successfully
AuthVerificationSent()         // Verification email sent
AuthNeedsReauthentication()    // User needs to re-authenticate

// Error Types
AuthErrorType.invalidCredentials
AuthErrorType.emailAlreadyInUse
AuthErrorType.weakPassword
AuthErrorType.userNotFound
AuthErrorType.tooManyRequests
AuthErrorType.networkError
AuthErrorType.emailNotVerified
AuthErrorType.accountDisabled
AuthErrorType.biometricFailed
AuthErrorType.unknown
```

### BLoC Usage
**Location**: `lib/presentation/bloc/auth/auth_bloc.dart`

```dart
// In screen
context.read<AuthBloc>().add(const AuthCheckRequested());
context.read<AuthBloc>().add(AuthSignInWithEmailRequested(
  email: emailController.text,
  password: passwordController.text,
));

// Listen to state changes
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
)
```

---

## Budget BLoC

### Events
**Location**: `lib/presentation/bloc/budget/budget_event.dart`

```dart
// Load Events
BudgetLoadRequested({userId})        // Load all budgets
BudgetLoadActiveRequested({userId})  // Load only active budgets
BudgetSummaryRequested({userId})     // Load budget summary
BudgetWatchRequested({userId})       // Start watching budgets (stream)

// CRUD Events
BudgetCreateRequested({categoryId, amount, period, rollover?, alertsEnabled?, alertThreshold?})
BudgetUpdateRequested({budget})
BudgetDeleteRequested({budgetId})

// Status Events
BudgetCheckStatusRequested({budgetId})
BudgetLoadExceededRequested({userId})
BudgetLoadWarningRequested({userId})

// Spending Events
BudgetAddSpendingRequested({budgetId, amount})
BudgetSubtractSpendingRequested({budgetId, amount})

// Period Events
BudgetResetPeriodRequested({budgetId})

// Internal Events (for stream updates)
BudgetDataChanged({budgets})
BudgetErrorCleared()
```

### States
**Location**: `lib/presentation/bloc/budget/budget_state.dart`

```dart
BudgetInitial()                // Before any action
BudgetLoading({message?})      // Processing budget action
BudgetLoaded({
  budgets,                     // List<Budget>
  summary,                     // BudgetSummary?
  exceededBudgets,            // List<Budget> computed
  warningBudgets,             // List<Budget> computed
  healthyBudgets,             // List<Budget> computed
})
BudgetDetailLoaded({budget, status?})
BudgetOperationInProgress({operationType, message?})
BudgetOperationSuccess({operationType, message, budget?})
BudgetError({errorType, message, code?})

// Operation Types
BudgetOperationType.create
BudgetOperationType.update
BudgetOperationType.delete
BudgetOperationType.addSpending
BudgetOperationType.resetPeriod

// Error Types
BudgetErrorType.notFound
BudgetErrorType.alreadyExists
BudgetErrorType.invalidData
BudgetErrorType.permissionDenied
BudgetErrorType.networkError
BudgetErrorType.databaseError
BudgetErrorType.syncError
BudgetErrorType.unknown
```

### BLoC Usage
**Location**: `lib/presentation/bloc/budget/budget_bloc.dart`

```dart
// In screen - provide and start watching
BlocProvider(
  create: (context) => sl<BudgetBloc>()
    ..add(BudgetWatchRequested(userId: userId)),
  child: const BudgetListView(),
)

// Create budget
context.read<BudgetBloc>().add(BudgetCreateRequested(
  categoryId: 'cat_food',
  amount: 500.0,
  period: BudgetPeriod.monthly,
  alertsEnabled: true,
  alertThreshold: 0.80,
));

// Delete budget
context.read<BudgetBloc>().add(BudgetDeleteRequested(budgetId: budget.id));

// Listen to state changes
BlocConsumer<BudgetBloc, BudgetState>(
  listener: (context, state) {
    if (state is BudgetOperationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    } else if (state is BudgetError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    return switch (state) {
      BudgetLoading() => const CircularProgressIndicator(),
      BudgetLoaded(:final budgets) => BudgetList(budgets: budgets),
      BudgetError(:final message) => ErrorWidget(message: message),
      _ => const SizedBox.shrink(),
    };
  },
)
```

### Passing BLoC to Modal Sheets
When opening modal bottom sheets, pass the BLoC using `BlocProvider.value`:

```dart
void _showCreateBudgetSheet(BuildContext context) {
  final budgetBloc = context.read<BudgetBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider.value(
      value: budgetBloc,
      child: const CreateBudgetSheet(),
    ),
  );
}
```

---

## Category BLoC

### Events
**Location**: `lib/presentation/bloc/category/category_event.dart`

```dart
// Load Events
CategoryLoadRequested({userId})              // Load all categories
CategoryLoadByTypeRequested({userId, type})  // Load by expense/income
CategoryLoadExpenseRequested({userId})       // Load expense categories
CategoryLoadIncomeRequested({userId})        // Load income categories
CategoryWatchRequested({userId})             // Start watching (stream)

// CRUD Events
CategoryCreateRequested({name, icon, color, type, parentId?})
CategoryUpdateRequested({category})
CategoryDeleteRequested({categoryId})

// Search Events
CategorySearchRequested({userId, query})
CategorySearchCleared()

// System Events
CategoryInitializeDefaultsRequested({userId})

// Internal Events
CategoryDataChanged({categories})
CategoryErrorCleared()
```

### States
**Location**: `lib/presentation/bloc/category/category_state.dart`

```dart
CategoryInitial()              // Before any action
CategoryLoading({message?})    // Processing action
CategoryLoaded({
  categories,                  // List<Category>
  expenseCategories,          // List<Category> filtered
  incomeCategories,           // List<Category> filtered
  searchResults,              // List<Category>?
})
CategoryOperationSuccess({operationType, message, category?})
CategoryError({errorType, message, code?})

// Error Types
CategoryErrorType.notFound
CategoryErrorType.alreadyExists
CategoryErrorType.cannotDeleteSystem
CategoryErrorType.networkError
CategoryErrorType.databaseError
CategoryErrorType.unknown
```

### BLoC Usage
**Location**: `lib/presentation/bloc/category/category_bloc.dart`

```dart
// Provide and load categories
BlocProvider(
  create: (context) => sl<CategoryBloc>()
    ..add(CategoryLoadRequested(userId: userId)),
  child: const CategoryList(),
)

// Load expense categories only
context.read<CategoryBloc>().add(CategoryLoadExpenseRequested(userId: userId));

// Create custom category
context.read<CategoryBloc>().add(CategoryCreateRequested(
  name: 'Subscriptions',
  icon: 'subscriptions',
  color: '#FF5722',
  type: CategoryType.expense,
));

// Search categories
context.read<CategoryBloc>().add(CategorySearchRequested(
  userId: userId,
  query: 'food',
));
```

---

## CategorySelector Widget

### Usage
**Location**: `lib/presentation/widgets/category_selector.dart`

Reusable category picker widget with icon grid, search, and category creation:

```dart
CategorySelector(
  userId: currentUserId,  // Required for category creation
  selectedCategoryId: _selectedCategoryId,
  filterType: CategoryType.expense,  // Filter by type
  onCategorySelected: (category) {
    setState(() {
      _selectedCategoryId = category.id;
      _selectedCategory = category;
    });
  },
)
```

### Features
- Icon grid display with category colors
- Search/filter functionality
- **"+ Create New Category" option at top of picker**
- Integrates with CategoryBloc automatically
- Shows loading/error states
- Supports expense/income filtering
- Shows "Custom" badge for user-created categories

---

## IconConstants

### Usage
**Location**: `lib/core/constants/icon_constants.dart`

Centralized icon mapping with 140+ Material icons in 10 categories:

```dart
// Get icon by name
final icon = IconConstants.getIcon('shopping_cart');
final icon = IconConstants.getIcon('unknown');  // Returns Icons.category (fallback)

// Get all grouped icons (for icon picker)
final Map<String, List<String>> groups = IconConstants.groupedIcons;
// {'Shopping': ['shopping_cart', 'store', ...], 'Food': [...], ...}

// Get all icons as flat map
final Map<String, IconData> allIcons = IconConstants.allIcons;

// Categories: Shopping, Food, Transport, Entertainment, Bills, Health,
//             Education, Travel, Finance, General
```

---

## IconPicker Widgets

### IconPickerField
**Location**: `lib/presentation/widgets/icon_picker.dart`

Inline form field for icon selection:

```dart
IconPickerField(
  selectedIcon: _selectedIconName,  // e.g., 'shopping_cart'
  onIconSelected: (iconName) {
    setState(() => _selectedIconName = iconName);
  },
  label: 'Icon',  // Optional label
)
```

### IconPickerBottomSheet
Full-screen picker with search and grouped icons:

```dart
final selectedIcon = await IconPickerBottomSheet.show(
  context: context,
  selectedIcon: currentIconName,
);

if (selectedIcon != null) {
  setState(() => _iconName = selectedIcon);
}
```

---

## CreateCategorySheet

### Usage
**Location**: `lib/presentation/widgets/create_category_sheet.dart`

Bottom sheet form for creating custom categories:

```dart
final newCategory = await showModalBottomSheet<Category>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (ctx) => BlocProvider.value(
    value: context.read<CategoryBloc>(),
    child: CreateCategorySheet(
      userId: userId,
      initialType: CategoryType.expense,  // Optional preset
    ),
  ),
);

if (newCategory != null) {
  // Category was created, use it
}
```

### Features
- Name text field with validation
- Category type toggle (Expense/Income)
- IconPickerField integration
- Color palette (16 preset colors)
- Live preview of category appearance
- Uses CategoryBloc for creation
- Returns created Category on success

---

## EnsureUserExistsUseCase

### Usage
**Location**: `lib/domain/usecases/user/ensure_user_exists.dart`

Ensures user exists in local Drift database to satisfy FK constraints:

```dart
final useCase = EnsureUserExistsUseCase(userRepository);

final result = await useCase(
  EnsureUserExistsParams(
    userId: firebaseUserId,
    email: 'user@example.com',  // Optional
  ),
);

result.fold(
  (failure) => log('Failed: ${failure.message}'),
  (_) => log('User exists in local DB'),
);
```

### Integration in AuthBloc
Called automatically after successful authentication:

```dart
// In AuthBloc._onSignInWithEmail:
await result.fold(
  (failure) async => emit(AuthError(...)),
  (userId) async {
    // Ensure user exists in local database for FK constraints
    await ensureUserExists(
      EnsureUserExistsParams(userId: userId, email: event.email),
    );
    emit(AuthAuthenticated(userId: userId));
  },
);
```

### Why This Exists
- Local Drift database has FK constraints (Categories.userId → Users.id)
- Firebase Auth creates users in cloud, not in local DB
- Without this, creating categories/budgets fails with FK error
- This use case is idempotent - safe to call multiple times

---

## Use Case Composition

### GetBudgetsWithRelationsUseCase
**Location**: `lib/domain/usecases/budget/get_budgets_with_relations.dart`

Composes data from multiple repositories at the domain layer:

```dart
final useCase = GetBudgetsWithRelationsUseCase(
  budgetRepository: budgetRepo,
  categoryRepository: categoryRepo,
);

final result = await useCase(
  GetBudgetsWithRelationsParams(
    userId: 'user-123',
    includeCategory: true,
  ),
);

result.fold(
  (failure) => showError(failure.message),
  (budgets) {
    // budgets now have .category populated
    for (final budget in budgets) {
      print('${budget.category?.name}: ${budget.spentAmount}/${budget.amount}');
    }
  },
);
```

### WatchBudgetsWithRelationsUseCase
Stream version for real-time updates:

```dart
final stream = watchBudgetsWithRelations(
  WatchBudgetsWithRelationsParams(
    userId: userId,
    includeCategory: true,
  ),
);

stream.listen((result) {
  result.fold(
    (failure) => handleError(failure),
    (budgets) => updateUI(budgets),
  );
});
```

---

## Dependency Injection

### Service Locator
**Location**: `lib/core/di/injection_container.dart`

```dart
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

// Access registered dependencies
final authRepo = sl<AuthRepository>();
final authBloc = sl<AuthBloc>();
final budgetBloc = sl<BudgetBloc>();
final database = sl<AppDatabase>();

// Register types
sl.registerSingleton<Database>(AppDatabase());           // Eager singleton
sl.registerLazySingleton<AuthRepository>(() => impl);    // Lazy singleton
sl.registerFactory<AuthBloc>(() => AuthBloc(...));       // New instance each time
```

### Registered Dependencies

```dart
// Core - Database & Services
sl<AppDatabase>()              // Drift local database (LazySingleton)
sl<FirebaseService>()          // Shared Firebase service (LazySingleton)

// Data Sources
sl<BudgetRemoteDataSource>()   // Budget Firestore datasource (LazySingleton)
sl<CategoryRemoteDataSource>() // Category Firestore datasource (LazySingleton)

// Repositories
sl<AuthRepository>()           // Firebase Auth (LazySingleton)
sl<BudgetRepository>()         // Offline-first budget repo (LazySingleton)
sl<CategoryRepository>()       // Offline-first category repo (LazySingleton)

// Use Cases - Auth (13)
sl<SignInWithEmailUseCase>()
sl<RegisterWithEmailUseCase>()
sl<SignInWithGoogleUseCase>()
sl<SignInWithAppleUseCase>()
sl<SignOutUseCase>()
sl<GetCurrentUserIdUseCase>()
sl<IsAuthenticatedUseCase>()
sl<WatchAuthStateUseCase>()
sl<SendPasswordResetEmailUseCase>()
sl<SendEmailVerificationUseCase>()
sl<IsEmailVerifiedUseCase>()
sl<IsBiometricAvailableUseCase>()
sl<AuthenticateWithBiometricsUseCase>()

// Use Cases - Budget (10)
sl<CreateBudgetUseCase>()
sl<GetBudgetsUseCase>()
sl<GetActiveBudgetsUseCase>()
sl<UpdateBudgetUseCase>()
sl<DeleteBudgetUseCase>()
sl<GetBudgetSummaryUseCase>()
sl<CheckBudgetStatusUseCase>()
sl<WatchBudgetsUseCase>()
sl<GetBudgetsWithRelationsUseCase>()   // Use Case Composition
sl<WatchBudgetsWithRelationsUseCase>() // Use Case Composition

// Use Cases - Category (9)
sl<GetCategoriesUseCase>()
sl<GetCategoriesByTypeUseCase>()
sl<GetExpenseCategoriesUseCase>()
sl<GetIncomeCategoriesUseCase>()
sl<CreateCategoryUseCase>()
sl<UpdateCategoryUseCase>()
sl<SearchCategoriesUseCase>()
sl<WatchCategoriesUseCase>()
sl<InitializeDefaultCategoriesUseCase>()

// BLoCs
sl<AuthBloc>()                 // Factory - new instance each time
sl<BudgetBloc>()               // Factory - uses GetBudgetsWithRelationsUseCase
sl<CategoryBloc>()             // Factory - new instance each time
```

### Initialization
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initDependencies();
  runApp(const MyApp());
}
```

---

## Navigation System

### Routes
**Location**: `lib/main.dart`

```dart
// Available routes
'/'                → SplashScreen      // Initial route, auth check
'/login'           → LoginScreen       // Email/password + social sign-in
'/register'        → RegisterScreen    // New user registration
'/forgot-password' → ForgotPasswordScreen
'/main'            → MainScreen        // Main app with bottom navigation

// Navigate
Navigator.pushNamed(context, '/main');
Navigator.pushReplacementNamed(context, '/login');
```

### SplashScreen
**Location**: `lib/presentation/screens/splash/splash_screen.dart`

```dart
// Features:
// - Animated logo with scale + fade animations
// - Checks auth state via AuthBloc
// - Routes to /main (authenticated) or /login (unauthenticated)
// - Gradient background with dark/light support

// Auto-navigation based on auth state
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) {
      Navigator.pushReplacementNamed(context, '/main');
    } else if (state is AuthUnauthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  },
)
```

### MainScreen
**Location**: `lib/presentation/screens/main/main_screen.dart`

```dart
// Main app container with bottom navigation
// Features:
// - IndexedStack with 4 tabs (preserves state)
// - Custom bottom navigation bar with FAB notch
// - Floating Action Button with quick add menu
// - BlocListener for sign-out navigation
// - BlocBuilder for getting userId from AuthState

// Tabs
// Index 0: DashboardScreen (Home)
// Index 1: TransactionsPlaceholder
// Index 2: BudgetListScreen (IMPLEMENTED)
// Index 3: ChatPlaceholder

// FAB Quick Add Options
// - Add Expense
// - Add Income
// - Transfer
// - Scan Receipt
```

### MainBottomNav
**Location**: `lib/presentation/screens/main/widgets/main_bottom_nav.dart`

```dart
// Custom bottom navigation bar
MainBottomNav({
  required int currentIndex,
  required ValueChanged<int> onTap,
})

// Features:
// - CircularNotchedRectangle shape for FAB
// - 4 navigation items with icons
// - Active/inactive color states
// - Dark/light theme support

// Navigation Items:
// 0: Icons.home_rounded      → 'Home'
// 1: Icons.receipt_long      → 'Transactions'
// 2: Icons.account_balance_wallet → 'Budgets'
// 3: Icons.chat_bubble_outline → 'Chat'
```

### Navigation Flow
```
App Start
    ↓
SplashScreen (animated, auth check)
    ↓
┌───────────────────────────────────┐
│  AuthBloc.add(AuthCheckRequested) │
└───────────────────────────────────┘
    ↓
┌─────────────┬─────────────────────┐
│ Authenticated│   Unauthenticated  │
└─────────────┴─────────────────────┘
    ↓                    ↓
MainScreen           LoginScreen
(4 tabs + FAB)          ↓
    │              RegisterScreen
    │                   ↓
    │           ForgotPasswordScreen
    │
    ↓ (on sign out)
LoginScreen
```
