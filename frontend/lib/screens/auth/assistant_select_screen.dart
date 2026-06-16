import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/avatar/avatar_selector.dart';
import '../../widgets/ui/app_button.dart';

/// Серік таңдау: Бектұр/Назым карталары → «Таңдадым» →
/// қош келдің сыйлығы модалы (100 монета) → Home.
class AssistantSelectScreen extends ConsumerStatefulWidget {
  const AssistantSelectScreen({super.key});

  @override
  ConsumerState<AssistantSelectScreen> createState() =>
      _AssistantSelectScreenState();
}

class _AssistantSelectScreenState
    extends ConsumerState<AssistantSelectScreen> {
  AssistantType? _selected;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).chooseAssistant(_selected!);
    if (!mounted) return;
    setState(() => _saving = false);
    await _WelcomeGiftModal.show(context);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(currentUserProvider)?.firstName ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sp4),
              Text('Қош келдің, $name! 🎉', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sp6),
              Text(AppStrings.assistantTitle, style: AppTypography.h1)
                  .animate()
                  .fadeIn()
                  .slideY(begin: .15),
              const SizedBox(height: AppSpacing.sp2),
              Text(AppStrings.assistantSubtitle,
                      style: AppTypography.bodySmall)
                  .animate()
                  .fadeIn(delay: 100.ms),
              const SizedBox(height: AppSpacing.sp6),
              AvatarSelector(
                selected: _selected,
                onSelect: (type) => setState(() => _selected = type),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: .1),
              const Spacer(),
              AppButton(
                label:
                    _saving ? AppStrings.loading : AppStrings.assistantPicked,
                onPressed:
                    _selected != null && !_saving ? _confirm : null,
              ),
              const SizedBox(height: AppSpacing.sp4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Қош келдің сыйлығы: 100 монета анимациясы.
class _WelcomeGiftModal extends StatefulWidget {
  const _WelcomeGiftModal();

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.nightInk.withValues(alpha: .55),
      builder: (_) => const _WelcomeGiftModal(),
    );
  }

  @override
  State<_WelcomeGiftModal> createState() => _WelcomeGiftModalState();
}

class _WelcomeGiftModalState extends State<_WelcomeGiftModal> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2))
      ..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sp6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.rXl,
              boxShadow: AppColors.sh4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldSoar,
                    shape: BoxShape.circle,
                    boxShadow: AppColors.goldGlow,
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      size: 44, color: AppColors.white),
                ).animate().scale(
                      begin: const Offset(0, 0),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: AppSpacing.sp4),
                Text(AppStrings.welcomeGiftTitle, style: AppTypography.h2),
                const SizedBox(height: AppSpacing.sp2),
                Text(
                  AppStrings.welcomeGiftDesc,
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sp3),
                Text(
                  '💰 +100',
                  style: AppTypography.numberDisplay
                      .copyWith(color: AppColors.steppeGoldDeep),
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .scale(
                      begin: const Offset(.5, .5),
                      delay: 300.ms,
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: AppSpacing.sp5),
                AppButton(
                  label: AppStrings.enterApp,
                  variant: AppButtonVariant.gold,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 20,
            gravity: .25,
            colors: const [
              AppColors.steppeGold,
              AppColors.goldBright,
              AppColors.eagleBlue,
              AppColors.cosmicPurple,
            ],
          ),
        ],
      ),
    );
  }
}
