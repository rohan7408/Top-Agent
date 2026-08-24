import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({
    required this.icon,
    required this.title,
    required this.message,
    this.accent = AppColors.teal,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.content,
            AppSpacing.lg,
            AppSpacing.content,
            0,
          ),
          child: CompactEmptyState(
            icon: icon,
            title: title,
            message: message,
            accent: accent,
          ),
        ),
      );
}

class CompactEmptyState extends StatelessWidget {
  const CompactEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.accent = AppColors.teal,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.panelAlt,
          border: Border(
            left: BorderSide(color: accent, width: AppBorders.emphasis),
            top: const BorderSide(color: AppColors.divider),
            right: const BorderSide(color: AppColors.divider),
            bottom: const BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadii.small,
              ),
              child: Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
