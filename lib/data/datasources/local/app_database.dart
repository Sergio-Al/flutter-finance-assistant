import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_finance_assistant/core/constants/database_constants.dart';
import 'package:flutter_finance_assistant/data/datasources/local/tables/tables.dart';
import 'package:flutter_finance_assistant/data/datasources/local/daos/daos.dart';

part 'app_database.g.dart';

/// Main Drift database for the Finance Assistant app.
///
/// This database handles all local data persistence with offline-first support.
/// Tables are synced with Firebase Firestore when online.
///
/// Usage:
/// ```dart
/// final db = AppDatabase();
/// final accounts = await db.accountsDao.getAllAccounts();
/// ```
@DriftDatabase(
  tables: [
    Users,
    Accounts,
    Categories,
    Transactions,
    Budgets,
    RecurringRules,
    Receipts,
    ReceiptItems,
    ChatMessages,
    ChatSessions,
    SyncQueue,
  ],
  daos: [
    UsersDao,
    AccountsDao,
    CategoriesDao,
    TransactionsDao,
    BudgetsDao,
    RecurringRulesDao,
    ReceiptsDao,
    ChatDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Creates a new database instance.
  ///
  /// Uses lazy initialization - database file created on first access.
  AppDatabase() : super(_openConnection());

  /// Creates a database instance for testing with in-memory storage.
  AppDatabase.forTesting(super.e);

  /// Current database schema version.
  ///
  /// Increment when making schema changes and add migration logic.
  @override
  int get schemaVersion => DatabaseConfig.databaseVersion;

  /// Handle database migrations when schema version changes.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Create all tables on fresh install
        await m.createAll();
        // Seed default categories
        await _seedDefaultCategories();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Add migration logic here for future schema changes
        // Example:
        // if (from < 2) {
        //   await m.addColumn(transactions, transactions.newColumn);
        // }
      },
      beforeOpen: (details) async {
        // Enable foreign keys for SQLite
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Seed default expense and income categories on first run.
  Future<void> _seedDefaultCategories() async {
    final now = DateTime.now();
    
    // Default expense categories
    final expenseCategories = [
      _createCategory('cat_food', 'Food & Dining', 'restaurant', 0xFFFF6B6B, 'expense', now),
      _createCategory('cat_transport', 'Transportation', 'directions_car', 0xFF4ECDC4, 'expense', now),
      _createCategory('cat_shopping', 'Shopping', 'shopping_bag', 0xFFFFE66D, 'expense', now),
      _createCategory('cat_entertainment', 'Entertainment', 'movie', 0xFF95E1D3, 'expense', now),
      _createCategory('cat_bills', 'Bills & Utilities', 'receipt_long', 0xFFF38181, 'expense', now),
      _createCategory('cat_health', 'Health & Medical', 'medical_services', 0xFFAA96DA, 'expense', now),
      _createCategory('cat_groceries', 'Groceries', 'local_grocery_store', 0xFF80ED99, 'expense', now),
      _createCategory('cat_personal', 'Personal Care', 'spa', 0xFFDDB892, 'expense', now),
      _createCategory('cat_education', 'Education', 'school', 0xFF90DBF4, 'expense', now),
      _createCategory('cat_travel', 'Travel', 'flight', 0xFFF9C74F, 'expense', now),
      _createCategory('cat_subscriptions', 'Subscriptions', 'subscriptions', 0xFFA8DADC, 'expense', now),
      _createCategory('cat_other_expense', 'Other', 'more_horiz', 0xFFBDBDBD, 'expense', now),
    ];

    // Default income categories
    final incomeCategories = [
      _createCategory('cat_salary', 'Salary', 'work', 0xFF52B788, 'income', now),
      _createCategory('cat_freelance', 'Freelance', 'computer', 0xFF3D5A80, 'income', now),
      _createCategory('cat_investments', 'Investments', 'trending_up', 0xFF06D6A0, 'income', now),
      _createCategory('cat_gifts', 'Gifts', 'card_giftcard', 0xFFE07BE0, 'income', now),
      _createCategory('cat_refunds', 'Refunds', 'replay', 0xFF48CAE4, 'income', now),
      _createCategory('cat_other_income', 'Other Income', 'attach_money', 0xFF99D98C, 'income', now),
    ];

    // Insert all categories
    await batch((batch) {
      batch.insertAll(categories, [...expenseCategories, ...incomeCategories]);
    });
  }

  /// Helper to create a category companion for insertion.
  CategoriesCompanion _createCategory(
    String id,
    String name,
    String icon,
    int color,
    String type,
    DateTime createdAt,
  ) {
    return CategoriesCompanion.insert(
      id: id,
      name: name,
      icon: icon,
      color: color,
      type: type,
      isSystem: const Value(true),
      createdAt: createdAt,
      syncStatus: const Value('synced'),
    );
  }

  /// Delete all data from the database.
  ///
  /// Use with caution - primarily for logout/account deletion.
  Future<void> deleteAllData() async {
    await transaction(() async {
      // Delete in reverse order of dependencies
      await delete(syncQueue).go();
      await delete(chatMessages).go();
      await delete(chatSessions).go();
      await delete(receiptItems).go();
      await delete(receipts).go();
      await delete(recurringRules).go();
      await delete(budgets).go();
      await delete(transactions).go();
      await delete(categories).go();
      await delete(accounts).go();
      await delete(users).go();
    });
  }

  /// Close the database connection.
  Future<void> closeDatabase() async {
    await close();
  }
}

/// Opens a connection to the SQLite database.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, DatabaseConfig.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
