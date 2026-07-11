import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../widgets/ui/ambient_backdrop.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/app_input.dart';
import '../../widgets/ui/reward_toast.dart';

/// Кіру: телефон + құпиясөз (offline — формат қана тексеріледі).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      Validators.isValidPhone(_phoneController.text) &&
      _passwordController.text.isNotEmpty &&
      !_loading;

  Future<void> _login() async {
    setState(() => _loading = true);
    final ok = await ref
        .read(authProvider.notifier)
        .login(_phoneController.text, _passwordController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      await ref.read(gameProvider.notifier).checkStreak();
      if (mounted) context.go('/home');
    } else {
      final error =
          ref.read(authProvider).errorMessage ?? AppStrings.loginError;
      RewardToast.show(
        context,
        message: error,
        icon: Icons.error_outline_rounded,
        color: AppColors.dangerCoral,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Stack(
        children: [
          const AmbientBackdrop(
            colors: [
              AppColors.eagleBlue,
              AppColors.cosmicPurple,
              AppColors.steppeGold,
            ],
            opacity: .10,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.loginTitle, style: AppTypography.h1)
                  .animate()
                  .fadeIn(duration: 320.ms)
                  .slideY(begin: .12, curve: Curves.easeOutCubic),
              const SizedBox(height: AppSpacing.sp2),
              Text(AppStrings.loginSubtitle, style: AppTypography.bodySmall)
                  .animate()
                  .fadeIn(delay: 70.ms, duration: 320.ms)
                  .slideY(begin: .12, curve: Curves.easeOutCubic),
              const SizedBox(height: AppSpacing.sp8),
              AppInput(
                controller: _phoneController,
                label: AppStrings.phoneLabel,
                hint: AppStrings.phoneHint,
                leadingIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                onChanged: (_) => setState(() {}),
              ).animate().fadeIn(delay: 140.ms, duration: 320.ms).slideY(
                  begin: .1, curve: Curves.easeOutCubic),
              const SizedBox(height: AppSpacing.sp4),
              AppInput(
                controller: _passwordController,
                label: AppStrings.passwordLabel,
                hint: AppStrings.passwordHint,
                leadingIcon: Icons.lock_rounded,
                obscure: _obscure,
                onChanged: (_) => setState(() {}),
                trailing: IconButton(
                  tooltip: _obscure
                      ? AppStrings.a11yShowPassword
                      : AppStrings.a11yHidePassword,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppColors.muted,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ).animate().fadeIn(delay: 210.ms, duration: 320.ms).slideY(
                  begin: .1, curve: Curves.easeOutCubic),
              const SizedBox(height: AppSpacing.sp3),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                    AppStrings.forgotPassword,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.eagleBlue, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sp6),
              AppButton(
                label: _loading ? AppStrings.loading : AppStrings.loginBtn,
                onPressed: _canSubmit ? _login : null,
              ).animate().fadeIn(delay: 280.ms, duration: 320.ms).slideY(
                  begin: .14, curve: Curves.easeOutBack),
              const SizedBox(height: AppSpacing.sp4),
              Center(
                child: TextButton(
                  onPressed: () {
                    context.pop();
                    context.push('/register');
                  },
                  child: Text(
                    AppStrings.noAccount,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.eagleBlue),
                  ),
                ),
              ).animate().fadeIn(delay: 360.ms, duration: 320.ms),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}
