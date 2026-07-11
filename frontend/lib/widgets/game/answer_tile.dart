import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Жауап батырмасының күйі (викторина мен қайталау сессиясы ортақ қолданады).
enum AnswerState { idle, correct, wrong, disabled }

/// Claymorphic жауап батырмасы: дұрыс → жасыл check, қате → қызыл + шайқалу.
/// Тапсырма экраны мен қайталау сессиясы бір көрініс үшін осыны бөліседі.
class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final AnswerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      AnswerState.idle => (AppColors.surface, AppColors.border, AppColors.ink),
      AnswerState.correct => (
          AppColors.tintJade,
          AppColors.successJade,
          AppColors.successJade
        ),
      AnswerState.wrong => (
          AppColors.tintCoral,
          AppColors.dangerCoral,
          AppColors.dangerCoral
        ),
      AnswerState.disabled => (AppColors.bg, AppColors.border, AppColors.muted),
    };

    Widget button = GestureDetector(
      onTap: state == AnswerState.idle ? onTap : null,
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
          boxShadow: state == AnswerState.idle ? AppColors.sh1 : null,
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
            if (state == AnswerState.correct)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.successJade, size: 24),
            if (state == AnswerState.wrong)
              const Icon(Icons.cancel_rounded,
                  color: AppColors.dangerCoral, size: 24),
          ],
        ),
      ),
    );

    if (state == AnswerState.wrong) {
      button = button.animate().shakeX(hz: 5, amount: 4, duration: 450.ms);
    }
    if (state == AnswerState.correct) {
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

/// Қате жауаптан кейінгі үйрету картасы: дұрыс жауап + түсіндірме.
class ExplanationCard extends StatelessWidget {
  const ExplanationCard({super.key, required this.correctAnswer, this.hint});

  final String correctAnswer;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.tintBlue,
        borderRadius: AppRadius.rLg,
        border: Border.all(
            color: AppColors.eagleBlue.withValues(alpha: .22), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.successJade),
              const SizedBox(width: AppSpacing.sp2),
              Expanded(
                child: Text(
                  '${AppStrings.answerCorrectLabel}: $correctAnswer',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.successJade,
                  ),
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.sp3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded,
                    size: 20, color: AppColors.steppeGoldDeep),
                const SizedBox(width: AppSpacing.sp2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.explanationLabel,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.steppeGoldDeep)),
                      const SizedBox(height: 2),
                      Text(hint!,
                          style: AppTypography.body.copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 240.ms).slideY(begin: .12);
  }
}
