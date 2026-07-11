import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';
import '../../models/lesson.dart';
import '../../models/task_node.dart';
import '../../providers/task_provider.dart';
import 'node_widget.dart';

// ============================================================================
//  Оқу картасының ҮСТЕМЕ ҚАБАТТАРЫ (overlays)
//  ──────────────────────────────────────────────────────────────────────────
//  Бұл файл — карта экранының навигация мен бағдар беретін «екінші қабаты»:
//    • [JourneyOverviewSheet] — бүкіл саяхаттың шолуы (сынып·модуль прогресі,
//      жалпы статистика, түртіп секіру);
//    • [MapLegendSheet] — түйін түрлері мен күйлерінің анықтамасы;
//    • [GradeJumpRail] — оң жиектегі сыныптар арасында жылдам секіру рейлі;
//    • [MapControls] — жоғарғы оң жақтағы дөңгелек басқару түймелері;
//    • Жалпы көмекшілер: [RingBadge], [LegendCoin] және [buildJourney].
//
//  Барлық дерек — ОФЛАЙН (taskProvider.nodeViews()); ешқандай желі қажет емес.
//  Тақырыпқа бейім (жарық/қараңғы) — AppColors семантикалық токендері арқылы.
// ============================================================================

/// Картаны түртіп секіру қолтаңбасы: [grade] — мақсат сынып, [module] — нақты
/// модуль (null болса — сынып банеріне секіреді).
typedef MapJumpCallback = void Function(int grade, int? module);

// ----------------------------------------------------------------------------
//  Саяхат моделі (views → сынып/модуль ағашы)
// ----------------------------------------------------------------------------

/// Бір модульдің жинақталған прогресі (overview/rail осыдан оқиды).
class JourneyModule {
  JourneyModule({
    required this.grade,
    required this.module,
    required this.title,
    required this.nodes,
  });

  final int grade;
  final int module;
  final String title;
  final List<NodeView> nodes;

  static bool _isDone(NodeView v) =>
      v.status == NodeStatus.completed || v.status == NodeStatus.mastered;

  int get total => nodes.length;
  int get done => nodes.where(_isDone).length;
  int get mastered =>
      nodes.where((v) => v.status == NodeStatus.mastered).length;
  int get stars => nodes.fold(0, (s, v) => s + v.stars);
  double get frac => total == 0 ? 0 : done / total;
  bool get complete => total > 0 && done == total;
  bool get hasCurrent => nodes.any((v) => v.isCurrent);

  /// Модуль толық жабық па (бірде-бір ашық/аяқталған түйін жоқ).
  bool get locked => nodes.every((v) => v.status == NodeStatus.locked);

  /// Модульдегі барлық сұрақ саны (overview статистикасы үшін).
  int get questionCount => nodes.fold(0, (s, v) => s + v.node.questions.length);

  int get xpReward => nodes.fold(0, (s, v) => s + v.node.xpReward);
}

/// Бір сыныптың модульдер тобы.
class JourneyGrade {
  JourneyGrade({required this.grade, required this.modules});

  final int grade;
  final List<JourneyModule> modules;

  int get total => modules.fold(0, (s, m) => s + m.total);
  int get done => modules.fold(0, (s, m) => s + m.done);
  int get mastered => modules.fold(0, (s, m) => s + m.mastered);
  int get stars => modules.fold(0, (s, m) => s + m.stars);
  int get questionCount => modules.fold(0, (s, m) => s + m.questionCount);
  int get xpReward => modules.fold(0, (s, m) => s + m.xpReward);
  double get frac => total == 0 ? 0 : done / total;
  bool get complete => total > 0 && done == total;
  bool get hasCurrent => modules.any((m) => m.hasCurrent);
}

/// `views` тізімін (реті сақталған) сынып→модуль ағашына жинайды.
List<JourneyGrade> buildJourney(List<NodeView> views) {
  final grades = <int, Map<int, JourneyModule>>{};
  final gradeOrder = <int>[];
  final moduleOrder = <int, List<int>>{};

  for (final v in views) {
    final g = v.node.grade;
    final m = v.node.module;
    grades.putIfAbsent(g, () {
      gradeOrder.add(g);
      moduleOrder[g] = [];
      return {};
    });
    final mods = grades[g]!;
    final mod = mods.putIfAbsent(m, () {
      moduleOrder[g]!.add(m);
      return JourneyModule(
        grade: g,
        module: m,
        title: v.node.moduleTitle,
        nodes: [],
      );
    });
    mod.nodes.add(v);
  }

  return [
    for (final g in gradeOrder)
      JourneyGrade(
        grade: g,
        modules: [for (final m in moduleOrder[g]!) grades[g]![m]!],
      ),
  ];
}

Color _shade(Color c, double amount) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
}

// ----------------------------------------------------------------------------
//  Ортақ примитивтер
// ----------------------------------------------------------------------------

/// Дөңгелек прогресс белгісі: сақина + ортада мазмұн (нөмір / галочка / тәж).
class RingBadge extends StatelessWidget {
  const RingBadge({
    super.key,
    required this.frac,
    required this.color,
    required this.size,
    this.child,
    this.strokeWidth = 4,
    this.trackColor,
  });

  final double frac;
  final Color color;
  final double size;
  final Widget? child;
  final double strokeWidth;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: frac.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: trackColor ?? AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Анықтама/шолу үшін КІШІ статикалық түйме (node_widget визуалының
/// ықшамдалған, басылмайтын нұсқасы): жалпақ стадион бет + қою ернеу + икон,
/// қалауы бойынша құлып/галочка/тәж және жұлдыз белдеуі.
class LegendCoin extends StatelessWidget {
  const LegendCoin({
    super.key,
    required this.base,
    required this.icon,
    this.size = 44,
    this.locked = false,
    this.crown = false,
    this.stars,
    this.pulse = false,
  });

  final Color base;
  final IconData icon;
  final double size;
  final bool locked;
  final bool crown;
  final int? stars;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final face = locked ? AppColors.border : base;
    final rim = _shade(face, -.16);
    final w = size + 12;
    final h = size - 4;
    const lip = 5.0;
    final radius = BorderRadius.circular(h);
    Widget coin = SizedBox(
      width: w,
      height: h + lip + 2,
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
                boxShadow: locked
                    ? null
                    : [
                        BoxShadow(
                          color: face.withValues(alpha: .3),
                          offset: const Offset(0, 3),
                          blurRadius: 7,
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
              child: Icon(
                icon,
                size: h * .52,
                color: locked
                    ? AppColors.inkSoft.withValues(alpha: .8)
                    : AppColors.white,
              ),
            ),
          ),
          if (locked)
            Positioned(
              bottom: -1,
              right: -3,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: AppColors.nightInk.withValues(alpha: .82),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 1.4),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 9,
                  color: AppColors.white,
                ),
              ),
            ),
          if (crown)
            Positioned(
              top: -size * .3,
              left: 0,
              right: 0,
              child: Center(
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: size * .42,
                  color: AppColors.goldBright,
                ),
              ),
            ),
        ],
      ),
    );

    if (stars != null) {
      coin = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          coin,
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Icon(
                  Icons.star_rounded,
                  size: 11,
                  color: i < stars! ? AppColors.goldBright : AppColors.border,
                ),
            ],
          ),
        ],
      );
    }

    if (pulse) {
      coin = Stack(
        alignment: Alignment.center,
        children: [
          Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: base, width: 2),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 1, end: 1.5, duration: 1600.ms)
              .fadeOut(duration: 1600.ms),
          coin,
        ],
      );
    }

    return coin;
  }
}

// ----------------------------------------------------------------------------
//  Жоғарғы оң жақ басқару түймелері (шолу + белгілер)
// ----------------------------------------------------------------------------

/// Картаның жоғарғы оң бұрышындағы тік дөңгелек түймелер шоғыры.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.accent,
    required this.onOverview,
    required this.onLegend,
  });

  final Color accent;
  final VoidCallback onOverview;
  final VoidCallback onLegend;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(
          icon: Icons.map_rounded,
          accent: accent,
          tooltip: AppStrings.mapOverviewTitle,
          onTap: onOverview,
        ),
        const SizedBox(height: AppSpacing.sp2),
        _RoundButton(
          icon: Icons.help_outline_rounded,
          accent: accent,
          tooltip: AppStrings.mapLegendTitle,
          onTap: onLegend,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.accent,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Ink(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: AppColors.cardShadow,
              border: Border.all(
                color: accent.withValues(alpha: .25),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
//  Сынып секіру рейлі (оң жиекте)
// ----------------------------------------------------------------------------

/// Оң жиектегі тік рейл: бар сыныптардың дөңгелектері (прогресс сақинасымен),
/// ағымдағы сынып бөлектеніп тұрады; түрту → сол сыныпқа тегіс скролл.
class GradeJumpRail extends StatelessWidget {
  const GradeJumpRail({
    super.key,
    required this.grades,
    required this.currentGrade,
    required this.accent,
    required this.onJump,
  });

  /// Прогресс деректері бар сыныптар (төменнен жоғары рет).
  final List<JourneyGrade> grades;
  final int currentGrade;
  final Color accent;
  final MapJumpCallback onJump;

  @override
  Widget build(BuildContext context) {
    if (grades.length < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .92),
        borderRadius: AppRadius.rFull,
        boxShadow: AppColors.sh2,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final g in grades)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _RailDot(
                grade: g,
                active: g.grade == currentGrade,
                accent: accent,
                onTap: () => onJump(g.grade, null),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailDot extends StatelessWidget {
  const _RailDot({
    required this.grade,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  final JourneyGrade grade;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = grade.complete ? AppColors.successJade : accent;
    return Semantics(
      button: true,
      label: '${grade.grade}${AppStrings.mapGradeSuffix}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 34,
          height: 34,
          child: RingBadge(
            frac: grade.frac,
            color: color,
            size: 34,
            strokeWidth: 3,
            child: Container(
              width: active ? 26 : 22,
              height: active ? 26 : 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? color : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${grade.grade}',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: active ? 13 : 11,
                  color: active ? AppColors.white : AppColors.inkSoft,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
//  Саяхат картасы (overview) парағы
// ----------------------------------------------------------------------------

/// Бүкіл саяхаттың шолуы — төменнен ашылатын парақ: жоғарыда жалпы статистика,
/// сосын әр сынып карточкасы (модуль прогрестерімен), кез келгенін түртіп —
/// сол жерге секіруге болады.
class JourneyOverviewSheet extends StatelessWidget {
  const JourneyOverviewSheet({
    super.key,
    required this.journey,
    required this.userGrade,
    required this.subjectTitle,
    required this.accent,
    required this.onJump,
  });

  final List<JourneyGrade> journey;
  final int userGrade;
  final String subjectTitle;
  final Color accent;
  final MapJumpCallback onJump;

  int get _done => journey.fold(0, (s, g) => s + g.done);
  int get _total => journey.fold(0, (s, g) => s + g.total);
  int get _stars => journey.fold(0, (s, g) => s + g.stars);
  int get _mastered => journey.fold(0, (s, g) => s + g.mastered);
  int get _questions => journey.fold(0, (s, g) => s + g.questionCount);
  int get _xp => journey.fold(0, (s, g) => s + g.xpReward);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .86,
      minChildSize: .5,
      maxChildSize: .96,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const _SheetGrip(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp6,
                  0,
                  AppSpacing.sp6,
                  AppSpacing.sp2,
                ),
                child: Row(
                  children: [
                    Icon(Icons.map_rounded, color: accent, size: 24),
                    const SizedBox(width: AppSpacing.sp2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.mapOverviewTitle,
                            style: AppTypography.h3,
                          ),
                          Text(
                            '$subjectTitle · ${AppStrings.mapOverviewHint}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.sp5,
                    AppSpacing.sp2,
                    AppSpacing.sp5,
                    AppSpacing.sp6 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    _StatsCard(
                          done: _done,
                          total: _total,
                          stars: _stars,
                          mastered: _mastered,
                          questions: _questions,
                          xp: _xp,
                          accent: accent,
                        )
                        .animate()
                        .fadeIn(duration: 280.ms)
                        .slideY(begin: .12, curve: Curves.easeOutCubic),
                    const SizedBox(height: AppSpacing.sp4),
                    // Сынып карточкалары сатылап (stagger) пайда болады —
                    // парақ ашылғанда премиум «құрастырылу» сезімі.
                    ...journey.reversed.toList().asMap().entries.map((e) {
                      final i = e.key;
                      final g = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sp4),
                        child:
                            _GradeCard(
                                  grade: g,
                                  isOwn: g.grade == userGrade,
                                  accent: accent,
                                  onJump: onJump,
                                )
                                .animate()
                                .fadeIn(
                                  delay: (60 * (i + 1)).ms,
                                  duration: 300.ms,
                                )
                                .slideY(begin: .14, curve: Curves.easeOutCubic),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Парақтың жоғарғы «тұтқасы» (drag indicator).
class _SheetGrip extends StatelessWidget {
  const _SheetGrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sp3),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: AppRadius.rFull,
      ),
    );
  }
}

/// Жалпы жол статистикасы: үлкен прогресс жолағы + 4 шағын көрсеткіш.
class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.done,
    required this.total,
    required this.stars,
    required this.mastered,
    required this.questions,
    required this.xp,
    required this.accent,
  });

  final int done;
  final int total;
  final int stars;
  final int mastered;
  final int questions;
  final int xp;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : done / total;
    final pct = (frac * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_shade(accent, .04), _shade(accent, -.18)],
        ),
        borderRadius: AppRadius.rXl,
        boxShadow: AppColors.glow(accent, opacity: .35, blur: 22, y: 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppStrings.mapJourneyStats,
                style: AppTypography.body.copyWith(
                  color: AppColors.white.withValues(alpha: .9),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: AppTypography.h3.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp2),
          ClipRRect(
            borderRadius: AppRadius.rFull,
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 10,
              backgroundColor: AppColors.white.withValues(alpha: .25),
              valueColor: const AlwaysStoppedAnimation(AppColors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Row(
            children: [
              _Stat(
                icon: Icons.check_circle_rounded,
                value: '$done/$total',
                label: AppStrings.mapStatDone,
              ),
              _Stat(
                icon: Icons.star_rounded,
                value: '$stars',
                label: AppStrings.mapStatStars,
              ),
              _Stat(
                icon: Icons.workspace_premium_rounded,
                value: '$mastered',
                label: AppStrings.mapStatMastered,
              ),
              _Stat(
                icon: Icons.bolt_rounded,
                value: '$xp',
                label: AppStrings.mapStatXp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.white.withValues(alpha: .92), size: 20),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withValues(alpha: .8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Бір сынып карточкасы: тақырып + жалпы сақина + модуль қатарлары.
class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.grade,
    required this.isOwn,
    required this.accent,
    required this.onJump,
  });

  final JourneyGrade grade;
  final bool isOwn;
  final Color accent;
  final MapJumpCallback onJump;

  @override
  Widget build(BuildContext context) {
    final ringColor = grade.complete ? AppColors.successJade : accent;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rXl,
        border: Border.all(
          color: isOwn ? accent.withValues(alpha: .5) : AppColors.border,
          width: isOwn ? 2 : 1.5,
        ),
        boxShadow: AppColors.sh1,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sp4),
            child: Row(
              children: [
                RingBadge(
                  frac: grade.frac,
                  color: ringColor,
                  size: 48,
                  child: grade.complete
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.successJade,
                          size: 22,
                        )
                      : Text(
                          '${grade.grade}',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w900,
                            color: ringColor,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.sp3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${grade.grade}${AppStrings.mapGradeSuffix}',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.ink,
                            ),
                          ),
                          if (isOwn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: .14),
                                borderRadius: AppRadius.rFull,
                              ),
                              child: Text(
                                AppStrings.mapStartHere,
                                style: AppTypography.caption.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${grade.modules.length} ${AppStrings.mapModulesWord} · '
                        '${grade.done}/${grade.total} ${AppStrings.mapDone}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                // Сыныптан жиналған жұлдыздар — жетістіктің жылдам көрсеткіші.
                if (grade.stars > 0) ...[
                  const SizedBox(width: AppSpacing.sp2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.goldBright,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${grade.stars}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          for (final m in grade.modules)
            _ModuleRow(
              module: m,
              accent: accent,
              onTap: () => onJump(grade.grade, m.module),
            ),
        ],
      ),
    );
  }
}

/// Модуль қатары: нөмір/прогресс + тақырып + мини жолақ + күй белгісі.
class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.module,
    required this.accent,
    required this.onTap,
  });

  final JourneyModule module;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = module.complete
        ? AppColors.successJade
        : (module.locked ? AppColors.slate : accent);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4,
          vertical: AppSpacing.sp3,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: module.complete
                  ? Icon(Icons.verified_rounded, color: color, size: 22)
                  : (module.locked
                        ? Icon(
                            Icons.lock_rounded,
                            color: AppColors.muted,
                            size: 18,
                          )
                        : RingBadge(
                            frac: module.frac,
                            color: color,
                            size: 30,
                            strokeWidth: 3,
                            child: Text(
                              '${module.module}',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                          )),
            ),
            const SizedBox(width: AppSpacing.sp3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: module.locked ? AppColors.muted : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: AppRadius.rFull,
                    child: LinearProgressIndicator(
                      value: module.frac,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            if (module.locked)
              Text(
                AppStrings.mapModuleLocked,
                style: AppTypography.caption.copyWith(color: AppColors.muted),
              )
            else if (module.hasCurrent)
              Icon(Icons.play_circle_fill_rounded, color: accent, size: 22)
            else
              Text(
                '${module.done}/${module.total}',
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
//  Белгілер (legend) парағы
// ----------------------------------------------------------------------------

/// Карта белгілерінің анықтамасы: түйін түрлері, күйлері және жол түрлері.
class MapLegendSheet extends StatelessWidget {
  const MapLegendSheet({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sp6,
        0,
        AppSpacing.sp6,
        AppSpacing.sp6 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: _SheetGrip()),
            Row(
              children: [
                Icon(Icons.help_outline_rounded, color: accent, size: 24),
                const SizedBox(width: AppSpacing.sp2),
                Text(AppStrings.mapLegendTitle, style: AppTypography.h3),
              ],
            ),
            const SizedBox(height: AppSpacing.sp4),
            _LegendSection(
              title: AppStrings.legendTypesTitle,
              children: [
                _LegendRow(
                  coin: LegendCoin(
                    base: accent,
                    icon: NodeWidget.typeIcon(NodeType.lesson),
                    size: 40,
                  ),
                  text: AppStrings.legendLesson,
                ),
                _LegendRow(
                  coin: LegendCoin(
                    base: accent,
                    icon: NodeWidget.typeIcon(NodeType.quiz),
                    size: 40,
                  ),
                  text: AppStrings.legendQuiz,
                ),
                _LegendRow(
                  coin: LegendCoin(
                    base: AppColors.steppeGold,
                    icon: NodeWidget.typeIcon(NodeType.boss),
                    size: 40,
                  ),
                  text: AppStrings.legendBoss,
                ),
                _LegendRow(
                  coin: LegendCoin(
                    base: AppColors.steppeGold,
                    icon: NodeWidget.typeIcon(NodeType.treasure),
                    size: 40,
                  ),
                  text: AppStrings.legendTreasure,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sp4),
            _LegendSection(
              title: AppStrings.legendStatesTitle,
              children: [
                _LegendRow(
                  coin: LegendCoin(
                    base: AppColors.slate,
                    icon: Icons.menu_book_rounded,
                    size: 40,
                    locked: true,
                  ),
                  text: AppStrings.legendLocked,
                ),
                _LegendRow(
                  coin: LegendCoin(
                    base: AppColors.steppeGold,
                    icon: Icons.bolt_rounded,
                    size: 40,
                    pulse: true,
                  ),
                  text: AppStrings.legendCurrent,
                ),
                _LegendRow(
                  coin: LegendCoin(
                    base: AppColors.successJade,
                    icon: Icons.check_rounded,
                    size: 40,
                    stars: 2,
                  ),
                  text: AppStrings.legendDone,
                ),
                _LegendRow(
                  coin: LegendCoin(
                    base: AppColors.successJade,
                    icon: Icons.check_rounded,
                    size: 40,
                    crown: true,
                    stars: 3,
                  ),
                  text: AppStrings.legendMastered,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendSection extends StatelessWidget {
  const _LegendSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: AppSpacing.sp2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp4,
            vertical: AppSpacing.sp2,
          ),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: AppRadius.rLg,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.coin, required this.text});

  final Widget coin;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp2),
      child: Row(
        children: [
          SizedBox(width: 56, child: Center(child: coin)),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
//  Header streak (от) чипі
// ----------------------------------------------------------------------------

/// Header-дегі streak (от) чипі — қатарынан оқыған күндер саны.
/// Жылы алтын градиент + жұмсақ жарқыл — баланы күн сайын оралуға ынталандырады.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$streak — ${AppStrings.mapStreakTooltip}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppColors.heroGold,
          borderRadius: AppRadius.rFull,
          boxShadow: AppColors.glow(
            AppColors.warningSunset,
            opacity: .4,
            blur: 12,
            y: 4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.streak, size: 16, color: AppColors.white),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: AppTypography.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
//  Түйін фактілері (preview парағында)
// ----------------------------------------------------------------------------

/// Түйін фактілері: сұрақ саны + болжамды уақыт, одан төмен — банктегі
/// сұрақтардың ҚИЫНДЫҚ ТАРАЛЫМЫ (стек жолақ + белгілер). Бала қандай күшке
/// дайындалатынын алдын ала көреді.
class NodeFacts extends StatelessWidget {
  const NodeFacts({super.key, required this.node, required this.questionCount});

  final TaskNode node;
  final int questionCount;

  static Color difficultyColor(Difficulty d) => switch (d) {
    Difficulty.light => AppColors.successJade,
    Difficulty.easy => AppColors.eagleBlue,
    Difficulty.medium => AppColors.steppeGold,
    Difficulty.hard => AppColors.warningSunset,
    Difficulty.complex => AppColors.dangerCoral,
    Difficulty.brainTeaser => AppColors.cosmicPurple,
  };

  @override
  Widget build(BuildContext context) {
    final minutes = math.max(1, (questionCount * 0.75).ceil());
    final counts = <Difficulty, int>{};
    for (final q in node.questions) {
      counts[q.difficulty] = (counts[q.difficulty] ?? 0) + 1;
    }
    final present = Difficulty.values
        .where((d) => (counts[d] ?? 0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FactChip(
              icon: Icons.quiz_rounded,
              text: '$questionCount ${AppStrings.questionWord}',
            ),
            const SizedBox(width: AppSpacing.sp2),
            _FactChip(
              icon: Icons.schedule_rounded,
              text: '~$minutes ${AppStrings.mapEstMinutes}',
            ),
          ],
        ),
        if (present.length > 1) ...[
          const SizedBox(height: AppSpacing.sp4),
          Text(
            AppStrings.mapDifficultyMix.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w800,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.rFull,
            child: SizedBox(
              height: 9,
              child: Row(
                children: [
                  for (final d in present)
                    Expanded(
                      flex: counts[d]!,
                      child: Container(color: difficultyColor(d)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp2),
          Wrap(
            spacing: AppSpacing.sp3,
            runSpacing: 4,
            children: [
              for (final d in present)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: difficultyColor(d),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${d.label} · ${counts[d]}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Ықшам факт чипі (икон + мәтін) — сұрақ/уақыт көрсеткіші.
class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: AppRadius.rFull,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.inkSoft),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
//  Сабақ алдыңғы көрінісі (preview парағында)
// ----------------------------------------------------------------------------

/// «Бұл сабақта үйренесің» картасы (сабақ түйіндері үшін): тірек ой + негізгі
/// ереже/формула + үлгі есеп саны. Бала бастамас бұрын не үйренетінін көреді.
class LessonPreview extends StatelessWidget {
  const LessonPreview({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.tintBlue,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppColors.eagleBlue.withValues(alpha: .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_rounded,
                size: 18,
                color: AppColors.eagleBlue,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.mapWillLearn,
                style: AppTypography.caption.copyWith(
                  color: AppColors.eagleBlue,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp2),
          Text(
            lesson.takeaway,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.ink,
              height: 1.35,
            ),
          ),
          if (lesson.formula != null) ...[
            const SizedBox(height: AppSpacing.sp3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp3,
                vertical: AppSpacing.sp2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.rMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.mapFormula.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lesson.formula!,
                    style: AppTypography.body.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (lesson.examples.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sp3),
            Row(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: AppColors.successJade,
                ),
                const SizedBox(width: 6),
                Text(
                  '${lesson.examples.length} ${AppStrings.mapExamplesCount}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
