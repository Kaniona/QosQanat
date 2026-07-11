import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_sounds.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/battle_provider.dart';
import '../../providers/game_provider.dart';
import '../../widgets/avatar/avatar_display.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/stat_label.dart';
import '../../widgets/ui/level_up_modal.dart';

/// Батл нәтижесі: ЖЕҢІС (конфетти) немесе жігерлендіру, ұпайлар,
/// дәлдік %, марапаттар, «Қайта батл» / «Басты бетке».
class BattleResultScreen extends ConsumerStatefulWidget {
  const BattleResultScreen({super.key});

  @override
  ConsumerState<BattleResultScreen> createState() =>
      _BattleResultScreenState();
}

class _BattleResultScreenState extends ConsumerState<BattleResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    final battle = ref.read(battleProvider).battle;
    if (battle?.result == BattleResult.win) {
      _confetti.play();
      AppSounds.win();
    } else {
      AppSounds.lose();
    }

    // Батл XP-і деңгей көтерсе — модал.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = ref.read(gameProvider).pendingLevelUp;
      if (pending != null && mounted) {
        LevelUpModal.show(context, pending);
        ref.read(gameProvider.notifier).consumeLevelUp();
      }
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  void _rebattle() {
    final battle = ref.read(battleProvider).battle;
    if (battle == null) return;
    final opponent = ref.read(storageProvider).getUser(battle.opponentId);
    ref.read(battleProvider.notifier).reset();
    if (opponent != null) {
      context.pushReplacement('/battle-setup', extra: opponent);
    } else {
      context.go('/home');
    }
  }

  void _goHome() {
    ref.read(battleProvider.notifier).reset();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(battleProvider);
    final battle = state.battle;
    final user = ref.watch(currentUserProvider);

    if (battle == null) {
      return Scaffold(
        body: Center(
          child: Text(AppStrings.error, style: AppTypography.body),
        ),
      );
    }

    final won = battle.result == BattleResult.win;
    final draw = battle.result == BattleResult.draw;
    final total = battle.questions.length;
    final accuracy =
        total == 0 ? 0 : (battle.myScore * 100 / total).round();

    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          SafeArea(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    won
                        ? AppStrings.battleWin
                        : (draw
                            ? AppStrings.battleDraw
                            : AppStrings.battleLose),
                    style: AppTypography.h1.copyWith(
                      color: won
                          ? AppColors.steppeGoldDeep
                          : AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().slideY(begin: .2),
                  const SizedBox(height: AppSpacing.sp6),

                  // ---- Ұпайлар: сен vs қарсылас ----
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sp5),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.rLg,
                      boxShadow: AppColors.sh2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ScoreColumn(
                            name: AppStrings.you,
                            score: battle.myScore,
                            accent: AppColors.eagleBlue,
                            highlight: won,
                          ),
                        ),
                        Text(
                          ':',
                          style: AppTypography.numberDisplay
                              .copyWith(color: AppColors.muted),
                        ),
                        Expanded(
                          child: _ScoreColumn(
                            name: battle.opponentName,
                            score: battle.opponentScore,
                            accent: AppColors.dangerCoral,
                            highlight: battle.result == BattleResult.lose,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: .12),
                  const SizedBox(height: AppSpacing.sp4),
                  Text(
                    '${AppStrings.accuracy}: $accuracy%',
                    style:
                        AppTypography.h3.copyWith(color: AppColors.eagleBlue),
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: AppSpacing.sp5),

                  // ---- Марапаттар ----
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp6,
                      vertical: AppSpacing.sp4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tintGold,
                      borderRadius: AppRadius.rLg,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RewardChip(
                            icon: AppIcons.xp,
                            text: '+${state.rewardXp}',
                            color: AppColors.eagleBlue),
                        const SizedBox(width: AppSpacing.sp4),
                        _RewardChip(
                            icon: AppIcons.coin,
                            text: '+${state.rewardCoins}',
                            color: AppColors.steppeGoldDeep),
                        const SizedBox(width: AppSpacing.sp4),
                        _RewardChip(
                            icon: AppIcons.akyl,
                            text: '+${state.rewardAkyl}',
                            color: AppColors.cosmicPurple),
                      ],
                    ),
                  ).animate().fadeIn(delay: 650.ms).slideY(begin: .15),

                  // ---- Шеберлік бонустары (комбо / мінсіз ойын) ----
                  if (state.maxCombo >= 3 || state.perfect) ...[
                    const SizedBox(height: AppSpacing.sp3),
                    Wrap(
                      spacing: AppSpacing.sp2,
                      runSpacing: AppSpacing.sp2,
                      alignment: WrapAlignment.center,
                      children: [
                        if (state.maxCombo >= 3)
                          _BonusPill(
                            text: '🔥 ${state.maxCombo}× комбо · '
                                '+${state.comboBonus} ақыл',
                            color: AppColors.warningSunset,
                          ),
                        if (state.perfect)
                          _BonusPill(
                            text: '⭐ Мінсіз ойын! +40 монета',
                            color: AppColors.successJade,
                          ),
                      ],
                    ).animate().fadeIn(delay: 720.ms),
                  ],
                  const Spacer(),
                  AvatarDisplay(
                    assistant: user?.assistantType ?? AssistantType.bektur,
                    mood: won ? AvatarMood.celebrate : AvatarMood.sad,
                    size: 110,
                  ),
                  const Spacer(),
                  AppButton(
                    label: AppStrings.rebattle,
                    variant: AppButtonVariant.gold,
                    icon: Icons.replay_rounded,
                    onPressed: _rebattle,
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: AppSpacing.sp3),
                  AppButton(
                    label: AppStrings.toHome,
                    variant: AppButtonVariant.secondary,
                    onPressed: _goHome,
                  ),
                ],
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            maxBlastForce: 20,
            gravity: .22,
            colors: const [
              AppColors.steppeGold,
              AppColors.goldBright,
              AppColors.eagleBlue,
              AppColors.cosmicPurple,
              AppColors.successJade,
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({
    required this.name,
    required this.score,
    required this.accent,
    required this.highlight,
  });

  final String name;
  final int score;
  final Color accent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$score',
          style: AppTypography.numberDisplay.copyWith(
            color: highlight ? accent : AppColors.ink,
          ),
        ),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return StatLabel(
      icon: icon,
      text: text,
      color: color,
      iconSize: 18,
      gap: 4,
      style: AppTypography.body,
    );
  }
}

/// Шеберлік бонусының белгісі (комбо / мінсіз ойын).
class _BonusPill extends StatelessWidget {
  const _BonusPill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sp3, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: AppRadius.rFull,
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        text,
        style: AppTypography.caption
            .copyWith(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}
