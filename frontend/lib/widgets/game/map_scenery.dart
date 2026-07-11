import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Оқу картасының әлемдік деңгейдегі АТМОСФЕРАЛЫҚ фоны — «аврора пейзажы».
/// Таза түйіндермен таласпайтын тыныш қабаттар (артқыдан алдыға):
///   1. **Пәндік аспан** — әр әлемнің ҚОЛМЕН теңгерілген 3 сатылы палитрасы
///      (дала таңы / көк сызба / саяхат батысы / ғарыш / схема; тема бөлек);
///   2. **Жұлдыздар** (тек қараңғы темада) — сирек, баяу жымыңдайды;
///   3. **Аспан шырағы** — жарықта жұмсақ күн, қараңғыда жарты ай (гало-мен);
///   4. **Аврора орбтары** — үлкен жұмсақ жарық дақтары, өте баяу қалқиды;
///   5. **Бұлттар + алыстағы қырандар** (жарық) / **ұшқан жұлдыз** (қараңғы);
///   6. **Қошқар мүйіз ою-спиральдары** — қазақ болмысының әрең көрінетін
///      қолтаңбасы, жол шетінде;
///   7. **Аврора ленталары** — аспан бойымен ирелеңдеп аққан жарық жолақтары
///      (қараңғыда additive жанады) — сахнаның қолтаңба құбылысы;
///   8. **Күн сәулелері** (жарық тема) — күннен тарайтын кинематографиялық
///      шапақ бағандары;
///   9. **Пәндік қолтаңба-силуэт** — әр пәннің ЖАЛҒЫЗ ірі сым-сызық белгісі
///      (киіз үй / көпжақ / әуе шары / ғаламшар / микросхема), елес-белгідей;
///   9б. **Пәндік тірі құбылыс** — дала самалы / сызба торы / қағаз ұшақ ізі /
///      ай орбиталары мен серігі / схема трассалары + ток импульстері;
///  10. **Тұман-жоталар** — ҮШ қабат толқынды силуэт, скроллда әртүрлі
///      жылдамдықпен (паралакс) сырғиды → «биіктеп бара жатырмын» сезімі;
///  11. **Көкжиек шапағы + жарық түйіршіктері + жиек фокусы** — тереңдік
///      пен назарды ортаға жинайтын соңғы жылтырату.
///
/// Барлығы процедуралық (accent + AppColors.bg): бес пәнге де, жарық/қараңғы
/// темаға да бір код. Мәтін, портрет, ұсақ фигура ЖОҚ — көз жолда қалады.
///
/// [scrollOffset] — паралакс көзі; [t] — 0..1 дрейф циклі (анимация өшік
/// болса 0 → тыныш кадр).
class MapScenery extends StatelessWidget {
  const MapScenery({
    super.key,
    required this.subjectId,
    required this.accent,
    required this.scrollOffset,
    required this.t,
  });

  /// Пән идентификаторы — қолтаңба-силуэтті таңдайды (kazakh/math/…).
  final String subjectId;
  final Color accent;
  final double scrollOffset;
  final double t;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          size: Size.infinite,
          isComplex: true,
          willChange: true,
          painter: _MapSceneryPainter(
            subjectId: subjectId,
            accent: accent,
            isDark: isDark,
            scrollOffset: scrollOffset,
            t: t,
          ),
        ),
      ),
    );
  }
}

class _MapSceneryPainter extends CustomPainter {
  const _MapSceneryPainter({
    required this.subjectId,
    required this.accent,
    required this.isDark,
    required this.scrollOffset,
    required this.t,
  });

  final String subjectId;
  final Color accent;
  final bool isDark;
  final double scrollOffset;
  final double t;

  _World get _world => switch (subjectId) {
    'math' => _World.blueprint,
    'english' => _World.skyway,
    'physics' => _World.cosmos,
    'cs' => _World.circuit,
    'biology' => _World.flora,
    'chemistry' => _World.lab,
    'history' => _World.heritage,
    _ => _World.steppe,
  };

  _WorldSpec get _spec => _specs[_world]!;

  /// Әр әлемнің қолмен теңгерілген дискрет ерекшеліктері.
  static const Map<_World, _WorldSpec> _specs = {
    // Дала таңы: жоғарыда лаванда → төменде жылы алтын шапақ.
    _World.steppe: _WorldSpec(
      skyLight: [Color(0xFFEFE7FB), Color(0xFFFFE9CD), Color(0xFFFFD9A0)],
      skyDark: [Color(0xFF241D50), Color(0xFF33254E), Color(0xFF45305C)],
      glow: Color(0xFFFFC46B),
    ),
    // Көк сызба: мұзды инженерлік көгілдір.
    _World.blueprint: _WorldSpec(
      skyLight: [Color(0xFFEAF3FF), Color(0xFFDCEBFF), Color(0xFFC7DDFB)],
      skyDark: [Color(0xFF101E42), Color(0xFF16295A), Color(0xFF1D3470)],
      glow: Color(0xFF9CC4FF),
      ribbonBoost: .8,
    ),
    // Саяхат аспаны: биік көк → батар күннің цитрус жылуы.
    _World.skyway: _WorldSpec(
      skyLight: [Color(0xFFDFF0FF), Color(0xFFFFE9D6), Color(0xFFFFD4AE)],
      skyDark: [Color(0xFF1F1B4E), Color(0xFF35255C), Color(0xFF54305C)],
      glow: Color(0xFFFFAB76),
    ),
    // Ғарыш: небула күлгіні → түпсіз түн (жарықта — ымырт лавандасы).
    _World.cosmos: _WorldSpec(
      skyLight: [Color(0xFFE9E4FF), Color(0xFFDCD2F8), Color(0xFFCEC2F0)],
      skyDark: [Color(0xFF241B58), Color(0xFF150F3D), Color(0xFF0B0827)],
      glow: Color(0xFF8B6CFF),
      ribbonBoost: 1.25,
      showStarsInLight: true,
    ),
    // Схема түні: терең индиго → жасыл-көгілдір сигнал.
    _World.circuit: _WorldSpec(
      skyLight: [Color(0xFFE2F7F5), Color(0xFFD3EEF0), Color(0xFFC2E3ED)],
      skyDark: [Color(0xFF142449), Color(0xFF0F1C3D), Color(0xFF0A1230)],
      glow: Color(0xFF2BC6C6),
      ribbonBoost: .9,
    ),
    // Гүлденген алқап: ашық көк → жасыл шапақ (өмір, өсу).
    _World.flora: _WorldSpec(
      skyLight: [Color(0xFFDBF1FF), Color(0xFFE7F6E2), Color(0xFFC7EACE)],
      skyDark: [Color(0xFF15311F), Color(0xFF1A3B27), Color(0xFF22452F)],
      glow: Color(0xFFA7E88C),
    ),
    // Зертхана: көгілдір шыны → жеңіл күлгін реагент реңкі.
    _World.lab: _WorldSpec(
      skyLight: [Color(0xFFDDF4F5), Color(0xFFE3EFF9), Color(0xFFD6D2EF)],
      skyDark: [Color(0xFF14303A), Color(0xFF161F3D), Color(0xFF1E1F44)],
      glow: Color(0xFF5FD3CC),
      ribbonBoost: .85,
    ),
    // Тарихи дала: жылы құм → алтын шапақ (көне, шежіре).
    _World.heritage: _WorldSpec(
      skyLight: [Color(0xFFF6E7C4), Color(0xFFF3DDB4), Color(0xFFE6C994)],
      skyDark: [Color(0xFF33260F), Color(0xFF3D2E15), Color(0xFF48381C)],
      glow: Color(0xFFF0C877),
    ),
  };

  /// Акценттің реңк-жылжыған серігі — дуотон градиенттің екінші дауысы.
  static Color _hueShift(Color c, double degrees) {
    final h = HSLColor.fromColor(c);
    return h.withHue((h.hue + degrees) % 360).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final accentB = _hueShift(accent, 30);
    final spec = _spec;
    final world = _world;
    // Ғарыш пен схема әлемдерінде аспан шырағы ӘРҚАШАН ай (жарық темада да).
    final moonMode =
        isDark || world == _World.cosmos || world == _World.circuit;
    _sky(canvas, size, spec);
    if (world == _World.blueprint) _blueprintGrid(canvas, size);
    if (isDark || spec.showStarsInLight) _stars(canvas, size);
    _celestial(canvas, size, accentB, moonMode);
    if (world == _World.cosmos) _orbits(canvas, size);
    if (!isDark && !moonMode) _godrays(canvas, size);
    _auroraRibbons(canvas, size, accentB, spec.ribbonBoost);
    _auroraOrbs(canvas, size, accentB);
    // Әр әлемнің ЖЕКЕ тірі құбылысы — пәннің қолтаңба тынысы.
    switch (world) {
      case _World.steppe:
        _windCurls(canvas, size);
      case _World.skyway:
        _jetTrail(canvas, size);
      case _World.circuit:
        _traces(canvas, size, spec.glow);
      case _World.lab:
        _traces(canvas, size, spec.glow);
      case _World.flora:
        _windCurls(canvas, size);
      case _World.heritage:
        _windCurls(canvas, size);
      case _World.blueprint:
      case _World.cosmos:
        break;
    }
    if (isDark || world == _World.cosmos) _shootingStar(canvas, size);
    if (!isDark &&
        (world == _World.steppe ||
            world == _World.skyway ||
            world == _World.flora ||
            world == _World.heritage)) {
      _clouds(canvas, size);
      _birds(canvas, size);
    }
    _heroSilhouette(canvas, size, accentB);
    _ornaments(canvas, size, accentB);
    // Жоталар: ең алысы — ең баяу әрі бозғылт, жақындаған сайын тезірек
    // әрі қанығырақ (үш қабат = нағыз атмосфералық тереңдік).
    _mistRange(
      canvas,
      size,
      parallax: .08,
      seedPhase: 4.4,
      amp: 12,
      alpha: isDark ? .06 : .04,
      color: accentB,
    );
    _mistRange(
      canvas,
      size,
      parallax: .16,
      seedPhase: 0,
      amp: 16,
      alpha: isDark ? .10 : .06,
      color: accentB,
    );
    _mistRange(
      canvas,
      size,
      parallax: .30,
      seedPhase: 2.1,
      amp: 24,
      alpha: isDark ? .14 : .09,
      color: accent,
    );
    _horizonGlow(canvas, size, spec.glow);
    _motes(canvas, size);
    _edgeFocus(canvas, size);
  }

  /// Аврора ленталары: аспан бойымен ирелеңдеп аққан жарық жолақтары —
  /// сахнаның «қолтаңба» құбылысы. Қараңғыда additive (жанып тұрады),
  /// жарықта қалыпты араласу; көлденең жиектері еріп жоғалады. Үш қабат
  /// қалыңдық (кең→өзек) blur-сыз жарқырау береді.
  void _auroraRibbons(Canvas canvas, Size size, Color accentB, double boost) {
    final w = size.width;
    final h = size.height;
    final specs = [
      (.20, 26.0, accent, (isDark ? .15 : .09) * boost, 44.0, 0.0),
      (.33, 34.0, accentB, (isDark ? .11 : .06) * boost, 32.0, 2.3),
    ];
    for (final (yF, amp, col, alpha, wd, ph) in specs) {
      final base = h * yF;
      final path = Path();
      for (var i = 0; i <= 24; i++) {
        final x = w * i / 24;
        final y =
            base +
            sin(x / w * 2 * pi * 1.15 + (t == 0 ? 0 : t * 2 * pi) + ph) * amp +
            sin(x / w * 2 * pi * 2.4 + ph * 1.7) * amp * .3;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          Offset(0, base),
          Offset(w, base),
          [
            col.withValues(alpha: 0),
            col.withValues(alpha: alpha),
            col.withValues(alpha: alpha),
            col.withValues(alpha: 0),
          ],
          const [0, .22, .78, 1],
        );
      if (isDark) paint.blendMode = BlendMode.plus;
      canvas.drawPath(path, paint..strokeWidth = wd);
      canvas.drawPath(path, paint..strokeWidth = wd * .45);
      canvas.drawPath(path, paint..strokeWidth = wd * .16);
    }
  }

  /// Күн сәулелері (жарық тема): күннен төмен-солға тарайтын жұмсақ шапақ
  /// бағандары — кинематографиялық жарық (additive, әрең байқалады).
  void _godrays(Canvas canvas, Size size) {
    final w = size.width;
    final sun = Offset(w * .84, size.height * .16);
    final sway = t == 0 ? 0.0 : sin(t * 2 * pi) * .02;
    for (var i = 0; i < 3; i++) {
      final ang = 1.95 + i * .28 + sway;
      final len = size.height * .95;
      final dir = Offset(cos(ang), sin(ang));
      final n = Offset(-dir.dy, dir.dx);
      final farW = 46.0 + i * 26;
      final tip = sun + dir * len;
      canvas.drawPath(
        Path()
          ..moveTo(sun.dx, sun.dy)
          ..lineTo(tip.dx + n.dx * farW, tip.dy + n.dy * farW)
          ..lineTo(tip.dx - n.dx * farW, tip.dy - n.dy * farW)
          ..close(),
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.linear(sun, tip, [
            accent.withValues(alpha: .07 - i * .015),
            accent.withValues(alpha: 0),
          ]),
      );
    }
  }

  /// Пәндік қолтаңба-силуэт: әр пәннің ЖАЛҒЫЗ ірі, әрең көрінетін белгісі —
  /// сым-сызық (wireframe) стилінде: «бояулы әлем» емес, елес су-белгі.
  void _heroSilhouette(Canvas canvas, Size size, Color accentB) {
    const tileH = 1500.0;
    final sh = (scrollOffset * .18) % tileH;
    final w = size.width;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = (isDark ? accentB : accent).withValues(
        alpha: isDark ? .12 : .08,
      );
    for (final tileOff in const [0.0, -tileH]) {
      final c = Offset(w * .18, .42 * tileH + sh + tileOff);
      if (c.dy < -140 || c.dy > size.height + 140) continue;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      switch (subjectId) {
        case 'math':
          _wirePolyhedron(canvas, paint);
        case 'english':
          _wireBalloon(canvas, paint);
        case 'physics':
          _wirePlanet(canvas, paint);
        case 'cs':
          _wireChip(canvas, paint);
        case 'biology':
          _wireLeaf(canvas, paint);
        case 'chemistry':
          _wireFlask(canvas, paint);
        case 'history':
          _wireBalbal(canvas, paint);
        default:
          _wireYurt(canvas, paint);
      }
      canvas.restore();
    }
  }

  /// Балбал тас: көне түркі тас мүсіні — бас, дене, білектегі тостаған (тарих).
  static void _wireBalbal(Canvas c, Paint p) {
    c.drawCircle(const Offset(0, -34), 16, p);
    c.drawPath(
      Path()
        ..moveTo(-20, -18)
        ..lineTo(-24, 52)
        ..lineTo(24, 52)
        ..lineTo(20, -18)
        ..close(),
      p,
    );
    c.drawLine(const Offset(-14, 4), const Offset(0, 12), p);
    c.drawLine(const Offset(14, 4), const Offset(0, 12), p);
    c.drawCircle(const Offset(0, 14), 6, p);
  }

  /// Жапырақ: контур + орталық тамыр + бүйір тамырлар (биология әлемі).
  static void _wireLeaf(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(0, -52)
        ..quadraticBezierTo(46, -20, 0, 52)
        ..quadraticBezierTo(-46, -20, 0, -52)
        ..close(),
      p,
    );
    c.drawLine(const Offset(0, -52), const Offset(0, 52), p);
    for (final dy in [-28.0, -6.0, 16.0]) {
      c.drawLine(Offset(0, dy), Offset(24, dy - 14), p);
      c.drawLine(Offset(0, dy), Offset(-24, dy - 14), p);
    }
  }

  /// Колба: мойын + конус + сұйықтық деңгейі + көпіршіктер (химия әлемі).
  static void _wireFlask(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(-12, -50)
        ..lineTo(-12, -20)
        ..lineTo(-46, 44)
        ..lineTo(46, 44)
        ..lineTo(12, -20)
        ..lineTo(12, -50),
      p,
    );
    c.drawLine(const Offset(-16, -50), const Offset(16, -50), p);
    c.drawLine(const Offset(-30, 20), const Offset(30, 20), p);
    for (final o in [
      const Offset(-6, 6),
      const Offset(10, 16),
      const Offset(0, 30),
    ]) {
      c.drawCircle(o, 3.5, p);
    }
  }

  /// Киіз үй: күмбез доғасы + керегелер + есік (қазақ тілі әлемі).
  static void _wireYurt(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(-58, 0)
        ..quadraticBezierTo(-30, -46, 0, -48)
        ..quadraticBezierTo(30, -46, 58, 0)
        ..close(),
      p,
    );
    c.drawLine(const Offset(-20, 0), const Offset(-8, -44), p);
    c.drawLine(const Offset(20, 0), const Offset(8, -44), p);
    c.drawRect(
      Rect.fromCenter(center: const Offset(0, -10), width: 18, height: 20),
      p,
    );
  }

  /// Сым-қаңқа көпжақ: алтыбұрыш + ішкі қырлар (математика әлемі).
  static void _wirePolyhedron(Canvas c, Paint p) {
    const r = 52.0;
    final hex = Path();
    final pts = <Offset>[];
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + i * pi / 3;
      final pt = Offset(cos(a) * r, sin(a) * r);
      pts.add(pt);
      i == 0 ? hex.moveTo(pt.dx, pt.dy) : hex.lineTo(pt.dx, pt.dy);
    }
    hex.close();
    c.drawPath(hex, p);
    c.drawLine(pts[0], pts[2], p);
    c.drawLine(pts[2], pts[4], p);
    c.drawLine(pts[4], pts[0], p);
  }

  /// Әуе шары: шар + арқан + себет (ағылшын — саяхат әлемі).
  static void _wireBalloon(Canvas c, Paint p) {
    c.drawPath(
      Path()
        ..moveTo(0, 20)
        ..cubicTo(-44, -12, -34, -58, 0, -58)
        ..cubicTo(34, -58, 44, -12, 0, 20)
        ..close(),
      p,
    );
    c.drawLine(const Offset(-10, 20), const Offset(-8, 40), p);
    c.drawLine(const Offset(10, 20), const Offset(8, 40), p);
    c.drawRect(
      Rect.fromCenter(center: const Offset(0, 46), width: 22, height: 14),
      p,
    );
  }

  /// Сақиналы ғаламшар (физика — ғарыш әлемі).
  static void _wirePlanet(Canvas c, Paint p) {
    c.drawCircle(Offset.zero, 34, p);
    c.save();
    c.rotate(-.32);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 118, height: 34), p);
    c.restore();
  }

  /// Микросхема: корпус + аяқтар + өзек (информатика әлемі).
  static void _wireChip(Canvas c, Paint p) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 76, height: 76),
        const Radius.circular(9),
      ),
      p,
    );
    c.drawRect(Rect.fromCenter(center: Offset.zero, width: 38, height: 38), p);
    for (var i = -1; i <= 1; i++) {
      final d = i * 22.0;
      c.drawLine(Offset(d, -38), Offset(d, -50), p);
      c.drawLine(Offset(d, 38), Offset(d, 50), p);
      c.drawLine(Offset(-38, d), Offset(-50, d), p);
      c.drawLine(Offset(38, d), Offset(50, d), p);
    }
  }

  /// Нәзік жиек фокусы: шеттерді бірнеше пайызға ғана күңгірттеу — көз
  /// ортадағы жолға жиналады (байқалмайтын фотографиялық тереңдік).
  void _edgeFocus(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final col = const Color(0xFF060618).withValues(alpha: isDark ? .26 : .08);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * .5, size.height * .45),
          size.longestSide * .78,
          [const Color(0x00000000), col],
          const [.72, 1],
        ),
    );
  }

  /// Аспан шырағы: күн әлемдерінде — жұмсақ күн, ай режимінде (қараңғы тема
  /// НЕМЕСЕ ғарыш/схема әлемі) — жарты ай. Аспанға «бекітілген»
  /// (паралакссыз), тек нәзік тыныс тербелісі бар — скроллда орнында қалады.
  void _celestial(Canvas canvas, Size size, Color accentB, bool moonMode) {
    final w = size.width;
    final bob = t == 0 ? 0.0 : sin(t * 2 * pi) * 3;
    final c = Offset(w * .84, size.height * .16 + bob);
    final f = isDark ? 1.0 : .7;
    if (moonMode) {
      final r = w * .062;
      final halo = accentB.withValues(alpha: .18 * f);
      canvas.drawCircle(
        c,
        r * 2.6,
        Paint()
          ..shader = ui.Gradient.radial(c, r * 2.6, [
            halo,
            halo.withValues(alpha: 0),
          ]),
      );
      // Жарты ай — екі шеңбердің айырмасы (қиылған дөңгелек).
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
        Path()
          ..addOval(
            Rect.fromCircle(
              center: c.translate(r * .42, -r * .18),
              radius: r * .86,
            ),
          ),
      );
      canvas.drawPath(
        moon,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFEDEAFF),
            accent,
            .15,
          )!.withValues(alpha: .55 * f),
      );
    } else {
      final r = w * .085;
      final halo = accent.withValues(alpha: .16);
      canvas.drawCircle(
        c,
        r * 2.4,
        Paint()
          ..shader = ui.Gradient.radial(c, r * 2.4, [
            halo,
            halo.withValues(alpha: 0),
          ]),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(c.translate(-r * .25, -r * .25), r * 1.4, [
            Color.lerp(
              const Color(0xFFFFFBEA),
              accent,
              .10,
            )!.withValues(alpha: .85),
            Color.lerp(
              const Color(0xFFFFE9B8),
              accent,
              .22,
            )!.withValues(alpha: .5),
          ]),
      );
    }
  }

  /// Жұмсақ бұлт үлпектері (жарық тема): үш қабат радиалды үлпек, баяу
  /// паралакс + нәзік тербеліс. Айқын жиек жоқ — таза «мамық».
  void _clouds(Canvas canvas, Size size) {
    const tileH = 1100.0;
    final sh = (scrollOffset * .09) % tileH;
    final w = size.width;
    const puffs = [(.20, .12, .16), (.75, .50, .13), (.35, .86, .11)];
    void puff(Offset c, double r, double a) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(c, r, [
            AppColors.white.withValues(alpha: a),
            AppColors.white.withValues(alpha: 0),
          ]),
      );
    }

    for (final tileOff in const [0.0, -tileH]) {
      for (var k = 0; k < puffs.length; k++) {
        final (fx, fy, fr) = puffs[k];
        final bob = t == 0 ? 0.0 : sin(t * 2 * pi + k * 2.1) * 6;
        final c = Offset(fx * w + bob, fy * tileH + sh + tileOff);
        if (c.dy < -100 || c.dy > size.height + 100) continue;
        final r = fr * w;
        puff(c, r, .32);
        puff(c.translate(r * .7, r * .18), r * .7, .26);
        puff(c.translate(-r * .65, r * .22), r * .6, .24);
      }
    }
  }

  /// Алыстағы қырандар (жарық тема): экранды асықпай кесіп өтетін екі
  /// силуэт — дала аспанының тірі белгісі. Анимация өшік болса көрінбейді.
  void _birds(Canvas canvas, Size size) {
    if (t == 0) return;
    final w = size.width;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = _hueShift(accent, -12).withValues(alpha: .18);
    for (var k = 0; k < 2; k++) {
      final fx = ((k * .5 + .12) + t) % 1.0;
      final x = fx * (w + 140) - 70;
      final y = size.height * (.20 + k * .07) + sin(t * 2 * pi * 2 + k) * 5;
      final s = 8.0 - k * 2;
      final lift = sin(t * 2 * pi * 6 + k * 2) * s * .35;
      canvas.drawPath(
        Path()
          ..moveTo(x - s, y + lift * .3)
          ..quadraticBezierTo(x - s * .4, y - s * .45 - lift, x, y)
          ..quadraticBezierTo(x + s * .4, y - s * .45 - lift, x + s, y + lift * .3),
        paint,
      );
    }
  }

  /// Ұшқан жұлдыз: дрейф циклінде екі рет, қысқа әрі әсем (жарық темадағы
  /// ғарыш әлемінде бозғылтырақ).
  void _shootingStar(Canvas canvas, Size size) {
    if (t == 0) return;
    final w = size.width;
    final h = size.height;
    final f = isDark ? 1.0 : .55;
    for (final base in const [.22, .74]) {
      var local = t - base;
      if (local < 0) local += 1;
      if (local >= .08) continue;
      final p = local / .08;
      final head = Offset(w * (.2 + p * .5), h * (.12 + p * .18));
      final tail = head - Offset(w * .11, h * .045);
      final a = sin(p * pi) * f;
      canvas.drawLine(
        head,
        tail,
        Paint()
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(head, tail, [
            AppColors.white.withValues(alpha: .8 * a),
            AppColors.white.withValues(alpha: 0),
          ]),
      );
      canvas.drawCircle(
        head,
        1.6,
        Paint()..color = AppColors.white.withValues(alpha: .9 * a),
      );
    }
  }

  /// Дала самалы: желдің бұйра ағындары — ұшы оралған талғампаз сызықтар,
  /// t-мен көлденең сырғып өтеді (қазақ тілі әлемінің тірі демі).
  void _windCurls(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? const Color(0xFFFFD9A0) : accent).withValues(
        alpha: isDark ? .14 : .12,
      );
    for (var k = 0; k < 2; k++) {
      final drift = t == 0 ? .3 + k * .3 : ((t + k * .5) % 1.0);
      final x0 = drift * (w + 260) - 130;
      final y0 = h * (.30 + k * .26) + (t == 0 ? 0 : sin(t * 2 * pi + k) * 6);
      final s = 60.0 - k * 14;
      final path = Path()
        ..moveTo(x0 - s * 1.6, y0 + s * .18)
        ..quadraticBezierTo(x0 - s * .4, y0 - s * .22, x0 + s * .5, y0)
        ..arcTo(
          Rect.fromCircle(
            center: Offset(x0 + s * .5, y0 - s * .16),
            radius: s * .16,
          ),
          pi / 2,
          1.6 * pi,
          false,
        );
      canvas.drawPath(path, paint);
    }
  }

  /// Көк сызба торы: ірі ұяшықты әрең көрінетін тор + өлшеу «+» белгілері —
  /// математика әлемінің инженерлік қолтаңбасы (тор скроллмен бірге жүреді).
  void _blueprintGrid(Canvas canvas, Size size) {
    const cell = 96.0;
    final sh = scrollOffset % cell;
    final aBase = isDark ? .06 : .05;
    final base = isDark ? const Color(0xFF9CC4FF) : accent;
    final p = Paint()
      ..strokeWidth = 1
      ..color = base.withValues(alpha: aBase);
    for (var x = 0.0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = sh - cell; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final cross = Paint()
      ..strokeWidth = 1.4
      ..color = base.withValues(alpha: aBase * 1.9);
    final rnd = Random(5);
    final cols = (size.width / cell).ceil() + 1;
    for (var i = 0; i < 8; i++) {
      final cx = rnd.nextInt(cols) * cell;
      final cy = rnd.nextInt(14) * cell + sh - cell;
      if (cy < -8 || cy > size.height + 8) continue;
      canvas.drawLine(Offset(cx - 5, cy), Offset(cx + 5, cy), cross);
      canvas.drawLine(Offset(cx, cy - 5), Offset(cx, cy + 5), cross);
    }
  }

  /// Саяхат ізі: аспанда баяу жүзіп өтетін қағаз ұшақ + артындағы үзік із
  /// доғасы (ағылшын әлемінің «сапар» рухы).
  void _jetTrail(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final prog = t == 0 ? .55 : t;
    final head = Offset(
      prog * (w + 320) - 160,
      h * .26 - sin(prog * pi) * h * .06,
    );
    final a = isDark ? .30 : .22;
    final col = (isDark ? const Color(0xFFFFC9A0) : accent).withValues(
      alpha: a,
    );
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = col.withValues(alpha: a * .6);
    Offset trail(double u) =>
        Offset(head.dx - u * 170, head.dy + sin(u * pi * .9) * 16 + u * 8);
    var d = 0.0;
    while (d < 150) {
      canvas.drawLine(trail(d / 150), trail((d + 9) / 150), dash);
      d += 20;
    }
    canvas.save();
    canvas.translate(head.dx, head.dy);
    canvas.rotate(-.18);
    canvas.drawPath(
      Path()
        ..moveTo(12, 0)
        ..lineTo(-9, -5.5)
        ..lineTo(-3.5, 0)
        ..close(),
      Paint()..color = col,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 0)
        ..lineTo(-9, 5)
        ..lineTo(-3.5, 0)
        ..close(),
      Paint()..color = col.withValues(alpha: a * .6),
    );
    canvas.restore();
  }

  /// Ғарыш орбиталары: ай маңындағы қос эллипс орбита және үлкенінде айналып
  /// жүрген жарық серік (физика әлемінің тынысы).
  void _orbits(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w * .84, size.height * .16);
    final col = const Color(0xFFB9A6FF).withValues(alpha: isDark ? .16 : .12);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = col;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-.30);
    final r2 = Rect.fromCenter(
      center: Offset.zero,
      width: w * .52,
      height: w * .20,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * .34, height: w * .13),
      p,
    );
    canvas.drawOval(r2, p);
    final ang = (t == 0 ? .3 : t) * 2 * pi;
    final sat = Offset(cos(ang) * r2.width / 2, sin(ang) * r2.height / 2);
    canvas.drawCircle(
      sat,
      5,
      Paint()
        ..shader = ui.Gradient.radial(sat, 8, [
          col.withValues(alpha: .5),
          col.withValues(alpha: 0),
        ]),
    );
    canvas.drawCircle(
      sat,
      1.8,
      Paint()
        ..color = const Color(0xFFEDE8FF).withValues(
          alpha: isDark ? .8 : .6,
        ),
    );
    canvas.restore();
  }

  /// Схема жолдары: Манхэттен бұрылысты трассалар + бойымен жүгірген жарық
  /// импульстер (информатика әлемінің тірі тогы).
  void _traces(Canvas canvas, Size size, Color glow) {
    const tileH = 700.0;
    final sh = (scrollOffset * .14) % tileH;
    final w = size.width;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round
      ..color = glow.withValues(alpha: isDark ? .12 : .10);
    for (final tileOff in const [0.0, -tileH]) {
      for (var k = 0; k < 3; k++) {
        final y0 = (k + .5) / 3 * tileH + sh + tileOff;
        if (y0 < -80 || y0 > size.height + 80) continue;
        final rnd = Random(k * 37 + 3);
        final path = Path()..moveTo(0, y0);
        var x = 0.0;
        var y = y0;
        Offset? node;
        while (x < w) {
          x += w * (.14 + rnd.nextDouble() * .18);
          path.lineTo(x, y);
          node ??= Offset(x, y);
          if (rnd.nextBool()) {
            y += (rnd.nextBool() ? 1 : -1) * 34;
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, line);
        if (node != null) {
          canvas.drawCircle(
            node,
            2.2,
            Paint()..color = glow.withValues(alpha: isDark ? .22 : .16),
          );
        }
        // Жүгірген импульс — трасса бойымен (қараңғыда additive жанады).
        if (t > 0) {
          final m = path.computeMetrics().first;
          final pos = ((t * (k.isEven ? 1 : 2)) % 1.0) * m.length;
          final tan = m.getTangentForOffset(pos);
          if (tan != null) {
            canvas.drawCircle(
              tan.position,
              4.5,
              Paint()
                ..shader = ui.Gradient.radial(tan.position, 7, [
                  glow.withValues(alpha: .5),
                  glow.withValues(alpha: 0),
                ]),
            );
            final pulse = Paint()..color = glow.withValues(alpha: .75);
            if (isDark) pulse.blendMode = BlendMode.plus;
            canvas.drawCircle(tan.position, 1.8, pulse);
          }
        }
      }
    }
  }

  /// Қошқар мүйіз ою-спиральдары — қазақ болмысының нәзік қолтаңбасы:
  /// жол шетінде, әрең көрінетін штрихпен (айқындықпен таласпайды).
  void _ornaments(Canvas canvas, Size size, Color accentB) {
    const tileH = 1500.0;
    final sh = (scrollOffset * .22) % tileH;
    final w = size.width;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = (isDark ? accentB : accent).withValues(
        alpha: isDark ? .10 : .07,
      );
    const spots = [(.10, .18, 44.0, false), (.90, .62, 52.0, true)];
    for (final tileOff in const [0.0, -tileH]) {
      for (final (fx, fy, s, flip) in spots) {
        final c = Offset(fx * w, fy * tileH + sh + tileOff);
        if (c.dy < -s * 2 || c.dy > size.height + s * 2) continue;
        canvas.save();
        canvas.translate(c.dx, c.dy);
        if (flip) canvas.scale(-1, 1);
        // Қос мүйіз: үлкен спираль + кішірек айнасы.
        canvas.drawPath(_horn(s), paint);
        canvas
          ..save()
          ..scale(-1, 1)
          ..translate(s * .1, 0)
          ..drawPath(_horn(s * .8), paint)
          ..restore();
        canvas.restore();
      }
    }
  }

  /// Ішке қарай оралатын спираль (мүйіз) полисызығы.
  static Path _horn(double s) {
    final p = Path();
    for (var i = 0; i <= 44; i++) {
      final th = i / 44 * 2.2 * pi;
      final r = s * (1 - th / (2.9 * pi));
      final pt = Offset(cos(th) * r, -sin(th) * r);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p;
  }

  /// Төменгі көкжиек шапағы — әлемнің өз реңкімен (дала алтыны / сызба
  /// мұзы / батыс қызғылты / ғарыш күлгіні / схема көгілдірі) жанады.
  void _horizonGlow(Canvas canvas, Size size, Color glow) {
    final c = Offset(size.width * .5, size.height * 1.08);
    final r = size.width * 1.05;
    final col = glow.withValues(alpha: isDark ? .14 : .10);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(c, r, [col, col.withValues(alpha: 0)]),
    );
  }

  /// Көтерілген жарық түйіршіктері — ауадағы тіршілік (өте нәзік, 10 дана).
  void _motes(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rnd = Random(29);
    final col = isDark ? AppColors.white : accent;
    for (var i = 0; i < 10; i++) {
      final fx = rnd.nextDouble();
      final fy = rnd.nextDouble();
      final fr = rnd.nextDouble();
      final rise = t == 0 ? fy : (fy + t * (1 + i % 2)) % 1.0;
      final y = h * (1 - rise);
      final x = fx * w + (t == 0 ? 0 : sin(t * 2 * pi + i) * 9);
      final tw = t == 0
          ? .6
          : .4 + .6 * (.5 + .5 * sin(t * 2 * pi * (2 + i % 3) + i));
      canvas.drawCircle(
        Offset(x, y),
        1.2 + fr * 1.8,
        Paint()..color = col.withValues(alpha: .10 * tw),
      );
    }
  }

  /// Пән әлемінің аспаны: әр әлемге қолмен теңгерілген 3 сатылы палитра
  /// (жарық/қараңғы тема бөлек) — дала таңы, көк сызба, саяхат батысы,
  /// ғарыш түні, схема тереңі бірден танылады.
  void _sky(Canvas canvas, Size size, _WorldSpec spec) {
    final rect = Offset.zero & size;
    final cols = isDark ? spec.skyDark : spec.skyLight;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topCenter,
          rect.bottomCenter,
          cols,
          const [0, .55, 1],
        ),
    );
  }

  /// Сирек жұлдыздар — өте баяу паралакс + жұмсақ жымың. Қараңғы темада
  /// толық, жарық темада (ғарыш әлемі) әлдеқайда бозғылт.
  void _stars(Canvas canvas, Size size) {
    const tileH = 900.0;
    final sh = (scrollOffset * .06) % tileH;
    final dim = isDark ? 1.0 : .45;
    final rnd = Random(11);
    for (var i = 0; i < 26; i++) {
      final fx = rnd.nextDouble();
      final fy = rnd.nextDouble();
      final fr = rnd.nextDouble();
      for (final tileOff in const [0.0, -tileH]) {
        final y = fy * tileH + sh + tileOff;
        if (y < -8 || y > size.height + 8) continue;
        final tw = t == 0
            ? .7
            : .45 + .55 * (.5 + .5 * sin(t * 2 * pi * (2 + i % 3) + i));
        canvas.drawCircle(
          Offset(fx * size.width, y),
          .6 + fr * .9,
          Paint()
            ..color = (isDark ? AppColors.white : accent).withValues(
              alpha: .3 * tw * dim,
            ),
        );
      }
    }
  }

  /// Аврора орбтары: үлкен, жұмсақ, өте баяу тыныс алып қалқиды.
  void _auroraOrbs(Canvas canvas, Size size, Color accentB) {
    const tileH = 1300.0;
    final sh = (scrollOffset * .12) % tileH;
    final w = size.width;
    // (x үлесі, y үлесі, радиус үлесі) — қолмен теңгерілген композиция.
    const spots = [
      (.18, .10, .62),
      (.88, .34, .50),
      (.10, .58, .46),
      (.80, .84, .66),
    ];
    for (final tileOff in const [0.0, -tileH]) {
      for (var k = 0; k < spots.length; k++) {
        final (fx, fy, fr) = spots[k];
        final drift = t == 0
            ? Offset.zero
            : Offset(
                sin(t * 2 * pi + k * 1.7) * 16,
                cos(t * 2 * pi + k * 1.1) * 12,
              );
        final c = Offset(fx * w, fy * tileH + sh + tileOff) + drift;
        final r = fr * w;
        if (c.dy < -r || c.dy > size.height + r) continue;
        final col = (k.isEven ? accent : accentB).withValues(
          alpha: isDark ? (k.isEven ? .14 : .10) : (k.isEven ? .09 : .06),
        );
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = ui.Gradient.radial(c, r, [
              col,
              col.withValues(alpha: 0),
            ]),
        );
      }
    }
  }

  /// Тұман-жота: толқынды жоғарғы жиегі бар, төмен қарай еріп жоғалатын
  /// силуэт белдеуі. Скроллда [parallax] жылдамдығымен өтеді (тік тайл).
  void _mistRange(
    Canvas canvas,
    Size size, {
    required double parallax,
    required double seedPhase,
    required double amp,
    required double alpha,
    required Color color,
  }) {
    const tileH = 560.0;
    const depth = 150.0;
    final sh = (scrollOffset * parallax) % tileH;
    final w = size.width;
    for (final tileOff in const [0.0, -tileH]) {
      final baseY = tileH * .5 + sh + tileOff;
      if (baseY < -depth - amp * 2 || baseY > size.height + depth) continue;
      final path = Path()..moveTo(0, baseY + _waveY(0, w, amp, seedPhase));
      for (var x = 0.0; x <= w; x += w / 22) {
        path.lineTo(x, baseY + _waveY(x, w, amp, seedPhase));
      }
      path
        ..lineTo(w, baseY + depth)
        ..lineTo(0, baseY + depth)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, baseY - amp),
            Offset(0, baseY + depth),
            [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
          ),
      );
    }
  }

  /// Екі синустың қосындысы — табиғи, қайталанбайтын жота сызығы.
  static double _waveY(double x, double w, double amp, double phase) =>
      sin(x / w * 2 * pi * 1.3 + phase) * amp +
      sin(x / w * 2 * pi * 2.9 + phase * 1.8 + 1.2) * amp * .38;

  @override
  bool shouldRepaint(_MapSceneryPainter old) =>
      old.scrollOffset != scrollOffset ||
      old.t != t ||
      old.accent != accent ||
      old.subjectId != subjectId ||
      old.isDark != isDark;
}

/// Пән әлемдері: әрқайсысының өз аспаны, шапағы және тірі құбылысы бар.
enum _World { steppe, blueprint, skyway, cosmos, circuit, flora, lab, heritage }

/// Бір әлемнің дискрет ерекшеліктері (палитра — қолмен теңгерілген).
class _WorldSpec {
  const _WorldSpec({
    required this.skyLight,
    required this.skyDark,
    required this.glow,
    this.ribbonBoost = 1,
    this.showStarsInLight = false,
  });

  /// Аспанның 3 сатылы палитрасы (top→mid→bottom), тема бойынша бөлек.
  final List<Color> skyLight;
  final List<Color> skyDark;

  /// Көкжиек шапағы мен импульстердің фирмалық реңкі.
  final Color glow;

  /// Аврора ленталарының салыстырмалы қарқыны (техникалық әлемде бәсең,
  /// ғарышта күшті).
  final double ribbonBoost;

  /// Жарық темада да жұлдыз көрсету (ғарыш әлеміне ымырт сезімі).
  final bool showStarsInLight;
}
