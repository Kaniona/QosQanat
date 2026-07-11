import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/mastery.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/mastery_provider.dart';
import '../../widgets/ui/coach_card.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/mastery_heatmap.dart';
import '../../widgets/ui/panels.dart';

/// «Менің прогресім» — оқушының ӨЗІНЕ арналған аналитика (PIN жоқ): жалпы дәлдік,
/// шеберлік деңгейлерінің таралуы, әлсіз тақырыптар, пән бойынша жылу-карталар.
/// Бұл «QosQanat сені таниды» идеясын оқушыға тікелей көрсетеді.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(masteryProvider);
    final user = ref.watch(currentUserProvider);
    final game = ref.watch(gameProvider);
    final grade = user?.grade ?? 5;

    final practiced = snap.skills.values.where((s) => s.attempts > 0).toList();
    final hasData = practiced.isNotEmpty;

    final practicedSubjects = CurriculumData.subjects
        .where((s) =>
            snap.skillsForSubject(s.id).any((st) => st.attempts > 0))
        .toList();
    final weak = snap.weakSkills.take(4).toList();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.progressTitle)),
      body: !hasData
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sp6),
                child: EmptyState(
                  icon: Icons.insights_rounded,
                  title: AppStrings.progressEmpty,
                  accent: AppColors.eagleBlue,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sp5, AppSpacing.sp5,
                  AppSpacing.sp5, AppSpacing.sp12),
              children: [
                _SummaryCard(snap: snap, streak: game.currentStreak),
                const SizedBox(height: AppSpacing.sp5),

                // Шеберлік деңгейлерінің таралуы.
                _LevelBars(snap: snap),
                const SizedBox(height: AppSpacing.sp5),

                // Әлсіз тақырыптар + қайталау.
                if (weak.isNotEmpty) ...[
                  SectionHeader(title: AppStrings.guardianWeakTopics),
                  PanelCard(
                    child: Column(
                      children: [
                        for (final s in weak)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sp1),
                            child: Row(
                              children: [
                                const Icon(Icons.flag_rounded,
                                    size: 18, color: AppColors.warningSunset),
                                const SizedBox(width: AppSpacing.sp2),
                                Expanded(
                                  child: Text(CoachCard.topicTitle(s.skillId),
                                      style: AppTypography.bodySmall),
                                ),
                                Text(s.level.label,
                                    style: AppTypography.caption.copyWith(
                                        color: masteryColor(s.level),
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sp2),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => context.push('/learn/review'),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text(AppStrings.coachReviewCta),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp5),
                ],

                // Пәндер бойынша жылу-карталар.
                SectionHeader(title: AppStrings.progressSubjectsTitle),
                for (final subject in practicedSubjects) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        top: AppSpacing.sp2, bottom: AppSpacing.sp2),
                    child: Text(subject.title,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                  PanelCard(
                    child: MasteryHeatmap(
                      subjectId: subject.id,
                      grade: grade,
                      snapshot: snap,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                ],
                const SizedBox(height: AppSpacing.sp2),
                const MasteryLegend(),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.snap, required this.streak});
  final MasterySnapshot snap;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final mastered =
        snap.skills.values.where((s) => s.level == MasteryLevel.mastered).length;
    return PanelCard(
      gradient: AppColors.heroEagle,
      child: Row(
        children: [
          _Metric(
              value: '${(snap.overallAccuracy * 100).round()}%',
              label: AppStrings.progressOverall),
          _Metric(value: '$mastered', label: AppStrings.progressMasteredTopics),
          _Metric(value: '${snap.dueCount}', label: AppStrings.coachReviewCta),
          _Metric(value: '$streak', label: AppStrings.statStreak),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTypography.h2.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w900)),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTypography.caption
                  .copyWith(color: Colors.white.withValues(alpha: .85)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Шеберлік деңгейлерінің таралуы — түрлі-түсті жолақ.
class _LevelBars extends StatelessWidget {
  const _LevelBars({required this.snap});
  final MasterySnapshot snap;

  @override
  Widget build(BuildContext context) {
    final practiced =
        snap.skills.values.where((s) => s.attempts > 0).toList();
    final total = practiced.length;
    int countOf(MasteryLevel l) =>
        practiced.where((s) => s.level == l).length;

    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const OyuDiamond(),
              const SizedBox(width: AppSpacing.sp3),
              Text('Тақырыптар: $total',
                  style: AppTypography.body
                      .copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: AppSpacing.sp3),
          ClipRRect(
            borderRadius: AppRadius.rFull,
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (final level in MasteryLevel.values)
                    if (countOf(level) > 0)
                      Expanded(
                        flex: countOf(level),
                        child: Container(color: masteryColor(level)),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp3),
          const MasteryLegend(),
        ],
      ),
    );
  }
}
