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
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/app_input.dart';
import '../../widgets/ui/reward_toast.dart';

/// Құпиясөзді қалпына келтіру: телефон → OTP (offline mock код) →
/// жаңа құпиясөз → сәтті.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 0;
  bool _loading = false;
  String _otp = '';
  int _resendSeconds = 59;
  Timer? _timer;

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _sendCode() async {
    setState(() => _loading = true);
    final code = await ref
        .read(authProvider.notifier)
        .requestPasswordReset(_phoneController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (code == null) {
      RewardToast.show(
        context,
        message: AppStrings.userNotFound,
        icon: Icons.error_outline_rounded,
        color: AppColors.dangerCoral,
      );
      return;
    }
    setState(() => _step = 1);
    _startResendTimer();
    // Offline режім: SMS жоқ, кодты экранда көрсетеміз.
    RewardToast.show(
      context,
      message: 'Растау коды (offline): $code',
      icon: Icons.sms_rounded,
      color: AppColors.eagleBlue,
    );
  }

  void _verifyOtp() {
    if (ref.read(authProvider.notifier).verifyOtp(_otp)) {
      setState(() => _step = 2);
    } else {
      RewardToast.show(
        context,
        message: AppStrings.otpWrong,
        icon: Icons.error_outline_rounded,
        color: AppColors.dangerCoral,
      );
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _loading = true);
    final ok = await ref
        .read(authProvider.notifier)
        .resetPassword(_phoneController.text, _passwordController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) setState(() => _step = 3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              _step > 0 && _step < 3 ? setState(() => _step--) : context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          // Әр қадам ауысқанда тегіс кіреді (key — қадам нөмірі).
          child: (switch (_step) {
            0 => _buildPhoneStep(),
            1 => _buildOtpStep(),
            2 => _buildPasswordStep(),
            _ => _buildSuccessStep(),
          })
              .animate(key: ValueKey(_step))
              .fadeIn(duration: 300.ms)
              .slideX(begin: .06, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.forgotTitle, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sp2),
        Text(AppStrings.forgotSubtitle, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sp6),
        AppInput(
          controller: _phoneController,
          label: AppStrings.phoneLabel,
          hint: AppStrings.phoneHint,
          leadingIcon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sp8),
        AppButton(
          label: _loading ? AppStrings.loading : AppStrings.sendCode,
          onPressed:
              Validators.isValidPhone(_phoneController.text) && !_loading
                  ? _sendCode
                  : null,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.otpTitle, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sp2),
        Text(
          '${Formatters.maskedPhone(_phoneController.text)} нөміріне жіберілді.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sp8),
        OtpInput(onChanged: (v) => setState(() => _otp = v)),
        const SizedBox(height: AppSpacing.sp5),
        Center(
          child: _resendSeconds > 0
              ? Text(
                  '${AppStrings.otpResend} (${Formatters.timer(_resendSeconds)})',
                  style: AppTypography.caption,
                )
              : TextButton(
                  onPressed: _sendCode,
                  child: Text(
                    AppStrings.otpResend,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.eagleBlue, fontSize: 14),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.sp6),
        AppButton(
          label: AppStrings.verify,
          onPressed: Validators.isValidOtp(_otp) ? _verifyOtp : null,
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    final match = _confirmController.text.isNotEmpty &&
        _confirmController.text == _passwordController.text;
    final valid =
        Validators.isStrongPassword(_passwordController.text) && match;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.newPasswordLabel, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sp6),
        AppInput(
          controller: _passwordController,
          label: AppStrings.newPasswordLabel,
          leadingIcon: Icons.lock_rounded,
          obscure: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sp3),
        PasswordStrengthMeter(password: _passwordController.text),
        const SizedBox(height: AppSpacing.sp4),
        AppInput(
          controller: _confirmController,
          label: AppStrings.confirmPasswordLabel,
          leadingIcon: Icons.lock_rounded,
          obscure: true,
          success: match,
          errorText: _confirmController.text.isNotEmpty && !match
              ? AppStrings.passwordsMismatch
              : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sp8),
        AppButton(
          label: _loading ? AppStrings.loading : AppStrings.continueBtn,
          onPressed: valid && !_loading ? _resetPassword : null,
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sp12),
        Container(
          width: 108,
          height: 108,
          decoration: const BoxDecoration(
            gradient: AppColors.eagleGrad,
            shape: BoxShape.circle,
            boxShadow: AppColors.sh3,
          ),
          child: const Icon(Icons.check_rounded,
              size: 56, color: AppColors.white),
        ),
        const SizedBox(height: AppSpacing.sp6),
        Text(AppStrings.resetSuccess, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sp8),
        AppButton(
          label: AppStrings.loginBtn,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
