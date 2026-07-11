import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../models/enums.dart';
import '../../providers/task_provider.dart';

/// Оқу картасының түйіні — Duolingo-стиль ЖАЛПАҚ шырынды түйме: стадион
/// (pill) пішіні + астында қалың қою «ернеу» (3D басылу сезімі). Жылтыр,
/// градиент, ақ жиек ЖОҚ — бір таза түс, көз бірден оқиды.
///  - completed/mastered — жасыл (#00C48C) + ақ галочка (+ mastered: тәж),
///  - current — алтын + кеңейетін сақина пульсі,
///  - босс/қазына — алтын әрі ірірек,
///  - available — пәннің акцент түсі,
///  - locked — бейтарап сұр + бұрышта құлып белгісі.
class NodeWidget extends StatelessWidget {
  const NodeWidget({
    super.key,
    required this.view,
    required this.accent,
    required this.onTap,
    this.animationsOn = true,
  });

  final NodeView view;

  /// Пәннің акцент түсі (available node-тардың негізі).
  final Color accent;
  final VoidCallback onTap;
  final bool animationsOn;

  // Кәдімгі түйме мен ірі (босс/қазына) түйменің өлшемдері.
  static const double _w = 72;
  static const double _h = 58;
  static const double _lip = 7;
  static const double _wBig = 88;
  static const double _hBig = 68;
  static const double _lipBig = 8;

  bool get _done =>
      view.status == NodeStatus.completed ||
      view.status == NodeStatus.mastered;
  bool get _locked => view.status == NodeStatus.locked;
  bool get _mastered => view.status == NodeStatus.mastered;
  bool get _big =>
      view.node.type == NodeType.boss || view.node.type == NodeType.treasure;

  static IconData typeIcon(NodeType type) => switch (type) {
    NodeType.lesson => Icons.menu_book_rounded,
    NodeType.quiz => Icons.bolt_rounded,
    NodeType.boss => Icons.local_fire_department_rounded,
    NodeType.treasure => Icons.diamond_rounded,
  };

  static Color _shade(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final w = _big ? _wBig : _w;
    final h = _big ? _hBig : _h;
    final lip = _big ? _lipBig : _lip;

    // Күй бойынша БІР таза түс (жалпақ, градиентсіз).
    final Color face;
    Color iconColor = AppColors.white;
    if (_locked) {
      face = AppColors.border;
      iconColor = AppColors.inkSoft.withValues(alpha: .8);
    } else if (_done) {
      face = AppColors.successJade;
    } else if (view.isCurrent || _big) {
      face = AppColors.steppeGold;
    } else {
      face = accent;
    }
    final rim = _shade(face, -.16);
    final radius = BorderRadius.circular(h);
    final icon = _done ? Icons.check_rounded : typeIcon(view.node.type);

    // Түйменің өзі: астыңғы ернеу + жалпақ бет + икон.
    Widget button = SizedBox(
      width: w,
      height: h + lip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: lip,
            left: 0,
            right: 0,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: rim,
                borderRadius: radius,
                boxShadow: _locked
                    ? null
                    : [
                        BoxShadow(
                          color: face.withValues(
                            alpha: view.isCurrent ? .45 : .28,
                          ),
                          offset: const Offset(0, 5),
                          blurRadius: view.isCurrent ? 16 : 9,
                        ),
                      ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: h,
              decoration: BoxDecoration(color: face, borderRadius: radius),
              child: Icon(icon, size: h * .52, color: iconColor),
            ),
          ),
          // Ағымдағы түйін: беттің айналасында кеңейетін алтын сақина пульсі.
          if (view.isCurrent && animationsOn)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: h,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child:
                      Container(
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              border: Border.all(
                                color: AppColors.steppeGold,
                                width: 3,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .scaleXY(begin: 1, end: 1.35, duration: 1800.ms)
                          .fadeOut(duration: 1800.ms),
                ),
              ),
            ),
          // Құлып белгісі (кіші, бұрышта) — солғын сабақ ишарасын жаппайды.
          if (_locked)
            Positioned(
              bottom: lip - 4,
              right: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.nightInk.withValues(alpha: .82),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 11,
                  color: AppColors.white,
                ),
              ),
            ),
        ],
      ),
    );

    return Pressable(
      onTap: onTap,
      semanticLabel: view.node.title,
      // Құлыпталған node — нәзік squish (тек ишара); ашық node — толық басу.
      pressedScale: _locked ? 0.97 : 0.92,
      child: SizedBox(
        width: w + 12,
        height: h + lip + 10,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: 2, left: 6, right: 6, child: button),
            // Меңгерілген түйін — төбесінде алтын тәж.
            if (_mastered)
              Positioned(
                left: 0,
                right: 0,
                top: -10,
                child: Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 19,
                    color: AppColors.goldBright,
                    shadows: [
                      Shadow(
                        color: AppColors.nightInk.withValues(alpha: .4),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            // Жиналған жұлдыздар — түйменің төменгі ернеуіне жабысқан белдеу.
            if (_done)
              Positioned(
                left: 0,
                right: 0,
                top: h + lip - 9,
                child: Center(child: _StarRow(stars: view.stars)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Аяқталған node ернеуіне жабысқан ықшам жұлдыз белдеуі (медаль тәрізді):
/// қою мөлдір pill фон + 3 кішкентай жұлдыз (ортаңғысы сәл үлкен/көтеріңкі).
class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.nightInk.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == 1 ? 3 : 0,
                left: i == 0 ? 0 : 1,
              ),
              child: Icon(
                Icons.star_rounded,
                size: i == 1 ? 15 : 12,
                color: i < stars
                    ? AppColors.goldBright
                    : AppColors.white.withValues(alpha: .3),
              ),
            ),
        ],
      ),
    );
  }
}
