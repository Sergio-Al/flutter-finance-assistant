import 'package:flutter/material.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';

/// Visual indicator for password strength.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final strength = _calculateStrength(password);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength Bars
        Row(
          children: List.generate(4, (index) {
            final isActive = index < strength.level;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? strength.color
                      : (isDark ? Colors.grey[700] : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Strength Label & Requirements
        Row(
          children: [
            Text(
              strength.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: strength.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (strength.level < 4)
              Text(
                strength.suggestion,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
          ],
        ),
      ],
    );
  }

  _PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) {
      return _PasswordStrength(
        level: 0,
        label: '',
        color: Colors.grey,
        suggestion: '',
      );
    }

    int score = 0;
    String suggestion = '';

    // Length check
    if (password.length >= 8) {
      score++;
    } else {
      suggestion = 'Add ${8 - password.length} more characters';
    }

    // Uppercase check
    if (password.contains(RegExp(r'[A-Z]'))) {
      score++;
    } else if (suggestion.isEmpty) {
      suggestion = 'Add uppercase letter';
    }

    // Number check
    if (password.contains(RegExp(r'[0-9]'))) {
      score++;
    } else if (suggestion.isEmpty) {
      suggestion = 'Add a number';
    }

    // Special character check
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score++;
    } else if (suggestion.isEmpty) {
      suggestion = 'Add special character';
    }

    switch (score) {
      case 0:
      case 1:
        return _PasswordStrength(
          level: 1,
          label: 'Weak',
          color: AppTheme.error,
          suggestion: suggestion,
        );
      case 2:
        return _PasswordStrength(
          level: 2,
          label: 'Fair',
          color: AppTheme.warning,
          suggestion: suggestion,
        );
      case 3:
        return _PasswordStrength(
          level: 3,
          label: 'Good',
          color: AppTheme.info,
          suggestion: suggestion,
        );
      case 4:
      default:
        return _PasswordStrength(
          level: 4,
          label: 'Strong',
          color: AppTheme.success,
          suggestion: '',
        );
    }
  }
}

class _PasswordStrength {
  final int level;
  final String label;
  final Color color;
  final String suggestion;

  _PasswordStrength({
    required this.level,
    required this.label,
    required this.color,
    required this.suggestion,
  });
}
