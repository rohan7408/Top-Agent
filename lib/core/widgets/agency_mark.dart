import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AgencyMark extends StatelessWidget {
  const AgencyMark({this.size = 52, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.sports_soccer_rounded,
        size: size * 0.56,
        color: AppColors.midnight,
      ),
    );
  }
}
