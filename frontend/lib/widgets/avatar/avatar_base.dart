import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/shop_item.dart';

/// Маскот плейсхолдері — Бектұр/Назым слойлары.
/// Финалды арт (Lottie/vector) келгенде осы виджеттің слоттары ауыстырылады.
/// Слойлар реті: көлеңке → дене → бет → бас киім → аксессуар → питомец.
class AvatarBase extends StatelessWidget {
  const AvatarBase({
    super.key,
    required this.assistant,
    this.size = 160,
    this.equipped = const [],
    this.expression = AvatarExpression.happy,
  });

  final AssistantType assistant;
  final double size;
  final List<ShopItem> equipped;
  final AvatarExpression expression;

  Color get _accent => assistant == AssistantType.bektur
      ? AppColors.eagleBlue
      : AppColors.nazymRose;

  Color get _accentLight => assistant == AssistantType.bektur
      ? AppColors.eagleBlueLight
      : AppColors.nazymRoseLight;

  ShopItem? _byCategory(ShopCategory category) {
    for (final item in equipped) {
      if (item.category == category) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hat = _byCategory(ShopCategory.hat);
    final accessory = _byCategory(ShopCategory.accessory);
    final pet = _byCategory(ShopCategory.pet);
    final top = _byCategory(ShopCategory.top);

    final u = size / 160; // масштаб бірлігі

    return SizedBox(
      width: size,
      height: size * 1.1,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Көлеңке
          Positioned(
            bottom: 0,
            child: Container(
              width: size * .62,
              height: 12 * u,
              decoration: BoxDecoration(
                color: AppColors.nightInk.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          // Дене
          Positioned(
            bottom: 8 * u,
            child: Container(
              width: size * .78,
              height: size * .92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_accent, Color.lerp(_accent, AppColors.nightInk, .25)!],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(size * .39),
                  bottom: Radius.circular(size * .30),
                ),
                boxShadow: AppColors.sh2,
              ),
            ),
          ),
          // Кеуде дақтары (жоғарғы киім түсі)
          if (top != null)
            Positioned(
              bottom: 10 * u,
              child: Container(
                width: size * .74,
                height: size * .42,
                decoration: BoxDecoration(
                  color: top.color,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(size * .12),
                    bottom: Radius.circular(size * .28),
                  ),
                ),
              ),
            ),
          // Бет (іш жағы ашық)
          Positioned(
            bottom: size * .42,
            child: Container(
              width: size * .56,
              height: size * .42,
              decoration: BoxDecoration(
                color: _accentLight,
                borderRadius: BorderRadius.circular(size * .28),
              ),
              child: CustomPaint(
                painter: _FacePainter(
                  accent: _accent,
                  expression: expression,
                ),
              ),
            ),
          ),
          // Бас киім
          if (hat != null)
            Positioned(
              top: -6 * u,
              child: Icon(hat.icon, size: 34 * u, color: hat.color),
            ),
          // Аксессуар (оң жақ иық)
          if (accessory != null)
            Positioned(
              right: size * .02,
              bottom: size * .30,
              child: Icon(accessory.icon, size: 28 * u, color: accessory.color),
            ),
          // Питомец (сол жақ төмен)
          if (pet != null)
            Positioned(
              left: -10 * u,
              bottom: 0,
              child: Container(
                width: 44 * u,
                height: 44 * u,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.sh1,
                ),
                child: Icon(pet.icon, size: 26 * u, color: pet.color),
              ),
            ),
        ],
      ),
    );
  }
}

enum AvatarExpression { happy, celebrate, sad, neutral }

class _FacePainter extends CustomPainter {
  _FacePainter({required this.accent, required this.expression});

  final Color accent;
  final AvatarExpression expression;

  @override
  void paint(Canvas canvas, Size size) {
    final eye = Paint()..color = AppColors.nightInk;
    final eyeY = size.height * .42;
    final eyeR = size.width * .055;

    if (expression == AvatarExpression.celebrate) {
      // Қуанған көздер: ^ ^
      final stroke = Paint()
        ..color = AppColors.nightInk
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final cx in [size.width * .32, size.width * .68]) {
        final path = Path()
          ..moveTo(cx - eyeR * 1.4, eyeY + eyeR)
          ..lineTo(cx, eyeY - eyeR)
          ..lineTo(cx + eyeR * 1.4, eyeY + eyeR);
        canvas.drawPath(path, stroke);
      }
    } else {
      canvas.drawCircle(Offset(size.width * .32, eyeY), eyeR, eye);
      canvas.drawCircle(Offset(size.width * .68, eyeY), eyeR, eye);
    }

    // Ауыз
    final mouth = Paint()
      ..color = AppColors.nightInk
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final my = size.height * .66;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, my),
      width: size.width * .34,
      height: size.height * .22,
    );
    switch (expression) {
      case AvatarExpression.happy:
      case AvatarExpression.celebrate:
        canvas.drawArc(rect, .3, 2.5, false, mouth);
      case AvatarExpression.sad:
        canvas.drawArc(
          rect.translate(0, size.height * .12),
          3.45,
          2.5,
          false,
          mouth,
        );
      case AvatarExpression.neutral:
        canvas.drawLine(
          Offset(size.width * .40, my),
          Offset(size.width * .60, my),
          mouth,
        );
    }

    // Беттегі қызару
    final blush = Paint()..color = accent.withValues(alpha: .25);
    canvas.drawCircle(
        Offset(size.width * .18, size.height * .56), eyeR * 1.1, blush);
    canvas.drawCircle(
        Offset(size.width * .82, size.height * .56), eyeR * 1.1, blush);
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) =>
      oldDelegate.expression != expression || oldDelegate.accent != accent;
}
