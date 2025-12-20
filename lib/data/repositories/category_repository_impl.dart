import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_finance_assistant/core/errors/exceptions.dart';
import 'package:flutter_finance_assistant/core/errors/failures.dart';
import 'package:flutter_finance_assistant/data/datasources/local/app_database.dart';
import 'package:flutter_finance_assistant/data/datasources/remote/category_remote_datasource.dart';
import 'package:flutter_finance_assistant/data/models/category_model.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/domain/repositories/category_repository.dart';
import 'package:flutter_finance_assistant/domain/repositories/user_repository.dart';

/// Implementation of [CategoryRepository] with offline-first approach.
///
/// Uses local Drift database as primary source and syncs with Firebase Firestore.
/// Provides methods to create, read, update, and delete categories,
/// handling both local and remote data sources transparently.
class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase _database;
  final CategoryRemoteDataSource _remoteDataSource;
  final UserRepository _userRepository;
  final Uuid _uuid;

  /// Creates [CategoryRepositoryImpl] with required data sources.
  CategoryRepositoryImpl({
    required AppDatabase database,
    required CategoryRemoteDataSource remoteDataSource,
    required UserRepository userRepository,
    Uuid? uuid,
  }) : _database = database,
       _remoteDataSource = remoteDataSource,
       _userRepository = userRepository,
       _uuid = uuid ?? const Uuid();

  // ═══════════════════════════════════════════════════════════════════════════
  // Read Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Category>>> getCategories(String userId) async {
    try {
      final entries = await _database.categoriesDao.getAllCategories(userId);
      final categories = entries.map(_entryToEntity).toList();
      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting categories: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategoriesByType(
    String userId,
    CategoryType type,
  ) async {
    try {
      final entries = await _database.categoriesDao.getByType(
        userId,
        type.value,
      );
      final categories = entries.map(_entryToEntity).toList();
      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get categories by type: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting categories by type: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getExpenseCategories(
    String userId,
  ) async {
    try {
      final entries = await _database.categoriesDao.getExpenseCategories(
        userId,
      );
      final categories = entries.map(_entryToEntity).toList();
      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get expense categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting expense categories: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getIncomeCategories(
    String userId,
  ) async {
    try {
      final entries = await _database.categoriesDao.getIncomeCategories(userId);
      final categories = entries.map(_entryToEntity).toList();
      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get income categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting income categories: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String categoryId) async {
    try {
      final entry = await _database.categoriesDao.getCategoryById(categoryId);
      if (entry == null) {
        return Left(
          NotFoundFailure(message: 'Category not found: $categoryId'),
        );
      }
      return Right(_entryToEntity(entry));
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get category: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting category: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getSubcategories(
    String parentId,
  ) async {
    try {
      final entries = await _database.categoriesDao.getSubcategories(parentId);
      final categories = entries.map(_entryToEntity).toList();
      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get subcategories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting subcategories: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getSystemCategories() async {
    try {
      final entries = await _database.categoriesDao.getSystemCategories();
      final categories = entries.map(_entryToEntity).toList();
      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get system categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting system categories: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCustomCategories(
    String userId,
  ) async {
    try {
      final entries = await _database.categoriesDao.getUserCategories(userId);
      final categories = entries.map(_entryToEntity).toList();
      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get custom categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting custom categories: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Create/Update/Delete Operations
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      // Ensure user exists in local database to satisfy foreign key constraint
      if (category.userId != null) {
        final ensureResult = await _userRepository.ensureUserExists(
          category.userId!,
        );
        if (ensureResult.isLeft()) {
          return Left(ensureResult.fold((l) => l, (_) => throw Exception()));
        }
      }

      final now = DateTime.now();

      final newCategory = category.copyWith(
        id: _uuid.v4(),
        createdAt: now,
        syncStatus: 'pending',
        isSystem: false, // User-created categories are never system categories
      );

      // Insert into local database
      await _database.categoriesDao.insertCategory(
        _entityToCompanion(newCategory),
      );

      // Add to sync queue
      await _database.syncQueueDao.enqueueCreate(
        tableName: 'categories',
        recordId: newCategory.id,
        data: CategoryModel.fromEntity(newCategory).toJson().toString(),
      );

      return Right(newCategory);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to create category: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error creating category: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(Category category) async {
    try {
      // Check if category can be edited (not a system category)
      final existingEntry = await _database.categoriesDao.getCategoryById(
        category.id,
      );
      if (existingEntry == null) {
        return Left(
          NotFoundFailure(
            message: 'Category not found for update: ${category.id}',
          ),
        );
      }
      if (existingEntry.isSystem) {
        return Left(
          PermissionFailure(message: 'System categories cannot be edited'),
        );
      }

      final updatedCategory = category.copyWith(syncStatus: 'pending');

      final success = await _database.categoriesDao.updateCategory(
        _entityToCompanion(updatedCategory),
      );

      if (!success) {
        return Left(
          NotFoundFailure(
            message: 'Category not found for update: ${category.id}',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueUpdate(
        tableName: 'categories',
        recordId: updatedCategory.id,
        data: CategoryModel.fromEntity(updatedCategory).toJson().toString(),
      );

      return Right(updatedCategory);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to update category: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error updating category: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String categoryId) async {
    try {
      // Check if category can be deleted (not a system category)
      final existingEntry = await _database.categoriesDao.getCategoryById(
        categoryId,
      );
      if (existingEntry == null) {
        return Left(
          NotFoundFailure(
            message: 'Category not found for deletion: $categoryId',
          ),
        );
      }
      if (existingEntry.isSystem) {
        return Left(
          PermissionFailure(message: 'System categories cannot be deleted'),
        );
      }

      // Check for subcategories
      final subcategories = await _database.categoriesDao.getSubcategories(
        categoryId,
      );
      if (subcategories.isNotEmpty) {
        return Left(
          ValidationFailure(
            message:
                'Cannot delete category with subcategories. '
                'Please delete subcategories first.',
          ),
        );
      }

      final deletedCount = await _database.categoriesDao.deleteCategory(
        categoryId,
      );

      if (deletedCount == 0) {
        return Left(
          NotFoundFailure(
            message: 'Category not found for deletion: $categoryId',
          ),
        );
      }

      // Add to sync queue
      await _database.syncQueueDao.enqueueDelete(
        tableName: 'categories',
        recordId: categoryId,
      );

      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to delete category: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error deleting category: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Initialization & Search
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<Category>>> initializeDefaultCategories(
    String userId,
  ) async {
    try {
      final now = DateTime.now();
      final createdCategories = <Category>[];

      // Check if user already has categories
      final existingCategories = await _database.categoriesDao.getAllCategories(
        userId,
      );
      if (existingCategories.isNotEmpty) {
        // User already has categories, return them
        return Right(existingCategories.map(_entryToEntity).toList());
      }

      // Create expense categories
      for (final catData in DefaultCategories.expense) {
        final category = Category(
          id: 'cat_${_uuid.v4()}',
          userId: userId,
          name: catData['name'] as String,
          icon: catData['icon'] as String,
          color: catData['color'] as int,
          type: CategoryType.expense,
          isSystem: false,
          createdAt: now,
          syncStatus: 'pending',
        );

        await _database.categoriesDao.insertCategory(
          _entityToCompanion(category),
        );
        createdCategories.add(category);
      }

      // Create income categories
      for (final catData in DefaultCategories.income) {
        final category = Category(
          id: 'cat_${_uuid.v4()}',
          userId: userId,
          name: catData['name'] as String,
          icon: catData['icon'] as String,
          color: catData['color'] as int,
          type: CategoryType.income,
          isSystem: false,
          createdAt: now,
          syncStatus: 'pending',
        );

        await _database.categoriesDao.insertCategory(
          _entityToCompanion(category),
        );
        createdCategories.add(category);
      }

      // Add all to sync queue as batch
      for (final category in createdCategories) {
        await _database.syncQueueDao.enqueueCreate(
          tableName: 'categories',
          recordId: category.id,
          data: CategoryModel.fromEntity(category).toJson().toString(),
        );
      }

      return Right(createdCategories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to initialize default categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error initializing default categories: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> searchCategories(
    String userId,
    String query,
  ) async {
    try {
      final entries = await _database.categoriesDao.getAllCategories(userId);

      // Filter by search query (case-insensitive)
      final lowercaseQuery = query.toLowerCase();
      final matchingEntries = entries.where((entry) {
        return entry.name.toLowerCase().contains(lowercaseQuery);
      }).toList();

      final categories = matchingEntries.map(_entryToEntity).toList();
      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to search categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error searching categories: $e',
          originalError: e,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getMostUsedCategories(
    String userId, {
    int limit = 5,
  }) async {
    try {
      // Get all categories for the user
      final entries = await _database.categoriesDao.getAllCategories(userId);

      // To get most used categories, we would need to count transactions per category
      // For now, return the first `limit` categories as a simple implementation
      // In a full implementation, this would join with transactions table
      final limitedEntries = entries.take(limit).toList();
      final categories = limitedEntries.map(_entryToEntity).toList();
      return Right(categories);
    } on DatabaseException catch (e) {
      return Left(
        DatabaseFailure(
          message: 'Failed to get most used categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        CacheFailure(
          message: 'Unexpected error getting most used categories: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Streams
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Stream<Either<Failure, List<Category>>> watchCategories(String userId) {
    return _database.categoriesDao.watchAllCategories(userId).map((entries) {
      try {
        final categories = entries.map(_entryToEntity).toList();
        return Right<Failure, List<Category>>(categories);
      } catch (e) {
        return Left<Failure, List<Category>>(
          CacheFailure(
            message: 'Error watching categories: $e',
            originalError: e,
          ),
        );
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Remote Sync Operations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Sync categories from remote to local database.
  Future<Either<Failure, void>> syncFromRemote(String userId) async {
    try {
      final remoteCategories = await _remoteDataSource.getCategories(userId);

      for (final model in remoteCategories) {
        final existingEntry = await _database.categoriesDao.getCategoryById(
          model.id,
        );

        if (existingEntry == null) {
          await _database.categoriesDao.insertCategory(
            _modelToCompanion(model, syncStatus: 'synced'),
          );
        } else {
          if (model.createdAt.isAfter(existingEntry.createdAt)) {
            await _database.categoriesDao.updateCategory(
              _modelToCompanion(model, syncStatus: 'synced'),
            );
          }
        }
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync categories from remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing categories: $e',
          originalError: e,
        ),
      );
    }
  }

  /// Push pending local changes to remote.
  Future<Either<Failure, void>> syncToRemote(String userId) async {
    try {
      final pendingCategories = await _database.categoriesDao.getPendingSync();

      for (final entry in pendingCategories) {
        final model = CategoryModel.fromEntity(_entryToEntity(entry));
        await _remoteDataSource.updateCategory(userId, model);
        await _database.categoriesDao.updateSyncStatus(entry.id, 'synced');
      }

      return const Right(null);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to sync categories to remote: ${e.message}',
          originalError: e,
        ),
      );
    } on NetworkException catch (e) {
      return Left(
        NetworkFailure(
          message: 'Network error syncing categories: ${e.message}',
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(
        SyncFailure(
          message: 'Unexpected error syncing categories: $e',
          originalError: e,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Conversion Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  /// Convert Drift [CategoryEntry] to domain [Category] entity.
  Category _entryToEntity(CategoryEntry entry) {
    return Category(
      id: entry.id,
      userId: entry.userId,
      name: entry.name,
      icon: entry.icon,
      color: entry.color,
      type: CategoryTypeExtension.fromString(entry.type),
      parentId: entry.parentId,
      isSystem: entry.isSystem,
      createdAt: entry.createdAt,
      syncStatus: entry.syncStatus,
    );
  }

  /// Convert domain [Category] entity to Drift [CategoriesCompanion].
  CategoriesCompanion _entityToCompanion(Category entity) {
    return CategoriesCompanion(
      id: Value(entity.id),
      userId: Value(entity.userId),
      name: Value(entity.name),
      icon: Value(entity.icon),
      color: Value(entity.color),
      type: Value(entity.type.value),
      parentId: Value(entity.parentId),
      isSystem: Value(entity.isSystem),
      createdAt: Value(entity.createdAt),
      syncStatus: Value(entity.syncStatus),
    );
  }

  /// Convert [CategoryModel] to Drift [CategoriesCompanion].
  CategoriesCompanion _modelToCompanion(
    CategoryModel model, {
    String syncStatus = 'pending',
  }) {
    return CategoriesCompanion(
      id: Value(model.id),
      userId: Value(model.userId),
      name: Value(model.name),
      icon: Value(model.icon),
      color: Value(model.color),
      type: Value(model.type),
      parentId: Value(model.parentId),
      isSystem: Value(model.isSystem),
      createdAt: Value(model.createdAt),
      syncStatus: Value(syncStatus),
    );
  }
}
