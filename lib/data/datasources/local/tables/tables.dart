import 'package:drift/drift.dart';

/// Users table - stores user profile information.
///
/// Linked to Firebase Auth UID as primary key.
/// Most fields are nullable since user info comes from Firebase Auth.
@DataClassName('UserEntry')
class Users extends Table {
  /// Firebase Auth UID (primary key)
  TextColumn get id => text()();

  /// User's email address
  TextColumn get email => text()();

  /// Display name (optional)
  TextColumn get displayName => text().nullable()();

  /// Profile photo URL (optional)
  TextColumn get photoUrl => text().nullable()();

  /// Preferred currency code (e.g., 'USD', 'EUR')
  TextColumn get preferredCurrency => text().withDefault(const Constant('USD'))();

  /// Whether biometric authentication is enabled
  BoolColumn get biometricEnabled => boolean().withDefault(const Constant(false))();

  /// Theme preference: 'light', 'dark', or 'system'
  TextColumn get themePreference => text().withDefault(const Constant('system'))();

  /// When the account was created
  DateTimeColumn get createdAt => dateTime()();

  /// When the profile was last updated
  DateTimeColumn get updatedAt => dateTime()();

  /// When last synced with remote
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Accounts table - stores financial accounts (bank, cash, credit cards, etc.)
@DataClassName('AccountEntry')
class Accounts extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Owner user ID (foreign key to Users)
  TextColumn get userId => text().references(Users, #id)();

  /// Account display name
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Account type (cash, bank_account, credit_card, etc.)
  TextColumn get type => text()();

  /// Current balance
  RealColumn get balance => real().withDefault(const Constant(0.0))();

  /// Currency code
  TextColumn get currency => text().withDefault(const Constant('USD'))();

  /// Material icon name for display
  TextColumn get icon => text().withDefault(const Constant('account_balance_wallet'))();

  /// Color hex value for display
  IntColumn get color => integer().withDefault(const Constant(0xFF2E7D6F))();

  /// Whether the account is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// When the account was created
  DateTimeColumn get createdAt => dateTime()();

  /// When the account was last updated
  DateTimeColumn get updatedAt => dateTime()();

  /// Sync status: 'synced', 'pending', 'failed', 'syncing', 'conflict'
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Categories table - stores transaction categories.
///
/// Supports both system-defined and user-created categories.
/// Supports hierarchical structure with parent-child relationships.
@DataClassName('CategoryEntry')
class Categories extends Table {
  /// Unique identifier (UUID or system ID like 'cat_food')
  TextColumn get id => text()();

  /// Owner user ID (null for system categories)
  TextColumn get userId => text().nullable().references(Users, #id)();

  /// Category display name
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Material icon name
  TextColumn get icon => text()();

  /// Color hex value for display
  IntColumn get color => integer()();

  /// Category type: 'expense' or 'income'
  TextColumn get type => text()();

  /// Parent category ID for subcategories (self-referencing)
  TextColumn get parentId => text().nullable()();

  /// Whether this is a system-defined category (cannot be deleted)
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  /// When the category was created
  DateTimeColumn get createdAt => dateTime()();

  /// Sync status
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Transactions table - stores all financial transactions.
///
/// Core table for the app. Supports expenses, income, and transfers.
/// Includes AI categorization confidence and receipt attachments.
@DataClassName('TransactionEntry')
class Transactions extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Account this transaction belongs to
  TextColumn get accountId => text().references(Accounts, #id)();

  /// Category for this transaction
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Transaction amount (always positive)
  RealColumn get amount => real()();

  /// Transaction type: 'expense', 'income', or 'transfer'
  TextColumn get type => text()();

  /// Description or note (optional)
  TextColumn get description => text().nullable()();

  /// Date of the transaction
  DateTimeColumn get date => dateTime()();

  /// URL to receipt image (optional)
  TextColumn get receiptUrl => text().nullable()();

  /// Location where transaction occurred (optional)
  TextColumn get location => text().nullable()();

  /// Tags as JSON array string (optional)
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// AI categorization confidence (0.0 - 1.0)
  RealColumn get aiCategoryConfidence => real().nullable()();

  /// Whether this is a recurring transaction
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  /// ID of the recurring rule (if recurring)
  TextColumn get recurringId => text().nullable()();

  /// Target account for transfers
  TextColumn get toAccountId => text().nullable()();

  /// When the transaction was created
  DateTimeColumn get createdAt => dateTime()();

  /// When the transaction was last updated
  DateTimeColumn get updatedAt => dateTime()();

  /// Sync status
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Budgets table - stores budget limits per category/period.
@DataClassName('BudgetEntry')
class Budgets extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Account this budget applies to (null for all accounts)
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  /// Category this budget tracks
  TextColumn get categoryId => text().references(Categories, #id)();

  /// Budget limit amount
  RealColumn get amount => real()();

  /// Amount spent so far in current period
  RealColumn get spentAmount => real().withDefault(const Constant(0.0))();

  /// Budget period: 'daily', 'weekly', 'monthly', etc.
  TextColumn get period => text()();

  /// Start date of current budget period
  DateTimeColumn get startDate => dateTime()();

  /// End date of current budget period
  DateTimeColumn get endDate => dateTime()();

  /// Whether to roll over unused amount to next period
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();

  /// Whether budget alerts are enabled
  BoolColumn get alertsEnabled => boolean().withDefault(const Constant(true))();

  /// Custom alert threshold (0.0 - 1.0)
  RealColumn get alertThreshold => real().withDefault(const Constant(0.80))();

  /// When the budget was created
  DateTimeColumn get createdAt => dateTime()();

  /// When the budget was last updated
  DateTimeColumn get updatedAt => dateTime()();

  /// Sync status
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// RecurringRules table - defines recurring transaction schedules.
@DataClassName('RecurringRuleEntry')
class RecurringRules extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Template transaction ID
  TextColumn get transactionId => text().references(Transactions, #id)();

  /// Frequency: 'daily', 'weekly', 'monthly', etc.
  TextColumn get frequency => text()();

  /// Interval between occurrences (e.g., every 2 weeks)
  IntColumn get interval => integer().withDefault(const Constant(1))();

  /// Next scheduled date
  DateTimeColumn get nextDate => dateTime()();

  /// End date for the recurrence (null for indefinite)
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Whether the rule is active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Number of occurrences completed
  IntColumn get occurrenceCount => integer().withDefault(const Constant(0))();

  /// Maximum number of occurrences (null for unlimited)
  IntColumn get maxOccurrences => integer().nullable()();

  /// When the rule was created
  DateTimeColumn get createdAt => dateTime()();

  /// When the rule was last updated
  DateTimeColumn get updatedAt => dateTime()();

  /// Sync status
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Receipts table - stores OCR-scanned receipt data.
@DataClassName('ReceiptEntry')
class Receipts extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// Linked transaction ID (null if not yet linked)
  TextColumn get transactionId => text().nullable().references(Transactions, #id)();

  /// URL to receipt image (remote storage)
  TextColumn get imageUrl => text().nullable()();

  /// Local file path (before upload)
  TextColumn get localPath => text().nullable()();

  /// Raw text extracted by OCR
  TextColumn get ocrRawText => text().nullable()();

  /// OCR extraction confidence (0.0 - 1.0)
  RealColumn get ocrConfidence => real().nullable()();

  /// Extracted merchant name
  TextColumn get merchantName => text().nullable()();

  /// Extracted total amount
  RealColumn get totalAmount => real().nullable()();

  /// Extracted tax amount
  RealColumn get taxAmount => real().nullable()();

  /// Extracted receipt date
  DateTimeColumn get receiptDate => dateTime().nullable()();

  /// Suggested category based on merchant
  TextColumn get suggestedCategoryId => text().nullable()();

  /// Processing status: 'pending', 'processing', 'extracted', 'linked', 'failed'
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// When the receipt was created
  DateTimeColumn get createdAt => dateTime()();

  /// Sync status
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// ReceiptItems table - stores line items from receipts.
@DataClassName('ReceiptItemEntry')
class ReceiptItems extends Table {
  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// Parent receipt ID
  TextColumn get receiptId => text().references(Receipts, #id)();

  /// Item name/description
  TextColumn get name => text()();

  /// Item quantity
  RealColumn get quantity => real().withDefault(const Constant(1.0))();

  /// Unit price
  RealColumn get unitPrice => real()();

  /// Total price for this item
  RealColumn get totalPrice => real()();
}

/// ChatMessages table - stores AI conversation messages.
@DataClassName('ChatMessageEntry')
class ChatMessages extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// User ID who owns this chat
  TextColumn get userId => text().references(Users, #id)();

  /// Session ID for grouping conversations
  TextColumn get sessionId => text().references(ChatSessions, #id)();

  /// Role: 'user', 'assistant', or 'system'
  TextColumn get role => text()();

  /// Message content
  TextColumn get content => text()();

  /// Tokens used for this message (for AI messages)
  IntColumn get tokensUsed => integer().nullable()();

  /// AI model used (for AI messages)
  TextColumn get model => text().nullable()();

  /// Metadata as JSON string (function calls, tool responses)
  TextColumn get metadata => text().nullable()();

  /// When the message was created
  DateTimeColumn get createdAt => dateTime()();

  /// Sync status
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// ChatSessions table - groups chat messages into sessions.
@DataClassName('ChatSessionEntry')
class ChatSessions extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text()();

  /// User ID who owns this session
  TextColumn get userId => text().references(Users, #id)();

  /// Session title (auto-generated or user-defined)
  TextColumn get title => text().nullable()();

  /// When the session was created
  DateTimeColumn get createdAt => dateTime()();

  /// When the session was last updated
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// SyncQueue table - tracks pending sync operations for offline-first support.
///
/// When offline, operations are queued here and processed when back online.
@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  /// Auto-increment primary key
  IntColumn get id => integer().autoIncrement()();

  /// Table name for the operation
  TextColumn get tableNameColumn => text()();

  /// Record ID that was modified
  TextColumn get recordId => text()();

  /// Operation type: 'create', 'update', 'delete'
  TextColumn get operation => text()();

  /// Serialized data as JSON (for create/update)
  TextColumn get data => text().nullable()();

  /// When the operation was queued
  DateTimeColumn get createdAt => dateTime()();

  /// Number of sync attempts
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Last sync error message (if failed)
  TextColumn get lastError => text().nullable()();

  /// Status: 'pending', 'processing', 'failed'
  TextColumn get status => text().withDefault(const Constant('pending'))();
}
