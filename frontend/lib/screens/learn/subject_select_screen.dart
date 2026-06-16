import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/subject_worlds.dart';
import '../../core/utils/app_haptics.dart';
import '../../providers/task_provider.dart';
import '../../widgets/game/map_backdrop.dart';
import '../../widgets/ui/hud_bar.dart';

/// Пән таңдау: әр пән — өз «әлемінің» тірі превью-карточкасы
/// (дала / геометрия / аспан / ғарыш / микросхема) + прогресс.
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
              Text(AppStrings.learnTitle, style: AppTypography.h1)
                  .animate()
                  .fadeIn(),
              const SizedBox(height: AppSpacing.sp5),
              for (var i = 0; i < CurriculumData.subjects.length; i++) ...[
                _WorldCard(subject: CurriculumData.subjects[i])
                    .animate()
                    .fadeIn(delay: (70 * i).ms, duration: 280.ms)
                    .slideY(begin: .08, curve: Curves.easeOutCubic),
                const SizedBox(height: AppSpacing.sp4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Пән әлемінің карточкасы: фонда әлем превьюі, үстінде икон,
/// атау және прогресс. Басқанда серіппелі «squish».
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
    final progress = ref.watch(subjectProgressProvider(subject.id));
    final worldTheme = SubjectWorldTheme.of(subject.id);

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
          height: 132,
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
                MapBackdrop(theme: worldTheme, accent: subject.accent, t: 0),
                // Мәтін оқылуы үшін төменгі қою скрим.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.nightInk.withValues(alpha: .04),
                        AppColors.nightInk.withValues(alpha: .62),
                      ],
                      stops: const [.35, 1],
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
                                color: AppColors.white,
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
                                  '${(progress * 100).round()}%',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
