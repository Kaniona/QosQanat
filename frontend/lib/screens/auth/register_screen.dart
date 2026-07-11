import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ui/ambient_backdrop.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/app_input.dart';
import '../../widgets/ui/reward_toast.dart';

/// Тіркелу: 4 қадамды MultiStep форма (handoff §5.1 стилінде).
/// 1) аты-жөні/телефон/ЖСН 2) құпиясөз 3) қала/мектеп/сынып 4) растау.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 0;
  bool _loading = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _iinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _schoolController = TextEditingController();

  String? _city;
  int _grade = 7;
  bool _obscure = true;
  bool _agree1 = false;
  bool _agree2 = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _iinController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  bool get _step1Valid =>
      Validators.isValidFullName(_nameController.text) &&
      Validators.isValidPhone(_phoneController.text) &&
      Validators.isValidIin(_iinController.text);

  bool get _step2Valid =>
      Validators.isStrongPassword(_passwordController.text) &&
      _confirmController.text == _passwordController.text;

  bool get _step3Valid =>
      _city != null && _schoolController.text.trim().length >= 3;

  bool get _step4Valid => _agree1 && _agree2 && !_loading;

  bool get _currentStepValid => switch (_step) {
        0 => _step1Valid,
        1 => _step2Valid,
        2 => _step3Valid,
        _ => _step4Valid,
      };

  Future<void> _next() async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    setState(() => _loading = true);
    final ok = await ref.read(authProvider.notifier).register(
          fullName: _nameController.text,
          phone: _phoneController.text,
          iin: _iinController.text,
          password: _passwordController.text,
          city: _city!,
          school: _schoolController.text,
          grade: _grade,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.go('/assistant-select');
    } else {
      RewardToast.show(
        context,
        message: ref.read(authProvider).errorMessage ?? AppStrings.error,
        icon: Icons.error_outline_rounded,
        color: AppColors.dangerCoral,
      );
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
                // ---- Жоғарғы панель: артқа + 4 сегментті прогресс ----
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp4,
                vertical: AppSpacing.sp2,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: AppStrings.back,
                    onPressed: _back,
                    icon: const Icon(Icons.chevron_left_rounded, size: 30),
                  ),
                  const Spacer(),
                  for (var i = 0; i < 4; i++) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: i <= _step ? AppColors.eagleGrad : null,
                        color: i <= _step ? null : AppColors.border,
                        borderRadius: AppRadius.rFull,
                      ),
                    ),
                    if (i < 3) const SizedBox(width: AppSpacing.sp2),
                  ],
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(
                    begin: const Offset(.15, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: AppSpacing.screenPadding,
                  child: switch (_step) {
                    0 => _buildStep1(),
                    1 => _buildStep2(),
                    2 => _buildStep3(),
                    _ => _buildStep4(),
                  },
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.screenPadding,
              child: AppButton(
                label: _step < 3
                    ? AppStrings.continueBtn
                    : (_loading ? AppStrings.loading : AppStrings.registerBtn),
                onPressed: _currentStepValid ? _next : null,
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.step1Title, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sp2),
        Text(AppStrings.step1Subtitle, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sp6),
        AppInput(
          controller: _nameController,
          label: AppStrings.fullNameLabel,
          hint: AppStrings.fullNameHint,
          leadingIcon: Icons.person_rounded,
          success: Validators.isValidFullName(_nameController.text),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sp4),
        AppInput(
          controller: _phoneController,
          label: AppStrings.phoneLabel,
          hint: AppStrings.phoneHint,
          leadingIcon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          success: Validators.isValidPhone(_phoneController.text),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sp4),
        AppInput(
          controller: _iinController,
          label: AppStrings.iinLabel,
          hint: AppStrings.iinHint,
          leadingIcon: Icons.badge_rounded,
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          success: Validators.isValidIin(_iinController.text),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final match = _confirmController.text.isNotEmpty &&
        _confirmController.text == _passwordController.text;
    final mismatch = _confirmController.text.isNotEmpty && !match;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.step2Title, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sp2),
        Text(AppStrings.step2Subtitle, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sp6),
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
          errorText: mismatch ? AppStrings.passwordsMismatch : null,
          onChanged: (_) => setState(() {}),
        ),
        if (match)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sp1),
            child: Text(
              AppStrings.passwordsMatch,
              style: AppTypography.caption
                  .copyWith(color: AppColors.successJade),
            ),
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.step3Title, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sp2),
        Text(AppStrings.step3Subtitle, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sp6),
        Text(
          AppStrings.cityLabel,
          style: AppTypography.caption
              .copyWith(color: AppColors.inkSoft, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sp2),
        DropdownButtonFormField<String>(
          initialValue: _city,
          items: [
            for (final city in CurriculumData.cities)
              DropdownMenuItem(value: city, child: Text(city)),
          ],
          onChanged: (v) => setState(() => _city = v),
          style: AppTypography.body,
          hint: Text(
            AppStrings.choose,
            style: AppTypography.body.copyWith(color: AppColors.muted),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.location_city_rounded,
                color: AppColors.muted, size: 22),
          ),
        ),
        const SizedBox(height: AppSpacing.sp4),
        AppInput(
          controller: _schoolController,
          label: AppStrings.schoolLabel,
          hint: AppStrings.schoolHint,
          leadingIcon: Icons.school_rounded,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sp5),
        Text(
          AppStrings.gradeLabel,
          style: AppTypography.caption
              .copyWith(color: AppColors.inkSoft, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sp3),
        Wrap(
          spacing: AppSpacing.sp2,
          runSpacing: AppSpacing.sp2,
          children: [
            for (var g = 1; g <= 11; g++)
              GestureDetector(
                onTap: () => setState(() => _grade = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _grade == g ? AppColors.eagleGrad : null,
                    color: _grade == g ? null : AppColors.surface,
                    borderRadius: AppRadius.rSm,
                    border: Border.all(
                      color: _grade == g
                          ? Colors.transparent
                          : AppColors.border,
                      width: 1.5,
                    ),
                    boxShadow: _grade == g ? AppColors.sh2 : null,
                  ),
                  child: Center(
                    child: Text(
                      '$g',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _grade == g
                            ? AppColors.white
                            : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.step4Title, style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sp2),
        Text(AppStrings.step4Subtitle, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sp6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sp5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.rLg,
            boxShadow: AppColors.sh2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(
                label: AppStrings.fullNameLabel,
                value: _nameController.text,
              ),
              _SummaryRow(
                label: AppStrings.phoneLabel,
                value: Formatters.maskedPhone(_phoneController.text),
              ),
              _SummaryRow(
                label: 'ЖСН',
                value: Formatters.maskedIin(_iinController.text),
              ),
              _SummaryRow(
                label: AppStrings.passwordLabel,
                value: '•' * _passwordController.text.length,
              ),
              _SummaryRow(label: AppStrings.cityLabel, value: _city ?? ''),
              _SummaryRow(
                label: AppStrings.schoolLabel,
                value: _schoolController.text,
              ),
              _SummaryRow(
                label: AppStrings.gradeLabel,
                value: '$_grade-сынып',
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sp5),
        _AgreementCheck(
          value: _agree1,
          label: AppStrings.agreement1,
          onChanged: (v) => setState(() => _agree1 = v),
        ),
        _AgreementCheck(
          value: _agree2,
          label: AppStrings.agreement2,
          onChanged: (v) => setState(() => _agree2 = v),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.sp3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementCheck extends StatelessWidget {
  const _AgreementCheck({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: value ? AppColors.eagleGrad : null,
                color: value ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value ? Colors.transparent : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sp3),
            Expanded(
              child: Text(label, style: AppTypography.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
