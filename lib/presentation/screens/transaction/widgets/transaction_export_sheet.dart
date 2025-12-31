import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';
import 'package:flutter_finance_assistant/presentation/widgets/glass_card.dart';

/// Bottom sheet for exporting transactions (PDF/CSV).
class TransactionExportSheet extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final int transactionCount;
  final Function(ExportConfig config) onExport;

  const TransactionExportSheet({
    super.key,
    this.startDate,
    this.endDate,
    required this.transactionCount,
    required this.onExport,
  });

  static Future<void> show(
    BuildContext context, {
    DateTime? startDate,
    DateTime? endDate,
    required int transactionCount,
    required Function(ExportConfig config) onExport,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionExportSheet(
        startDate: startDate,
        endDate: endDate,
        transactionCount: transactionCount,
        onExport: onExport,
      ),
    );
  }

  @override
  State<TransactionExportSheet> createState() => _TransactionExportSheetState();
}

class _TransactionExportSheetState extends State<TransactionExportSheet> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  ExportDateRange _selectedDateRange = ExportDateRange.currentMonth;
  late DateTime _customStartDate;
  late DateTime _customEndDate;
  bool _includeReceipts = false;
  bool _includeNotes = true;
  bool _groupByCategory = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _customStartDate = widget.startDate ?? DateTime(now.year, now.month, 1);
    _customEndDate = widget.endDate ?? now;

    if (widget.startDate != null || widget.endDate != null) {
      _selectedDateRange = ExportDateRange.custom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.file_download_outlined,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Transactions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.transactionCount} transactions available',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Export Format
              _buildSectionLabel('Format', isDark),
              const SizedBox(height: 8),
              Row(
                children: ExportFormat.values.map((format) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: format != ExportFormat.values.last ? 8 : 0,
                      ),
                      child: _FormatOption(
                        format: format,
                        isSelected: _selectedFormat == format,
                        onTap: () => setState(() => _selectedFormat = format),
                        isDark: isDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Date Range
              _buildSectionLabel('Date Range', isDark),
              const SizedBox(height: 8),
              _DateRangeSelector(
                selectedRange: _selectedDateRange,
                customStartDate: _customStartDate,
                customEndDate: _customEndDate,
                onRangeChanged: (range) {
                  setState(() => _selectedDateRange = range);
                },
                onCustomDatesChanged: (start, end) {
                  setState(() {
                    _customStartDate = start;
                    _customEndDate = end;
                  });
                },
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // Export Options
              _buildSectionLabel('Options', isDark),
              const SizedBox(height: 8),
              _OptionToggle(
                label: 'Group by category',
                subtitle: 'Organize transactions by category',
                value: _groupByCategory,
                onChanged: (value) => setState(() => _groupByCategory = value),
                isDark: isDark,
              ),
              _OptionToggle(
                label: 'Include notes',
                subtitle: 'Add transaction descriptions',
                value: _includeNotes,
                onChanged: (value) => setState(() => _includeNotes = value),
                isDark: isDark,
              ),
              if (_selectedFormat == ExportFormat.pdf)
                _OptionToggle(
                  label: 'Include receipt images',
                  subtitle: 'Attach receipt photos to PDF',
                  value: _includeReceipts,
                  onChanged: (value) =>
                      setState(() => _includeReceipts = value),
                  isDark: isDark,
                ),
              const SizedBox(height: 24),

              // Preview info
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppTheme.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getPreviewText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _handleExport,
                      icon: _isExporting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            )
                          : Icon(_selectedFormat.icon, size: 18),
                      label: Text(
                        _isExporting
                            ? 'Exporting...'
                            : 'Export ${_selectedFormat.label}',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
    );
  }

  String _getPreviewText() {
    final dateRange = _getDateRangeText();
    return 'Export will include transactions from $dateRange as ${_selectedFormat.label} file.';
  }

  String _getDateRangeText() {
    switch (_selectedDateRange) {
      case ExportDateRange.currentMonth:
        return 'this month';
      case ExportDateRange.lastMonth:
        return 'last month';
      case ExportDateRange.last3Months:
        return 'the last 3 months';
      case ExportDateRange.last6Months:
        return 'the last 6 months';
      case ExportDateRange.thisYear:
        return 'this year';
      case ExportDateRange.allTime:
        return 'all time';
      case ExportDateRange.custom:
        return '${_formatDate(_customStartDate)} to ${_formatDate(_customEndDate)}';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _handleExport() async {
    setState(() => _isExporting = true);

    final dates = _getDateRange();
    final config = ExportConfig(
      format: _selectedFormat,
      startDate: dates.$1,
      endDate: dates.$2,
      includeReceipts: _includeReceipts,
      includeNotes: _includeNotes,
      groupByCategory: _groupByCategory,
    );

    widget.onExport(config);

    // Simulate export delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();

    switch (_selectedDateRange) {
      case ExportDateRange.currentMonth:
        return (DateTime(now.year, now.month, 1), now);
      case ExportDateRange.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        return (lastMonth, lastDayOfLastMonth);
      case ExportDateRange.last3Months:
        return (DateTime(now.year, now.month - 3, 1), now);
      case ExportDateRange.last6Months:
        return (DateTime(now.year, now.month - 6, 1), now);
      case ExportDateRange.thisYear:
        return (DateTime(now.year, 1, 1), now);
      case ExportDateRange.allTime:
        return (DateTime(2020, 1, 1), now);
      case ExportDateRange.custom:
        return (_customStartDate, _customEndDate);
    }
  }
}

class _FormatOption extends StatelessWidget {
  final ExportFormat format;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FormatOption({
    required this.format,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight.withValues(alpha: 0.15)
              : (isDark ? Colors.grey[900] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              format.icon,
              size: 28,
              color: isSelected ? AppTheme.primaryLight : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              format.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryLight
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            Text(
              format.description,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  final ExportDateRange selectedRange;
  final DateTime customStartDate;
  final DateTime customEndDate;
  final ValueChanged<ExportDateRange> onRangeChanged;
  final Function(DateTime start, DateTime end) onCustomDatesChanged;
  final bool isDark;

  const _DateRangeSelector({
    required this.selectedRange,
    required this.customStartDate,
    required this.customEndDate,
    required this.onRangeChanged,
    required this.onCustomDatesChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExportDateRange.values.map((range) {
            final isSelected = selectedRange == range;
            return GestureDetector(
              onTap: () => onRangeChanged(range),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryLight.withValues(alpha: 0.15)
                      : (isDark ? Colors.grey[900] : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  range.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryLight
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedRange == ExportDateRange.custom) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DatePickerButton(
                  label: 'From',
                  date: customStartDate,
                  onDateSelected: (date) =>
                      onCustomDatesChanged(date, customEndDate),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerButton(
                  label: 'To',
                  date: customEndDate,
                  onDateSelected: (date) =>
                      onCustomDatesChanged(customStartDate, date),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;
  final bool isDark;

  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onDateSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                    ),
                  ),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _OptionToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _OptionToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }
}

/// Export format enum.
enum ExportFormat {
  pdf('PDF', 'Formatted report', Icons.picture_as_pdf),
  csv('CSV', 'Spreadsheet data', Icons.table_chart),
  excel('Excel', 'Full workbook', Icons.grid_on);

  final String label;
  final String description;
  final IconData icon;

  const ExportFormat(this.label, this.description, this.icon);
}

/// Export date range options.
enum ExportDateRange {
  currentMonth('This Month'),
  lastMonth('Last Month'),
  last3Months('Last 3 Months'),
  last6Months('Last 6 Months'),
  thisYear('This Year'),
  allTime('All Time'),
  custom('Custom');

  final String label;

  const ExportDateRange(this.label);
}

/// Export configuration model.
class ExportConfig {
  final ExportFormat format;
  final DateTime startDate;
  final DateTime endDate;
  final bool includeReceipts;
  final bool includeNotes;
  final bool groupByCategory;

  const ExportConfig({
    required this.format,
    required this.startDate,
    required this.endDate,
    this.includeReceipts = false,
    this.includeNotes = true,
    this.groupByCategory = true,
  });
}
