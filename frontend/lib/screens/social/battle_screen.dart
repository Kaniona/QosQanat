import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../core/utils/app_haptics.dart';
import '../../providers/auth_provider.dart';
import '../../providers/battle_provider.dart';
import '../../widgets/avatar/avatar_display.dart';

/// LIVE батл: қарсылас ұпайы (жоғары), өз ұпайың (төмен), сұрақ + 4 жауап,
/// толық енді кері санақ жолағы (10с жасыл → 5с сары → 3с қызыл).
class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen> {
  static const _secondsPerQuestion = 10;

  Timer? _timer;
  int _secondsLeft = _secondsPerQuestion;
  int? _selected;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _secondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      // Уақыт бітті — жауапсыз өткізу.
      if (_secondsLeft <= 0) _submit(null);
    });
  }

  Future<void> _submit(int? option) async {
    if (_answered) return;
    _timer?.cancel();
    if (option != null) AppHaptics.select();
    setState(() {
      _answered = true;
      _selected = option;
    });

    await ref.read(battleProvider.notifier).submitAnswer(option);
    // Раунд нәтижесін көрсетуге қысқа пауза.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    if (ref.read(battleProvider).finished) {
      context.pushReplacement('/battle-result');
      return;
    }
    setState(() {
      _answered = false;
      _selected = null;
    });
    _startTimer();
  }

  Color get _timerColor {
    if (_secondsLeft > 5) return AppColors.successJade;
    if (_secondsLeft > 3) return AppColors.steppeGold;
    return AppColors.dangerCoral;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(battleProvider);
    final battle = state.battle;
    final user = ref.watch(currentUserProvider);

    if (battle == null || state.currentIndex >= battle.questions.length) {
      return Scaffold(
        body: Center(
          child: Text(AppStrings.loading, style: AppTypography.body),
        ),
      );
    }

    final question = battle.questions[state.currentIndex];
    final round = state.lastRound;
    final mood = !_answered
        ? AvatarMood.idle
        : (round?.myCorrect ?? false ? AvatarMood.celebrate : AvatarMood.sad);

    // Android back: батлдан кездейсоқ шығып кетуден қорғау.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final quit = await _confirmQuit();
        if (quit && context.mounted) {
          ref.read(battleProvider.notifier).reset();
          context.pop();
        }
      },
      child: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sp3),

              // ---- Қарсылас (жоғарыда) ----
              _ScoreRow(
                name: battle.opponentName,
                score: battle.opponentScore,
                accent: AppColors.dangerCoral,
                reversed: true,
              ),
              const SizedBox(height: AppSpacing.sp3),

              // ---- Кері санақ жолағы ----
              ClipRRect(
                borderRadius: AppRadius.rFull,
                child: SizedBox(
                  height: 14,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Container(color: AppColors.border),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.linear,
                        widthFactor:
                            (_secondsLeft / _secondsPerQuestion).clamp(0, 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          color: _timerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sp1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppStrings.questionCounter} ${state.currentIndex + 1}/${battle.questions.length}',
                    style: AppTypography.caption,
                  ),
                  if (state.myStreak >= 2)
                    _ComboBadge(streak: state.myStreak)
                  else
                    const SizedBox.shrink(),
                  Text(
                    Formatters.timer(_secondsLeft.clamp(0, 99)),
                    style: AppTypography.caption.copyWith(
                      color: _timerColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp3),

              // ---- Сұрақ ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sp5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.rLg,
                  boxShadow: AppColors.sh2,
                ),
                child: Text(
                  question.text,
                  style: AppTypography.h3.copyWith(height: 1.4),
                ),
              )
                  .animate(key: ValueKey('bq${state.currentIndex}'))
                  .fadeIn()
                  .slideX(begin: .06),
              const SizedBox(height: AppSpacing.sp4),

              // ---- Жауаптар ----
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < question.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sp3),
                        child: _BattleAnswer(
                          key: ValueKey('ba${state.currentIndex}$i'),
                          text: question.options[i],
                          state: _answerState(i, question.correctIndex),
                          onTap: () => _submit(i),
                        ),
                      ),
                  ],
                ),
              ),

              // ---- Маскот + өз ұпайың (төменде) ----
              Row(
                children: [
                  AvatarDisplay(
                    assistant: user?.assistantType ?? AssistantType.bektur,
                    mood: mood,
                    size: 72,
                  ),
                  const SizedBox(width: AppSpacing.sp3),
                  Expanded(
                    child: _ScoreRow(
                      name: AppStrings.you,
                      score: battle.myScore,
                      accent: AppColors.eagleBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp3),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Батлдан шығуды растау диалогы.
  Future<bool> _confirmQuit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.battleQuitTitle),
        content: const Text(AppStrings.battleQuitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.battleQuitStay),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.battleQuitConfirm,
              style: AppTypography.button
                  .copyWith(color: AppColors.dangerCoral),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  _BattleAnswerState _answerState(int index, int correctIndex) {
    if (!_answered) return _BattleAnswerState.idle;
    if (index == correctIndex) return _BattleAnswerState.correct;
    if (index == _selected) return _BattleAnswerState.wrong;
    return _BattleAnswerState.disabled;
  }
}

/// Ұпай жолы: аты + ұпай бейджі.
/// Комбо белгісі — қатарынан дұрыс жауап (🔥 ×N), әр өсуде секіреді.
class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sp3, vertical: 2),
      decoration: BoxDecoration(
        gradient: AppColors.heroGold,
        borderRadius: AppRadius.rFull,
        boxShadow: AppColors.glow(AppColors.steppeGold, opacity: .4, blur: 8),
      ),
      child: Text(
        '🔥 Комбо ×$streak',
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    )
        .animate(key: ValueKey(streak))
        .scaleXY(begin: 1.3, end: 1, duration: 280.ms, curve: Curves.easeOut);
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.name,
    required this.score,
    required this.accent,
    this.reversed = false,
  });

  final String name;
  final int score;
  final Color accent;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final children = [
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: reversed ? TextAlign.right : TextAlign.left,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(width: AppSpacing.sp3),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Container(
          key: ValueKey(score),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp4,
            vertical: AppSpacing.sp1,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .12),
            borderRadius: AppRadius.rFull,
            border: Border.all(color: accent, width: 1.5),
          ),
          child: Text(
            '$score',
            style: AppTypography.h3.copyWith(color: accent),
          ),
        ),
      ),
    ];

    return Row(children: reversed ? children.reversed.toList() : children);
  }
}

enum _BattleAnswerState { idle, correct, wrong, disabled }

class _BattleAnswer extends StatelessWidget {
  const _BattleAnswer({
    super.key,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _BattleAnswerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _BattleAnswerState.idle => (
          AppColors.surface,
          AppColors.border,
          AppColors.ink
        ),
      _BattleAnswerState.correct => (
          AppColors.tintJade,
          AppColors.successJade,
          AppColors.successJade
        ),
      _BattleAnswerState.wrong => (
          AppColors.tintCoral,
          AppColors.dangerCoral,
          AppColors.dangerCoral
        ),
      _BattleAnswerState.disabled => (
          AppColors.bg,
          AppColors.border,
          AppColors.muted
        ),
    };

    Widget button = GestureDetector(
      onTap: state == _BattleAnswerState.idle ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.sp4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.rMd,
          border: Border.all(color: border, width: 2),
          boxShadow: state == _BattleAnswerState.idle ? AppColors.sh1 : null,
        ),
        child: Text(
          text,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );

    if (state == _BattleAnswerState.wrong) {
      button = button.animate().shakeX(hz: 5, amount: 4, duration: 450.ms);
    }
    return button;
  }
}
