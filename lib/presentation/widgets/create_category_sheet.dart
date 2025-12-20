import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_finance_assistant/core/constants/icon_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/domain/entities/category.dart';
import 'package:flutter_finance_assistant/presentation/bloc/category/category_bloc_exports.dart';
import 'package:flutter_finance_assistant/presentation/widgets/icon_picker.dart';

/// Bottom sheet for creating a new custom category.
///
/// Allows users to set name, icon, color, and type for their category.
/// Uses CategoryBloc to handle creation.
class CreateCategorySheet extends StatefulWidget {
  /// The user ID for the new category.
  final String userId;

  /// Pre-selected category type (expense/income).
  final CategoryType? initialType;

  /// Callback when category is successfully created.
  final ValueChanged<Category>? onCategoryCreated;

  const CreateCategorySheet({
    super.key,
    required this.userId,
    this.initialType,
    this.onCategoryCreated,
  });

  /// Show the create category sheet as a modal bottom sheet.
  static Future<Category?> show({
    required BuildContext context,
    required String userId,
    CategoryType? initialType,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        // Check if CategoryBloc exists in parent context
        final categoryBloc = context.read<CategoryBloc>();
        return BlocProvider.value(
          value: categoryBloc,
          child: CreateCategorySheet(userId: userId, initialType: initialType),
        );
      },
    );
  }

  @override
  State<CreateCategorySheet> createState() => _CreateCategorySheetState();
}

class _CreateCategorySheetState extends State<CreateCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late CategoryType _selectedType;
  String _selectedIcon = 'category';
  int _selectedColor = 0xFF6C5CE7; // Default purple

  bool _isLoading = false;

  // Available colors for selection
  static const List<int> _availableColors = [
    0xFFFF6B6B, // Red
    0xFFFF8E53, // Orange
    0xFFFFD93D, // Yellow
    0xFF6BCB77, // Green
    0xFF4ECDC4, // Teal
    0xFF45B7D1, // Cyan
    0xFF6C5CE7, // Purple
    0xFFA8A4FF, // Lavender
    0xFFFF85A1, // Pink
    0xFF9B59B6, // Violet
    0xFF3498DB, // Blue
    0xFF1ABC9C, // Emerald
    0xFFE67E22, // Carrot
    0xFF95A5A6, // Gray
    0xFF34495E, // Dark Gray
    0xFF16A085, // Green Sea
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryOperationSuccess) {
          setState(() => _isLoading = false);
          // Find the newly created category and return it
          print('Category created successfully');
          if (state.category != null) {
            widget.onCategoryCreated?.call(state.category!);
            Navigator.pop(context, state.category);
          } else {
            Navigator.pop(context);
          }
        } else if (state is CategoryError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Create Category',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a custom category for your transactions',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Category Name
                  _buildLabel('Category Name', isDark),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'e.g., Groceries, Gym, Coffee',
                      filled: true,
                      fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a category name';
                      }
                      if (value.trim().length > 30) {
                        return 'Name must be 30 characters or less';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Category Type
                  _buildLabel('Category Type', isDark),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeOption(
                          type: CategoryType.expense,
                          isSelected: _selectedType == CategoryType.expense,
                          isDark: isDark,
                          onTap: () => setState(
                            () => _selectedType = CategoryType.expense,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeOption(
                          type: CategoryType.income,
                          isSelected: _selectedType == CategoryType.income,
                          isDark: isDark,
                          onTap: () => setState(
                            () => _selectedType = CategoryType.income,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Icon Selector
                  _buildLabel('Icon', isDark),
                  const SizedBox(height: 8),
                  _IconSelector(
                    selectedIcon: _selectedIcon,
                    selectedColor: _selectedColor,
                    isDark: isDark,
                    onIconSelected: (icon) =>
                        setState(() => _selectedIcon = icon),
                  ),
                  const SizedBox(height: 24),

                  // Color Selector
                  _buildLabel('Color', isDark),
                  const SizedBox(height: 8),
                  _ColorSelector(
                    selectedColor: _selectedColor,
                    colors: _availableColors,
                    isDark: isDark,
                    onColorSelected: (color) =>
                        setState(() => _selectedColor = color),
                  ),
                  const SizedBox(height: 32),

                  // Preview
                  _buildLabel('Preview', isDark),
                  const SizedBox(height: 8),
                  _CategoryPreview(
                    name: _nameController.text.isEmpty
                        ? 'Category Name'
                        : _nameController.text,
                    icon: _selectedIcon,
                    color: _selectedColor,
                    type: _selectedType,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createCategory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppTheme.primaryDark
                            : AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[300],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Category',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }

  void _createCategory() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    context.read<CategoryBloc>().add(
      CategoryCreateRequested(
        userId: widget.userId,
        name: _nameController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        type: _selectedType,
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final CategoryType type;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _TypeOption({
    required this.type,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = type == CategoryType.expense
        ? AppTheme.error
        : AppTheme.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? Colors.grey[900] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == CategoryType.expense
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: isSelected
                  ? color
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              type.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? color
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconSelector extends StatelessWidget {
  final String selectedIcon;
  final int selectedColor;
  final bool isDark;
  final ValueChanged<String> onIconSelected;

  const _IconSelector({
    required this.selectedIcon,
    required this.selectedColor,
    required this.isDark,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final icon = await IconPickerBottomSheet.show(
          context: context,
          selectedIcon: selectedIcon,
          iconColor: Color(selectedColor),
        );
        if (icon != null) {
          onIconSelected(icon);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(selectedColor).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconConstants.getIcon(selectedIcon),
                color: Color(selectedColor),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatIconName(selectedIcon),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Tap to change icon',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  String _formatIconName(String iconName) {
    return iconName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _ColorSelector extends StatelessWidget {
  final int selectedColor;
  final List<int> colors;
  final bool isDark;
  final ValueChanged<int> onColorSelected;

  const _ColorSelector({
    required this.selectedColor,
    required this.colors,
    required this.isDark,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((color) {
        final isSelected = color == selectedColor;
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(color),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: isDark ? Colors.white : Colors.black,
                      width: 3,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(color).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryPreview extends StatelessWidget {
  final String name;
  final String icon;
  final int color;
  final CategoryType type;
  final bool isDark;

  const _CategoryPreview({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(color).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              IconConstants.getIcon(icon),
              color: Color(color),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (type == CategoryType.expense
                                    ? AppTheme.error
                                    : AppTheme.success)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: type == CategoryType.expense
                              ? AppTheme.error
                              : AppTheme.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Custom',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
