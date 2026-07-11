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
import '../../data/curriculum.dart';
import '../../models/enums.dart';
import '../../models/task_node.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tournament_provider.dart';
import '../../widgets/game/answer_tile.dart';

/// Турнир раунды — аралас пәндік викторина. Соңында оқушы детерминистік
/// кестеде орналасады әрі орнына сай жүлде алады.
class TournamentPlayScreen extends ConsumerStatefulWidget {
  const TournamentPlayScreen({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TournamentPlayScreen> createState() =>
      _TournamentPlayScreenState();
}

class _TournamentPlayScreenState extends ConsumerState<TournamentPlayScreen> {
  late final List<Question> _questions = _build();
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _answered = false;
  bool _finishing = false;

  List<Question> _build() {
    final grade = ref.read(currentUserProvider)?.grade ?? 5;
    final out = <Question>[];
    for (final subject in ['math', 'kazakh', 'english', 'physics', 'cs']) {
      final nodes = Curriculum.nodesForGrade(subject, grade);
      if (nodes.isEmpty) continue;
      final qs = Curriculum.sessionQuestions(nodes.first)
          .where((q) => q.type != QuestionType.matchPairs)
          .toList();
      for (final i in [3, 8]) {
        if (i < qs.length) out.add(qs[i]);
      }
    }
    return out;
  }

  Question get _q => _questions[_index];

  Future<void> _answer(int option) async {
    if (_answered || _finishing) return;
    final correct = option == _q.correctIndex;
    if (correct) {
      AppHaptics.select();
      AppSounds.correct();
    } else {
      AppHaptics.heavy();
      AppSounds.wrong();
    }
    setState(() {
      _selected = option;
      _answered = true;
      if (correct) _correct++;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (_index + 1 >= _questions.length) {
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
    setState(() => _finishing = true);
    final result = await ref.read(tournamentProvider.notifier).play(
          widget.tournamentId,
          correct: _correct,
          total: _questions.length,
        );
    if (!mounted) return;
    context.pushReplacement('/tournament/result', extra: result);
  }

  AnswerState _stateFor(int i) {
    if (!_answered) return AnswerState.idle;
    if (i == _q.correctIndex) return AnswerState.correct;
    if (i == _selected) return AnswerState.wrong;
    return AnswerState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.tournamentPlayTitle)),
        body: Center(child: Text(AppStrings.error, style: AppTypography.body)),
      );
    }
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
                                  _questions.length,
                              child: Container(
                                decoration: const BoxDecoration(
                                    gradient: AppColors.heroGold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp3),
                  const Icon(Icons.emoji_events_rounded,
                      size: 22, color: AppColors.steppeGold),
                ],
              ),
              const SizedBox(height: AppSpacing.sp2),
              Text(
                '${AppStrings.tournamentRound} · ${_index + 1}/${_questions.length}',
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
                child: Text(_q.text,
                    style: AppTypography.h3.copyWith(height: 1.4)),
              ).animate(key: ValueKey('tq$_index')).fadeIn().slideX(begin: .06),
              const SizedBox(height: AppSpacing.sp5),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < _q.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sp3),
                        child: AnswerButton(
                          key: ValueKey('ta$_index$i'),
                          text: _q.options[i],
                          state: _stateFor(i),
                          onTap: () => _answer(i),
                        ),
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
}
