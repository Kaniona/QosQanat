import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/curriculum.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mastery_provider.dart';
import '../avatar/avatar_base.dart';
import 'panels.dart';

/// «Жеке коуч» картасы — қосымша баланы танып, әлсіз тұсын айтады әрі
/// қайталауды ұсынады. Бейімделетін оқытудың басты көрінісі (home экраны).
class CoachCard extends ConsumerWidget {
  const CoachCard({super.key});

  /// Тақырып id-інен оқылатын атау (мыс. «Жай бөлшектер»).
  static String topicTitle(String skillId) =>
      Curriculum.nodeById('${skillId}_n0')?.moduleTitle ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(masteryProvider);
    final assignments = ref.watch(assignmentsProvider);
    final assistant = ref.watch(
            currentUserProvider.select((u) => u?.assistantType)) ??
        AssistantType.bektur;
    final weakest = snap.weakest;
    final due = snap.dueCount;

    // 0) Ұстаз тапсырмасы бар — ол ең басты (мұғалім нұсқауы алдымен).
    if (assignments.isNotEmpty) {
      final a = assignments.first;
      final topic = topicTitle(a.skillId);
      return _CoachHero(
        assistant: assistant,
        gradient: _heroFor(a.subject),
        icon: Icons.assignment_rounded,
        lead: AppStrings.assignmentBadge,
        title: topic.isEmpty ? a.skillId : topic,
        sub: AppStrings.coachStartLearning,
        cta: AppStrings.nodeStart,
        onTap: () => context.push('/learn/map/${a.subject}'),
      );
    }

    // 1) Қайталайтын сұрақ бар — басты әрекет: қайталау.
    if (due > 0) {
      final subjectId = weakest?.subject ?? 'math';
      final topic = weakest != null ? topicTitle(weakest.skillId) : '';
      return _CoachHero(
        assistant: assistant,
        gradient: _heroFor(subjectId),
        icon: Icons.refresh_rounded,
        lead: topic.isEmpty ? AppStrings.coachReviewCta : AppStrings.coachWeakLead,
        title: topic.isEmpty ? '$due ${AppStrings.questionWord}' : topic,
        sub: '$due ${AppStrings.questionWord} · ${AppStrings.coachReviewReady}',
        cta: AppStrings.coachReviewCta,
        onTap: () => context.push('/learn/review'),
      );
    }

    // 2) Қайталау жоқ, бірақ әлсіз тақырып бар — жаттығуды ұсынамыз.
    if (weakest != null) {
      final topic = topicTitle(weakest.skillId);
      return _CoachHero(
        assistant: assistant,
        gradient: _heroFor(weakest.subject),
        icon: Icons.trending_up_rounded,
        lead: AppStrings.coachWeakLead,
        title: topic.isEmpty ? weakest.skillId : topic,
        sub: weakest.level.label,
        cta: AppStrings.nodeStart,
        onTap: () => context.push('/learn/map/${weakest.subject}'),
      );
    }

    // 3) Дерек бар, бәрі тәртіпте — мадақтау.
    if (snap.skills.values.any((s) => s.attempts > 0)) {
      return _CoachCalm(
        assistant: assistant,
        title: AppStrings.coachAllGood,
        sub: AppStrings.coachAllGoodSub,
      );
    }

    // 4) Әлі жаттықпаған — алдымен орналастыру диагностикасын ұсынамыз.
    final uid = ref.watch(authProvider.select((s) => s.user?.id));
    final placed = uid != null && ref.watch(storageProvider).placementDone(uid);
    if (!placed) {
      return _CoachHero(
        assistant: assistant,
        gradient: AppColors.heroEagle,
        icon: Icons.explore_rounded,
        lead: '',
        title: AppStrings.placementTitle,
        sub: AppStrings.placementStart,
        cta: AppStrings.placementStart,
        onTap: () => context.push('/placement'),
      );
    }
    return _CoachCalm(
      assistant: assistant,
      title: AppStrings.coachTitle,
      sub: AppStrings.coachStartLearning,
    );
  }

  static LinearGradient _heroFor(String subject) => switch (subject) {
        'kazakh' => AppColors.heroJade,
        'english' => AppColors.heroGold,
        'physics' => AppColors.heroRose,
        _ => AppColors.heroEagle,
      };
}

/// Әрекетке шақыратын градиентті коуч картасы.
class _CoachHero extends StatelessWidget {
  const _CoachHero({
    required this.assistant,
    required this.gradient,
    required this.icon,
    required this.lead,
    required this.title,
    required this.sub,
    required this.cta,
    required this.onTap,
  });

  final AssistantType assistant;
  final LinearGradient gradient;
  final IconData icon;
  final String lead;
  final String title;
  final String sub;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      gradient: gradient,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sp4),
      child: Row(
        children: [
          _CoachAvatar(assistant: assistant, badge: icon, onHero: true),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.isEmpty
                      ? AppStrings.coachTitle
                      : '${AppStrings.coachTitle} · $lead',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: .85),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: AppTypography.caption
                      .copyWith(color: Colors.white.withValues(alpha: .9)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp2),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp3, vertical: AppSpacing.sp2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .24),
              borderRadius: AppRadius.rFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cta,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Әрекетсіз (мадақтау / шақыру) коуч картасы.
class _CoachCalm extends StatelessWidget {
  const _CoachCalm({
    required this.assistant,
    required this.title,
    required this.sub,
  });

  final AssistantType assistant;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.all(AppSpacing.sp4),
      child: Row(
        children: [
          _CoachAvatar(
            assistant: assistant,
            badge: Icons.psychology_rounded,
            onHero: false,
            badgeColor: AppColors.successJade,
          ),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(sub, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Коуч серігі — тірі маскот (Бектұр/Назым) дөңгелек рамкада, оң төменде
/// әрекет түрін білдіретін кішкене белгі (тапсырма / қайталау / өсу).
/// «Жеке коуч» картасына тұлға береді: генерик икон емес, нақты серік.
class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({
    required this.assistant,
    required this.badge,
    required this.onHero,
    this.badgeColor,
  });

  final AssistantType assistant;
  final IconData badge;

  /// Түрлі-түсті hero фонында ба (ақ шеңбер) әлде ашық бетте ме (тінт шеңбер).
  final bool onHero;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final accent = assistant == AssistantType.nazym
        ? AppColors.nazymRose
        : AppColors.eagleBlue;
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: onHero
                  ? Colors.white.withValues(alpha: .22)
                  : accent.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: AvatarBase(assistant: assistant, size: 46),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: AppColors.sh1,
              ),
              child: Icon(badge, size: 13, color: badgeColor ?? accent),
            ),
          ),
        ],
      ),
    );
  }
}
