import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_finance_assistant/core/themes/app_theme.dart';

/// Social sign-in button for Google, Apple, etc.
class SocialSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String icon;
  final String label;
  final bool isDark;
  final bool isApple;
  final bool isCompact;

  const SocialSignInButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.isDark,
    this.isApple = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Apple button styling
    final backgroundColor = isApple
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? Colors.grey[850] : Colors.white);

    final borderColor = isApple
        ? Colors.transparent
        : (isDark ? Colors.grey[700] : Colors.grey[300]);

    final textColor = isApple
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight);

    final iconColor = isApple ? (isDark ? Colors.black : Colors.white) : null;

    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor!, width: isApple ? 0 : 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(iconColor),
            if (!isCompact || label.isNotEmpty) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color? iconColor) {
    // Try to load SVG, fallback to icon
    if (icon.endsWith('.svg')) {
      return SvgPicture.asset(
        icon,
        width: 24,
        height: 24,
        colorFilter: iconColor != null
            ? ColorFilter.mode(iconColor, BlendMode.srcIn)
            : null,
        placeholderBuilder: (context) => Icon(
          isApple ? Icons.apple : Icons.g_mobiledata_rounded,
          size: 24,
          color: iconColor,
        ),
      );
    }

    // Fallback icons
    return Icon(
      isApple ? Icons.apple : Icons.g_mobiledata_rounded,
      size: 24,
      color: iconColor,
    );
  }
}
