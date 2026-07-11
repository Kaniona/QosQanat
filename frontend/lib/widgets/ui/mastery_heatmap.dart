import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/curriculum.dart';
import '../../models/mastery.dart';
import '../../providers/mastery_provider.dart';

/// Тақырып шеберлігінің түсі (heatmap/панель ортақ қолданады).
Color masteryColor(MasteryLevel level) => switch (level) {
      MasteryLevel.fresh => AppColors.muted,
      MasteryLevel.learning => AppColors.warningSunset,
      MasteryLevel.proven => AppColors.eagleBlue,
      MasteryLevel.mastered => AppColors.successJade,
    };

/// Бір пәннің бір сыныптағы тақырыптарының шеберлік картасы (жылу-картасы):
/// әр модуль — түрлі-түсті жол (Жаңа/Үйренуде/Бекіді/Шебер) + EMA жолағы.
/// [snapshot] берілсе — сол оқушының (панельде басқа баланың) деректері;
/// әйтпесе ағымдағы қолданушынікі.
class MasteryHeatmap extends ConsumerWidget {
  const MasteryHeatmap({
    super.key,
    required this.subjectId,
    required this.grade,
    this.snapshot,
  });

  final String subjectId;
  final int grade;
  final MasterySnapshot? snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MasterySnapshot snap = snapshot ?? ref.watch(masteryProvider);
    final count = Curriculum.moduleCount(subjectId, grade);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var m = 1; m <= count; m++)
          _ModuleRow(
            title: Curriculum.nodeById('${skillIdFor(subjectId, grade, m)}_n0')
                    ?.moduleTitle ??
                '$m-модуль',
            stat: snap.statFor(skillIdFor(subjectId, grade, m)),
          ),
      ],
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.title, required this.stat});

  final String title;
  final SkillStat? stat;

  @override
  Widget build(BuildContext context) {
    final level = stat?.level ?? MasteryLevel.fresh;
    final ema = stat?.ema ?? 0;
    final color = masteryColor(level);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: AppRadius.rFull,
                  child: LinearProgressIndicator(
                    value: stat == null ? 0 : ema.clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp3),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp2, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: AppRadius.rFull,
            ),
            child: Text(
              level.label,
              style: AppTypography.caption
                  .copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Деңгей түстерінің шартты белгісі (легенда).
class MasteryLegend extends StatelessWidget {
  const MasteryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sp3,
      runSpacing: AppSpacing.sp2,
      children: [
        for (final level in MasteryLevel.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: masteryColor(level), shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(level.label, style: AppTypography.caption),
            ],
          ),
      ],
    );
  }
}
