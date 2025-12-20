import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/constants/icon_constants.dart';
import 'package:flutter_finance_assistant/core/di/injection_container.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/presentation/bloc/category/category_bloc_exports.dart';
import 'package:flutter_finance_assistant/presentation/widgets/create_category_sheet.dart';

/// A widget for selecting a category from a bottom sheet list.
///
/// Uses CategoryBloc to load and display categories.
/// Can filter by CategoryType (expense/income).
class CategorySelector extends StatelessWidget {
  /// The currently selected category ID.
  final String? selectedCategoryId;

  /// Callback when a category is selected.
  final ValueChanged<Category> onCategorySelected;

  /// Filter categories by type (null = all).
  final CategoryType? filterType;

  /// The user ID to load categories for.
  final String userId;

  /// Optional hint text when no category is selected.
  final String? hintText;

  const CategorySelector({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.filterType,
    required this.userId,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = sl<CategoryBloc>();
        // Load based on filter type
        if (filterType == CategoryType.expense) {
          bloc.add(CategoryLoadExpenseRequested(userId: userId));
        } else if (filterType == CategoryType.income) {
          bloc.add(CategoryLoadIncomeRequested(userId: userId));
        } else {
          bloc.add(CategoryLoadRequested(userId: userId));
        }
        return bloc;
      },
      child: _CategorySelectorContent(
        userId: userId,
        selectedCategoryId: selectedCategoryId,
        onCategorySelected: onCategorySelected,
        filterType: filterType,
        hintText: hintText,
      ),
    );
  }
}

class _CategorySelectorContent extends StatelessWidget {
  final String userId;
  final String? selectedCategoryId;
  final ValueChanged<Category> onCategorySelected;
  final CategoryType? filterType;
  final String? hintText;

  const _CategorySelectorContent({
    required this.userId,
    this.selectedCategoryId,
    required this.onCategorySelected,
    this.filterType,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        Category? selectedCategory;
        if (state is CategoryLoaded && selectedCategoryId != null) {
          selectedCategory = state.categories.firstWhere(
            (c) => c.id == selectedCategoryId,
            orElse: () => state.categories.first,
          );
        }

        return GestureDetector(
          onTap: () => _showCategoryPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                if (selectedCategory != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(
                        selectedCategory.color,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconConstants.getIcon(selectedCategory.icon),
                      color: Color(selectedCategory.color),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedCategory.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          selectedCategory.type.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.category_outlined,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hintText ?? 'Select a category',
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
                Icon(
                  Icons.keyboard_arrow_down,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryPicker(BuildContext context) {
    final categoryBloc = context.read<CategoryBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: categoryBloc,
        child: _CategoryPickerSheet(
          userId: userId,
          parentContext: context,
          selectedCategoryId: selectedCategoryId,
          onCategorySelected: (category) {
            onCategorySelected(category);
            Navigator.pop(sheetContext);
          },
          // Separate callback for when category is created (picker already closed)
          onCategoryCreated: onCategorySelected,
          filterType: filterType,
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  final String userId;
  final BuildContext parentContext;
  final String? selectedCategoryId;
  final ValueChanged<Category> onCategorySelected;
  final ValueChanged<Category> onCategoryCreated;
  final CategoryType? filterType;

  const _CategoryPickerSheet({
    required this.userId,
    required this.parentContext,
    this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onCategoryCreated,
    this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Select Category',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Category List
          Flexible(
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is CategoryError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is CategoryLoaded) {
                  final categories = state.filteredCategories;

                  if (categories.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 48,
                              color: isDark
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No categories available',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Group by type
                  final expenseCategories = categories
                      .where((c) => c.type == CategoryType.expense)
                      .toList();
                  final incomeCategories = categories
                      .where((c) => c.type == CategoryType.income)
                      .toList();

                  return ListView(
                    shrinkWrap: true,
                    children: [
                      // Add Category Button
                      _buildAddCategoryTile(context, isDark),
                      const Divider(height: 1),
                      if (filterType == null ||
                          filterType == CategoryType.expense) ...[
                        if (expenseCategories.isNotEmpty) ...[
                          _buildSectionHeader('Expense', isDark),
                          ...expenseCategories.map(
                            (c) => _buildCategoryTile(context, c, isDark),
                          ),
                        ],
                      ],
                      if (filterType == null ||
                          filterType == CategoryType.income) ...[
                        if (incomeCategories.isNotEmpty) ...[
                          _buildSectionHeader('Income', isDark),
                          ...incomeCategories.map(
                            (c) => _buildCategoryTile(context, c, isDark),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAddCategoryTile(BuildContext context, bool isDark) {
    final primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;

    return ListTile(
      onTap: () async {
        final categoryBloc = context.read<CategoryBloc>();

        // Close the picker first
        Navigator.pop(context);

        // Show create category sheet using parent context (which is still valid)
        final newCategory = await showModalBottomSheet<Category>(
          context: parentContext,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => BlocProvider.value(
            value: categoryBloc,
            child: CreateCategorySheet(userId: userId, initialType: filterType),
          ),
        );

        // If a category was created, select it (using onCategoryCreated which doesn't pop)
        if (newCategory != null) {
          onCategoryCreated(newCategory);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Icon(Icons.add, color: primaryColor, size: 24),
      ),
      title: Text(
        'Create New Category',
        style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor),
      ),
      subtitle: Text(
        'Add a custom category',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    Category category,
    bool isDark,
  ) {
    final isSelected = category.id == selectedCategoryId;
    final color = Color(category.color);

    return ListTile(
      onTap: () => onCategorySelected(category),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          IconConstants.getIcon(category.icon),
          color: color,
          size: 22,
        ),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: category.isSystem
          ? null
          : Text(
              'Custom',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
            )
          : null,
    );
  }
}
