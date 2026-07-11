import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/theme/app_colors.dart';
import '../../core/theme/subject_legends.dart';
import '../../core/theme/subject_worlds.dart';

/// Оқу картасының фоны — пәннің **тірі әлемі**. Қабаттар (төменнен жоғары):
/// терең градиент → көкжиектегі **статикалық силуэт декоры** (таулар/қала/
/// ғаламшар/схема) → жұмсақ жарқыл орбтары → кинематографиялық **vignette** →
/// **тірі анимация қабаты** (жымыңдаған жұлдыздар, ұшқан жұлдыз, айналатын ай,
/// схемадағы энергия импульстері, қалқыған әуе шарлары мен бұлттар, сырғыған
/// **қыран**, ұшқан бөлшектер) → **ұлы тұлғалар галереясы** → **формулалар**.
///
/// Ортасы (жол + тиындар) ӘРҚАШАН ашық — декор шетте/көкжиекте.
///
/// [t] — 0..1 дрейф циклі (бүкіл «өмір» осыдан жүреді; бүтін жиіліктер →
/// циклдің тігісі білінбейді). Анимация өшік болса t=0 → бәрі тыныш кадр.
/// [scrollOffset] — тұлғалар/символдар параллаксы (көкжиек тұрақты).
class MapBackdrop extends StatefulWidget {
  const MapBackdrop({
    super.key,
    required this.subjectId,
    required this.theme,
    required this.accent,
    required this.t,
    this.scrollOffset = 0,
    this.companion,
  });

  final String subjectId;
  final SubjectWorldTheme theme;
  final Color accent;
  final double t;
  final double scrollOffset;

  /// Оқушының серігінің түсі (Бектұр көк / Назым қызғылт). Берілсе — аспанда
  /// сырғыған бренд қыраны осы түспен, жұмсақ жарқыл әрі қозғалыс ізімен ұшады.
  final Color? companion;

  @override
  State<MapBackdrop> createState() => _MapBackdropState();
}

class _MapBackdropState extends State<MapBackdrop> {
  /// Жүктелген портреттер (subjectId-ге сай). null болса — әлі жүктелуде.
  List<ui.Image>? _figures;

  @override
  void initState() {
    super.initState();
    _loadFigures();
  }

  @override
  void didUpdateWidget(MapBackdrop old) {
    super.didUpdateWidget(old);
    if (old.subjectId != widget.subjectId) {
      _figures = null;
      _loadFigures();
    }
  }

  Future<void> _loadFigures() async {
    final subjectId = widget.subjectId;
    final paths = legendsFor(subjectId).figures;
    try {
      final imgs = await Future.wait(paths.map(_LegendImages.load));
      if (mounted && widget.subjectId == subjectId) {
        setState(() => _figures = imgs);
      }
    } catch (_) {
      // Сурет жүктелмесе — фон әлем декоры + символдармен қала береді.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.isDark;
    final legends = legendsFor(widget.subjectId);
    final figures = _figures;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1) Пән градиенті (терең аспан).
        DecoratedBox(decoration: BoxDecoration(gradient: theme.gradient)),
        // 2) Көкжиек силуэт әлемі (статикалық) — кэште.
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              isComplex: true,
              willChange: false,
              painter: _SceneryPainter(theme: theme),
            ),
          ),
        ),
        // 3) Жұмсақ жарқыл орбтары (эффект) — статикалық, кэште.
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              willChange: false,
              painter: _GlowPainter(accent: widget.accent, isDark: isDark),
            ),
          ),
        ),
        // 4) Кинематографиялық vignette — шеттер күңгірт, орта айқын.
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              willChange: false,
              painter: _VignettePainter(isDark: isDark),
            ),
          ),
        ),
        // 5) ТІРІ анимация қабаты — әлемді қозғалысқа келтіреді.
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              isComplex: true,
              willChange: true,
              painter: _LifePainter(
                theme: theme,
                accent: widget.accent,
                t: widget.t,
                companion: widget.companion,
              ),
            ),
          ),
        ),
        // 6) Ұлы тұлғалар галереясы — екі қапталда «тұрады», параллакспен.
        if (figures != null && figures.isNotEmpty)
          RepaintBoundary(
            child: IgnorePointer(
              child: CustomPaint(
                size: Size.infinite,
                isComplex: true,
                painter: _LegendsPainter(
                  images: figures,
                  scrollOffset: widget.scrollOffset,
                  accent: widget.accent,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        // 7) Формула / символдар — нәзік қалқиды (параллакс + жай тербеліс).
        RepaintBoundary(
          child: IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              willChange: true,
              painter: _GlyphsPainter(
                glyphs: legends.glyphs,
                accent: widget.accent,
                isDark: isDark,
                t: widget.t,
                scrollOffset: widget.scrollOffset,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Портреттерді ui.Image етіп жүктеп, кэштейтін көмекші.
class _LegendImages {
  static final Map<String, ui.Image> _cache = {};

  static Future<ui.Image> load(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return _cache[assetPath] = frame.image;
  }
}

// ===================== Ортақ силуэт көмекшілері =====================

void _chevron(Canvas c, Offset o, double r, Paint p) {
  c.drawLine(Offset(o.dx - r, o.dy), Offset(o.dx, o.dy - r * .5), p);
  c.drawLine(Offset(o.dx, o.dy - r * .5), Offset(o.dx + r, o.dy), p);
}

void _cloud(Canvas c, Offset o, double r, Paint p) {
  c.drawCircle(o, r * .5, p);
  c.drawCircle(Offset(o.dx + r * .45, o.dy + r * .05), r * .38, p);
  c.drawCircle(Offset(o.dx - r * .45, o.dy + r * .08), r * .32, p);
  c.drawRect(Rect.fromLTWH(o.dx - r * .6, o.dy, r * 1.2, r * .35), p);
}

void _balloon(Canvas c, Offset o, double r, Color color) {
  final paint = Paint()..color = color;
  final body = Path()
    ..moveTo(o.dx, o.dy + r * 1.25)
    ..cubicTo(o.dx - r * 1.2, o.dy + r * .2, o.dx - r, o.dy - r, o.dx, o.dy - r)
    ..cubicTo(
        o.dx + r, o.dy - r, o.dx + r * 1.2, o.dy + r * .2, o.dx, o.dy + r * 1.25)
    ..close();
  c.drawPath(body, paint);
  c.drawRect(
    Rect.fromCenter(
        center: Offset(o.dx, o.dy + r * 1.5), width: r * .35, height: r * .3),
    paint,
  );
}

/// Пәннің көкжиек силуэт әлемі — тұрақты, тыныш, жолдың артында.
class _SceneryPainter extends CustomPainter {
  const _SceneryPainter({required this.theme});

  final SubjectWorldTheme theme;

  Color get _s => theme.scenery;

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme.world) {
      case SubjectWorld.steppe:
        _steppe(canvas, size);
      case SubjectWorld.geometry:
        _geometry(canvas, size);
      case SubjectWorld.skyTravel:
        _skyTravel(canvas, size);
      case SubjectWorld.cosmos:
        _cosmos(canvas, size);
      case SubjectWorld.circuit:
        _circuit(canvas, size);
      case SubjectWorld.flora:
        _flora(canvas, size);
      case SubjectWorld.lab:
        _lab(canvas, size);
      case SubjectWorld.heritage:
        _heritage(canvas, size);
    }
  }

  void _horizonGlow(Canvas c, Size size,
      {double yf = 1.0, double rf = .85, double? alpha}) {
    final center = Offset(size.width * .5, size.height * yf);
    final r = size.width * rf;
    final a = alpha ?? (theme.isDark ? .4 : .55);
    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            theme.horizonGlow.withValues(alpha: a),
            theme.horizonGlow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  void _hill(Canvas c, Size size,
      {required double baseY,
      required double amp,
      required double alpha,
      double phase = 0}) {
    final w = size.width;
    final h = size.height;
    final y0 = h * baseY;
    final a = h * amp;
    final path = Path()..moveTo(0, y0 + sin(phase) * a);
    for (var x = 0.0; x <= w; x += w / 16) {
      path.lineTo(x, y0 + sin(x / w * pi * 1.4 + phase) * a);
    }
    path
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(path, Paint()..color = _s.withValues(alpha: alpha));
  }

  void _yurt(Canvas c, Offset base, double r, Color color) {
    final body = Path()
      ..moveTo(base.dx - r, base.dy)
      ..lineTo(base.dx - r * .9, base.dy - r * .7)
      ..quadraticBezierTo(
          base.dx, base.dy - r * 1.5, base.dx + r * .9, base.dy - r * .7)
      ..lineTo(base.dx + r, base.dy)
      ..close();
    c.drawPath(body, Paint()..color = color);
  }

  void _steppe(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    _horizonGlow(c, size, yf: 1.04, rf: .78);
    final mtn = Path()..moveTo(0, h * .84);
    const pts = [
      [.16, .73], [.32, .82], [.5, .69], [.68, .81], [.84, .72], [1.0, .82],
    ];
    for (final p in pts) {
      mtn.lineTo(w * p[0], h * p[1]);
    }
    mtn
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(mtn, Paint()..color = _s.withValues(alpha: .16));
    _hill(c, size, baseY: .88, amp: .03, alpha: .22, phase: .6);
    _hill(c, size, baseY: .93, amp: .04, alpha: .34, phase: 2.1);
    _yurt(c, Offset(w * .72, h * .915), w * .07, _s.withValues(alpha: .5));
    _yurt(c, Offset(w * .2, h * .95), w * .05, _s.withValues(alpha: .42));
  }

  void _geometry(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    _horizonGlow(c, size, yf: 1.02, rf: .8, alpha: .5);
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _s.withValues(alpha: .14);
    final vp = Offset(w * .5, h * .8);
    for (var i = -6; i <= 6; i++) {
      c.drawLine(Offset(w * .5 + i * w * .14, h), vp, grid);
    }
    for (var j = 1; j <= 4; j++) {
      final y = h * .8 + (h * .2) * (j / 4) * (j / 4);
      c.drawLine(Offset(0, y), Offset(w, y), grid);
    }
    final city = Paint()..color = _s.withValues(alpha: .24);
    void box(double x, double bw, double bh) {
      c.drawRect(Rect.fromLTWH(w * x, h * .8 - h * bh, w * bw, h * bh), city);
    }

    box(.06, .1, .12);
    box(.17, .08, .2);
    final prism = Path()
      ..moveTo(w * .26, h * .8)
      ..lineTo(w * .33, h * .58)
      ..lineTo(w * .4, h * .8)
      ..close();
    c.drawPath(prism, city);
    box(.6, .09, .18);
    box(.7, .12, .1);
    box(.83, .07, .22);
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .45, h * .6, w * .12, h * .2),
          const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _s.withValues(alpha: .2),
    );
  }

  void _skyTravel(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    _horizonGlow(c, size, yf: 1.04, rf: .82, alpha: .5);
    final city = Paint()..color = _s.withValues(alpha: .24);
    void tower(double x, double bw, double bh, {bool spire = false}) {
      c.drawRect(Rect.fromLTWH(w * x, h * .86 - h * bh, w * bw, h * bh), city);
      if (spire) {
        final s = Path()
          ..moveTo(w * x, h * .86 - h * bh)
          ..lineTo(w * x + w * bw / 2, h * .86 - h * bh - h * .05)
          ..lineTo(w * x + w * bw, h * .86 - h * bh)
          ..close();
        c.drawPath(s, city);
      }
    }

    tower(.04, .09, .12);
    tower(.14, .07, .2, spire: true);
    tower(.23, .1, .15);
    tower(.66, .08, .18, spire: true);
    tower(.76, .11, .12);
    tower(.88, .08, .17);
  }

  void _cosmos(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final planet = Offset(w * .2, h * 1.02);
    final pr = w * .42;
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _s.withValues(alpha: .2);
    for (final k in [1.5, 2.1, 2.8]) {
      _oval(c, planet, pr * k, pr * k * .42, orbit);
    }
    final pg = RadialGradient(
      center: const Alignment(-.4, -.5),
      colors: [
        theme.horizonGlow.withValues(alpha: .9),
        _s.withValues(alpha: .55),
      ],
    ).createShader(Rect.fromCircle(center: planet, radius: pr));
    c.drawCircle(planet, pr, Paint()..shader = pg);
    _oval(
      c,
      planet,
      pr * 1.5,
      pr * .55,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .03
        ..color = theme.horizonGlow.withValues(alpha: .35),
    );
  }

  void _oval(Canvas c, Offset center, double rx, double ry, Paint p) {
    c.drawOval(
        Rect.fromCenter(center: center, width: rx * 2, height: ry * 2), p);
  }

  void _circuit(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    _horizonGlow(c, size, yf: 1.06, rf: .9, alpha: .3);
    final trace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round
      ..color = _s.withValues(alpha: .22);
    final rnd = Random(13);
    for (var i = 0; i < 7; i++) {
      final y = h * (.3 + i * .1);
      final path = Path()..moveTo(0, y);
      var x = 0.0;
      var cy = y;
      while (x < w) {
        x += w * (.12 + rnd.nextDouble() * .16);
        path.lineTo(x, cy);
        if (rnd.nextBool()) {
          final ny = (cy + (rnd.nextBool() ? 1 : -1) * h * .06)
              .clamp(h * .22, h * .98);
          path.lineTo(x, ny);
          cy = ny;
        }
      }
      c.drawPath(path, trace);
    }
    void chip(double x, double y, double s) {
      final r = Rect.fromLTWH(w * x, h * y, s, s * .8);
      c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()..color = _s.withValues(alpha: .3),
      );
      final leg = Paint()
        ..color = _s.withValues(alpha: .35)
        ..strokeWidth = 1.5;
      for (var i = 0; i < 4; i++) {
        final lx = r.left + r.width * (.2 + i * .22);
        c.drawLine(Offset(lx, r.top), Offset(lx, r.top - 5), leg);
        c.drawLine(Offset(lx, r.bottom), Offset(lx, r.bottom + 5), leg);
      }
    }

    chip(.12, .82, w * .12);
    chip(.74, .8, w * .14);
  }

  /// Биология: жасыл төбешіктер + өсімдік силуэттері (сабақ + жапырақтар).
  void _flora(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    _horizonGlow(c, size, yf: 1.04, rf: .8);
    _hill(c, size, baseY: .86, amp: .03, alpha: .18, phase: .4);
    _hill(c, size, baseY: .92, amp: .04, alpha: .3, phase: 1.8);
    void plant(double x, double baseY, double s) {
      final base = Offset(w * x, h * baseY);
      c.drawLine(
        base,
        base.translate(0, -s),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * .08
          ..strokeCap = StrokeCap.round
          ..color = _s.withValues(alpha: .5),
      );
      final leaf = Paint()..color = _s.withValues(alpha: .42);
      for (final dir in [-1.0, 1.0]) {
        final ly = base.dy - s * .6;
        c.drawPath(
          Path()
            ..moveTo(base.dx, ly)
            ..quadraticBezierTo(
                base.dx + dir * s * .5, ly - s * .2, base.dx + dir * s * .1,
                ly - s * .45)
            ..quadraticBezierTo(
                base.dx + dir * s * .1, ly - s * .18, base.dx, ly)
            ..close(),
          leaf,
        );
      }
    }

    plant(.2, .95, h * .13);
    plant(.78, .92, h * .17);
    plant(.5, .97, h * .1);
  }

  /// Химия: көкжиек шапағы + Эрленмейер колбаларының силуэттері.
  void _lab(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    _horizonGlow(c, size, yf: 1.05, rf: .82, alpha: .5);
    void flask(double x, double baseY, double s) {
      final cx = w * x;
      final by = h * baseY;
      final path = Path()
        ..moveTo(cx - s * .12, by - s)
        ..lineTo(cx - s * .12, by - s * .62)
        ..lineTo(cx - s * .5, by)
        ..lineTo(cx + s * .5, by)
        ..lineTo(cx + s * .12, by - s * .62)
        ..lineTo(cx + s * .12, by - s)
        ..close();
      c.drawPath(path, Paint()..color = _s.withValues(alpha: .26));
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = _s.withValues(alpha: .4),
      );
      c.drawLine(
        Offset(cx - s * .32, by - s * .16),
        Offset(cx + s * .32, by - s * .16),
        Paint()
          ..color = theme.horizonGlow.withValues(alpha: .55)
          ..strokeWidth = 2.5,
      );
    }

    flask(.22, .9, h * .2);
    flask(.75, .93, h * .26);
  }

  /// Тарих: алтын дала + балбал тас (тас мүсін) + шаңырақ силуэттері.
  void _heritage(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    _horizonGlow(c, size, yf: 1.04, rf: .8);
    _hill(c, size, baseY: .88, amp: .03, alpha: .2, phase: .5);
    void balbal(double x, double baseY, double s) {
      final cx = w * x;
      final by = h * baseY;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - s * .18, by - s, s * .36, s),
          Radius.circular(s * .18),
        ),
        Paint()..color = _s.withValues(alpha: .4),
      );
      c.drawCircle(
        Offset(cx, by - s),
        s * .22,
        Paint()..color = _s.withValues(alpha: .45),
      );
    }

    balbal(.18, .95, h * .2);
    balbal(.8, .92, h * .26);
    final cx = w * .5;
    final cy = h * .9;
    final r = w * .05;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _s.withValues(alpha: .3);
    c.drawCircle(Offset(cx, cy), r, ring);
    for (var i = 0; i < 6; i++) {
      final a = i * pi / 3;
      c.drawLine(Offset(cx, cy), Offset(cx + cos(a) * r, cy + sin(a) * r), ring);
    }
  }

  @override
  bool shouldRepaint(_SceneryPainter old) => old.theme != theme;
}

/// ТІРІ анимация қабаты — әр пәннің әлемін қозғалысқа келтіреді.
/// Барлық қозғалыс [t] (0..1, циклдік) арқылы; жіксіз болу үшін бүтін
/// жиіліктер (sin) мен бүтін жылдамдықтар (дрейф) қолданылады.
class _LifePainter extends CustomPainter {
  const _LifePainter({
    required this.theme,
    required this.accent,
    required this.t,
    this.companion,
  });

  final SubjectWorldTheme theme;
  final Color accent;
  final double t;
  final Color? companion;

  Color get _s => theme.scenery;
  Color get _glow => theme.horizonGlow;

  /// Жоғары қарай жіксіз дрейф фракциясы [0,1) (speed — бүтін).
  double _frac(double base, int speed) {
    final v = (base + t * speed) % 1.0;
    return v < 0 ? v + 1 : v;
  }

  @override
  void paint(Canvas c, Size size) {
    switch (theme.world) {
      case SubjectWorld.steppe:
        _steppe(c, size);
      case SubjectWorld.geometry:
        _geometry(c, size);
      case SubjectWorld.skyTravel:
        _sky(c, size);
      case SubjectWorld.cosmos:
        _cosmos(c, size);
      case SubjectWorld.circuit:
        _circuit(c, size);
      case SubjectWorld.flora:
        _flora(c, size);
      case SubjectWorld.lab:
        _lab(c, size);
      case SubjectWorld.heritage:
        _heritage(c, size);
    }
    _eagle(c, size);
  }

  /// Ұшқан бөлшектер (тозаң / ұшқын / дерек) — жоғары қарай жіктеледі.
  void _motes(Canvas c, Size size, Color color, int n, double maxR) {
    final w = size.width;
    final h = size.height;
    for (var i = 0; i < n; i++) {
      final r = Random(i * 131 + 5);
      final fr = _frac(r.nextDouble(), 1 + (i % 2));
      final y = h * (1 - fr);
      final x = r.nextDouble() * w + sin(t * 2 * pi + i) * 8;
      final rad = maxR * (.4 + r.nextDouble() * .6);
      final tw = .35 + .65 * (.5 + .5 * sin(t * 2 * pi * (2 + i % 3) + i));
      c.drawCircle(Offset(x, y), rad, Paint()..color = color.withValues(alpha: .3 * tw));
    }
  }

  /// Аспанда сырғыған қыран (бренд) — қанаттарын қағады. Серік түсі берілсе —
  /// оқушының серігі (Бектұр/Назым) болып, жұмсақ жарқыл әрі қозғалыс ізімен ұшады.
  void _eagle(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final x = -140 + t * (w + 280);
    final y = h * .14 + sin(t * 2 * pi * 2) * 10;
    final flap = sin(t * 2 * pi * 6);
    final s = (w * .055).clamp(10.0, 30.0);
    final base = companion ?? (theme.isDark ? Colors.white : _s);

    if (companion != null) {
      // Серіктің жұмсақ аурасы — кез келген фонда бөлектеніп тұрады.
      c.drawCircle(
        Offset(x, y),
        s * 2.2,
        Paint()
          ..shader = RadialGradient(colors: [
            base.withValues(alpha: .22),
            base.withValues(alpha: 0),
          ]).createShader(
              Rect.fromCircle(center: Offset(x, y), radius: s * 2.2)),
      );
      // Қозғалыс ізі — артта солғындай екі елес.
      for (var k = 2; k >= 1; k--) {
        _eagleShape(
          c,
          x - k * s * .9,
          y + sin(t * 2 * pi * 2 - k * .5) * 3,
          s * (1 - k * .12),
          base.withValues(alpha: .10 / k),
          flap,
        );
      }
    }

    _eagleShape(
        c, x, y, s, base.withValues(alpha: companion != null ? .5 : .3), flap);
  }

  /// Қыран силуэтін (дене + екі қанат) берілген орын/өлшем/түспен салады.
  void _eagleShape(
      Canvas c, double x, double y, double s, Color col, double flap) {
    final p = Paint()..color = col;
    c.drawCircle(Offset(x, y), s * .22, p);
    final lift = s * .7 * (.55 + flap * .45);
    c.drawPath(
      Path()
        ..moveTo(x, y - s * .1)
        ..quadraticBezierTo(x - s * 1.1, y - lift, x - s * 2.1, y + s * .12)
        ..quadraticBezierTo(x - s, y + s * .16, x, y + s * .14)
        ..close(),
      p,
    );
    c.drawPath(
      Path()
        ..moveTo(x, y - s * .1)
        ..quadraticBezierTo(x + s * 1.1, y - lift, x + s * 2.1, y + s * .12)
        ..quadraticBezierTo(x + s, y + s * .16, x, y + s * .14)
        ..close(),
      p,
    );
  }

  void _steppe(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    // Көкжиектен таралатын жұмсақ шапақ сәулелері (жыпылықтайды).
    final rayC = Offset(w * .5, h * 1.03);
    for (var i = -3; i <= 3; i++) {
      final ang = -pi / 2 + i * .2;
      final shimmer = .05 + .04 * (.5 + .5 * sin(t * 2 * pi * 2 + i));
      final far = rayC + Offset(cos(ang), sin(ang)) * h * .95;
      c.drawPath(
        Path()
          ..moveTo(rayC.dx, rayC.dy)
          ..lineTo(far.dx - 16, far.dy)
          ..lineTo(far.dx + 16, far.dy)
          ..close(),
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.linear(rayC, far, [
            _glow.withValues(alpha: shimmer),
            _glow.withValues(alpha: 0),
          ]),
      );
    }
    // Сырғыған құстар.
    final bird = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _s.withValues(alpha: .34);
    for (var k = 0; k < 3; k++) {
      final bx = _frac(k * .33, 1) * (w + 80) - 40;
      final by = h * (.26 + k * .05) + sin(t * 2 * pi * 3 + k) * 4;
      _chevron(c, Offset(bx, by), w * (.024 - k * .003), bird);
    }
    _motes(c, size, _glow, 16, 2.4);
  }

  void _geometry(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 14; i++) {
      final r = Random(i * 71 + 3);
      final fr = _frac(r.nextDouble(), 1 + (i % 2));
      final y = h * (1 - fr);
      final x = r.nextDouble() * w;
      final sz = 4.0 + r.nextDouble() * 5;
      paint.color =
          _s.withValues(alpha: .2 * (.5 + .5 * sin(t * 2 * pi * 2 + i)));
      c.save();
      c.translate(x, y);
      c.rotate(t * 2 * pi * (i.isEven ? 1 : -1) + i);
      switch (i % 3) {
        case 0:
          c.drawPath(
            Path()
              ..moveTo(0, -sz)
              ..lineTo(sz * .9, sz * .6)
              ..lineTo(-sz * .9, sz * .6)
              ..close(),
            paint,
          );
        case 1:
          c.drawLine(Offset(-sz, 0), Offset(sz, 0), paint);
          c.drawLine(Offset(0, -sz), Offset(0, sz), paint);
        default:
          c.drawCircle(Offset.zero, sz * .8, paint);
      }
      c.restore();
    }
  }

  void _sky(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final cloud = Paint()..color = Colors.white.withValues(alpha: .14);
    for (var k = 0; k < 3; k++) {
      final r = Random(k * 97 + 1);
      final cx = ((r.nextDouble() + t) % 1) * (w + 220) - 110;
      _cloud(c, Offset(cx, h * (.42 + k * .12)), w * (.1 + r.nextDouble() * .04),
          cloud);
    }
    final cols = [_s, _glow, accent];
    for (var k = 0; k < 3; k++) {
      final bx = w * (.2 + k * .28) + sin(t * 2 * pi + k) * 14;
      final by = h * (.24 + k * .06) + sin(t * 2 * pi * 2 + k) * 16;
      _balloon(c, Offset(bx, by), w * (.06 - k * .01),
          cols[k % cols.length].withValues(alpha: .42 - k * .06));
    }
    _motes(c, size, Colors.white, 10, 1.8);
  }

  void _cosmos(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    // Жымыңдаған жұлдыздар.
    final rnd = Random(7);
    for (var i = 0; i < 54; i++) {
      final px = rnd.nextDouble() * w;
      final py = rnd.nextDouble() * h * .92;
      final base = .12 + rnd.nextDouble() * .5;
      final a = (base * (.5 + .5 * sin(t * 2 * pi * (2 + i % 4) + i)))
          .clamp(0.0, 1.0);
      c.drawCircle(Offset(px, py), rnd.nextDouble() * 1.3 + .4,
          Paint()..color = Colors.white.withValues(alpha: a));
    }
    // Орбита бойымен айналатын ай.
    final planet = Offset(w * .2, h * 1.02);
    final ang = t * 2 * pi;
    final moon = Offset(planet.dx + cos(ang) * w * .6,
        planet.dy + sin(ang) * w * .6 * .42);
    c.drawCircle(
      moon,
      w * .05,
      Paint()
        ..shader = RadialGradient(
          colors: [_glow.withValues(alpha: .35), _glow.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: moon, radius: w * .05)),
    );
    c.drawCircle(moon, w * .024,
        Paint()..color = const Color(0xFFE9E4FF).withValues(alpha: .75));
    // Ұшқан жұлдыздар (циклде екі рет).
    for (final base in [0.18, 0.66]) {
      var local = t - base;
      if (local < 0) local += 1;
      if (local < 0.1) {
        final p = local / 0.1;
        final head = Offset(w * .15 + p * w * .55, h * .1 + p * h * .22);
        final tail = Offset(head.dx - w * .13, head.dy - h * .055);
        final a = sin(p * pi);
        c.drawLine(
          head,
          tail,
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..shader = ui.Gradient.linear(head, tail, [
              Colors.white.withValues(alpha: .9 * a),
              Colors.white.withValues(alpha: 0),
            ]),
        );
        c.drawCircle(
            head, 1.9, Paint()..color = Colors.white.withValues(alpha: a));
      }
    }
    _motes(c, size, Colors.white, 8, 1.5);
  }

  void _circuit(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    // Трассалар бойымен жүгіретін энергия импульстері.
    for (var i = 0; i < 7; i++) {
      final y = h * (.3 + i * .1);
      final x = _frac(i * .13, 1 + (i % 2)) * w;
      final tail = Offset(x - w * .1, y);
      c.drawLine(
        Offset(x, y),
        tail,
        Paint()
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(Offset(x, y), tail, [
            _glow.withValues(alpha: .9),
            _glow.withValues(alpha: 0),
          ]),
      );
      c.drawCircle(
        Offset(x, y),
        2.4,
        Paint()
          ..color = _glow.withValues(alpha: .95)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      c.drawCircle(
          Offset(x, y), 1.5, Paint()..color = Colors.white.withValues(alpha: .9));
    }
    // Жыпылықтаған контактілер.
    final rnd = Random(21);
    for (var k = 0; k < 10; k++) {
      final a = .2 + .6 * (.5 + .5 * sin(t * 2 * pi * (2 + k % 3) + k));
      c.drawCircle(
        Offset(rnd.nextDouble() * w, h * (.28 + rnd.nextDouble() * .68)),
        1.8,
        Paint()..color = _glow.withValues(alpha: a),
      );
    }
    // Қалқыған «0/1» биттер.
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var k = 0; k < 10; k++) {
      final r = Random(k * 61 + 2);
      final y = h * (1 - _frac(r.nextDouble(), 1 + (k % 2)));
      tp.text = TextSpan(
        text: k.isEven ? '1' : '0',
        style: TextStyle(
          color: _glow.withValues(alpha: .32),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
      tp
        ..layout()
        ..paint(c, Offset(r.nextDouble() * w, y));
    }
  }

  /// Биология: жасыл тозаң/спора жоғары қарай нәзік қалқиды.
  void _flora(Canvas c, Size size) {
    _motes(c, size, const Color(0xFF7CC98A), 14, 3);
  }

  /// Химия: көгілдір көпіршіктер жоғары көтеріледі.
  void _lab(Canvas c, Size size) {
    _motes(c, size, const Color(0xFF7FD8E0), 12, 4);
  }

  /// Тарих: алтын дала шаңы жоғары қарай нәзік қалқиды.
  void _heritage(Canvas c, Size size) {
    _motes(c, size, const Color(0xFFE7C77A), 12, 3);
  }

  @override
  bool shouldRepaint(_LifePainter old) =>
      old.t != t ||
      old.theme != theme ||
      old.accent != accent ||
      old.companion != companion;
}

/// Жұмсақ жарқыл орбтары — фонға тыныш премиум тереңдік (blursіз шейдер).
class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.accent, required this.isDark});

  final Color accent;
  final bool isDark;

  void _orb(Canvas canvas, Offset c, double r, double alpha) {
    final color = accent.withValues(alpha: alpha);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _orb(canvas, Offset(w * .84, h * .16), 170, isDark ? .26 : .16);
    _orb(canvas, Offset(w * .08, h * .48), 150, isDark ? .22 : .12);
    _orb(canvas, Offset(w * .74, h * .84), 140, isDark ? .2 : .09);
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.accent != accent || old.isDark != isDark;
}

/// Кинематографиялық vignette: шеттер мен бұрыштарды күңгірттендіріп, көзді
/// ортадағы жолға бағыттайды.
class _VignettePainter extends CustomPainter {
  const _VignettePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final edge = isDark ? .34 : .14;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -.1),
          radius: 1.05,
          colors: [
            const Color(0x00000000),
            Color.fromRGBO(8, 8, 28, edge),
          ],
          stops: const [.6, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.center,
          colors: [
            Color.fromRGBO(6, 6, 24, isDark ? .4 : .12),
            const Color(0x00000000),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_VignettePainter old) => old.isDark != isDark;
}

/// Ұлы тұлғалар галереясы: портреттер жолдың сол/оң қапталында «тұрады»
/// (астында жұмсақ spotlight + жер көлеңкесі), скроллда параллакспен жылжиды.
class _LegendsPainter extends CustomPainter {
  const _LegendsPainter({
    required this.images,
    required this.scrollOffset,
    required this.accent,
    required this.isDark,
  });

  final List<ui.Image> images;
  final double scrollOffset;
  final Color accent;
  final bool isDark;

  static const double _gap = 360;
  static const double _figW = 150;
  static const double _figH = 200;
  static const double _parallax = .3;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = images.length;
    if (n == 0) return;
    final tileH = n * _gap;
    final sh = tileH <= 0 ? 0.0 : (scrollOffset * _parallax) % tileH;
    final opacity = isDark ? .9 : .74;
    final paint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, opacity)
      ..filterQuality = FilterQuality.medium;
    final spotColor = isDark ? AppColors.white : accent;

    for (final tileOff in [-sh, tileH - sh]) {
      for (var k = 0; k < n; k++) {
        final jitter = ((k * 53) % 40) - 12.0;
        final y = k * _gap + 60 + tileOff + jitter;
        if (y > h + _figH || y < -_figH) continue;
        final onLeft = k.isEven;
        final dx = onLeft ? -_figW * .2 : w - _figW * .8;
        final cx = dx + _figW * .5;
        final spotR = _figW * .62;
        final spotC = Offset(cx, y + _figH * .42);
        canvas.drawCircle(
          spotC,
          spotR,
          Paint()
            ..shader = RadialGradient(
              colors: [
                spotColor.withValues(alpha: isDark ? .16 : .2),
                spotColor.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: spotC, radius: spotR)),
        );
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, y + _figH * .9),
              width: _figW * .7,
              height: _figH * .12),
          Paint()
            ..color = Color.fromRGBO(0, 0, 0, isDark ? .25 : .12)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        final img = images[k % n];
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(dx, y, _figW, _figH),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LegendsPainter old) =>
      old.scrollOffset != scrollOffset ||
      old.images != images ||
      old.accent != accent ||
      old.isDark != isDark;
}

/// Формула / символ / әріптер: жолдың бойымен сирек, нәзік қалқиды.
class _GlyphsPainter extends CustomPainter {
  const _GlyphsPainter({
    required this.glyphs,
    required this.accent,
    required this.isDark,
    required this.t,
    required this.scrollOffset,
  });

  final List<String> glyphs;
  final Color accent;
  final bool isDark;
  final double t;
  final double scrollOffset;

  static const double _gap = 232;
  static const double _parallax = .46;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final n = glyphs.length;
    if (n == 0) return;
    final tileH = n * _gap;
    final sh = tileH <= 0 ? 0.0 : (scrollOffset * _parallax) % tileH;
    final base = isDark ? AppColors.white : accent;

    for (final tileOff in [-sh, tileH - sh]) {
      for (var k = 0; k < n; k++) {
        final r = Random(k * 911 + 17);
        final x = 24 + r.nextDouble() * (w - 150);
        final bob = sin(t * 2 * pi + k) * 5;
        final y = k * _gap + r.nextDouble() * _gap * .55 + tileOff + bob;
        if (y > h + 30 || y < -30) continue;
        final size0 = 12.5 + r.nextDouble() * 7;
        final alpha = (isDark ? .24 : .17) * (.7 + r.nextDouble() * .5);
        final tp = TextPainter(
          text: TextSpan(
            text: glyphs[k],
            style: TextStyle(
              color: base.withValues(alpha: alpha),
              fontSize: size0,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: w * .6);
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(_GlyphsPainter old) =>
      old.t != t ||
      old.scrollOffset != scrollOffset ||
      old.accent != accent ||
      old.isDark != isDark ||
      old.glyphs != glyphs;
}
