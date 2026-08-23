import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class CompactTableHeader extends StatelessWidget {
  const CompactTableHeader({
    required this.identityLabel,
    required this.trailing,
    super.key,
  });

  final String identityLabel;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 13, right: 8),
      decoration: const BoxDecoration(
        color: AppColors.midnight,
        border: Border(
          top: BorderSide(color: AppColors.slate),
          bottom: BorderSide(color: AppColors.slate),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: CompactColumnLabel(identityLabel)),
          ...trailing,
        ],
      ),
    );
  }
}

class CompactColumnLabel extends StatelessWidget {
  const CompactColumnLabel(
    this.label, {
    this.width,
    this.alignment = Alignment.center,
    super.key,
  });

  final String label;
  final double? width;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: alignment,
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontSize: 8,
              letterSpacing: 0.8,
            ),
      ),
    );
    return width == null ? content : SizedBox(width: width, child: content);
  }
}

class CompactRatingCell extends StatelessWidget {
  const CompactRatingCell({
    required this.value,
    required this.color,
    this.width = 38,
    this.emphasized = false,
    super.key,
  });

  final int value;
  final Color color;
  final double width;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      alignment: Alignment.center,
      color: color.withValues(alpha: emphasized ? 0.28 : 0.16),
      child: Text(
        '$value',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class CompactPositionBadge extends StatelessWidget {
  const CompactPositionBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.slate.withValues(alpha: 0.72),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.38)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.teal,
              fontSize: 7,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}

Color compactRatingColor(int rating) {
  if (rating >= 80) return AppColors.teal;
  if (rating >= 65) return AppColors.ratingBlue;
  if (rating >= 50) return AppColors.amber;
  return AppColors.danger;
}

class CompactSectionBar extends StatelessWidget {
  const CompactSectionBar({
    required this.title,
    this.trailing,
    this.accent = AppColors.teal,
    super.key,
  });

  final String title;
  final String? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: AppColors.panelAlt,
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top: const BorderSide(color: AppColors.slate),
          bottom: const BorderSide(color: AppColors.slate),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontSize: 8,
                    letterSpacing: 1,
                  ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
            ),
        ],
      ),
    );
  }
}

class CompactInfoRow extends StatelessWidget {
  const CompactInfoRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.paper,
    this.height = 34,
    super.key,
  });

  final String label;
  final String value;
  final Color valueColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.slate)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: valueColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
