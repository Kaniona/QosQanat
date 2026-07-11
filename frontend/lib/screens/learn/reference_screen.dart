import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../data/reference.dart';
import '../../widgets/ui/empty_state.dart';
import '../../widgets/ui/panels.dart';

/// Формулалар анықтамалығы (v2): барлық сабақтың формулалары бір жерде —
/// іздеу + пән сүзгісі; әр карта толық теория сабағына апарады. Офлайн,
/// контент сабақтардан авто-құрастырылады (іскерлік логика — data/reference).
class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen> {
  late final List<RefEntry> _all = buildReferenceEntries();
  String? _subject;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final entries =
        filterReferenceEntries(_all, subject: _subject, query: _query);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.refTitle)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Іздеу ----
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp5, AppSpacing.sp3, AppSpacing.sp5, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: AppStrings.refSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.rLg,
                    borderSide: BorderSide(
                      color: AppColors.eagleBlue.withValues(alpha: .3),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp3),

            // ---- Пән чиптері ----
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
                children: [
                  _SubjectChip(
                    label: AppStrings.refAll,
                    icon: Icons.apps_rounded,
                    accent: AppColors.eagleBlue,
                    selected: _subject == null,
                    onTap: () => setState(() => _subject = null),
                  ),
                  for (final s in CurriculumData.subjects)
                    _SubjectChip(
                      label: s.title,
                      icon: s.icon,
                      accent: s.accent,
                      selected: _subject == s.id,
                      onTap: () => setState(() => _subject = s.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sp2),

            // ---- Формула карталары ----
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: AppStrings.refEmpty,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.sp5,
                          AppSpacing.sp2, AppSpacing.sp5, AppSpacing.sp12),
                      itemCount: entries.length,
                      itemBuilder: (context, i) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sp3),
                        child: _RefCard(entry: entries[i])
                            .animate()
                            .fadeIn(duration: 200.ms),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Пән сүзгісінің чипі: таңдалғаны түс + қалың жиекпен көрсетіледі.
class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sp2),
      child: Pressable(
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp3, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: .12) : AppColors.surface,
            borderRadius: AppRadius.rFull,
            border: Border.all(
              color: selected ? accent : accent.withValues(alpha: .3),
              width: selected ? 1.8 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: selected ? accent : AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Бір формула картасы: пән-сынып белгісі + тақырып + формула (акцентті
/// қорап) + тірек қорытынды; басқанда толық теория сабағы ашылады.
class _RefCard extends StatelessWidget {
  const _RefCard({required this.entry});

  final RefEntry entry;

  @override
  Widget build(BuildContext context) {
    final subject = CurriculumData.subjectById(entry.subject);
    return Pressable(
      onTap: () {
        AppHaptics.tap();
        context.push('/learn/lesson/${entry.lessonNodeId}');
      },
      child: PanelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(subject.icon, size: 16, color: subject.accent),
                const SizedBox(width: 6),
                Text(
                  '${subject.title} · ${entry.grade}-${AppStrings.refGradeShort}',
                  style: AppTypography.caption.copyWith(
                    color: subject.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.inkSoft),
              ],
            ),
            const SizedBox(height: AppSpacing.sp2),
            Text(
              entry.title,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sp2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp3, vertical: AppSpacing.sp2),
              decoration: BoxDecoration(
                color: subject.accent.withValues(alpha: .08),
                borderRadius: AppRadius.rMd,
                border: Border.all(
                  color: subject.accent.withValues(alpha: .25),
                ),
              ),
              child: Text(
                entry.formula,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp2),
            Text(
              entry.takeaway,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
