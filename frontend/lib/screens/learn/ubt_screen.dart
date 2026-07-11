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
import '../../core/utils/app_haptics.dart';
import '../../core/utils/format_utils.dart';
import '../../providers/ubt_provider.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/panels.dart';

/// ҰБТ дайындық бөлімі (10–11 сынып): міндетті 3 пән + таңдаулы 2 профиль
/// пәні, блок-блокпен өтетін таймерлі толық байқау; соңында пән бойынша
/// талдау мен әлсіз тақырыпқа теория сілтемесі. Тек қосымшада бар пәндер.
class UbtScreen extends ConsumerWidget {
  const UbtScreen({super.key});

  Future<void> _guardedPop(BuildContext context, WidgetRef ref) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.examExitTitle),
        content: const Text(AppStrings.examExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.examExitStay),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              AppStrings.examExitLeave,
              style: TextStyle(color: AppColors.dangerCoral),
            ),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) {
      ref.read(ubtProvider.notifier).reset();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(ubtProvider.select((s) => s.phase));
    final running = phase == UbtPhase.running;

    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _guardedPop(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () =>
                running ? _guardedPop(context, ref) : context.pop(),
          ),
          title: const Text(AppStrings.ubtTitle),
        ),
        body: SafeArea(
          child: switch (phase) {
            UbtPhase.intro => const _IntroView(),
            UbtPhase.running => const _RunView(),
            UbtPhase.finished => const _ResultView(),
          },
        ),
      ),
    );
  }
}

/// Интро: формат hero + міндетті блок + профиль пәндерін таңдау + ережелер
/// + тарих. Бір ғана негізгі CTA — «ҰБТ сынағын бастау».
class _IntroView extends ConsumerWidget {
  const _IntroView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(ubtProvider.select((s) => s.profile));
    final history = ref.watch(ubtHistoryProvider);
    final best = history.isEmpty
        ? null
        : history.reduce((a, b) => a.percent >= b.percent ? a : b);
    final ready = profile.length == UbtConfig.profileCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sp5, AppSpacing.sp3, AppSpacing.sp5, AppSpacing.sp12),
      children: [
        // ---- Hero: ҰБТ форматы ----
        Container(
          padding: const EdgeInsets.all(AppSpacing.sp5),
          decoration: BoxDecoration(
            gradient: AppColors.heroEagle,
            borderRadius: AppRadius.rXl,
            boxShadow:
                AppColors.glow(AppColors.eagleBlue, opacity: .3, blur: 18),
          ),
          child: Row(
            children: [
              const Icon(Icons.school_rounded,
                  color: AppColors.white, size: 42),
              const SizedBox(width: AppSpacing.sp4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.ubtIntroTitle,
                      style: AppTypography.h2.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${UbtConfig.totalQuestions} ${AppStrings.examQuestions}'
                      ' · ~${UbtConfig.totalQuestions * UbtConfig.secondsPerQuestion ~/ 60} '
                      '${AppStrings.examMinutes}',
                      style: AppTypography.body.copyWith(
                        color: AppColors.white.withValues(alpha: .92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 320.ms).slideY(begin: .08),
        const SizedBox(height: AppSpacing.sp4),

        // ---- Міндетті блок ----
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 20, color: AppColors.successJade),
                  const SizedBox(width: AppSpacing.sp2),
                  Text(
                    AppStrings.ubtMandatory,
                    style: AppTypography.body
                        .copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp2),
              Text(
                AppStrings.ubtMandatoryDesc,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 80.ms, duration: 320.ms).slideY(begin: .08),
        const SizedBox(height: AppSpacing.sp5),

        // ---- Профиль пәндерін таңдау ----
        SectionHeader(
          title: AppStrings.ubtPickProfile,
          trailing: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp3, vertical: 4),
            decoration: BoxDecoration(
              color: ready ? AppColors.tintGold : AppColors.tintBlue,
              borderRadius: AppRadius.rFull,
            ),
            child: Text(
              '${profile.length}/${UbtConfig.profileCount} '
              '${AppStrings.ubtPickedCount}',
              style: AppTypography.caption.copyWith(
                color:
                    ready ? AppColors.steppeGoldDeep : AppColors.eagleBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        for (final id in UbtConfig.profileChoices)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sp2),
            child: _ProfileTile(
              subject: CurriculumData.subjectById(id),
              selected: profile.contains(id),
              onTap: () {
                AppHaptics.tap();
                ref.read(ubtProvider.notifier).toggleProfile(id);
              },
            ),
          ),
        const SizedBox(height: AppSpacing.sp4),

        // ---- Ережелер ----
        const PanelCard(
          child: Column(
            children: [
              _RuleRow(icon: Icons.school_rounded, text: AppStrings.ubtRule1),
              SizedBox(height: AppSpacing.sp3),
              _RuleRow(
                  icon: Icons.view_agenda_rounded, text: AppStrings.ubtRule2),
              SizedBox(height: AppSpacing.sp3),
              _RuleRow(icon: Icons.insights_rounded, text: AppStrings.ubtRule3),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sp5),

        AppButton(
          label: AppStrings.ubtStart,
          icon: Icons.play_arrow_rounded,
          onPressed: !ready
              ? null
              : () {
                  AppHaptics.tap();
                  ref.read(ubtProvider.notifier).start();
                },
        ),

        // ---- Дайындық индексі (v2): соңғы сынақтардан пән-пән ----
        if (history.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sp6),
          SectionHeader(title: AppStrings.ubtReadiness),
          PanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.ubtReadinessHint,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp3),
                for (final e in ubtReadiness(history).entries) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${(e.value * 100).round()}%',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _accuracyColor(e.value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: AppRadius.rFull,
                    child: LinearProgressIndicator(
                      value: e.value,
                      minHeight: 6,
                      backgroundColor:
                          AppColors.inkSoft.withValues(alpha: .14),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _accuracyColor(e.value)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                ],
              ],
            ),
          ),
        ],

        // ---- Тарих ----
        if (history.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sp6),
          SectionHeader(
            title: AppStrings.ubtHistory,
            trailing: best == null
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp3, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tintGold,
                      borderRadius: AppRadius.rFull,
                    ),
                    child: Text(
                      '${AppStrings.examBest}: ${best.percent}%',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.steppeGoldDeep,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
          for (final a in history.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sp2),
              child: PanelCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
                child: Row(
                  children: [
                    Icon(
                      a.percent >= 70
                          ? Icons.emoji_events_rounded
                          : Icons.history_rounded,
                      size: 18,
                      color: a.percent >= 70
                          ? AppColors.steppeGoldDeep
                          : AppColors.inkSoft,
                    ),
                    const SizedBox(width: AppSpacing.sp3),
                    Expanded(
                      child: Text(
                        '${a.date.day.toString().padLeft(2, '0')}.'
                        '${a.date.month.toString().padLeft(2, '0')} · '
                        '${a.correct}/${a.total}',
                        style: AppTypography.bodySmall
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${a.percent}%',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _accuracyColor(a.percent / 100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Профиль пәнінің таңдау карточкасы: таңдалғаны түс + белгішемен (түске
/// ғана сүйенбейміз) көрсетіледі; 44pt-тан биік басу аймағы.
class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final SubjectInfo subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
        decoration: BoxDecoration(
          color: selected
              ? subject.accent.withValues(alpha: .1)
              : AppColors.surface,
          borderRadius: AppRadius.rLg,
          border: Border.all(
            color: selected
                ? subject.accent
                : subject.accent.withValues(alpha: .3),
            width: selected ? 2 : 1.3,
          ),
        ),
        child: Row(
          children: [
            Icon(subject.icon, size: 22, color: subject.accent),
            const SizedBox(width: AppSpacing.sp3),
            Expanded(
              child: Text(
                subject.title,
                style:
                    AppTypography.body.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: selected ? subject.accent : AppColors.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.eagleBlue),
        const SizedBox(width: AppSpacing.sp3),
        Expanded(
          child: Text(text, style: AppTypography.body.copyWith(height: 1.45)),
        ),
      ],
    );
  }
}

/// Сынақ ағыны: пән блогы чипі + жалпы прогресс + таймер + сұрақ +
/// нұсқалар (кері байланыссыз).
class _RunView extends ConsumerWidget {
  const _RunView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ubtProvider);
    if (state.questions.isEmpty) return const SizedBox.shrink();
    final uq = state.questions[state.index];
    final q = uq.question;
    final lowTime = state.secondsLeft <= 120;
    final (blockSubject, blockAt, blockOf) = state.blockProgress;
    final subject = CurriculumData.subjectById(blockSubject);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sp5, AppSpacing.sp2, AppSpacing.sp5, AppSpacing.sp6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Пән блогы + таймер ----
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp3, vertical: 5),
                decoration: BoxDecoration(
                  color: subject.accent.withValues(alpha: .12),
                  borderRadius: AppRadius.rFull,
                ),
                child: Row(
                  children: [
                    Icon(subject.icon, size: 14, color: subject.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${subject.title} · $blockAt/$blockOf',
                      style: AppTypography.caption.copyWith(
                        color: subject.accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp3, vertical: 5),
                decoration: BoxDecoration(
                  color: lowTime
                      ? AppColors.dangerCoral.withValues(alpha: .14)
                      : AppColors.tintGold,
                  borderRadius: AppRadius.rFull,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 15,
                      color: lowTime
                          ? AppColors.dangerCoral
                          : AppColors.steppeGoldDeep,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      mmss(state.secondsLeft),
                      style: AppTypography.caption.copyWith(
                        color: lowTime
                            ? AppColors.dangerCoral
                            : AppColors.steppeGoldDeep,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp3),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.rFull,
                  child: LinearProgressIndicator(
                    value: state.index / state.questions.length,
                    minHeight: 6,
                    backgroundColor:
                        AppColors.eagleBlue.withValues(alpha: .12),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.eagleBlue),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sp3),
              Text(
                '${state.index + 1}/${state.questions.length}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp4),

          // ---- Сұрақ + нұсқалар (кезекпен пайда болады) ----
          Expanded(
            child: ListView(
              key: ValueKey(state.index),
              children: [
                PanelCard(
                  padding: const EdgeInsets.all(AppSpacing.sp5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uq.moduleTitle,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp2),
                      Text(q.text,
                          style: AppTypography.h3.copyWith(height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sp4),
                for (var i = 0; i < q.options.length; i++) ...[
                  Pressable(
                    onTap: () {
                      AppHaptics.tap();
                      ref.read(ubtProvider.notifier).answer(i);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp4,
                          vertical: AppSpacing.sp4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.rLg,
                        border: Border.all(
                          color: AppColors.eagleBlue.withValues(alpha: .35),
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        q.options[i],
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                ],
              ]
                  .animate(interval: 40.ms)
                  .fadeIn(duration: 220.ms)
                  .slideY(begin: .06, curve: Curves.easeOutCubic),
            ),
          ),
        ],
      ),
    );
  }
}

/// Нәтиже: жалпы ұпай + пән бойынша талдау + әлсіз тақырыпқа теория
/// сілтемесі.
class _ResultView extends ConsumerWidget {
  const _ResultView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (attempt, weak) = ref.watch(
      ubtProvider.select((s) => (s.attempt, s.weakTopics)),
    );
    if (attempt == null) return const SizedBox.shrink();
    final percent = attempt.percent;
    final gradient = percent >= 70
        ? AppColors.heroJade
        : (percent >= 50 ? AppColors.heroGold : AppColors.heroEagle);
    final mood = percent >= 70
        ? AppStrings.examGreatJob
        : (percent >= 50 ? AppStrings.examGoodJob : AppStrings.examKeepGoing);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sp5, AppSpacing.sp3, AppSpacing.sp5, AppSpacing.sp12),
      children: [
        // ---- Жиынтық ұпай ----
        Container(
          padding: const EdgeInsets.all(AppSpacing.sp5),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: AppRadius.rXl,
            boxShadow:
                AppColors.glow(AppColors.eagleBlue, opacity: .25, blur: 18),
          ),
          child: Column(
            children: [
              Text(
                '$percent%',
                style: AppTypography.h1.copyWith(
                  color: AppColors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${attempt.correct}/${attempt.total} '
                '${AppStrings.examCorrectOf}',
                style: AppTypography.body.copyWith(
                  color: AppColors.white.withValues(alpha: .95),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sp2),
              Text(
                mood,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: .9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sp3),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp4, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .16),
                  borderRadius: AppRadius.rFull,
                ),
                child: Text(
                  '${AppStrings.examTimeLabel}: '
                  '${mmss(attempt.durationSec)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 320.ms).scaleXY(begin: .96),
        const SizedBox(height: AppSpacing.sp6),

        // ---- Пән бойынша талдау ----
        SectionHeader(title: AppStrings.ubtPerSubject),
        for (final m in attempt.modules)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sp3),
            child: PanelCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          m.title,
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '${m.correct}/${m.total}',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _accuracyColor(m.accuracy),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sp2),
                  ClipRRect(
                    borderRadius: AppRadius.rFull,
                    child: LinearProgressIndicator(
                      value: m.accuracy,
                      minHeight: 6,
                      backgroundColor:
                          AppColors.inkSoft.withValues(alpha: .14),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _accuracyColor(m.accuracy)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ---- Әлсіз тақырыптар → теория ----
        if (weak.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sp3),
          SectionHeader(title: AppStrings.ubtWeakTopics),
          for (final t in weak)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sp2),
              child: Pressable(
                onTap: () => context.push('/learn/lesson/${t.lessonNodeId}'),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sp4),
                  decoration: BoxDecoration(
                    color: AppColors.tintSunset,
                    borderRadius: AppRadius.rLg,
                    border: Border.all(
                      color: AppColors.warningSunset.withValues(alpha: .4),
                      width: 1.4,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          size: 20, color: AppColors.warningSunset),
                      const SizedBox(width: AppSpacing.sp3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${CurriculumData.subjectById(t.subject).title}'
                              ' · ${t.title}',
                              style: AppTypography.body
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              AppStrings.examReviewTopic,
                              style: AppTypography.caption
                                  .copyWith(color: AppColors.inkSoft),
                            ),
                          ],
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

        const SizedBox(height: AppSpacing.sp6),
        AppButton(
          label: AppStrings.examRetry,
          icon: Icons.refresh_rounded,
          onPressed: () => ref.read(ubtProvider.notifier).reset(),
        ),
        const SizedBox(height: AppSpacing.sp3),
        AppButton(
          label: AppStrings.examDone,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

/// Дәлдікке қарай түс: жасыл (мықты) → алтын (орташа) → коралл (әлсіз).
Color _accuracyColor(double accuracy) {
  if (accuracy >= .8) return AppColors.successJade;
  if (accuracy >= UbtConfig.weakThreshold) return AppColors.steppeGoldDeep;
  return AppColors.dangerCoral;
}
