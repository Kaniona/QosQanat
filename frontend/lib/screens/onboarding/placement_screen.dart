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
import '../../providers/mastery_provider.dart';
import '../../widgets/avatar/avatar_display.dart';
import '../../widgets/game/answer_tile.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/panels.dart';

/// Орналастыру диагностикасы — бала алғаш кіргенде деңгейін табады. Әр пәннен
/// бірнеше сұрақ; жауаптар mastery движогіне беріледі, сонда коуч пен карта
/// БІРДЕН жекеленеді. Жүрек/жаза жоқ — бұл тест емес, танысу.
class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  late final List<({Question question, String nodeId})> _cards = _buildCards();

  bool _started = false;
  bool _finished = false;
  bool _recorded = false;
  int _index = 0;
  int? _selected;
  bool _answered = false;
  final List<SessionAnswer> _answers = [];

  /// Оқушы сыныбындағы 5 пәннен ~2 сұрақтан (жеңіл + қиындау).
  List<({Question question, String nodeId})> _buildCards() {
    final grade = ref.read(currentUserProvider)?.grade ?? 5;
    final out = <({Question question, String nodeId})>[];
    for (final subject in ['math', 'kazakh', 'english', 'physics', 'cs']) {
      final nodes = Curriculum.nodesForGrade(subject, grade);
      if (nodes.isEmpty) continue;
      final node = nodes.first;
      final qs = Curriculum.sessionQuestions(node)
          .where((q) => q.type != QuestionType.matchPairs)
          .toList();
      for (final i in [2, 7]) {
        if (i < qs.length) out.add((question: qs[i], nodeId: node.id));
      }
    }
    return out;
  }

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
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
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
      final uid = ref.read(currentUserProvider)?.id;
      if (uid != null) {
        await ref.read(storageProvider).setPlacementDone(uid);
      }
    }
    if (!mounted) return;
    setState(() => _finished = true);
  }

  Future<void> _skip() async {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid != null) await ref.read(storageProvider).setPlacementDone(uid);
    if (mounted) context.go('/home');
  }

  AnswerState _stateFor(int i) {
    if (!_answered) return AnswerState.idle;
    if (i == _question.correctIndex) return AnswerState.correct;
    if (i == _selected) return AnswerState.wrong;
    return AnswerState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final assistant = user?.assistantType ?? AssistantType.bektur;

    if (_cards.isEmpty) {
      // Сұрақ табылмаса — өткізіп жібереміз.
      WidgetsBinding.instance.addPostFrameCallback((_) => _skip());
      return const Scaffold();
    }

    if (!_started) {
      return _IntroOutro(
        assistant: assistant,
        title: AppStrings.placementTitle,
        subtitle: AppStrings.placementIntro,
        primaryLabel: AppStrings.placementStart,
        onPrimary: () => setState(() => _started = true),
        secondaryLabel: AppStrings.placementSkip,
        onSecondary: _skip,
      );
    }

    if (_finished) {
      return _IntroOutro(
        assistant: assistant,
        mood: AvatarMood.celebrate,
        title: AppStrings.placementDoneTitle,
        subtitle: AppStrings.placementDoneSub,
        primaryLabel: AppStrings.done,
        onPrimary: () => context.go('/home'),
      );
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
              const SizedBox(height: AppSpacing.sp4),
              ClipRRect(
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
                          decoration:
                              const BoxDecoration(gradient: AppColors.eagleGrad),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sp2),
              Text('${AppStrings.placementTitle} · ${_index + 1}/${_cards.length}',
                  style: AppTypography.caption),
              const SizedBox(height: AppSpacing.sp4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sp5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.rLg,
                  boxShadow: AppColors.sh2,
                ),
                child: Text(_question.text,
                    style: AppTypography.h3.copyWith(height: 1.4)),
              ).animate(key: ValueKey('pq$_index')).fadeIn().slideX(begin: .06),
              const SizedBox(height: AppSpacing.sp5),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < _question.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sp3),
                        child: AnswerButton(
                          key: ValueKey('pa$_index$i'),
                          text: _question.options[i],
                          state: _stateFor(i),
                          onTap: () => _answer(i),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: 96,
                child: AvatarDisplay(
                    assistant: assistant, mood: mood, size: 80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Кіріспе/қорытынды экраны (маскот + тақырып + батырмалар).
class _IntroOutro extends StatelessWidget {
  const _IntroOutro({
    required this.assistant,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.mood = AvatarMood.idle,
  });

  final AssistantType assistant;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final AvatarMood mood;

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
              Center(
                child: AvatarDisplay(assistant: assistant, mood: mood, size: 140),
              ),
              const SizedBox(height: AppSpacing.sp5),
              Text(title, textAlign: TextAlign.center, style: AppTypography.h1),
              const SizedBox(height: AppSpacing.sp3),
              PanelCard(
                child: Text(subtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(height: 1.5)),
              ),
              const SizedBox(height: AppSpacing.sp6),
              AppButton(label: primaryLabel, onPressed: onPrimary),
              if (secondaryLabel != null) ...[
                const SizedBox(height: AppSpacing.sp2),
                AppButton(
                  label: secondaryLabel!,
                  variant: AppButtonVariant.text,
                  onPressed: onSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
