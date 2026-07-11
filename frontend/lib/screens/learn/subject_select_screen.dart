import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/subject_worlds.dart';
import '../../core/utils/app_haptics.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/game/map_backdrop.dart';
import '../../widgets/ui/hud_bar.dart';
import '../../widgets/ui/panels.dart';

/// Пән таңдау: жоғарыда «Менің саяхатым» жиынтық панелі, астында әр пән —
/// өз «әлемінің» тірі превью-карточкасы (дала / геометрия / аспан / ғарыш /
/// микросхема) + прогресс саны мен күй белгісі.
class SubjectSelectScreen extends ConsumerWidget {
  const SubjectSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const HudBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp5,
              AppSpacing.sp5,
              AppSpacing.sp5,
              AppSpacing.sp12,
            ),
            children: [
              // ---- Саяхат жиынтығы (барлық пән бойынша) ----
              const _JourneyHeader()
                  .animate()
                  .fadeIn(duration: 340.ms)
                  .slideY(begin: .08, curve: Curves.easeOutCubic),
              const SizedBox(height: AppSpacing.sp3),

              // ---- ҚР бағдарламасы / ҰБТ сәйкестік белгісі ----
              const _CurriculumBadge()
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 320.ms),
              const SizedBox(height: AppSpacing.sp3),

              // ---- Байқау сынағы (емтихан режимі) ----
              const _ExamBanner()
                  .animate()
                  .fadeIn(delay: 160.ms, duration: 320.ms)
                  .slideY(begin: .08, curve: Curves.easeOutCubic),

              // ---- ҰБТ дайындығы (тек 10–11 сынып көреді) ----
              const _UbtBanner()
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 320.ms)
                  .slideY(begin: .08, curve: Curves.easeOutCubic),
              const SizedBox(height: AppSpacing.sp5),

              // ---- Пәндер тізімі (trailing — формулалар анықтамалығы) ----
              SectionHeader(
                title: AppStrings.learnTitle,
                trailing: Pressable(
                  onTap: () {
                    AppHaptics.tap();
                    context.push('/learn/reference');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp3, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.tintBlue,
                      borderRadius: AppRadius.rFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.functions_rounded,
                            size: 15, color: AppColors.eagleBlue),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.refTitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.eagleBlue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < CurriculumData.subjects.length; i++) ...[
                _WorldCard(subject: CurriculumData.subjects[i])
                    .animate()
                    .fadeIn(delay: (70 * i + 80).ms, duration: 300.ms)
                    .slideY(begin: .1, curve: Curves.easeOutCubic),
                const SizedBox(height: AppSpacing.sp4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// «Байқау сынағы» баннері — емтихан режиміне кіру: пәнді таңдап, ҰБТ
/// форматындағы таймерлі тексеріс тапсыру (алтын hero, айрықша көзге түседі).
class _ExamBanner extends StatelessWidget {
  const _ExamBanner();

  void _pickSubject(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp5, AppSpacing.sp3, AppSpacing.sp5, AppSpacing.sp5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inkSoft.withValues(alpha: .3),
                    borderRadius: AppRadius.rFull,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sp4),
              Text(AppStrings.examPickSubject, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sp3),
              for (final s in CurriculumData.subjects)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sp2),
                  child: Pressable(
                    onTap: () {
                      AppHaptics.tap();
                      Navigator.of(ctx).pop();
                      context.push('/learn/exam/${s.id}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp4,
                          vertical: AppSpacing.sp3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.rLg,
                        border: Border.all(
                          color: s.accent.withValues(alpha: .35),
                          width: 1.3,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(s.icon, size: 22, color: s.accent),
                          const SizedBox(width: AppSpacing.sp3),
                          Expanded(
                            child: Text(
                              s.title,
                              style: AppTypography.body
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.inkSoft),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        AppHaptics.tap();
        _pickSubject(context);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp4),
        decoration: BoxDecoration(
          gradient: AppColors.heroGold,
          borderRadius: AppRadius.rXl,
          boxShadow:
              AppColors.glow(AppColors.steppeGold, opacity: .28, blur: 16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .18),
                borderRadius: AppRadius.rLg,
              ),
              child: const Icon(Icons.timer_rounded,
                  color: AppColors.white, size: 26),
            ),
            const SizedBox(width: AppSpacing.sp4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.examTitle,
                    style: AppTypography.h3.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.examBannerSub,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: .92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}

/// «ҰБТ дайындығы» баннері — 10–11 сынып оқушысына ғана көрінеді: міндетті
/// 3 пән + 2 профиль пәнінен тұратын толық байқау бөліміне кіру нүктесі
/// (қыран hero, байқау сынағынан түсімен ерекшеленеді).
class _UbtBanner extends ConsumerWidget {
  const _UbtBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grade = ref.watch(authProvider.select((s) => s.user?.grade ?? 0));
    if (grade < 10) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sp3),
      child: Pressable(
        onTap: () {
          AppHaptics.tap();
          context.push('/learn/ubt');
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sp4),
          decoration: BoxDecoration(
            gradient: AppColors.heroEagle,
            borderRadius: AppRadius.rXl,
            boxShadow:
                AppColors.glow(AppColors.eagleBlue, opacity: .28, blur: 16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .18),
                  borderRadius: AppRadius.rLg,
                ),
                child: const Icon(Icons.school_rounded,
                    color: AppColors.white, size: 26),
              ),
              const SizedBox(width: AppSpacing.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.ubtTitle,
                      style: AppTypography.h3.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.ubtBannerSub,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white.withValues(alpha: .92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// ҚР мектеп бағдарламасы мен ҰБТ форматына сәйкестік белгісі — қазылар мен
/// ата-аналарға сенім сигналы. Нәзік жасыл pill, тексеру белгішесімен.
class _CurriculumBadge extends StatelessWidget {
  const _CurriculumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
      decoration: BoxDecoration(
        color: AppColors.successJade.withValues(alpha: .12),
        borderRadius: AppRadius.rFull,
        border: Border.all(
            color: AppColors.successJade.withValues(alpha: .3), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded,
              size: 18, color: AppColors.successJade),
          const SizedBox(width: AppSpacing.sp2),
          Flexible(
            child: Text(
              AppStrings.curriculumBadge,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.successJade,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Менің саяхатым» — барлық пән бойынша жиынтық: жалпы үлгерім сақинасы +
/// аяқталған сабақ, жиналған жұлдыз, белсенді streak.
class _JourneyHeader extends ConsumerWidget {
  const _JourneyHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(gameProvider.select((g) => g.currentStreak));

    var done = 0;
    var total = 0;
    var stars = 0;
    for (final s in CurriculumData.subjects) {
      final st = ref.watch(subjectStatsProvider(s.id));
      done += st.done;
      total += st.total;
      stars += st.stars;
    }
    final frac = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final pct = (frac * 100).round();

    return PanelCard(
      gradient: AppColors.heroEagle,
      padding: const EdgeInsets.all(AppSpacing.sp5),
      shadow: AppColors.glow(AppColors.eagleBlue,
          opacity: .36, blur: 30, y: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.learnJourneyTitle.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white.withValues(alpha: .85),
                        fontWeight: FontWeight.w800,
                        letterSpacing: .6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.learnPickPrompt,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sp4),
              _PercentRing(value: frac, percent: pct),
            ],
          ),
          const SizedBox(height: AppSpacing.sp4),
          Row(
            children: [
              _JStat(
                icon: Icons.menu_book_rounded,
                value: '$done/$total',
                label: AppStrings.learnLessonsWord,
              ),
              const SizedBox(width: AppSpacing.sp3),
              _JStat(
                icon: Icons.star_rounded,
                value: '$stars',
                label: AppStrings.mapStatStars,
              ),
              const SizedBox(width: AppSpacing.sp3),
              _JStat(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                label: AppStrings.daysShort,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Жалпы үлгерім сақинасы — мөлдір трек + ақ толтыру, ортасында пайыз.
class _PercentRing extends StatelessWidget {
  const _PercentRing({required this.value, required this.percent});

  final double value;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 66,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 66,
            height: 66,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.white.withValues(alpha: .26),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.goldBright),
            ),
          ),
          Text(
            '$percent%',
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Саяхат панеліндегі мөлдір «frosted» статистика чипі (тең енді).
class _JStat extends StatelessWidget {
  const _JStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp2,
          vertical: AppSpacing.sp3,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .18),
          borderRadius: AppRadius.rMd,
          border: Border.all(color: AppColors.white.withValues(alpha: .22)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: AppColors.white),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: AppTypography.body.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.white.withValues(alpha: .8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Пән әлемінің карточкасы: фонда әлем превьюі, прогресс сақинасындағы икон,
/// атау, прогресс жолағы + сабақ саны және оң жоғарыда күй белгісі.
/// Басқанда серіппелі «squish».
class _WorldCard extends ConsumerStatefulWidget {
  const _WorldCard({required this.subject});

  final SubjectInfo subject;

  @override
  ConsumerState<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends ConsumerState<_WorldCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    final stats = ref.watch(subjectStatsProvider(subject.id));
    final worldTheme = SubjectWorldTheme.of(subject.id);
    final progress = stats.total == 0 ? 0.0 : stats.done / stats.total;
    final complete = stats.total > 0 && stats.done >= stats.total;
    final started = stats.done > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        AppHaptics.tap();
        context.push('/learn/map/${subject.id}');
      },
      child: AnimatedScale(
        scale: _pressed ? .96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            boxShadow: AppColors.sh2,
          ),
          child: ClipRRect(
            borderRadius: AppRadius.rLg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Әлем превьюі (статикалық кадр).
                MapBackdrop(
                    subjectId: subject.id,
                    theme: worldTheme,
                    accent: subject.accent,
                    t: 0),
                // Мәтін оқылуы үшін төменгі қою скрим.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.nightInk.withValues(alpha: .04),
                        AppColors.nightInk.withValues(alpha: .66),
                      ],
                      stops: const [.3, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sp4),
                  child: Row(
                    children: [
                      // Прогресс сақинасы ішінде пән иконы.
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 4.5,
                                backgroundColor:
                                    AppColors.white.withValues(alpha: .3),
                                valueColor: const AlwaysStoppedAnimation(
                                    AppColors.white),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: AppColors.sh1,
                              ),
                              child: Icon(subject.icon,
                                  size: 26, color: subject.accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sp4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              subject.title,
                              style: AppTypography.h3.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sp2),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: AppRadius.rFull,
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 7,
                                      backgroundColor: AppColors.white
                                          .withValues(alpha: .28),
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                              AppColors.goldBright),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sp2),
                                Text(
                                  '${stats.done}/${stats.total}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sp2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.white,
                        size: 30,
                      ),
                    ],
                  ),
                ),
                // Оң жоғарыда күй белгісі.
                Positioned(
                  top: AppSpacing.sp3,
                  right: AppSpacing.sp3,
                  child: _StatusBadge(complete: complete, started: started),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Пән карточкасының күй белгісі: Аяқталды / Жалғастыру / Бастау.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.complete, required this.started});

  final bool complete;
  final bool started;

  @override
  Widget build(BuildContext context) {
    final (label, icon, gradient, fill) = complete
        ? (
            AppStrings.learnAllDone,
            Icons.verified_rounded,
            AppColors.heroJade,
            null,
          )
        : started
            ? (
                AppStrings.continueBtn,
                Icons.play_arrow_rounded,
                null,
                AppColors.white.withValues(alpha: .26),
              )
            : (
                AppStrings.startBtn,
                Icons.auto_awesome_rounded,
                AppColors.goldSoar,
                null,
              );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient,
        color: fill,
        borderRadius: AppRadius.rFull,
        border: fill != null
            ? Border.all(color: AppColors.white.withValues(alpha: .4))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.white),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
