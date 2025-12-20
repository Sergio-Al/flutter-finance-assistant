import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/constants/icon_constants.dart';
import 'package:flutter_finance_assistant/core/themes/app_theme.dart';

/// A widget for selecting an icon from a grid.
///
/// Displays icons grouped by category in a scrollable bottom sheet.
class IconPickerBottomSheet extends StatefulWidget {
  /// Currently selected icon name.
  final String? selectedIcon;

  /// Callback when an icon is selected.
  final ValueChanged<String> onIconSelected;

  /// Optional color to display icons in.
  final Color? iconColor;

  const IconPickerBottomSheet({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
    this.iconColor,
  });

  /// Show the icon picker as a bottom sheet.
  static Future<String?> show({
    required BuildContext context,
    String? selectedIcon,
    Color? iconColor,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IconPickerBottomSheet(
        selectedIcon: selectedIcon,
        iconColor: iconColor,
        onIconSelected: (icon) => Navigator.pop(context, icon),
      ),
    );
  }

  @override
  State<IconPickerBottomSheet> createState() => _IconPickerBottomSheetState();
}

class _IconPickerBottomSheetState extends State<IconPickerBottomSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, IconData>> _getFilteredIcons() {
    if (_searchQuery.isEmpty) {
      return IconConstants.iconMap.entries.toList();
    }
    return IconConstants.iconMap.entries
        .where((e) => e.key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredIcons = _getFilteredIcons();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Select Icon',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search icons...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Icon grid
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildGroupedIcons(isDark)
                : _buildFlatGrid(filteredIcons, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedIcons(bool isDark) {
    final groupedIcons = IconConstants.groupedIcons;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedIcons.length,
      itemBuilder: (context, index) {
        final entry = groupedIcons.entries.elementAt(index);
        final groupName = entry.key;
        final icons = entry.value;

        if (icons.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                groupName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            _buildIconGrid(icons, isDark),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildFlatGrid(List<MapEntry<String, IconData>> icons, bool isDark) {
    if (icons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No icons found',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildIconGrid(icons, isDark),
    );
  }

  Widget _buildIconGrid(List<MapEntry<String, IconData>> icons, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: icons.length,
      itemBuilder: (context, index) {
        final iconEntry = icons[index];
        final isSelected = widget.selectedIcon == iconEntry.key;

        return _IconTile(
          iconData: iconEntry.value,
          iconName: iconEntry.key,
          isSelected: isSelected,
          iconColor: widget.iconColor,
          isDark: isDark,
          onTap: () => widget.onIconSelected(iconEntry.key),
        );
      },
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData iconData;
  final String iconName;
  final bool isSelected;
  final Color? iconColor;
  final bool isDark;
  final VoidCallback onTap;

  const _IconTile({
    required this.iconData,
    required this.iconName,
    required this.isSelected,
    this.iconColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor =
        iconColor ?? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? displayColor.withValues(alpha: 0.2)
                : isDark
                ? Colors.grey[850]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: displayColor, width: 2)
                : null,
          ),
          child: Icon(
            iconData,
            color: isSelected
                ? displayColor
                : isDark
                ? Colors.grey[400]
                : Colors.grey[700],
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Inline icon picker for forms.
///
/// Displays a small selection of icons with a "more" button.
class IconPickerField extends StatelessWidget {
  /// Currently selected icon name.
  final String? selectedIcon;

  /// Callback when an icon is selected.
  final ValueChanged<String> onIconSelected;

  /// Optional color to display icons in.
  final Color? iconColor;

  /// Optional label for the field.
  final String? label;

  const IconPickerField({
    super.key,
    this.selectedIcon,
    required this.onIconSelected,
    this.iconColor,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayColor =
        iconColor ?? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        InkWell(
          onTap: () async {
            final icon = await IconPickerBottomSheet.show(
              context: context,
              selectedIcon: selectedIcon,
              iconColor: iconColor,
            );
            if (icon != null) {
              onIconSelected(icon);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: displayColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    IconConstants.getIcon(selectedIcon),
                    color: displayColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedIcon ?? 'No icon selected',
                        style: TextStyle(
                          fontSize: 14,
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
        ),
      ],
    );
  }
}
