import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Жұмсақ жүзбелі түрлі-түсті «блобтар» — премиум тереңдік фоны.
///
/// Экранның ең артына қойылады (Stack-та бірінші бала). Бренд түстерінің
/// нәзік радиалды дақтары баяу жылжып, интерфейске «тірі» атмосфера береді —
/// Brawl Stars / Headspace стиліндегі қабат. Түрту әрекеттерін ұстамайды
/// (IgnorePointer) және «қозғалысты азайту» режимінде қозғалмайды.
class AmbientBackdrop extends StatefulWidget {
  const AmbientBackdrop({
    super.key,
    required this.colors,
    this.opacity = 0.16,
    this.blobCount = 3,
    this.animate = true,
  });

  /// Блоб түстері (әдетте 2–3 бренд реңкі).
  final List<Color> colors;
  final double opacity;
  final int blobCount;
  final bool animate;

  @override
  State<AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends State<AmbientBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context) || !widget.animate;
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _BlobPainter(
                colors: widget.colors,
                opacity: widget.opacity,
                count: widget.blobCount,
                t: reduce ? 0.0 : _c.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({
    required this.colors,
    required this.opacity,
    required this.count,
    required this.t,
  });

  final List<Color> colors;
  final double opacity;
  final int count;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;
    final n = math.min(count, math.max(1, colors.length * 2));
    for (var i = 0; i < n; i++) {
      final color = colors[i % colors.length];
      // Әр блобтың базалық орны + баяу синусоидалы дрейф.
      final phase = t * 2 * math.pi + i * (2 * math.pi / n);
      final cx = size.width * (0.2 + 0.6 * _frac(i * 0.37 + 0.15)) +
          math.cos(phase) * 26;
      final cy = size.height * (0.12 + 0.7 * _frac(i * 0.61 + 0.05)) +
          math.sin(phase * 0.8) * 30;
      final radius = size.shortestSide * (0.34 + 0.10 * _frac(i * 0.53));

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        );
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  double _frac(double v) => v - v.floorToDouble();

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.t != t || old.colors != colors || old.opacity != opacity;
}
