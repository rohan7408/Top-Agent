import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class FootballBackdrop extends StatelessWidget {
  const FootballBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.midnight),
        CustomPaint(painter: _PitchLinesPainter()),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.midnight.withValues(alpha: 0.18),
                AppColors.midnight.withValues(alpha: 0.96),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final field = Rect.fromLTWH(
      size.width * 0.16,
      -size.height * 0.05,
      size.width * 0.98,
      size.height * 0.62,
    );
    canvas.save();
    final pivot = Offset(size.width / 2, size.height / 3);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(-0.12);
    canvas.translate(-pivot.dx, -pivot.dy);
    canvas.drawRect(field, paint);
    canvas.drawLine(field.centerLeft, field.centerRight, paint);
    canvas.drawCircle(field.center, size.width * 0.13, paint);
    canvas.drawRect(
      Rect.fromCenter(
        center: field.topCenter,
        width: size.width * 0.42,
        height: size.height * 0.15,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
