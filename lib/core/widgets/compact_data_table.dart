import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

class CompactTableHeader extends StatelessWidget {
  const CompactTableHeader({
    required this.identityLabel,
    required this.trailing,
    this.identityIndent = 0,
    super.key,
  });

  final String identityLabel;
  final List<Widget> trailing;
  final double identityIndent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.compactTableHeader,
      padding: const EdgeInsets.only(
        left: AppSpacing.content,
        right: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.panelAlt,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: identityIndent),
              child: CompactColumnLabel(
                identityLabel,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
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
              fontSize: 9,
              letterSpacing: 0.65,
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasized ? 0.2 : 0.11),
        border: const Border(
          left: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: color,
          fontSize: 12.5,
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
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.slate),
        borderRadius: AppRadii.small,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.teal,
              fontSize: 8,
              letterSpacing: 0.25,
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
      height: AppSizes.compactSectionBar,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border(
          left: BorderSide(color: accent, width: 2),
          bottom: const BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 9,
                    letterSpacing: 0.35,
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
    this.height = AppSizes.compactInfoRow,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
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
                    fontSize: 11,
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
                fontSize: 11,
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

/// Shared list-row surface used by dense player, staff and scouting tables.
/// It centralizes alternating fills, the status rail and the separator so
/// feature rows cannot slowly drift apart visually.
class CompactRowSurface extends StatelessWidget {
  const CompactRowSurface({
    required this.child,
    required this.railColor,
    this.onTap,
    this.isAlternate = false,
    this.height = AppSizes.compactListRow,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final Color railColor;
  final VoidCallback? onTap;
  final bool isAlternate;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final row = Material(
      color: isAlternate ? AppColors.panelAlt : AppColors.navy,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.slate),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 3, child: ColoredBox(color: railColor)),
                const SizedBox(width: 7),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
    if (semanticLabel == null) return row;
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: row,
    );
  }
}

class CompactActionCell extends StatelessWidget {
  const CompactActionCell({
    required this.label,
    this.onPressed,
    this.width = 68,
    this.color = AppColors.teal,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onPressed != null,
        label: label,
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Material(
            color: onPressed == null
                ? AppColors.surfaceHigh
                : color.withValues(alpha: 0.12),
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 13, color: color),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color:
                                  onPressed == null ? AppColors.muted : color,
                              fontSize: 8,
                              letterSpacing: 0.45,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
