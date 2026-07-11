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
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/avatar/avatar_base.dart';
import '../../widgets/avatar/avatar_selector.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/stat_label.dart';

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
              if (_selected != null) ...[
                _GreetingBubble(key: ValueKey(_selected), type: _selected!),
                const SizedBox(height: AppSpacing.sp4),
              ],
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

/// Таңдалған серіктің өз даусымен сәлемдесу көпіршігі — тұлға береді
/// («peak» сәті). Серік ауысқанда ValueKey арқылы қайта анимацияланады.
class _GreetingBubble extends StatelessWidget {
  const _GreetingBubble({super.key, required this.type});

  final AssistantType type;

  @override
  Widget build(BuildContext context) {
    final isNazym = type == AssistantType.nazym;
    final accent = isNazym ? AppColors.nazymRose : AppColors.eagleBlue;
    final greeting =
        isNazym ? AppStrings.nazymGreeting : AppStrings.bekturGreeting;
    final traits = isNazym
        ? const [AppStrings.nazymTrait1, AppStrings.nazymTrait2]
        : const [AppStrings.bekturTrait1, AppStrings.bekturTrait2];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: isNazym ? AppColors.tintRose : AppColors.tintBlue,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: accent.withValues(alpha: .35), width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: AppColors.sh1,
            ),
            child: AvatarBase(assistant: type, size: 40),
          ),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp2),
                Wrap(
                  spacing: AppSpacing.sp2,
                  runSpacing: AppSpacing.sp1,
                  children: [
                    for (final t in traits)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .14),
                          borderRadius: AppRadius.rFull,
                        ),
                        child: Text(
                          t,
                          style: AppTypography.caption.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms)
        .slideY(begin: .18, curve: Curves.easeOutCubic);
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
              color: AppColors.surface,
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
                StatLabel(
                  icon: AppIcons.coin,
                  text: '+100',
                  color: AppColors.steppeGoldDeep,
                  iconSize: 32,
                  gap: 6,
                  style: AppTypography.numberDisplay,
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
