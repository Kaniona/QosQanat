import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../data/curriculum.dart';
import '../../models/enums.dart';
import '../../models/task_node.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/avatar/avatar_display.dart';
import '../../widgets/ui/reward_toast.dart';

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

  Question get _question => _questions[_index];
  bool get _isMatch => _question.type == QuestionType.matchPairs;

  Future<void> _answer(int option) async {
    if (_answered || _finishing) return;
    final correct = option == _question.correctIndex;
    if (correct) {
      AppHaptics.select();
    } else {
      AppHaptics.heavy();
    }
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
    } else {
      AppHaptics.heavy();
    }
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

  (String, Color) get _difficultyBadge => switch (_question.difficulty) {
        Difficulty.easy => (AppStrings.diffEasy, AppColors.successJade),
        Difficulty.medium => (AppStrings.diffMedium, AppColors.steppeGoldDeep),
        Difficulty.hard => (AppStrings.diffHard, AppColors.dangerCoral),
      };

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
                            Container(color: AppColors.cloudBorder),
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
                          : AppColors.mist,
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
                  color: AppColors.white,
                  borderRadius: AppRadius.rLg,
                  boxShadow: AppColors.sh2,
                ),
                child: Text(
                  _isMatch
                      ? '${_question.text}\n${AppStrings.matchHint}'
                      : _question.text,
                  style: AppTypography.h3.copyWith(height: 1.4),
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
                              child: _AnswerButton(
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
                                  top: AppSpacing.sp1),
                              child: Text(
                                '${AppStrings.wrongAnswer} ${_question.correctAnswer}'
                                '${_question.hint != null ? '\n💡 ${_question.hint}' : ''}',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.dangerCoral),
                              ).animate().fadeIn(),
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
                        child: Text(
                          '+5 ⚡',
                          style: AppTypography.h3
                              .copyWith(color: AppColors.steppeGoldDeep),
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

  _AnswerState _answerState(int i) {
    if (!_answered) return _AnswerState.idle;
    if (i == _question.correctIndex) return _AnswerState.correct;
    if (i == _selected) return _AnswerState.wrong;
    return _AnswerState.disabled;
  }
}

enum _AnswerState { idle, correct, wrong, disabled }

/// Claymorphic жауап батырмасы: дұрыс → жасыл check, қате → қызыл + шайқалу.
class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    super.key,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _AnswerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _AnswerState.idle => (
          AppColors.white,
          AppColors.cloudBorder,
          AppColors.nightInk
        ),
      _AnswerState.correct => (
          const Color(0xFFE0FAF2),
          AppColors.successJade,
          AppColors.successJade
        ),
      _AnswerState.wrong => (
          const Color(0xFFFFEBEE),
          AppColors.dangerCoral,
          AppColors.dangerCoral
        ),
      _AnswerState.disabled => (
          AppColors.dawnBg,
          AppColors.cloudBorder,
          AppColors.mist
        ),
    };

    Widget button = GestureDetector(
      onTap: state == _AnswerState.idle ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4,
          vertical: AppSpacing.sp4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: border, width: 2),
          boxShadow: state == _AnswerState.idle ? AppColors.sh1 : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            if (state == _AnswerState.correct)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.successJade, size: 24),
            if (state == _AnswerState.wrong)
              const Icon(Icons.cancel_rounded,
                  color: AppColors.dangerCoral, size: 24),
          ],
        ),
      ),
    );

    // Қате жауап: жұмсақ шайқалу.
    if (state == _AnswerState.wrong) {
      button = button
          .animate()
          .shakeX(hz: 5, amount: 4, duration: 450.ms);
    }
    if (state == _AnswerState.correct) {
      button = button.animate().scaleXY(
            begin: 1,
            end: 1.02,
            duration: 180.ms,
            curve: Curves.easeOut,
          );
    }
    return button;
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
            const Color(0xFFE0FAF2),
            AppColors.successJade,
            AppColors.successJade
          )
        : flash
            ? (
                const Color(0xFFFFEBEE),
                AppColors.dangerCoral,
                AppColors.dangerCoral
              )
            : selected
                ? (
                    AppColors.steppeGoldLight,
                    AppColors.steppeGold,
                    AppColors.steppeGoldDeep
                  )
                : (AppColors.white, AppColors.cloudBorder, AppColors.nightInk);

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
