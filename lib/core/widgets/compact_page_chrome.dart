import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

/// Consistent, left-aligned identity block for compact detail-screen app bars.
class CompactPageTitle extends StatelessWidget {
  const CompactPageTitle({
    required this.title,
    this.eyebrow,
    this.accent = AppColors.teal,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final subtitle = eyebrow?.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
          ),
        ],
      ],
    );
  }
}

/// Shared tab treatment used by full-screen player, club, world, and report pages.
class CompactTabBar extends StatelessWidget implements PreferredSizeWidget {
  const CompactTabBar({
    required this.labels,
    this.height = AppSizes.minTouchTarget,
    this.fontSize = 10,
    this.isScrollable = false,
    super.key,
  });

  final List<String> labels;
  final double height;
  final double fontSize;
  final bool isScrollable;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: TabBar(
          isScrollable: isScrollable,
          tabAlignment: isScrollable ? TabAlignment.start : null,
          labelPadding: isScrollable
              ? const EdgeInsets.symmetric(horizontal: AppSpacing.md)
              : EdgeInsets.zero,
          labelStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
          tabs: [for (final label in labels) Tab(text: label)],
        ),
      );
}
