import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/curriculum.dart';
import '../../data/lessons/math_lessons.dart';
import '../../models/enums.dart';
import '../../models/lesson.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/avatar/avatar_base.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/lesson_visual.dart';
import '../../widgets/ui/panels.dart';
import '../../widgets/ui/speak_button.dart';

/// Сабақ экраны — баланы ТЕКСЕРМЕЙ, алдымен ҮЙРЕТУ.
/// Теория → формула → қадаммен ашылатын үлгі есептер → «Жаттығуды бастау».
class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.nodeId});

  final String nodeId;

  /// Интро мәтінін «негізгі идея» (бірінші сөйлем) мен қалған толық
  /// түсініктемеге бөледі — негізгі ойды жоғарыда бөлектеп, бірден түсіндіреді.
  static (String keyIdea, String body) _splitIntro(String intro) {
    final m = RegExp(r'[.!?]\s').firstMatch(intro);
    if (m == null || m.start < 16) return (intro, '');
    return (
      intro.substring(0, m.start + 1).trim(),
      intro.substring(m.end).trim(),
    );
  }

  /// Сабақты дауыстап оқуға арналған біріктірілген мәтін.
  static String _speakText(Lesson lesson) {
    final buffer = StringBuffer()..writeln(lesson.title);
    if (lesson.hook != null) buffer.writeln(lesson.hook);
    buffer.writeln(lesson.intro);
    lesson.explainSteps.forEach(buffer.writeln);
    if (lesson.formula != null) buffer.writeln(lesson.formula);
    if (lesson.whyFormula != null) {
      buffer.writeln('${AppStrings.lessonWhy} ${lesson.whyFormula}');
    }
    buffer.write('${AppStrings.lessonTakeaway}: ${lesson.takeaway}');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = Curriculum.nodeById(nodeId);
    final lesson =
        node == null ? null : lessonFor(node.subject, node.grade, node.module);

    // Сабақ жоқ болса — тікелей жаттығуға өтеміз (қорғаныс).
    if (lesson == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pushReplacement('/learn/task/$nodeId', extra: node?.subject);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final assistant =
        ref.watch(currentUserProvider.select((u) => u?.assistantType)) ??
            AssistantType.bektur;
    // hook бар жаңа құрылымда серік өмірден бастайды да, интро толығымен
    // «негізгі идея» картасына түседі; ескі контентте интро екіге бөлінеді.
    final hasHook = lesson.hook != null;
    final (keyIdea, introBody) =
        hasHook ? (lesson.intro, '') : _splitIntro(lesson.intro);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text(AppStrings.lessonTitle),
        actions: [SpeakButton(text: _speakText(lesson))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sp5,
            AppSpacing.sp2,
            AppSpacing.sp5,
            AppSpacing.sp12,
          ),
          children: [
            // ---- Тақырып ----
            Text(lesson.title, style: AppTypography.h1)
                .animate()
                .fadeIn(duration: 320.ms)
                .slideY(begin: .1, curve: Curves.easeOutCubic),
            const SizedBox(height: AppSpacing.sp4),

            // ---- Серік сабақты бастайды: өмірден кіріспе (әйтпесе идея) ----
            _CompanionBubble(
              assistant: assistant,
              label: hasHook ? AppStrings.lessonHook : AppStrings.lessonKeyIdea,
              icon: hasHook
                  ? Icons.auto_awesome_rounded
                  : Icons.lightbulb_rounded,
              text: lesson.hook ?? keyIdea,
            )
                .animate()
                .fadeIn(delay: 80.ms, duration: 320.ms)
                .slideY(begin: .08, curve: Curves.easeOutCubic),

            // ---- Негізгі идея — тақырыптың мәні бір ауыз сөзбен ----
            if (hasHook) ...[
              const SizedBox(height: AppSpacing.sp3),
              _KeyIdeaCard(keyIdea)
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 320.ms)
                  .slideY(begin: .08, curve: Curves.easeOutCubic),
            ],

            // ---- Толық түсініктеме (ескі бір-блок контент үшін) ----
            if (introBody.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sp3),
              _ExplainCard(introBody)
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 320.ms)
                  .slideY(begin: .08, curve: Curves.easeOutCubic),
            ],

            // ---- Ұғымды қадам-қадаммен құру (ұстазша түсіндіру) ----
            if (lesson.explainSteps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sp3),
              _StepsCard(lesson.explainSteps)
                  .animate()
                  .fadeIn(delay: 180.ms, duration: 320.ms)
                  .slideY(begin: .08, curve: Curves.easeOutCubic),
            ],

            // ---- Тұжырымдамалық визуал (болса) — суретпен бірден түсіну ----
            if (lesson.visual != null) ...[
              const SizedBox(height: AppSpacing.sp3),
              LessonVisualView(lesson.visual!)
                  .animate()
                  .fadeIn(delay: 180.ms, duration: 320.ms)
                  .slideY(begin: .08, curve: Curves.easeOutCubic),
            ],

            // ---- Формула / ереже + «Неге солай?» ----
            if (lesson.formula != null) ...[
              const SizedBox(height: AppSpacing.sp3),
              _FormulaCard(lesson.formula!, why: lesson.whyFormula)
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 320.ms)
                  .slideY(begin: .08, curve: Curves.easeOutCubic),
            ],

            // ---- Үлгі есептер ----
            if (lesson.examples.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sp6),
              const SectionHeader(title: AppStrings.lessonExamples),
              for (var i = 0; i < lesson.examples.length; i++) ...[
                _WorkedExampleCard(
                  index: i + 1,
                  example: lesson.examples[i],
                )
                    .animate()
                    .fadeIn(delay: (220 + i * 80).ms, duration: 320.ms)
                    .slideY(begin: .08, curve: Curves.easeOutCubic),
                const SizedBox(height: AppSpacing.sp3),
              ],
            ],

            // ---- Жиі қателік (ескерту) ----
            if (lesson.commonMistake != null) ...[
              const SizedBox(height: AppSpacing.sp3),
              _MistakeCard(lesson.commonMistake!)
                  .animate()
                  .fadeIn(delay: 380.ms, duration: 320.ms)
                  .slideY(begin: .08, curve: Curves.easeOutCubic),
            ],

            // ---- Тірек қорытынды ----
            const SizedBox(height: AppSpacing.sp3),
            _TakeawayCard(lesson.takeaway)
                .animate()
                .fadeIn(delay: 420.ms, duration: 320.ms)
                .slideY(begin: .08, curve: Curves.easeOutCubic),

            const SizedBox(height: AppSpacing.sp8),

            // ---- Жаттығуға өту ----
            AppButton(
              label: AppStrings.lessonStartPractice,
              icon: Icons.play_arrow_rounded,
              onPressed: () => context.pushReplacement(
                '/learn/task/$nodeId',
                extra: node!.subject,
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 320.ms),
          ],
        ),
      ),
    );
  }
}

/// Серік «мұғалім» сөйлейді — сабақты өмірден таныс жағдаятпен бастайды
/// (қорқынышты анықтама емес, серігіңнің жылы, қарапайым әңгімесі).
class _CompanionBubble extends StatelessWidget {
  const _CompanionBubble({
    required this.assistant,
    required this.label,
    required this.icon,
    required this.text,
  });

  final AssistantType assistant;
  final String label;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isNazym = assistant == AssistantType.nazym;
    final accent = isNazym ? AppColors.nazymRose : AppColors.eagleBlue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          height: 66,
          child: AvatarBase(assistant: assistant, size: 58),
        ),
        const SizedBox(width: AppSpacing.sp2),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sp4),
            decoration: BoxDecoration(
              color: isNazym ? AppColors.tintRose : AppColors.tintBlue,
              borderRadius: AppRadius.rLg,
              border:
                  Border.all(color: accent.withValues(alpha: .3), width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: AppTypography.body.copyWith(
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Негізгі идея картасы — тақырыптың мәні бір ауыз сөзбен, көк акцент
/// жолағымен (ұстаз тақтаға жазған басты ой сияқты бөлектенеді).
class _KeyIdeaCard extends StatelessWidget {
  const _KeyIdeaCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4.5,
              decoration: BoxDecoration(
                gradient: AppColors.heroEagle,
                borderRadius: AppRadius.rFull,
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          size: 15, color: AppColors.eagleBlue),
                      const SizedBox(width: 5),
                      Text(
                        AppStrings.lessonKeyIdea,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.eagleBlue,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    style: AppTypography.body.copyWith(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Қадам-қадаммен түсіндіру — мықты ұстаз тақтаға бір ойдан жазғандай:
/// нөмірлі тізбек, әр қадам — бір шағын ой, кезекпен пайда болады.
class _StepsCard extends StatelessWidget {
  const _StepsCard(this.steps);

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.all(AppSpacing.sp5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stairs_rounded, size: 15, color: AppColors.inkSoft),
              const SizedBox(width: 5),
              Text(
                AppStrings.lessonStepByStep,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp3),
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              index: i + 1,
              text: steps[i],
              isLast: i == steps.length - 1,
            )
                .animate()
                .fadeIn(delay: (100 + i * 90).ms, duration: 280.ms)
                .slideY(begin: .12, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

/// Түсіндірудің бір қадамы: нөмірлі шеңбер + келесіге жалғайтын сызық.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.text,
    required this.isLast,
  });

  final int index;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroEagle,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.white, fontWeight: FontWeight.w900),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.eagleBlue.withValues(alpha: .18),
                      borderRadius: AppRadius.rFull,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 3, bottom: isLast ? 0 : AppSpacing.sp4),
              child: Text(text,
                  style: AppTypography.body.copyWith(height: 1.55)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Негізгі идеядан кейінгі толық түсініктеме (тыныш, оқуға ыңғайлы).
class _ExplainCard extends StatelessWidget {
  const _ExplainCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded,
                  size: 15, color: AppColors.inkSoft),
              const SizedBox(width: 5),
              Text(
                AppStrings.lessonExplain,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp2),
          Text(text, style: AppTypography.body.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}

/// Негізгі формула / ереже картасы (көк градиент, ақ мәтін). [why] берілсе —
/// «Неге солай?» ашылмалы себеп: бала ережені жаттамай, ТҮСІНІП есте сақтайды.
class _FormulaCard extends StatefulWidget {
  const _FormulaCard(this.formula, {this.why});

  final String formula;
  final String? why;

  @override
  State<_FormulaCard> createState() => _FormulaCardState();
}

class _FormulaCardState extends State<_FormulaCard> {
  bool _showWhy = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp5,
        vertical: AppSpacing.sp5,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.heroEagle,
        borderRadius: AppRadius.rXl,
        boxShadow: AppColors.glow(AppColors.eagleBlue, opacity: .3, blur: 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.functions_rounded,
                  color: AppColors.white, size: 26),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Text(
                  widget.formula,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (widget.why != null) ...[
            const SizedBox(height: AppSpacing.sp3),
            Pressable(
              onTap: () => setState(() => _showWhy = !_showWhy),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .14),
                  borderRadius: AppRadius.rMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology_rounded,
                            color: AppColors.white, size: 18),
                        const SizedBox(width: AppSpacing.sp2),
                        Expanded(
                          child: Text(
                            AppStrings.lessonWhy,
                            style: AppTypography.body.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _showWhy ? .5 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: const Icon(Icons.expand_more_rounded,
                              color: AppColors.white, size: 20),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _showWhy
                          ? Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.sp2),
                              child: Text(
                                widget.why!,
                                style: AppTypography.bodySmall.copyWith(
                                  color:
                                      AppColors.white.withValues(alpha: .95),
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Қадаммен ашылатын үлгі есеп: есеп → «Келесі қадам» → … → жауап.
class _WorkedExampleCard extends StatefulWidget {
  const _WorkedExampleCard({required this.index, required this.example});

  final int index;
  final WorkedExample example;

  @override
  State<_WorkedExampleCard> createState() => _WorkedExampleCardState();
}

class _WorkedExampleCardState extends State<_WorkedExampleCard> {
  late final List<String> _choices = _shuffledChoices();
  String? _picked; // баланың болжамы (интерактив есепте)
  int _revealed = 0; // ашылған қадам саны

  List<String> _shuffledChoices() {
    final c = List<String>.from(widget.example.choices);
    c.shuffle(Random(widget.example.problem.hashCode));
    return c;
  }

  bool get _interactive => widget.example.choices.isNotEmpty;
  bool get _predicted => !_interactive || _picked != null;
  bool get _done => _revealed >= widget.example.steps.length;

  @override
  Widget build(BuildContext context) {
    final ex = widget.example;
    return PanelCard(
      padding: const EdgeInsets.all(AppSpacing.sp5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Есеп нөмірі + шарты.
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.eagleBlue,
                  shape: BoxShape.circle,
                ),
                child: Text('${widget.index}',
                    style: AppTypography.caption.copyWith(
                        color: AppColors.white, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Text(ex.problem,
                    style: AppTypography.h3.copyWith(fontSize: 19)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp3),

          // ---- БОЛЖАМ фазасы (интерактив) ----
          if (!_predicted) ...[
            Text(AppStrings.lessonGuess,
                style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.inkSoft)),
            const SizedBox(height: AppSpacing.sp3),
            Wrap(
              spacing: AppSpacing.sp2,
              runSpacing: AppSpacing.sp2,
              children: [
                for (final c in _choices)
                  _GuessChip(
                    label: c,
                    onTap: () => setState(() => _picked = c),
                  ),
              ],
            ),
          ] else ...[
            // Болжам нәтижесі.
            if (_interactive) _GuessResult(picked: _picked!, answer: ex.answer),

            // Ашылған қадамдар.
            for (var i = 0; i < _revealed; i++)
              Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.sp2, bottom: AppSpacing.sp1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.subdirectory_arrow_right_rounded,
                        size: 18, color: AppColors.inkSoft),
                    const SizedBox(width: AppSpacing.sp2),
                    Expanded(
                      child: Text(ex.steps[i].text,
                          style: AppTypography.body.copyWith(height: 1.5)),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 220.ms).slideX(begin: .05),

            const SizedBox(height: AppSpacing.sp2),
            if (_done)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp4, vertical: AppSpacing.sp2),
                decoration: BoxDecoration(
                  color: AppColors.successJade.withValues(alpha: .14),
                  borderRadius: AppRadius.rFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 18, color: AppColors.successJade),
                    const SizedBox(width: AppSpacing.sp2),
                    Text('${AppStrings.lessonAnswer}: ${ex.answer}',
                        style: AppTypography.body.copyWith(
                          color: AppColors.successJade,
                          fontWeight: FontWeight.w900,
                        )),
                  ],
                ),
              ).animate().fadeIn(duration: 240.ms).scaleXY(begin: .9)
            else
              Align(
                alignment: Alignment.centerLeft,
                child: _StepButton(
                  label: _revealed == 0
                      ? AppStrings.lessonShowSolution
                      : AppStrings.lessonNextStep,
                  onTap: () => setState(() => _revealed++),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Болжам нұсқасы — басылатын чип.
class _GuessChip extends StatelessWidget {
  const _GuessChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp4, vertical: AppSpacing.sp3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: AppColors.eagleBlue, width: 1.5),
        ),
        child: Text(label,
            style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.eagleBlue)),
      ),
    );
  }
}

/// Болжам нәтижесі: дұрыс/қате белгісі.
class _GuessResult extends StatelessWidget {
  const _GuessResult({required this.picked, required this.answer});

  final String picked;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final correct = picked == answer;
    final color = correct ? AppColors.successJade : AppColors.warningSunset;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp1),
      child: Row(
        children: [
          Icon(correct ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
              size: 18, color: color),
          const SizedBox(width: AppSpacing.sp2),
          Expanded(
            child: Text(
              correct
                  ? AppStrings.lessonGuessRight
                  : '${AppStrings.lessonGuessWrong} $picked',
              style: AppTypography.bodySmall
                  .copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }
}

/// «Келесі қадам» — нәзік көк pill (clay squish).
class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp4, vertical: AppSpacing.sp2),
        decoration: BoxDecoration(
          color: AppColors.tintBlue,
          borderRadius: AppRadius.rFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTypography.body.copyWith(
                  color: AppColors.eagleBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                )),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_rounded,
                size: 16, color: AppColors.eagleBlue),
          ],
        ),
      ),
    );
  }
}

/// «Жиі қателік» ескерту картасы (қызғылт-сары, ескерту белгішесімен).
class _MistakeCard extends StatelessWidget {
  const _MistakeCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.tintSunset,
        borderRadius: AppRadius.rLg,
        border: Border.all(
            color: AppColors.warningSunset.withValues(alpha: .4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warningSunset, size: 24),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.lessonCommonMistake,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.warningSunset)),
                const SizedBox(height: 2),
                Text(text,
                    style: AppTypography.body
                        .copyWith(height: 1.45, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Тірек қорытынды картасы (алтын, шам белгішесімен).
class _TakeawayCard extends StatelessWidget {
  const _TakeawayCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.tintGold,
        borderRadius: AppRadius.rLg,
        border: Border.all(
            color: AppColors.steppeGold.withValues(alpha: .4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: AppColors.steppeGoldDeep, size: 24),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.lessonTakeaway,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.steppeGoldDeep)),
                const SizedBox(height: 2),
                Text(text,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      color: AppColors.ink,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
