import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/curriculum.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/panels.dart';

/// «Жоба туралы / Impact» — қазылар мен қонақтарға арналған таныстыру панелі:
/// миссия → платформа сандармен (Curriculum-нан ТІРІ есептеледі) →
/// айырмашылықтар → CTA. Питч пен сенімділіктің бір экрандағы көрінісі.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  /// Барлық пән/сынып бойынша құрылым сандарын арифметикамен есептейді
  /// (пул құрылмайды — экран жылдам ашылады).
  static _PlatformStats _computeStats() {
    var topics = 0;
    var levels = 0;
    for (final s in CurriculumData.subjects) {
      for (var g = CurriculumData.minGrade; g <= CurriculumData.maxGrade; g++) {
        final mc = Curriculum.moduleCount(s.id, g);
        topics += mc;
        levels += mc * Curriculum.nodesPerModuleFor(s.id, g);
      }
    }
    return _PlatformStats(
      subjects: CurriculumData.subjects.length,
      grades: CurriculumData.maxGrade - CurriculumData.minGrade + 1,
      topics: topics,
      levels: levels,
      questions: levels * Curriculum.questionPoolSize,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = _computeStats();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.sp5, AppSpacing.sp5, AppSpacing.sp5, AppSpacing.sp10),
        children: [
          const _Hero(),
          const SizedBox(height: AppSpacing.sp6),
          SectionHeader(title: AppStrings.aboutNumbersTitle),
          _StatsGrid(stats: stats),
          const SizedBox(height: AppSpacing.sp6),
          SectionHeader(title: AppStrings.aboutWhyTitle),
          const _Why(),
          const SizedBox(height: AppSpacing.sp5),
          Center(
            child: Text(
              AppStrings.aboutTech,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(letterSpacing: .3),
            ),
          ),
          const SizedBox(height: AppSpacing.sp5),
          AppButton(
            label: AppStrings.aboutCta,
            variant: AppButtonVariant.gold,
            icon: Icons.explore_rounded,
            onPressed: () => context.go('/learn'),
          ),
        ]
            .animate(interval: 60.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: .06, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _PlatformStats {
  const _PlatformStats({
    required this.subjects,
    required this.grades,
    required this.topics,
    required this.levels,
    required this.questions,
  });

  final int subjects;
  final int grades;
  final int topics;
  final int levels;
  final int questions;
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      gradient: AppColors.heroEagle,
      padding: const EdgeInsets.all(AppSpacing.sp6),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(AppSpacing.sp3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: AppRadius.rLg,
            ),
            child: SvgPicture.asset('assets/brand/eagle_emblem.svg'),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            AppStrings.appName,
            style: AppTypography.h1.copyWith(
                color: Colors.white, fontWeight: FontWeight.w900),
          ),
          Text(
            AppStrings.appTagline,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.steppeGoldLight),
          ),
          const SizedBox(height: AppSpacing.sp3),
          Text(
            AppStrings.aboutMission,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: Colors.white.withValues(alpha: .92),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final _PlatformStats stats;

  static String _kPlus(int n) => '${(n / 1000).floor()} 000+';

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        value: '${stats.subjects}',
        label: AppStrings.aboutStatSubjects,
        icon: Icons.category_rounded,
        gradient: AppColors.heroEagle,
      ),
      _StatTile(
        value: '1–${stats.grades}',
        label: AppStrings.aboutStatGrades,
        icon: Icons.stairs_rounded,
        gradient: AppColors.heroRose,
      ),
      _StatTile(
        value: '${stats.topics}',
        label: AppStrings.aboutStatTopics,
        icon: Icons.account_tree_rounded,
        gradient: AppColors.heroJade,
      ),
      _StatTile(
        value: '${stats.levels}',
        label: AppStrings.aboutStatLevels,
        icon: Icons.flag_rounded,
        gradient: AppColors.heroGold,
      ),
      _StatTile(
        value: _kPlus(stats.questions),
        label: AppStrings.aboutStatQuestions,
        icon: Icons.quiz_rounded,
        gradient: AppColors.heroEagle,
      ),
      _StatTile(
        value: '100%',
        label: AppStrings.aboutStatOffline,
        icon: Icons.wifi_off_rounded,
        gradient: AppColors.heroJade,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = AppSpacing.sp3;
        final w = (c.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles) SizedBox(width: w, child: t),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.gradient,
  });

  final String value;
  final String label;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.all(AppSpacing.sp4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: AppRadius.rMd,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.h2.copyWith(fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTypography.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Why extends StatelessWidget {
  const _Why();

  static const _items = [
    (
      Icons.wifi_off_rounded,
      AppColors.successJade,
      AppStrings.aboutWhy1Title,
      AppStrings.aboutWhy1Body,
    ),
    (
      Icons.psychology_rounded,
      AppColors.cosmicPurple,
      AppStrings.aboutWhy2Title,
      AppStrings.aboutWhy2Body,
    ),
    (
      Icons.flag_circle_rounded,
      AppColors.steppeGold,
      AppStrings.aboutWhy3Title,
      AppStrings.aboutWhy3Body,
    ),
    (
      Icons.family_restroom_rounded,
      AppColors.eagleBlue,
      AppStrings.aboutWhy4Title,
      AppStrings.aboutWhy4Body,
    ),
    (
      Icons.workspace_premium_rounded,
      AppColors.dangerCoral,
      AppStrings.aboutWhy5Title,
      AppStrings.aboutWhy5Body,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0)
              const Divider(height: AppSpacing.sp4, indent: 56),
            _WhyRow(
              icon: _items[i].$1,
              color: _items[i].$2,
              title: _items[i].$3,
              body: _items[i].$4,
            ),
          ],
        ],
      ),
    );
  }
}

class _WhyRow extends StatelessWidget {
  const _WhyRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            borderRadius: AppRadius.rMd,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.sp3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    AppTypography.body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.inkSoft, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
