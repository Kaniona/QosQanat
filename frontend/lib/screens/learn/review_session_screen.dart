import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/app_sounds.dart';
import '../../models/enums.dart';
import '../../models/task_node.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mastery_provider.dart';
import '../../widgets/avatar/avatar_display.dart';
import '../../widgets/game/answer_tile.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/empty_state.dart';

/// Қайталау сессиясы (SRS): бұрын қателескен сұрақтарды араластырып, бекітеді.
/// Тапсырма экранымен бір көрініс (AnswerButton/ExplanationCard), бірақ жүрек
/// жоқ — қайталау жазаламайды, тек бекітеді.
class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  late final List<ReviewCard> _cards =
      ref.read(masteryProvider.notifier).buildReviewSession();

  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _answered = false;
  bool _finished = false;
  bool _recorded = false;

  final List<SessionAnswer> _answers = [];

  Question get _question => _cards[_index].question;

  Future<void> _answer(int option) async {
    if (_answered) return;
    final correct = option == _question.correctIndex;
    if (correct) {
      AppHaptics.select();
      AppSounds.correct();
    } else {
      AppHaptics.heavy();
      AppSounds.wrong();
    }
    _answers.add((
      questionId: _question.id,
      nodeId: _cards[_index].nodeId,
      correct: correct,
      difficulty: _question.difficulty,
    ));
    setState(() {
      _selected = option;
      _answered = true;
      if (correct) _correct++;
    });
    await Future<void>.delayed(Duration(milliseconds: correct ? 850 : 1700));
    if (!mounted) return;
    if (_index + 1 >= _cards.length) {
      await _finish();
    } else {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    }
  }

  Future<void> _finish() async {
    if (!_recorded) {
      _recorded = true;
      await ref.read(masteryProvider.notifier).recordSession(_answers);
    }
    if (!mounted) return;
    setState(() => _finished = true);
  }

  AnswerState _answerState(int i) {
    if (!_answered) return AnswerState.idle;
    if (i == _question.correctIndex) return AnswerState.correct;
    if (i == _selected) return AnswerState.wrong;
    return AnswerState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.reviewTitle)),
        body: Center(
          child: EmptyState(
            icon: Icons.verified_rounded,
            title: AppStrings.reviewEmpty,
            accent: AppColors.successJade,
          ),
        ),
      );
    }

    if (_finished) {
      return _ReviewDone(correct: _correct, total: _cards.length);
    }

    final correctNow = _selected == _question.correctIndex;
    final mood = !_answered
        ? AvatarMood.idle
        : (correctNow ? AvatarMood.celebrate : AvatarMood.sad);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sp3),
              Row(
                children: [
                  IconButton(
                    tooltip: AppStrings.a11yClose,
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close_rounded, size: 26),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.rFull,
                      child: SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            Container(color: AppColors.border),
                            AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 350),
                              widthFactor: (_index + (_answered ? 1 : 0)) /
                                  _cards.length,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.heroJade,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp3),
                  const Icon(Icons.refresh_rounded,
                      size: 22, color: AppColors.successJade),
                ],
              ),
              const SizedBox(height: AppSpacing.sp2),
              Text(
                '${AppStrings.reviewTitle} · ${_index + 1}/${_cards.length}',
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.sp4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sp5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.rLg,
                  boxShadow: AppColors.sh2,
                ),
                child: Text(
                  _question.text,
                  style: AppTypography.h3.copyWith(height: 1.4),
                ),
              ).animate(key: ValueKey('rq$_index')).fadeIn().slideX(begin: .06),
              const SizedBox(height: AppSpacing.sp5),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < _question.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sp3),
                        child: AnswerButton(
                          key: ValueKey('ra$_index$i'),
                          text: _question.options[i],
                          state: _answerState(i),
                          onTap: () => _answer(i),
                        ),
                      ),
                    if (_answered && !correctNow)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sp3),
                        child: ExplanationCard(
                          correctAnswer: _question.correctAnswer,
                          hint: _question.hint,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: AvatarDisplay(
                  assistant: user?.assistantType ?? AssistantType.bektur,
                  mood: mood,
                  size: 84,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Қайталау аяқталды — нәтиже + «Дайын».
class _ReviewDone extends StatelessWidget {
  const _ReviewDone({required this.correct, required this.total});

  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sp6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 96, color: AppColors.successJade),
              const SizedBox(height: AppSpacing.sp4),
              Text(
                AppStrings.reviewDone,
                textAlign: TextAlign.center,
                style: AppTypography.h1,
              ),
              const SizedBox(height: AppSpacing.sp2),
              Text(
                '$correct / $total',
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(color: AppColors.successJade),
              ),
              const SizedBox(height: AppSpacing.sp6),
              AppButton(
                label: AppStrings.done,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
