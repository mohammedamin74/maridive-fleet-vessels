import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Compact KPI card used across the dashboard command strip. Shows a tinted
/// icon chip, a large emphasised value, and a caption label. Designed to sit
/// four-across on wide layouts and stay legible when they narrow.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? accent;

  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final color = accent ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.navy800 : Colors.white,
        borderRadius: AppRadius.xlAll,
        border: Border.all(
          color: dark ? AppColors.navy700 : AppColors.slate200,
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.navy900.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: dark ? 0.18 : 0.12),
              borderRadius: AppRadius.smAll,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 19),
          ),
          Gaps.h12,
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
