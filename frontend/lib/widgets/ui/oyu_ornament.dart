import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Ою-өрнек бөлгіш: сызық · ◇ ◆ ◇ · сызық (алтын, ~40% мөлдірлік).
class OyuDivider extends StatelessWidget {
  const OyuDivider({super.key, this.opacity = .4});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: 14,
        child: CustomPaint(
          size: const Size(double.infinity, 14),
          painter: _OyuDividerPainter(),
        ),
      ),
    );
  }
}

class _OyuDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final cx = size.width / 2;
    final stroke = Paint()
      ..color = AppColors.steppeGold
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = AppColors.steppeGold;

    canvas.drawLine(Offset(0, cy), Offset(cx - 34, cy), stroke);
    canvas.drawLine(Offset(cx + 34, cy), Offset(size.width, cy), stroke);

    void diamond(double x, double half, Paint paint) {
      final path = Path()
        ..moveTo(x, cy - half)
        ..lineTo(x + half, cy)
        ..lineTo(x, cy + half)
        ..lineTo(x - half, cy)
        ..close();
      canvas.drawPath(path, paint);
    }

    diamond(cx - 20, 5, stroke..strokeWidth = 2.5);
    diamond(cx, 6.5, fill);
    diamond(cx + 20, 5, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Жоғарғы жиек белдеуі: 2px алтын штрихтер (5px on / 6px gap).
class OyuDashBand extends StatelessWidget {
  const OyuDashBand({super.key, this.opacity = .55});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: 2,
        width: double.infinity,
        child: CustomPaint(painter: _DashPainter()),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.steppeGold
      ..strokeWidth = 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 1), Offset(x + 5, 1), paint);
      x += 11;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
