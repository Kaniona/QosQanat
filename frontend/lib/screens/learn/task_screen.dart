import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/app_sounds.dart';
import '../../data/curriculum.dart';
import '../../models/enums.dart';
import '../../models/task_node.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mastery_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/avatar/avatar_display.dart';
import '../../widgets/game/answer_tile.dart';
import '../../widgets/ui/reward_toast.dart';
import '../../widgets/ui/speak_button.dart';
import '../../widgets/ui/stat_label.dart';

/// Викторина экраны: пулдан кездейсоқ ~12 сұрақ (жеңілден қиынға),
/// 4 формат — таңдау / дұрыс-бұрыс / бос орын / сәйкестендіру,
/// прогресс + жүректер, маскот реакциясы, қателерде түсіндірме.
class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key, required this.nodeId});

  final String nodeId;

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  late final TaskNode? _node = Curriculum.nodeById(widget.nodeId);
  late final List<Question> _questions =
      _node == null ? const [] : Curriculum.sessionQuestions(_node);

  int _index = 0;
  int _correct = 0;
  int _hearts = 3;
  int? _selected;
  bool _answered = false;
  bool _matchSucceeded = false;
  bool _finishing = false;
  bool _recorded = false;

  /// Әр сұраққа берілген жауап — бейімделу движогіне (mastery/SRS) азық.
  final List<SessionAnswer> _answers = [];

  void _logAnswer(bool correct) {
    _answers.add((
      questionId: _question.id,
      nodeId: widget.nodeId,
      correct: correct,
      difficulty: _question.difficulty,
    ));
  }

  /// Жинақталған жауаптарды бейімделу движогіне береді (бір рет қана).
  Future<void> _flushAnswers() async {
    if (_recorded || _answers.isEmpty) return;
    _recorded = true;
    await ref.read(masteryProvider.notifier).recordSession(_answers);
  }

  Question get _question => _questions[_index];
  bool get _isMatch => _question.type == QuestionType.matchPairs;

  Future<void> _answer(int option) async {
    if (_answered || _finishing) return;
    final correct = option == _question.correctIndex;
    if (correct) {
      AppHaptics.select();
      AppSounds.correct();
    } else {
      AppHaptics.heavy();
      AppSounds.wrong();
    }
    _logAnswer(correct);
    setState(() {
      _selected = option;
      _answered = true;
      if (correct) {
        _correct++;
      } else {
        _hearts--;
      }
    });
    await _advance(correct);
  }

  /// Сәйкестендіру аяқталды: 0-1 қате — дұрыс, көбі — қате.
  Future<void> _onMatchFinished(bool success) async {
    if (_answered || _finishing) return;
    if (success) {
      AppHaptics.select();
      AppSounds.correct();
    } else {
      AppHaptics.heavy();
      AppSounds.wrong();
    }
    _logAnswer(success);
    setState(() {
      _answered = true;
      _matchSucceeded = success;
      if (success) {
        _correct++;
      } else {
        _hearts--;
      }
    });
    await _advance(success);
  }

  Future<void> _advance(bool correct) async {
    await Future<void>.delayed(
      Duration(milliseconds: correct ? 900 : 1700),
    );
    if (!mounted) return;

    if (_hearts <= 0) {
      await _flushAnswers();
      if (!mounted) return;
      RewardToast.show(
        context,
        message: AppStrings.heartsOut,
        icon: Icons.heart_broken_rounded,
        color: AppColors.dangerCoral,
      );
      context.pop();
      return;
    }

    if (_index + 1 >= _questions.length) {
      await _finish();
    } else {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
        _matchSucceeded = false;
      });
    }
  }

  Future<void> _finish() async {
    if (_node == null) return;
    setState(() => _finishing = true);
    await _flushAnswers();
    final result = await ref
        .read(taskProvider(_node.subject).notifier)
        .completeTask(
          widget.nodeId,
          correctCount: _correct,
          totalCount: _questions.length,
        );
    if (!mounted) return;
    context.pushReplacement(
      '/learn/result',
      extra: (nodeId: widget.nodeId, result: result),
    );
  }

  String get _typeLabel => switch (_question.type) {
        QuestionType.trueFalse => AppStrings.typeTrueFalse,
        QuestionType.fillBlank => AppStrings.typeFillBlank,
        QuestionType.matchPairs => AppStrings.matchTitle,
        QuestionType.multipleChoice => AppStrings.typeChoice,
      };

  (String, Color) get _difficultyBadge => (
        _question.difficulty.label,
        switch (_question.difficulty) {
          Difficulty.light => AppColors.successJade,
          Difficulty.easy => AppColors.successJade,
          Difficulty.medium => AppColors.steppeGoldDeep,
          Difficulty.hard => AppColors.warningSunset,
          Difficulty.complex => AppColors.dangerCoral,
          Difficulty.brainTeaser => AppColors.cosmicPurple,
        },
      );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (_node == null || _questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(AppStrings.error, style: AppTypography.body),
        ),
      );
    }

    final correctNow =
        _isMatch ? _matchSucceeded : _selected == _question.correctIndex;
    final mood = !_answered
        ? AvatarMood.idle
        : (correctNow ? AvatarMood.celebrate : AvatarMood.sad);
    final (diffLabel, diffColor) = _difficultyBadge;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sp3),
              // ---- Жоғарғы панель: жабу + прогресс + жүректер ----
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
                                  _questions.length,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.eagleGrad,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp3),
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < _hearts
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: i < _hearts
                          ? AppColors.dangerCoral
                          : AppColors.muted,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp2),
              Row(
                children: [
                  Text(
                    '${AppStrings.questionCounter} ${_index + 1}/${_questions.length}'
                    ' · $_typeLabel',
                    style: AppTypography.caption,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: .12),
                      borderRadius: AppRadius.rFull,
                    ),
                    child: Text(
                      diffLabel,
                      style: AppTypography.caption.copyWith(
                        color: diffColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp4),

              // ---- Сұрақ картасы ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sp5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.rLg,
                  boxShadow: AppColors.sh2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _isMatch
                            ? '${_question.text}\n${AppStrings.matchHint}'
                            : _question.text,
                        style: AppTypography.h3.copyWith(height: 1.4),
                      ),
                    ),
                    // Дауыстап оқу (TTS қолжетімді болса ғана көрінеді).
                    if (!_isMatch)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sp2),
                        child: SpeakButton(text: _question.text),
                      ),
                  ],
                ),
              ).animate(key: ValueKey('q$_index')).fadeIn().slideX(begin: .06),
              const SizedBox(height: AppSpacing.sp5),

              // ---- Жауап аймағы ----
              Expanded(
                child: _isMatch
                    ? _MatchBoard(
                        key: ValueKey('m$_index'),
                        question: _question,
                        enabled: !_answered && !_finishing,
                        onFinished: _onMatchFinished,
                      )
                    : ListView(
                        children: [
                          for (var i = 0;
                              i < _question.options.length;
                              i++)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sp3),
                              child: AnswerButton(
                                key: ValueKey('a$_index$i'),
                                text: _question.options[i],
                                state: _answerState(i),
                                onTap: () => _answer(i),
                              ),
                            ),
                          if (_answered &&
                              _selected != _question.correctIndex)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: AppSpacing.sp3),
                              child: ExplanationCard(
                                correctAnswer: _question.correctAnswer,
                                hint: _question.hint,
                              ),
                            ),
                        ],
                      ),
              ),

              // ---- Маскот + дұрыс жауап қалқымасы ----
              SizedBox(
                height: 110,
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    AvatarDisplay(
                      assistant: user?.assistantType ?? AssistantType.bektur,
                      mood: mood,
                      size: 90,
                    ),
                    if (_answered && correctNow)
                      Positioned(
                        left: 90,
                        bottom: 50,
                        child: StatLabel(
                          icon: AppIcons.xp,
                          text: '+5',
                          color: AppColors.steppeGoldDeep,
                          iconSize: 20,
                          gap: 4,
                          style: AppTypography.h3,
                        )
                            .animate()
                            .moveY(begin: 0, end: -28, duration: 800.ms)
                            .fadeOut(delay: 350.ms, duration: 450.ms),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AnswerState _answerState(int i) {
    if (!_answered) return AnswerState.idle;
    if (i == _question.correctIndex) return AnswerState.correct;
    if (i == _selected) return AnswerState.wrong;
    return AnswerState.disabled;
  }
}

/// Сәйкестендіру тақтасы: сол бағанда сұрақтар, оң бағанда араласқан
/// сыңарлар. Дұрыс жұп — жасыл боп бекітіледі, қате — қызыл жыпылық.
/// Барлығы қосылғанда: 0-1 қате — сұрақ дұрыс, көбі — қате.
class _MatchBoard extends StatefulWidget {
  const _MatchBoard({
    super.key,
    required this.question,
    required this.enabled,
    required this.onFinished,
  });

  final Question question;
  final bool enabled;
  final ValueChanged<bool> onFinished;

  @override
  State<_MatchBoard> createState() => _MatchBoardState();
}

class _MatchBoardState extends State<_MatchBoard> {
  late final List<MatchPair> _pairs = widget.question.pairs;
  late final List<String> _rights = _pairs.map((p) => p.right).toList()
    ..shuffle();

  int? _selectedLeft;
  int? _flashRight;
  final Set<int> _matchedLeft = {};
  final Set<int> _matchedRight = {};
  int _mistakes = 0;

  void _onLeftTap(int i) {
    if (!widget.enabled || _matchedLeft.contains(i)) return;
    AppHaptics.select();
    setState(() => _selectedLeft = i);
  }

  Future<void> _onRightTap(int i) async {
    if (!widget.enabled ||
        _selectedLeft == null ||
        _matchedRight.contains(i)) {
      return;
    }
    final left = _selectedLeft!;
    final isCorrect = _rights[i] == _pairs[left].right;
    if (isCorrect) {
      AppHaptics.select();
      setState(() {
        _matchedLeft.add(left);
        _matchedRight.add(i);
        _selectedLeft = null;
      });
      if (_matchedLeft.length == _pairs.length) {
        widget.onFinished(_mistakes <= 1);
      }
    } else {
      AppHaptics.heavy();
      setState(() {
        _mistakes++;
        _flashRight = i;
        _selectedLeft = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) setState(() => _flashRight = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < _pairs.length; i++)
                _MatchCard(
                  text: _pairs[i].left,
                  matched: _matchedLeft.contains(i),
                  selected: _selectedLeft == i,
                  flash: false,
                  onTap: () => _onLeftTap(i),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sp3),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < _rights.length; i++)
                _MatchCard(
                  text: _rights[i],
                  matched: _matchedRight.contains(i),
                  selected: false,
                  flash: _flashRight == i,
                  onTap: () => _onRightTap(i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.text,
    required this.matched,
    required this.selected,
    required this.flash,
    required this.onTap,
  });

  final String text;
  final bool matched;
  final bool selected;
  final bool flash;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = matched
        ? (
            AppColors.tintJade,
            AppColors.successJade,
            AppColors.successJade
          )
        : flash
            ? (
                AppColors.tintCoral,
                AppColors.dangerCoral,
                AppColors.dangerCoral
              )
            : selected
                ? (
                    AppColors.tintGold,
                    AppColors.steppeGold,
                    AppColors.onTintGold
                  )
                : (AppColors.surface, AppColors.border, AppColors.ink);

    Widget card = GestureDetector(
      onTap: matched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp3,
          vertical: AppSpacing.sp4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: border, width: 2),
          boxShadow: matched || selected ? null : AppColors.sh1,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );

    if (flash) {
      card = card.animate().shakeX(hz: 5, amount: 3, duration: 400.ms);
    }
    return card;
  }
}
