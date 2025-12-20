/// Database constants for the AI-Powered Personal Finance Assistant
/// Used with Drift (local) and Firebase Firestore (remote)

// ============== Database Configuration ==============

class DatabaseConfig {
  DatabaseConfig._();

  /// Local database name (Drift/SQLite)
  static const String databaseName = 'finance_assistant.db';

  /// Database version for migrations
  static const int databaseVersion = 1;

  /// Sync batch size for Firestore operations
  static const int syncBatchSize = 500;

  /// Maximum retry attempts for sync operations
  static const int maxSyncRetries = 3;

  /// Delay between sync retries (milliseconds)
  static const int syncRetryDelayMs = 1000;
}

// ============== Table Names ==============

class TableNames {
  TableNames._();

  static const String users = 'users';
  static const String accounts = 'accounts';
  static const String categories = 'categories';
  static const String transactions = 'transactions';
  static const String budgets = 'budgets';
  static const String recurringRules = 'recurring_rules';
  static const String receipts = 'receipts';
  static const String chatHistory = 'chat_history';
  static const String syncQueue = 'sync_queue';
}

// ============== Users Table ==============

class UsersTable {
  UsersTable._();

  static const String tableName = TableNames.users;

  // Column names
  static const String colId = 'id';
  static const String colEmail = 'email';
  static const String colDisplayName = 'display_name';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colSyncedAt = 'synced_at';

  // All columns
  static const List<String> allColumns = [
    colId,
    colEmail,
    colDisplayName,
    colCreatedAt,
    colUpdatedAt,
    colSyncedAt,
  ];
}

// ============== Accounts Table ==============

class AccountsTable {
  AccountsTable._();

  static const String tableName = TableNames.accounts;

  // Column names
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colName = 'name';
  static const String colType = 'type';
  static const String colBalance = 'balance';
  static const String colCurrency = 'currency';
  static const String colIcon = 'icon';
  static const String colColor = 'color';
  static const String colIsActive = 'is_active';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colSyncStatus = 'sync_status';

  // All columns
  static const List<String> allColumns = [
    colId,
    colUserId,
    colName,
    colType,
    colBalance,
    colCurrency,
    colIcon,
    colColor,
    colIsActive,
    colCreatedAt,
    colUpdatedAt,
    colSyncStatus,
  ];

  // Account types
  static const String typeCash = 'cash';
  static const String typeBankAccount = 'bank_account';
  static const String typeCreditCard = 'credit_card';
  static const String typeDebitCard = 'debit_card';
  static const String typeSavings = 'savings';
  static const String typeInvestment = 'investment';
  static const String typeLoan = 'loan';
  static const String typeEwallet = 'e_wallet';

  static const List<String> accountTypes = [
    typeCash,
    typeBankAccount,
    typeCreditCard,
    typeDebitCard,
    typeSavings,
    typeInvestment,
    typeLoan,
    typeEwallet,
  ];

  // Default values
  static const String defaultCurrency = 'USD';
  static const double defaultBalance = 0.0;
  static const bool defaultIsActive = true;
}

// ============== Categories Table ==============

class CategoriesTable {
  CategoriesTable._();

  static const String tableName = TableNames.categories;

  // Column names
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colName = 'name';
  static const String colIcon = 'icon';
  static const String colColor = 'color';
  static const String colType = 'type';
  static const String colParentId = 'parent_id';
  static const String colIsSystem = 'is_system';
  static const String colCreatedAt = 'created_at';
  static const String colSyncStatus = 'sync_status';

  // All columns
  static const List<String> allColumns = [
    colId,
    colUserId,
    colName,
    colIcon,
    colColor,
    colType,
    colParentId,
    colIsSystem,
    colCreatedAt,
    colSyncStatus,
  ];

  // Category types (expense/income)
  static const String typeExpense = 'expense';
  static const String typeIncome = 'income';

  static const List<String> categoryTypes = [typeExpense, typeIncome];
}

// ============== Transactions Table ==============

class TransactionsTable {
  TransactionsTable._();

  static const String tableName = TableNames.transactions;

  // Column names
  static const String colId = 'id';
  static const String colAccountId = 'account_id';
  static const String colCategoryId = 'category_id';
  static const String colAmount = 'amount';
  static const String colType = 'type';
  static const String colDescription = 'description';
  static const String colDate = 'date';
  static const String colReceiptUrl = 'receipt_url';
  static const String colLocation = 'location';
  static const String colTags = 'tags';
  static const String colAiCategoryConfidence = 'ai_category_confidence';
  static const String colIsRecurring = 'is_recurring';
  static const String colRecurringId = 'recurring_id';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colSyncStatus = 'sync_status';

  // All columns
  static const List<String> allColumns = [
    colId,
    colAccountId,
    colCategoryId,
    colAmount,
    colType,
    colDescription,
    colDate,
    colReceiptUrl,
    colLocation,
    colTags,
    colAiCategoryConfidence,
    colIsRecurring,
    colRecurringId,
    colCreatedAt,
    colUpdatedAt,
    colSyncStatus,
  ];

  // Transaction types
  static const String typeExpense = 'expense';
  static const String typeIncome = 'income';
  static const String typeTransfer = 'transfer';

  static const List<String> transactionTypes = [
    typeExpense,
    typeIncome,
    typeTransfer,
  ];

  // AI confidence thresholds
  static const double highConfidence = 0.85;
  static const double mediumConfidence = 0.60;
  static const double lowConfidence = 0.40;
}

// ============== Budgets Table ==============

class BudgetsTable {
  BudgetsTable._();

  static const String tableName = TableNames.budgets;

  // Column names
  static const String colId = 'id';
  static const String colAccountId = 'account_id';
  static const String colCategoryId = 'category_id';
  static const String colAmount = 'amount';
  static const String colSpentAmount = 'spent_amount';
  static const String colPeriod = 'period';
  static const String colStartDate = 'start_date';
  static const String colEndDate = 'end_date';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colSyncStatus = 'sync_status';

  // All columns
  static const List<String> allColumns = [
    colId,
    colAccountId,
    colCategoryId,
    colAmount,
    colSpentAmount,
    colPeriod,
    colStartDate,
    colEndDate,
    colCreatedAt,
    colUpdatedAt,
    colSyncStatus,
  ];

  // Budget periods
  static const String periodDaily = 'daily';
  static const String periodWeekly = 'weekly';
  static const String periodBiweekly = 'biweekly';
  static const String periodMonthly = 'monthly';
  static const String periodQuarterly = 'quarterly';
  static const String periodYearly = 'yearly';

  static const List<String> budgetPeriods = [
    periodDaily,
    periodWeekly,
    periodBiweekly,
    periodMonthly,
    periodQuarterly,
    periodYearly,
  ];

  // Budget alert thresholds (percentage)
  static const double warningThreshold = 0.80; // 80%
  static const double dangerThreshold = 0.95; // 95%
  static const double exceededThreshold = 1.0; // 100%
}

// ============== Recurring Rules Table ==============

class RecurringRulesTable {
  RecurringRulesTable._();

  static const String tableName = TableNames.recurringRules;

  // Column names
  static const String colId = 'id';
  static const String colTransactionId = 'transaction_id';
  static const String colFrequency = 'frequency';
  static const String colInterval = 'interval';
  static const String colNextDate = 'next_date';
  static const String colEndDate = 'end_date';
  static const String colIsActive = 'is_active';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colSyncStatus = 'sync_status';

  // All columns
  static const List<String> allColumns = [
    colId,
    colTransactionId,
    colFrequency,
    colInterval,
    colNextDate,
    colEndDate,
    colIsActive,
    colCreatedAt,
    colUpdatedAt,
    colSyncStatus,
  ];

  // Frequency types
  static const String frequencyDaily = 'daily';
  static const String frequencyWeekly = 'weekly';
  static const String frequencyBiweekly = 'biweekly';
  static const String frequencyMonthly = 'monthly';
  static const String frequencyQuarterly = 'quarterly';
  static const String frequencyYearly = 'yearly';

  static const List<String> frequencies = [
    frequencyDaily,
    frequencyWeekly,
    frequencyBiweekly,
    frequencyMonthly,
    frequencyQuarterly,
    frequencyYearly,
  ];

  // Default interval
  static const int defaultInterval = 1;
}

// ============== Receipts Table (for OCR data) ==============

class ReceiptsTable {
  ReceiptsTable._();

  static const String tableName = TableNames.receipts;

  // Column names
  static const String colId = 'id';
  static const String colTransactionId = 'transaction_id';
  static const String colImageUrl = 'image_url';
  static const String colLocalPath = 'local_path';
  static const String colOcrRawText = 'ocr_raw_text';
  static const String colOcrConfidence = 'ocr_confidence';
  static const String colMerchantName = 'merchant_name';
  static const String colTotalAmount = 'total_amount';
  static const String colTaxAmount = 'tax_amount';
  static const String colReceiptDate = 'receipt_date';
  static const String colItems = 'items'; // JSON array
  static const String colCreatedAt = 'created_at';
  static const String colSyncStatus = 'sync_status';

  // All columns
  static const List<String> allColumns = [
    colId,
    colTransactionId,
    colImageUrl,
    colLocalPath,
    colOcrRawText,
    colOcrConfidence,
    colMerchantName,
    colTotalAmount,
    colTaxAmount,
    colReceiptDate,
    colItems,
    colCreatedAt,
    colSyncStatus,
  ];
}

// ============== Chat History Table ==============

class ChatHistoryTable {
  ChatHistoryTable._();

  static const String tableName = TableNames.chatHistory;

  // Column names
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  static const String colSessionId = 'session_id';
  static const String colRole = 'role'; // user, assistant, system
  static const String colContent = 'content';
  static const String colTokensUsed = 'tokens_used';
  static const String colModel = 'model';
  static const String colCreatedAt = 'created_at';
  static const String colSyncStatus = 'sync_status';

  // All columns
  static const List<String> allColumns = [
    colId,
    colUserId,
    colSessionId,
    colRole,
    colContent,
    colTokensUsed,
    colModel,
    colCreatedAt,
    colSyncStatus,
  ];

  // Chat roles
  static const String roleUser = 'user';
  static const String roleAssistant = 'assistant';
  static const String roleSystem = 'system';

  static const List<String> chatRoles = [roleUser, roleAssistant, roleSystem];
}

// ============== Sync Queue Table (for offline-first) ==============

class SyncQueueTable {
  SyncQueueTable._();

  static const String tableName = TableNames.syncQueue;

  // Column names
  static const String colId = 'id';
  static const String colTableName = 'table_name';
  static const String colRecordId = 'record_id';
  static const String colOperation = 'operation';
  static const String colPayload = 'payload'; // JSON
  static const String colRetryCount = 'retry_count';
  static const String colLastError = 'last_error';
  static const String colCreatedAt = 'created_at';
  static const String colProcessedAt = 'processed_at';

  // All columns
  static const List<String> allColumns = [
    colId,
    colTableName,
    colRecordId,
    colOperation,
    colPayload,
    colRetryCount,
    colLastError,
    colCreatedAt,
    colProcessedAt,
  ];

  // Sync operations
  static const String operationCreate = 'create';
  static const String operationUpdate = 'update';
  static const String operationDelete = 'delete';

  static const List<String> operations = [
    operationCreate,
    operationUpdate,
    operationDelete,
  ];
}

// ============== Sync Status Values ==============

class SyncStatus {
  SyncStatus._();

  /// Record is synced with remote
  static const String synced = 'synced';

  /// Record has local changes pending sync
  static const String pending = 'pending';

  /// Record sync failed, needs retry
  static const String failed = 'failed';

  /// Record is being synced
  static const String syncing = 'syncing';

  /// Record was deleted locally, pending remote deletion
  static const String deletedLocally = 'deleted_locally';

  /// Record has conflict between local and remote
  static const String conflict = 'conflict';

  static const List<String> allStatuses = [
    synced,
    pending,
    failed,
    syncing,
    deletedLocally,
    conflict,
  ];
}

// ============== Index Definitions ==============

class DatabaseIndexes {
  DatabaseIndexes._();

  // Accounts indexes
  static const String idxAccountsUserId = 'idx_accounts_user_id';
  static const String idxAccountsSyncStatus = 'idx_accounts_sync_status';

  // Categories indexes
  static const String idxCategoriesUserId = 'idx_categories_user_id';
  static const String idxCategoriesType = 'idx_categories_type';
  static const String idxCategoriesParentId = 'idx_categories_parent_id';

  // Transactions indexes
  static const String idxTransactionsAccountId = 'idx_transactions_account_id';
  static const String idxTransactionsCategoryId =
      'idx_transactions_category_id';
  static const String idxTransactionsDate = 'idx_transactions_date';
  static const String idxTransactionsType = 'idx_transactions_type';
  static const String idxTransactionsSyncStatus =
      'idx_transactions_sync_status';

  // Budgets indexes
  static const String idxBudgetsAccountId = 'idx_budgets_account_id';
  static const String idxBudgetsCategoryId = 'idx_budgets_category_id';
  static const String idxBudgetsPeriod = 'idx_budgets_period';

  // Recurring rules indexes
  static const String idxRecurringNextDate = 'idx_recurring_next_date';
  static const String idxRecurringIsActive = 'idx_recurring_is_active';

  // Chat history indexes
  static const String idxChatHistoryUserId = 'idx_chat_history_user_id';
  static const String idxChatHistorySessionId = 'idx_chat_history_session_id';

  // Sync queue indexes
  static const String idxSyncQueueTableName = 'idx_sync_queue_table_name';
  static const String idxSyncQueueCreatedAt = 'idx_sync_queue_created_at';
}

// ============== Default System Categories ==============

class DefaultCategories {
  DefaultCategories._();

  static const List<Map<String, dynamic>> expenseCategories = [
    {
      'id': 'cat_food',
      'name': 'Food & Dining',
      'icon': 'restaurant',
      'color': 0xFFFF6B6B,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_transport',
      'name': 'Transportation',
      'icon': 'directions_car',
      'color': 0xFF4ECDC4,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_shopping',
      'name': 'Shopping',
      'icon': 'shopping_bag',
      'color': 0xFFFFE66D,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_entertainment',
      'name': 'Entertainment',
      'icon': 'movie',
      'color': 0xFF95E1D3,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_bills',
      'name': 'Bills & Utilities',
      'icon': 'receipt_long',
      'color': 0xFFF38181,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_health',
      'name': 'Health & Medical',
      'icon': 'medical_services',
      'color': 0xFFAA96DA,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_education',
      'name': 'Education',
      'icon': 'school',
      'color': 0xFFFCBF49,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_travel',
      'name': 'Travel',
      'icon': 'flight',
      'color': 0xFF00B4D8,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_groceries',
      'name': 'Groceries',
      'icon': 'local_grocery_store',
      'color': 0xFF80ED99,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_personal',
      'name': 'Personal Care',
      'icon': 'spa',
      'color': 0xFFFFAFCC,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_home',
      'name': 'Home & Garden',
      'icon': 'home',
      'color': 0xFFB5838D,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_gifts',
      'name': 'Gifts & Donations',
      'icon': 'card_giftcard',
      'color': 0xFFE07A5F,
      'type': 'expense',
      'isSystem': true,
    },
    {
      'id': 'cat_other_expense',
      'name': 'Other',
      'icon': 'more_horiz',
      'color': 0xFF9E9E9E,
      'type': 'expense',
      'isSystem': true,
    },
  ];

  static const List<Map<String, dynamic>> incomeCategories = [
    {
      'id': 'cat_salary',
      'name': 'Salary',
      'icon': 'work',
      'color': 0xFF52B788,
      'type': 'income',
      'isSystem': true,
    },
    {
      'id': 'cat_freelance',
      'name': 'Freelance',
      'icon': 'computer',
      'color': 0xFF3D5A80,
      'type': 'income',
      'isSystem': true,
    },
    {
      'id': 'cat_investment_income',
      'name': 'Investments',
      'icon': 'trending_up',
      'color': 0xFF06D6A0,
      'type': 'income',
      'isSystem': true,
    },
    {
      'id': 'cat_rental',
      'name': 'Rental Income',
      'icon': 'apartment',
      'color': 0xFF118AB2,
      'type': 'income',
      'isSystem': true,
    },
    {
      'id': 'cat_bonus',
      'name': 'Bonus',
      'icon': 'card_giftcard',
      'color': 0xFFEF476F,
      'type': 'income',
      'isSystem': true,
    },
    {
      'id': 'cat_refund',
      'name': 'Refund',
      'icon': 'replay',
      'color': 0xFFFFD166,
      'type': 'income',
      'isSystem': true,
    },
    {
      'id': 'cat_other_income',
      'name': 'Other Income',
      'icon': 'attach_money',
      'color': 0xFF073B4C,
      'type': 'income',
      'isSystem': true,
    },
  ];

  static List<Map<String, dynamic>> get allCategories => [
    ...expenseCategories,
    ...incomeCategories,
  ];
}
