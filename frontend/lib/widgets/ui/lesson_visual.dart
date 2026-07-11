import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/lesson.dart';

/// Сабақтың тұжырымдамалық визуалын салады — ұғымды СУРЕТПЕН бірден түсіндіреді.
/// Бөлшек жолағы (FractionBar) немесе сан осі (NumberLineVisual).
class LessonVisualView extends StatelessWidget {
  const LessonVisualView(this.visual, {super.key});

  final LessonVisual visual;

  @override
  Widget build(BuildContext context) {
    final (child, caption) = switch (visual) {
      FractionBar(:final parts, :final shaded, :final caption) => (
          SizedBox(
            height: 46,
            child: CustomPaint(
              painter: _FractionBarPainter(parts: parts, shaded: shaded),
              size: Size.infinite,
            ),
          ),
          caption,
        ),
      NumberLineVisual(
        :final min,
        :final max,
        :final step,
        :final points,
        :final caption
      ) =>
        (
          SizedBox(
            height: 66,
            child: CustomPaint(
              painter: _NumberLinePainter(
                  min: min, max: max, step: step, points: points),
              size: Size.infinite,
            ),
          ),
          caption,
        ),
      RightTriangleVisual(
        :final aLabel,
        :final bLabel,
        :final cLabel,
        :final caption
      ) =>
        (
          SizedBox(
            height: 140,
            child: CustomPaint(
              painter: _RightTrianglePainter(a: aLabel, b: bLabel, c: cLabel),
              size: Size.infinite,
            ),
          ),
          caption,
        ),
      BarChartVisual(
        :final bars,
        :final markValue,
        :final markLabel,
        :final caption
      ) =>
        (
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _BarChartPainter(
                bars: bars,
                markValue: markValue,
                markLabel: markLabel,
              ),
              size: Size.infinite,
            ),
          ),
          caption,
        ),
      ProcessFlowVisual(
        :final steps,
        :final highlightLast,
        :final caption
      ) =>
        (_ProcessFlowView(steps: steps, highlightLast: highlightLast), caption),
      LabeledPartsVisual(:final parts, :final title, :final caption) =>
        (_LabeledPartsView(parts: parts, title: title), caption),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.sh1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_mosaic_rounded,
                  size: 15, color: AppColors.eagleBlue),
              const SizedBox(width: 5),
              Text(
                'КӨРНЕКІ',
                style: AppTypography.caption.copyWith(
                  color: AppColors.eagleBlue,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp3),
          child,
          if (caption != null) ...[
            const SizedBox(height: AppSpacing.sp2),
            Text(
              caption,
              style: AppTypography.bodySmall.copyWith(color: AppColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

/// Бөлшек жолағы: [parts] сегментке бөлінген, алғашқы [shaded] боялған.
class _FractionBarPainter extends CustomPainter {
  _FractionBarPainter({required this.parts, required this.shaded});

  final int parts;
  final int shaded;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    if (parts <= 0) return;
    const gap = 3.0;
    final cell = (w - gap * (parts - 1)) / parts;
    final radius = const Radius.circular(6);
    for (var i = 0; i < parts; i++) {
      final x = i * (cell + gap);
      final rr = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, cell, h), radius);
      if (i < shaded) {
        c.drawRRect(
          rr,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.eagleBlue, AppColors.cosmicPurple],
            ).createShader(rr.outerRect),
        );
      } else {
        c.drawRRect(
            rr, Paint()..color = AppColors.eagleBlue.withValues(alpha: .10));
        c.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = AppColors.eagleBlue.withValues(alpha: .22),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FractionBarPainter old) =>
      old.parts != parts || old.shaded != shaded;
}

/// Сан осі: [min]..[max] белгілермен + [points] ерекшеленген нүктелер.
class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter({
    required this.min,
    required this.max,
    required this.points,
    this.step = 1,
  });

  final int min;
  final int max;
  final int step;
  final List<int> points;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final span = max - min;
    if (span <= 0) return;
    const pad = 16.0;
    final axisY = h * .5;
    double xFor(int v) => pad + (w - 2 * pad) * (v - min) / span;

    final line = Paint()
      ..color = AppColors.inkSoft
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(pad - 6, axisY), Offset(w - pad + 6, axisY), line);

    // Екі ұштағы бағыт көрсеткіштері.
    for (final dir in [-1.0, 1.0]) {
      final tipX = dir < 0 ? pad - 6 : w - pad + 6;
      c.drawPath(
        Path()
          ..moveTo(tipX, axisY)
          ..lineTo(tipX - dir * 7, axisY - 5)
          ..lineTo(tipX - dir * 7, axisY + 5)
          ..close(),
        Paint()..color = AppColors.inkSoft,
      );
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    final tick = step < 1 ? 1 : step;
    for (var v = min; v <= max; v++) {
      if ((v - min) % tick != 0 && v != max) continue; // әр [step] сайын белгі
      final x = xFor(v);
      final zero = v == 0;
      c.drawLine(
        Offset(x, axisY - (zero ? 8 : 5)),
        Offset(x, axisY + (zero ? 8 : 5)),
        line,
      );
      tp.text = TextSpan(
        text: '$v',
        style: AppTypography.caption.copyWith(
          fontSize: 10,
          color: zero ? AppColors.ink : AppColors.inkSoft,
          fontWeight: zero ? FontWeight.w900 : FontWeight.w600,
        ),
      );
      tp.layout();
      tp.paint(c, Offset(x - tp.width / 2, axisY + 11));
    }

    // Ерекшеленген нүктелер.
    for (final v in points) {
      if (v < min || v > max) continue;
      final x = xFor(v);
      c.drawCircle(Offset(x, axisY), 6.5,
          Paint()..color = AppColors.steppeGold);
      c.drawCircle(
        Offset(x, axisY),
        6.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_NumberLinePainter old) =>
      old.min != min ||
      old.max != max ||
      old.step != step ||
      old.points != points;
}

/// Тікбұрышты үшбұрыш: тік бұрыш сол төменде, катеттер [a] (астыңғы) мен
/// [b] (сол), гипотенуза [c]. Пифагор теоремасын суретпен түсіндіреді.
class _RightTrianglePainter extends CustomPainter {
  _RightTrianglePainter({required this.a, required this.b, required this.c});

  final String a;
  final String b;
  final String c;

  void _label(Canvas canvas, String text, Offset center, Color color) {
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
          fontSize: 15,
        ),
      ),
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const pad = 30.0;
    final p0 = Offset(pad, h - pad); // тік бұрыш (сол төмен)
    final p1 = Offset(w - pad, h - pad); // оң төмен
    final p2 = Offset(pad, pad); // сол жоғары

    final tri = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(
      tri,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            AppColors.eagleBlue.withValues(alpha: .20),
            AppColors.cosmicPurple.withValues(alpha: .12),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      tri,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.eagleBlue,
    );

    // Тік бұрыш белгісі (кішкене шаршы).
    const m = 13.0;
    canvas.drawPath(
      Path()
        ..moveTo(p0.dx + m, p0.dy)
        ..lineTo(p0.dx + m, p0.dy - m)
        ..lineTo(p0.dx, p0.dy - m),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.inkSoft,
    );

    // Қабырға белгілері: катеттер бейтарап, гипотенуза акцентпен ерекшеленеді.
    _label(canvas, a, Offset((p0.dx + p1.dx) / 2, p0.dy + 14), AppColors.inkSoft);
    _label(canvas, b, Offset(p0.dx - 15, (p0.dy + p2.dy) / 2), AppColors.inkSoft);
    _label(
      canvas,
      c,
      Offset((p1.dx + p2.dx) / 2 + 14, (p1.dy + p2.dy) / 2 - 12),
      AppColors.eagleBlue,
    );
  }

  @override
  bool shouldRepaint(_RightTrianglePainter old) =>
      old.a != a || old.b != b || old.c != c;
}

/// Баған диаграммасы: тік бағандар + мән/белгі, қажет болса орташа пунктирі.
class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.bars, this.markValue, this.markLabel});

  final List<(String, double)> bars;
  final double? markValue;
  final String? markLabel;

  void _text(Canvas c, String s, Offset center, Color color,
      {double size = 11, FontWeight weight = FontWeight.w700}) {
    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: s,
        style: AppTypography.caption
            .copyWith(color: color, fontSize: size, fontWeight: weight),
      ),
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final w = size.width;
    final h = size.height;
    const bottomPad = 22.0; // белгілерге орын
    const topPad = 18.0; // мәндерге орын
    final chartH = h - bottomPad - topPad;
    final maxV = [
      for (final b in bars) b.$2,
      if (markValue != null) markValue!,
    ].reduce((a, b) => a > b ? a : b);
    if (maxV <= 0) return;

    final slot = w / bars.length;
    final barW = slot * .54;
    double yFor(double v) => topPad + chartH * (1 - v / maxV);

    for (var i = 0; i < bars.length; i++) {
      final (label, value) = bars[i];
      final cx = slot * i + slot / 2;
      final top = yFor(value);
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, top, barW, topPad + chartH - top),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.eagleBlue, AppColors.cosmicPurple],
          ).createShader(rect.outerRect),
      );
      _text(canvas, _fmt(value), Offset(cx, top - 9), AppColors.inkSoft);
      _text(canvas, label, Offset(cx, h - bottomPad / 2), AppColors.inkSoft,
          weight: FontWeight.w600);
    }

    // Орташа (немесе басқа) деңгей — пунктир сызық.
    if (markValue != null) {
      final y = yFor(markValue!);
      final dash = Paint()
        ..color = AppColors.steppeGoldDeep
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      const dashW = 7.0;
      const gap = 5.0;
      var x = 4.0;
      while (x < w - 40) {
        canvas.drawLine(Offset(x, y), Offset(x + dashW, y), dash);
        x += dashW + gap;
      }
      _text(
        canvas,
        '${markLabel ?? ''} ${_fmt(markValue!)}'.trim(),
        Offset(w - 22, y),
        AppColors.steppeGoldDeep,
        size: 10,
        weight: FontWeight.w800,
      );
    }
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.bars != bars ||
      old.markValue != markValue ||
      old.markLabel != markLabel;
}

/// Процесс тізбегі: қораптар солдан оңға көрсеткішпен жалғасады. Кең болса
/// келесі жолға оралады (Wrap). Соңғы қорап (нәтиже) акцент градиентімен.
class _ProcessFlowView extends StatelessWidget {
  const _ProcessFlowView({required this.steps, required this.highlightLast});

  final List<String> steps;
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepChip(
            text: steps[i],
            accent: highlightLast && i == steps.length - 1,
          ),
          if (i < steps.length - 1)
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: AppColors.eagleBlue),
        ],
      ],
    );
  }
}

/// Процесс қадамының қорабы: акцентті болса градиент, әйтпесе нәзік көк.
class _StepChip extends StatelessWidget {
  const _StepChip({required this.text, required this.accent});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp3, vertical: AppSpacing.sp2),
      decoration: BoxDecoration(
        gradient: accent
            ? const LinearGradient(
                colors: [AppColors.eagleBlue, AppColors.cosmicPurple])
            : null,
        color: accent ? null : AppColors.eagleBlue.withValues(alpha: .10),
        borderRadius: AppRadius.rMd,
        border: accent
            ? null
            : Border.all(color: AppColors.eagleBlue.withValues(alpha: .22)),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w800,
          color: accent ? AppColors.white : AppColors.eagleBlue,
        ),
      ),
    );
  }
}

/// Белгіленген бөліктер: әр жолда түсті нүкте + атау + рөлі. Құрылымды
/// (жасуша, атом, жүйе) бөлшектеп түсіндіреді.
class _LabeledPartsView extends StatelessWidget {
  const _LabeledPartsView({required this.parts, this.title});

  final List<(String, String)> parts;
  final String? title;

  static const _dots = [
    AppColors.eagleBlue,
    AppColors.cosmicPurple,
    AppColors.steppeGold,
    AppColors.successJade,
    AppColors.nazymRose,
    AppColors.warningSunset,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sp2),
        ],
        for (var i = 0; i < parts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sp2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 11,
                  height: 11,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: _dots[i % _dots.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp3),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.inkSoft),
                      children: [
                        TextSpan(
                          text: parts[i].$1,
                          style: const TextStyle(fontWeight: FontWeight.w800)
                              .copyWith(color: AppColors.ink),
                        ),
                        const TextSpan(text: ' — '),
                        TextSpan(text: parts[i].$2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
