import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/subject_worlds.dart';

/// Оқу картасының тақырыптық фоны: аспан градиенті + пән әлемінің декоры.
/// [t] — 0..1 цикл (жай дрейф анимациясы); анимация өшірулі болса 0 беріледі.
/// [scrollOffset] — карта скроллы: декор скроллға ілесіп баяу жылжиды
/// (параллакс), экран биіктігі сайын жіксіз қайталанады.
///
/// FPS үшін үш қабатқа бөлінген:
///  - алыс фон (жұлдыз, тор, дақ...) бір-ақ рет салынып, RepaintBoundary
///    кэшінде тұрады — параллакс тек қабатты жылжытады, қайта салмайды;
///  - бекітілген қабат (төбе, қала, атом, микросхема жолдары) скроллға
///    мүлде ілеспейді: жерге/орнына байланған декор экранда тұрақты тұрады,
///    әйтпесе қала аспанда «ұшып» жүрер еді, ал электрон/сигнал өз
///    атомынан/жолынан ажырап қалар еді;
///  - динамикалық қабат (бұлт, шар, электрон, сигнал) ғана қайта салынады,
///    әрі t ~30 кадр/с-қа квантталған — артық растрлеу жоқ.
class MapBackdrop extends StatelessWidget {
  const MapBackdrop({
    super.key,
    required this.theme,
    required this.accent,
    required this.t,
    this.scrollOffset = 0,
  });

  final SubjectWorldTheme theme;
  final Color accent;
  final double t;
  final double scrollOffset;

  /// 18 секундтық циклде ~30 кадр/с → 540 қадам.
  static const int _steps = 540;

  /// Декордың скроллға ілесу үлесі: 1 = бірге, 0 = қозғалмайды.
  static const double _parallaxFactor = .25;

  @override
  Widget build(BuildContext context) {
    final tq = (t * _steps).floor() / _steps;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        // Скролл өскенде (картада жоғары көтерілгенде) декор төмен жылжиды.
        final shift = h <= 0 ? 0.0 : (scrollOffset * _parallaxFactor) % h;
        final farDecor = RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              isComplex: true,
              willChange: false,
              painter: _FarDecorPainter(world: theme.world, accent: accent),
            ),
          ),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: theme.gradient)),
            // Екі көшірме бірінің үстінде бірі — цикл жігі көрінбейді.
            Positioned(
                top: shift - h, left: 0, right: 0, height: h, child: farDecor),
            Positioned(
                top: shift, left: 0, right: 0, height: h, child: farDecor),
            // Жерге/орнына бекітілген декор — скроллға тәуелсіз.
            RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  isComplex: true,
                  willChange: false,
                  painter:
                      _AnchoredWorldPainter(world: theme.world, accent: accent),
                ),
              ),
            ),
            RepaintBoundary(
              child: IgnorePointer(
                child: CustomPaint(
                  size: Size.infinite,
                  willChange: true,
                  painter: _DynamicWorldPainter(world: theme.world, t: tq),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------- Ортақ көмекшілер ----------------

void _drawCloud(Canvas canvas, double cx, double cy, double s, Paint p) {
  canvas.drawCircle(Offset(cx, cy), 18 * s, p);
  canvas.drawCircle(Offset(cx + 22 * s, cy + 4 * s), 14 * s, p);
  canvas.drawCircle(Offset(cx - 22 * s, cy + 5 * s), 13 * s, p);
  canvas.drawRect(
    Rect.fromCenter(
        center: Offset(cx, cy + 9 * s), width: 56 * s, height: 16 * s),
    p,
  );
}

void _drawStars(Canvas canvas, Size size,
    {required double maxY, int seed = 7, int count = 26, double alpha = .45}) {
  final random = Random(seed);
  final dot = Paint();
  for (var i = 0; i < count; i++) {
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * maxY;
    dot.color = AppColors.white
        .withValues(alpha: alpha * (.6 + random.nextDouble() * .8));
    canvas.drawCircle(Offset(x, y), .9 + random.nextDouble() * 1.8, dot);
  }
}

void _drawBird(Canvas canvas, Offset c, double s, Paint p) {
  final path = Path()
    ..moveTo(c.dx - 8 * s, c.dy)
    ..quadraticBezierTo(c.dx - 4 * s, c.dy - 6 * s, c.dx, c.dy)
    ..quadraticBezierTo(c.dx + 4 * s, c.dy - 6 * s, c.dx + 8 * s, c.dy);
  canvas.drawPath(path, p);
}

/// Микросхема жолдары — екі қабатқа да бірдей болуы үшін
/// детерминистік геометрия (seed=21).
List<List<Offset>> _circuitTraces(Size size) {
  final w = size.width;
  final h = size.height;
  final random = Random(21);
  final traces = <List<Offset>>[];
  for (var i = 0; i < 7; i++) {
    var p = Offset(
        random.nextDouble() * w, h * .06 + random.nextDouble() * h * .85);
    final pts = [p];
    for (var s = 0; s < 3; s++) {
      final horizontal = s.isEven;
      final delta =
          (random.nextDouble() * 90 + 50) * (random.nextBool() ? 1 : -1);
      p = horizontal
          ? Offset((p.dx + delta).clamp(8, w - 8), p.dy)
          : Offset(p.dx, (p.dy + delta).clamp(8, h - 8));
      pts.add(p);
    }
    traces.add(pts);
  }
  return traces;
}

// ---------------- Алыс фон (параллакспен циклді қайталанады) ----------------

/// Тек еркін қайталануға жарайтын текстура: жұлдыз, тор, дақ, бит.
/// Жерге не басқа қабатқа байланған ештеңе мұнда салынбайды.
class _FarDecorPainter extends CustomPainter {
  const _FarDecorPainter({required this.world, required this.accent});

  final SubjectWorld world;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    switch (world) {
      case SubjectWorld.steppe:
        _paintSteppe(canvas, size);
      case SubjectWorld.geometry:
        _paintGeometry(canvas, size);
      case SubjectWorld.skyTravel:
        _paintSkyTravel(canvas, size);
      case SubjectWorld.cosmos:
        _paintCosmos(canvas, size);
      case SubjectWorld.circuit:
        _paintCircuit(canvas, size);
    }
  }

  void _paintSteppe(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glow = Paint()..color = accent.withValues(alpha: .10);
    canvas.drawCircle(Offset(w * .9, h * .68), 70, glow);
    canvas.drawCircle(Offset(w * .08, h * .42), 52, glow);
    // Бүкіл биіктікке біркелкі — цикл жігінде жолақ болмайды.
    _drawStars(canvas, size, maxY: h, alpha: .35);
  }

  void _paintGeometry(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Жеңіл координаталық тор. Көлденең сызық қадамы биіктікке тұтас
    // бөлінеді — цикл жігінде тор «секірмейді».
    final grid = Paint()
      ..color = const Color(0x144A6CF7)
      ..strokeWidth = 1;
    for (var x = 0.0; x < w; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    final rows = max(1, (h / 44).round());
    final yStep = h / rows;
    for (var i = 0; i < rows; i++) {
      canvas.drawLine(Offset(0, i * yStep), Offset(w, i * yStep), grid);
    }

    // Шоқжұлдыз тәрізді нүкте-сызықтар.
    final random = Random(12);
    final nodes = [
      for (var i = 0; i < 7; i++)
        Offset(random.nextDouble() * w, h * .05 + random.nextDouble() * h * .3),
    ];
    final link = Paint()
      ..color = const Color(0x294A6CF7)
      ..strokeWidth = 1.4;
    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], link);
    }
    final nodePaint = Paint()..color = const Color(0x664A6CF7);
    for (final n in nodes) {
      canvas.drawCircle(n, 3, nodePaint);
    }

    final glow = Paint()..color = accent.withValues(alpha: .08);
    canvas.drawCircle(Offset(w * .9, h * .12), 56, glow);
    canvas.drawCircle(Offset(w * .06, h * .9), 64, glow);
  }

  void _paintSkyTravel(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Алыстағы солғын бұлттар — параллакс тереңдігі үшін.
    final cloud = Paint()..color = const Color(0x59FFFFFF);
    _drawCloud(canvas, w * .25, h * .2, .8, cloud);
    _drawCloud(canvas, w * .72, h * .36, .65, cloud);
    _drawCloud(canvas, w * .12, h * .58, .7, cloud);
    _drawCloud(canvas, w * .82, h * .76, .6, cloud);
  }

  void _paintCosmos(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawStars(canvas, size, maxY: h, count: 70, alpha: .5, seed: 3);

    // Сақиналы ғаламшар.
    final planetCenter = Offset(w * .82, h * .2);
    canvas.drawCircle(
        planetCenter, 26, Paint()..color = const Color(0xCCFF8C42));
    canvas.drawCircle(Offset(planetCenter.dx - 8, planetCenter.dy - 6), 6,
        Paint()..color = const Color(0x40FFFFFF));
    canvas.save();
    canvas.translate(planetCenter.dx, planetCenter.dy);
    canvas.rotate(-.42);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 84, height: 22),
      Paint()
        ..color = const Color(0xB3FFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.restore();

    // Кіші ғаламшар.
    canvas.drawCircle(
        Offset(w * .12, h * .55), 14, Paint()..color = const Color(0xCC00C48C));

    // Тұмандық дақтар.
    final glow = Paint()..color = accent.withValues(alpha: .14);
    canvas.drawCircle(Offset(w * .5, h * .4), 90, glow);
    canvas.drawCircle(Offset(w * .9, h * .78), 70, glow);
  }

  void _paintCircuit(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // «Бит» нүктелері — ұсақ шаршылар.
    final bit = Paint()..color = const Color(0x5900D9FF);
    final bitRandom = Random(5);
    for (var i = 0; i < 22; i++) {
      canvas.drawRect(
        Rect.fromCenter(
          center:
              Offset(bitRandom.nextDouble() * w, bitRandom.nextDouble() * h),
          width: 3.4,
          height: 3.4,
        ),
        bit,
      );
    }

    final glow = Paint()..color = accent.withValues(alpha: .12);
    canvas.drawCircle(Offset(w * .5, h * .12), 80, glow);
    canvas.drawCircle(Offset(w * .88, h * .9), 64, glow);
  }

  @override
  bool shouldRepaint(_FarDecorPainter old) =>
      old.world != world || old.accent != accent;
}

// ---------------- Бекітілген қабат (скроллға тәуелсіз) ----------------

/// Жерге не орнына байланған декор: дала төбелері мен киіз үйлер,
/// қала силуэті, атом (электроны айналып жүреді), микросхема жолдары
/// (бойымен сигнал жүгіреді). Экранда қозғалмай тұрады.
class _AnchoredWorldPainter extends CustomPainter {
  const _AnchoredWorldPainter({required this.world, required this.accent});

  final SubjectWorld world;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    switch (world) {
      case SubjectWorld.steppe:
        _paintSteppe(canvas, size);
      case SubjectWorld.geometry:
        break; // тор мен пішіндер еркін — жерге байланған декор жоқ
      case SubjectWorld.skyTravel:
        _paintSkyTravel(canvas, size);
      case SubjectWorld.cosmos:
        _paintCosmos(canvas, size);
      case SubjectWorld.circuit:
        _paintCircuit(canvas, size);
    }
  }

  void _paintSteppe(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Алыс және жақын дала төбелері.
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..quadraticBezierTo(w * .3, h - 150, w * .62, h - 60)
        ..quadraticBezierTo(w * .85, h - 10, w, h - 70)
        ..lineTo(w, h)
        ..close(),
      Paint()..color = const Color(0x33E8A33D),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..quadraticBezierTo(w * .22, h - 80, w * .5, h - 36)
        ..quadraticBezierTo(w * .78, h, w, h - 40)
        ..lineTo(w, h)
        ..close(),
      Paint()..color = const Color(0x40D4860A),
    );

    // Киіз үй силуэттері (күмбез + есік).
    final yurt = Paint()..color = const Color(0x4D9A6200);
    for (final x in [w * .18, w * .52, w * .82]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, h - 26), width: 48, height: 44),
        pi, pi, true, yurt,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, h - 30), width: 9, height: 12),
        Paint()..color = const Color(0x669A6200),
      );
    }
  }

  void _paintSkyTravel(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Төмендегі қала силуэті (Лондон сарайы тектес мұнаралар).
    final city = Paint()..color = const Color(0x40825A00);
    final towers = [
      (w * .08, 64.0, 26.0), (w * .2, 96.0, 20.0), (w * .32, 70.0, 30.0),
      (w * .52, 120.0, 22.0), (w * .66, 80.0, 28.0), (w * .84, 100.0, 24.0),
    ];
    for (final (x, th, tw) in towers) {
      canvas.drawRect(Rect.fromLTWH(x - tw / 2, h - th, tw, th), city);
      canvas.drawPath(
        Path()
          ..moveTo(x - tw / 2, h - th)
          ..lineTo(x, h - th - 16)
          ..lineTo(x + tw / 2, h - th)
          ..close(),
        city,
      );
    }

    // Үлкен сағат мұнарасының циферблаты.
    final clockCenter = Offset(w * .52, h - 96);
    canvas.drawCircle(clockCenter, 8, Paint()..color = const Color(0x66FFF4E0));
    canvas.drawCircle(
      clockCenter, 8,
      Paint()
        ..color = const Color(0x80825A00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    final glow = Paint()..color = accent.withValues(alpha: .1);
    canvas.drawCircle(Offset(w * .92, h * .85), 60, glow);
  }

  void _paintCosmos(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Атом: ядро + үш орбита (электрон — динамикалық қабатта, дәл осы
    // центрді айналады, сондықтан атом скроллмен жылжымауы керек).
    final atomCenter = Offset(w * .16, h * .18);
    canvas.drawCircle(atomCenter, 5, Paint()..color = const Color(0xFFFF6FA5));
    final orbitPaint = Paint()
      ..color = const Color(0x66FF6FA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final rot in [0.0, pi / 3, 2 * pi / 3]) {
      canvas.save();
      canvas.translate(atomCenter.dx, atomCenter.dy);
      canvas.rotate(rot);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 64, height: 24),
        orbitPaint,
      );
      canvas.restore();
    }
  }

  void _paintCircuit(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Жолдар — динамикалық қабаттағы сигналдар дәл осы геометриямен
    // жүгіреді, сондықтан скроллмен жылжымауы керек.
    final trace = Paint()
      ..color = const Color(0x4D7B61FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final node = Paint()..color = const Color(0x807B61FF);

    for (final pts in _circuitTraces(size)) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, trace);
      canvas.drawCircle(pts.first, 3.4, node);
      canvas.drawCircle(pts.last, 3.4, node);
    }

    // Чиптер: дөңгеленген шаршы + аяқшалар.
    void chip(Offset c, double s) {
      final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 44 * s, height: 44 * s),
        Radius.circular(8 * s),
      );
      canvas.drawRRect(body, Paint()..color = const Color(0x33121038));
      canvas.drawRRect(
        body,
        Paint()
          ..color = const Color(0x807B61FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final pin = Paint()
        ..color = const Color(0x807B61FF)
        ..strokeWidth = 2;
      for (var i = -1; i <= 1; i++) {
        final dy = c.dy + i * 12 * s;
        canvas.drawLine(
            Offset(c.dx - 22 * s, dy), Offset(c.dx - 30 * s, dy), pin);
        canvas.drawLine(
            Offset(c.dx + 22 * s, dy), Offset(c.dx + 30 * s, dy), pin);
      }
      canvas.drawCircle(c, 5 * s,
          Paint()..color = AppColors.accentCSCyan.withValues(alpha: .7));
    }

    chip(Offset(w * .2, h * .22), 1);
    chip(Offset(w * .84, h * .5), .8);
    chip(Offset(w * .14, h * .78), .9);
  }

  @override
  bool shouldRepaint(_AnchoredWorldPainter old) =>
      old.world != world || old.accent != accent;
}

// ---------------- Динамикалық қабат ----------------

class _DynamicWorldPainter extends CustomPainter {
  const _DynamicWorldPainter({required this.world, required this.t});

  final SubjectWorld world;
  final double t;

  /// Цикл бойынша жұмсақ ілгері-кейін тербеліс (-1..1).
  double get _sway => sin(t * 2 * pi);

  @override
  void paint(Canvas canvas, Size size) {
    switch (world) {
      case SubjectWorld.steppe:
        _paintSteppe(canvas, size);
      case SubjectWorld.geometry:
        _paintGeometry(canvas, size);
      case SubjectWorld.skyTravel:
        _paintSkyTravel(canvas, size);
      case SubjectWorld.cosmos:
        _paintCosmos(canvas, size);
      case SubjectWorld.circuit:
        _paintCircuit(canvas, size);
    }
  }

  void _paintSteppe(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final drift = _sway * 10;

    // Қалықтаған қырандар.
    final eagle = Paint()
      ..color = const Color(0x802D1B69)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    _drawBird(canvas, Offset(w * .3 + drift, h * .16), 1.6, eagle);
    _drawBird(canvas, Offset(w * .72 - drift, h * .1), 1.1, eagle);

    // Бұлттар (жай дрейф).
    final cloud = Paint()..color = const Color(0xB3FFFFFF);
    _drawCloud(canvas, w * .2 + drift, h * .32, 1.1, cloud);
    _drawCloud(canvas, w * .8 - drift, h * .45, .9, cloud);
    _drawCloud(canvas, w * .68 + drift, h * .2, 1.2, cloud);
    _drawCloud(canvas, w * .15 - drift, h * .6, .8, cloud);
  }

  void _paintGeometry(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final drift = _sway * 8;

    // Қалқыған пішіндер: үшбұрыш, шеңбер, шаршы, алтыбұрыш.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    void poly(Offset c, double r, int sides, double rot, Color color) {
      stroke.color = color;
      final path = Path();
      for (var i = 0; i <= sides; i++) {
        final a = rot + i * 2 * pi / sides;
        final p = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, stroke);
    }

    poly(Offset(w * .14, h * .25 + drift), 26, 3, -pi / 2 + _sway * .15,
        const Color(0x59F5A623));
    poly(Offset(w * .86, h * .38 - drift), 22, 4, pi / 4 + _sway * .1,
        const Color(0x597B61FF));
    poly(Offset(w * .8, h * .72 + drift), 26, 6, _sway * .12,
        const Color(0x5900C48C));
    stroke.color = const Color(0x594A6CF7);
    canvas.drawCircle(Offset(w * .12, h * .62 - drift), 22, stroke);
    canvas.drawCircle(Offset(w * .5, h * .12 + drift), 14, stroke);
  }

  void _paintSkyTravel(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final lift = _sway * 14;

    // Әуе шарлары.
    void balloon(Offset c, double s, Color color) {
      final body = Paint()..color = color;
      canvas.drawCircle(c, 22 * s, body);
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - 14 * s, c.dy + 14 * s)
          ..quadraticBezierTo(c.dx, c.dy + 34 * s, c.dx + 14 * s, c.dy + 14 * s)
          ..close(),
        body,
      );
      final line = Paint()
        ..color = color.withValues(alpha: .8)
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(c.dx - 8 * s, c.dy + 20 * s),
          Offset(c.dx - 5 * s, c.dy + 36 * s), line);
      canvas.drawLine(Offset(c.dx + 8 * s, c.dy + 20 * s),
          Offset(c.dx + 5 * s, c.dy + 36 * s), line);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset(c.dx, c.dy + 40 * s), width: 12 * s, height: 9 * s),
        Paint()..color = const Color(0xB39A6200),
      );
    }

    balloon(Offset(w * .18, h * .3 - lift), 1.1, const Color(0xCCFF8C42));
    balloon(Offset(w * .82, h * .5 + lift), .85, const Color(0xCC4A6CF7));
    balloon(Offset(w * .62, h * .14 - lift * .6), .7, const Color(0xCCFF6FA5));

    // Бұлттар мен құстар.
    final cloud = Paint()..color = const Color(0xB3FFFFFF);
    _drawCloud(canvas, w * .35 + lift, h * .42, 1.0, cloud);
    _drawCloud(canvas, w * .75 - lift, h * .68, .9, cloud);
    _drawCloud(canvas, w * .12 + lift, h * .76, .75, cloud);
    final bird = Paint()
      ..color = const Color(0x662D1B69)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    _drawBird(canvas, Offset(w * .4 - lift, h * .22), 1.0, bird);
    _drawBird(canvas, Offset(w * .5 - lift, h * .25), .7, bird);
  }

  void _paintCosmos(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Электрон (атом орбитасында).
    final atomCenter = Offset(w * .16, h * .18);
    final ea = _sway * pi + 1;
    canvas.drawCircle(
      Offset(atomCenter.dx + 32 * cos(ea), atomCenter.dy + 12 * sin(ea)),
      3.4,
      Paint()..color = const Color(0xFFFFD700),
    );

    // Құйрықты жұлдыз.
    final cometHead = Offset(w * (.3 + .4 * t), h * (.66 - .08 * _sway));
    final tail = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0x00FFFFFF), const Color(0xB3FFFFFF)],
      ).createShader(
          Rect.fromPoints(cometHead - const Offset(70, -26), cometHead));
    canvas.drawPath(
      Path()
        ..moveTo(cometHead.dx - 70, cometHead.dy + 26)
        ..lineTo(cometHead.dx, cometHead.dy - 2)
        ..lineTo(cometHead.dx - 64, cometHead.dy + 34)
        ..close(),
      tail,
    );
    canvas.drawCircle(cometHead, 4, Paint()..color = AppColors.white);
  }

  void _paintCircuit(Canvas canvas, Size size) {
    // Жолдар бойымен жүгіретін жарқыраған сигналдар (cyan).
    final signal = Paint()..color = AppColors.accentCSCyan;
    final signalGlow = Paint()
      ..color = AppColors.accentCSCyan.withValues(alpha: .35);
    final traces = _circuitTraces(size);
    for (var i = 0; i < traces.length; i += 2) {
      final pts = traces[i];
      final progress = ((t + i * .17) % 1) * (pts.length - 1);
      final seg = progress.floor().clamp(0, pts.length - 2);
      final local = progress - seg;
      final pos = Offset.lerp(pts[seg], pts[seg + 1], local)!;
      canvas.drawCircle(pos, 7, signalGlow);
      canvas.drawCircle(pos, 3, signal);
    }
  }

  @override
  bool shouldRepaint(_DynamicWorldPainter old) =>
      old.world != world || old.t != t;
}
