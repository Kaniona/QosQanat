import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/enums.dart';
import '../../models/shop_item.dart';

/// QosQanat серігі — **бүркіт балапаны** маскоты (Бектұр көк, Назым қызғылт).
/// Толық CustomPaint-пен салынады: дене + қанат + айдар + бүркіт қасы + алтын
/// тұмсық + үлкен достық көздер. Көңіл-күй (happy/celebrate/sad/neutral) қас,
/// көз бен тұмсықты өзгертеді. Дүкен заттары (бас киім/аксессуар/питомец)
/// үстіне қабатталады, ал «top» түсі іш реңкін береді.
class AvatarBase extends StatefulWidget {
  const AvatarBase({
    super.key,
    required this.assistant,
    this.size = 160,
    this.equipped = const [],
    this.expression = AvatarExpression.happy,
    this.animate = true,
  });

  final AssistantType assistant;
  final double size;
  final List<ShopItem> equipped;
  final AvatarExpression expression;

  /// Тірі маскот: жұмсақ тыныс алу + жеңіл қалқу + мезгіл-мезгіл көз жұму.
  /// Өнімділікке сезімтал не мүлде статикалық орындарда `false` беріледі.
  final bool animate;

  @override
  State<AvatarBase> createState() => _AvatarBaseState();
}

class _AvatarBaseState extends State<AvatarBase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle;

  /// Цикл санағышы — қылықтарды кезектестіреді (әр цикл бірдей болмасын):
  /// жан-жағына қарау / секіру / бас қисайту / қанат бұлғау лаптарға бөлінген.
  int _lap = 0;
  double _prevT = 0;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    _idle.addListener(() {
      // repeat() кезінде мән 1→0 оралады — жаңа лап басталды.
      if (_idle.value < _prevT) _lap++;
      _prevT = _idle.value;
    });
    if (widget.animate) _idle.repeat();
  }

  @override
  void didUpdateWidget(AvatarBase old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_idle.isAnimating) {
      _idle.repeat();
    } else if (!widget.animate && _idle.isAnimating) {
      _idle
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  Color get _accent => widget.assistant == AssistantType.bektur
      ? AppColors.eagleBlue
      : AppColors.nazymRose;

  ShopItem? _byCategory(ShopCategory category) {
    for (final item in widget.equipped) {
      if (item.category == category) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) return _mascot(0);
    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) {
        final t = _idle.value;
        final wave = sin(t * 2 * pi);
        final u = widget.size / 160;
        // Негізгі тіршілік: жұмсақ тыныс + қалқу; цикл соңында көз жұму.
        final floatY = wave * 2.4 * u;
        final breathe = 1 + wave * 0.012;
        final blink = t > .92 ? sin(((t - .92) / .08) * pi) : 0.0;

        // ---- Мінезді идл-репертуар (лаптар бойынша кезектеседі) ----
        final isBektur = widget.assistant == AssistantType.bektur;
        var lookX = wave * .12; // көз әрдайым сәл тірі
        var wingLift = 0.0;
        var tilt = 0.0;
        var hopY = 0.0;
        var squash = 1.0;

        // Жан-жағына қарау (әр 3-циклдің бірінде): солға → оңға → ортаға.
        if (_lap % 3 == 1 && t >= .18 && t < .42) {
          final p = (t - .18) / .24;
          lookX = sin(p * 2 * pi) * .85;
        }

        if (isBektur) {
          // Бектұр — спортшы: қос секіріс + қону сығылуы + қанат пампысы.
          if (_lap % 2 == 0 && t >= .55 && t < .78) {
            final p = (t - .55) / .23;
            final bounce = sin(p * 2 * pi).abs();
            hopY = -bounce * 5.5 * u;
            squash = 1 - (1 - bounce) * .05;
            wingLift = bounce * .55;
            tilt = sin(p * 2 * pi) * .02;
          }
        } else {
          if (_lap % 2 == 0 && t >= .5 && t < .78) {
            // Назым — сабырлы: бір рет нәзік бас қисайтып, қайта оралады.
            final p = (t - .5) / .28;
            tilt = sin(p * pi) * .085;
          } else if (_lap % 2 == 1 && t >= .5 && t < .82) {
            // Назымның «сәлем!» қанат бұлғауы — жұмсақ әрі биязы.
            final p = (t - .5) / .32;
            wingLift = sin(p * pi) * (.75 + sin(p * pi * 3) * .18);
          }
        }

        return Transform.translate(
          offset: Offset(0, floatY + hopY),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(
              scaleX: breathe,
              scaleY: breathe * squash,
              child: _mascot(
                blink,
                lookX: lookX,
                wingLift: wingLift,
                sway: wave,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mascot(
    double blink, {
    double lookX = 0,
    double wingLift = 0,
    double sway = 0,
  }) {
    final hat = _byCategory(ShopCategory.hat);
    final accessory = _byCategory(ShopCategory.accessory);
    final pet = _byCategory(ShopCategory.pet);
    final top = _byCategory(ShopCategory.top);

    final size = widget.size;
    final u = size / 160; // масштаб бірлігі
    final h = size * 1.1;

    return SizedBox(
      width: size,
      height: h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Бүркіт балапаны — бүтін дене.
          CustomPaint(
            size: Size(size, h),
            painter: _EagleMascotPainter(
              accent: _accent,
              expression: widget.expression,
              belly: top?.color,
              blink: blink,
              lookX: lookX,
              wingLift: wingLift,
              sway: sway,
            ),
          ),
          // Бас киім (айдардың үстіне).
          if (hat != null)
            Positioned(
              top: -2 * u,
              child: Icon(hat.icon, size: 38 * u, color: hat.color),
            ),
          // Аксессуар (оң қанат тұсы).
          if (accessory != null)
            Positioned(
              right: size * .04,
              bottom: size * .34,
              child: Icon(accessory.icon, size: 30 * u, color: accessory.color),
            ),
          // Питомец (сол жақ төмен).
          if (pet != null)
            Positioned(
              left: -8 * u,
              bottom: 2 * u,
              child: Container(
                width: 46 * u,
                height: 46 * u,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.sh1,
                ),
                child: Icon(pet.icon, size: 27 * u, color: pet.color),
              ),
            ),
        ],
      ),
    );
  }
}

enum AvatarExpression { happy, celebrate, sad, neutral }

/// Бүркіт балапанын толық салатын суретші.
class _EagleMascotPainter extends CustomPainter {
  _EagleMascotPainter({
    required this.accent,
    required this.expression,
    this.belly,
    this.blink = 0,
    this.lookX = 0,
    this.wingLift = 0,
    this.sway = 0,
  });

  final Color accent;
  final AvatarExpression expression;
  final Color? belly;

  /// 0 — көз ашық, 1 — толық жұмулы (тірі маскоттың көз жұмуы).
  final double blink;

  /// Қарашықтың көлденең бағыты (-1..1) — жан-жағына қарау.
  final double lookX;

  /// Оң қанаттың көтерілуі (0..1) — бұлғау/пампы (иықтан айналады).
  final double wingLift;

  /// Айдар қауырсындарының желбіреуі (-1..1) — нәзік самал.
  final double sway;

  static Color _sh(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final accentLite = _sh(accent, .1);
    final accentDark = _sh(accent, -.14);
    final accentDeep = _sh(accent, -.28);
    const cream = Color(0xFFFFF7EC);
    const gold = Color(0xFFF6B23A);
    const goldDeep = Color(0xFFE0851B);
    final ink = AppColors.nightInk;

    // ---- Жер көлеңкесі ----
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * .955), width: w * .58, height: h * .065),
      Paint()..color = ink.withValues(alpha: .12),
    );

    // ---- Алтын аяқтар ----
    final footPaint = Paint()..color = gold;
    final footLine = Paint()
      ..color = goldDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .015
      ..strokeCap = StrokeCap.round;
    for (final fx in [cx - w * .12, cx + w * .12]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, h * .9), width: w * .14, height: h * .045),
        footPaint,
      );
      for (final tx in [-1.0, 0.0, 1.0]) {
        canvas.drawLine(
          Offset(fx, h * .9),
          Offset(fx + tx * w * .05, h * .935),
          footLine,
        );
      }
    }

    // ---- Қанаттар (дененің артынан шығып тұрады) ----
    Path wing(bool left) {
      final s = left ? -1.0 : 1.0;
      final ox = cx + s * w * .3;
      return Path()
        ..moveTo(ox - s * w * .04, h * .4)
        ..quadraticBezierTo(ox + s * w * .16, h * .5, ox + s * w * .07, h * .78)
        ..quadraticBezierTo(ox - s * w * .03, h * .68, ox - s * w * .08, h * .5)
        ..close();
    }

    for (final left in [true, false]) {
      // Оң қанат [wingLift] бойынша иықтан сыртқа-жоғары айналады
      // (бұлғау / пампы) — сол қанат тыныш қалады.
      final lift = left ? 0.0 : wingLift;
      canvas.save();
      if (lift > 0) {
        final pivot = Offset(cx + w * .26, h * .42);
        canvas
          ..translate(pivot.dx, pivot.dy)
          ..rotate(-lift * 1.15)
          ..translate(-pivot.dx, -pivot.dy);
      }
      canvas.drawPath(wing(left), Paint()..color = accentDeep);
      // қанат қауырсын сызықтары
      final s = left ? -1.0 : 1.0;
      final ox = cx + s * w * .3;
      final fl = Paint()
        ..color = accentDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .01
        ..strokeCap = StrokeCap.round;
      for (final dy in [.56, .64, .72]) {
        canvas.drawLine(
          Offset(ox + s * w * .02, h * dy),
          Offset(ox + s * w * .07, h * (dy + .03)),
          fl,
        );
      }
      canvas.restore();
    }

    // ---- Дене (жұмыртқа пішіні, тік градиент) ----
    final bodyRect = Rect.fromLTRB(cx - w * .36, h * .2, cx + w * .36, h * .9);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accentLite, accent, accentDark],
        stops: const [0, .55, 1],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);
    // жоғарғы жылтыр жиек
    canvas.drawArc(
      bodyRect.deflate(w * .012),
      pi * 1.08,
      pi * .55,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .02
        ..strokeCap = StrokeCap.round,
    );

    // ---- Іш (ашық) ----
    final bellyColor = belly != null ? Color.lerp(belly!, cream, .3)! : cream;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * .68), width: w * .4, height: h * .32),
      Paint()..color = bellyColor.withValues(alpha: .92),
    );

    // ---- Айдар қауырсындары (бас үстінде) — [sway] самалмен желбірейді ----
    final crest = Paint()..color = accentDeep;
    final sw = sway * w * .012;
    for (final dx in [-w * .07, 0.0, w * .07]) {
      final tilt = dx.sign * w * .025;
      canvas.drawPath(
        Path()
          ..moveTo(cx + dx - w * .025, h * .22)
          ..quadraticBezierTo(
              cx + dx + tilt + sw, h * .12, cx + dx + tilt * 1.4 + sw * 1.6,
              h * .105)
          ..quadraticBezierTo(
              cx + dx + tilt + w * .015 + sw, h * .14, cx + dx + w * .025,
              h * .22)
          ..close(),
        crest,
      );
    }

    // ---- Бет (бүркіттің ақ басы) ----
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * .4), width: w * .58, height: h * .32),
      Paint()..color = cream,
    );

    // ---- Көздер ----
    final eyeY = h * .38;
    final eyeDX = w * .135;
    final eyeR = w * .088;
    if (expression == AvatarExpression.celebrate) {
      // Қуанған көздер: ^ ^
      final happy = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .03
        ..strokeCap = StrokeCap.round;
      for (final s in [-1.0, 1.0]) {
        final ex = cx + s * eyeDX;
        canvas.drawPath(
          Path()
            ..moveTo(ex - eyeR * .8, eyeY + eyeR * .3)
            ..quadraticBezierTo(ex, eyeY - eyeR * .8, ex + eyeR * .8, eyeY + eyeR * .3),
          happy,
        );
      }
    } else {
      final sad = expression == AvatarExpression.sad;
      final open = (1 - blink).clamp(0.0, 1.0);
      for (final s in [-1.0, 1.0]) {
        final ex = cx + s * eyeDX;
        if (open < .18) {
          // Көз жұмулы — жұмсақ иілген қабақ сызығы.
          canvas.drawPath(
            Path()
              ..moveTo(ex - eyeR * .9, eyeY)
              ..quadraticBezierTo(ex, eyeY + eyeR * .5, ex + eyeR * .9, eyeY),
            Paint()
              ..color = ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = w * .028
              ..strokeCap = StrokeCap.round,
          );
          continue;
        }
        final ry = (sad ? eyeR * .82 : eyeR) * open;
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ex, eyeY), width: eyeR * 1.8, height: ry * 2),
          Paint()..color = Colors.white,
        );
        // нұр (қарашық) — көз жеткілікті ашық болғанда ғана.
        if (open > .55) {
          final irisDy = sad ? -eyeR * .28 : eyeR * .12;
          // Қарашық [lookX] бойынша жан-жағына қарайды (нұр да ілеседі).
          final irisDx = lookX * eyeR * .34;
          canvas.drawCircle(
            Offset(ex + irisDx, eyeY + irisDy),
            eyeR * .62,
            Paint()..color = ink,
          );
          canvas.drawCircle(
            Offset(ex + irisDx - eyeR * .22, eyeY + irisDy - eyeR * .24),
            eyeR * .22,
            Paint()..color = Colors.white,
          );
        }
      }
    }

    // ---- Бүркіт қасы (көңіл-күй) ----
    final brow = Paint()
      ..color = accentDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .055
      ..strokeCap = StrokeCap.round;
    final browY = eyeY - eyeR * 1.5;
    for (final s in [-1.0, 1.0]) {
      final ex = cx + s * eyeDX;
      final double innerY, outerY;
      switch (expression) {
        case AvatarExpression.sad:
          innerY = browY - eyeR * .35;
          outerY = browY + eyeR * .35;
        case AvatarExpression.neutral:
          innerY = browY;
          outerY = browY;
        case AvatarExpression.happy:
        case AvatarExpression.celebrate:
          innerY = browY + eyeR * .35; // бүркітше: ішке қарай түседі
          outerY = browY - eyeR * .15;
      }
      canvas.drawLine(
        Offset(ex - s * eyeR * .7, innerY),
        Offset(ex + s * eyeR * .8, outerY),
        brow,
      );
    }

    // ---- Алтын тұмсық (ілмекті) ----
    final beakY = h * .455;
    final beakW = w * .07;
    final beakH = h * (expression == AvatarExpression.happy ? .085 : .075);
    final beakPath = Path()
      ..moveTo(cx - beakW, beakY)
      ..lineTo(cx + beakW, beakY)
      ..quadraticBezierTo(cx + beakW * .5, beakY + beakH, cx, beakY + beakH)
      ..quadraticBezierTo(cx - beakW * .5, beakY + beakH, cx - beakW, beakY)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = gold);
    // тұмсық ортасы көлеңке
    canvas.drawLine(
      Offset(cx - beakW * .8, beakY + beakH * .02),
      Offset(cx + beakW * .8, beakY + beakH * .02),
      Paint()
        ..color = goldDeep
        ..strokeWidth = w * .012
        ..strokeCap = StrokeCap.round,
    );
    if (expression == AvatarExpression.happy) {
      // сәл ашық тұмсық — кішкене қызыл тіл
      canvas.drawCircle(
        Offset(cx, beakY + beakH * .55),
        w * .018,
        Paint()..color = const Color(0xFFE8536B),
      );
    }

    // ---- Бет қызаруы ----
    final blush = Paint()..color = accent.withValues(alpha: .22);
    for (final s in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(cx + s * w * .2, h * .455),
        eyeR * .72,
        blush,
      );
    }
  }

  @override
  bool shouldRepaint(_EagleMascotPainter old) =>
      old.expression != expression ||
      old.accent != accent ||
      old.belly != belly ||
      old.blink != blink ||
      old.lookX != lookX ||
      old.wingLift != wingLift ||
      old.sway != sway;
}
