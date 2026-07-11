import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/validators.dart';

/// Стандартты енгізу өрісі: биіктік 56, радиус 16, фокус көк жарқыл.
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.leadingIcon,
    this.trailing,
    this.obscure = false,
    this.errorText,
    this.success = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.maxLength,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? leadingIcon;
  final Widget? trailing;
  final bool obscure;
  final String? errorText;
  final bool success;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final borderColor = errorText != null
        ? AppColors.dangerCoral
        : (success ? AppColors.successJade : null);

    OutlineInputBorder? overrideBorder(Color? color) => color == null
        ? null
        : OutlineInputBorder(
            borderRadius: AppRadius.rMd,
            borderSide: BorderSide(color: color, width: 1.5),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSoft,
                fontSize: 13,
              )),
          const SizedBox(height: AppSpacing.sp2),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          maxLength: maxLength,
          autofocus: autofocus,
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: leadingIcon != null
                ? Icon(leadingIcon, color: AppColors.muted, size: 22)
                : null,
            suffixIcon: trailing ??
                (success
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.successJade, size: 22)
                    : null),
            enabledBorder: overrideBorder(borderColor),
            focusedBorder: overrideBorder(borderColor),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sp1),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.dangerCoral),
              const SizedBox(width: AppSpacing.sp1),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.dangerCoral),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Құпиясөз күші индикаторы: 3 сегмент + талаптар тізімі (handoff §3).
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  final String password;
  final bool showRequirements;

  @override
  Widget build(BuildContext context) {
    final score = Validators.passwordScore(password);
    final colors = switch (score) {
      0 => [AppColors.border, AppColors.border, AppColors.border],
      1 => [AppColors.dangerCoral, AppColors.border, AppColors.border],
      2 => [AppColors.warningSunset, AppColors.warningSunset, AppColors.border],
      _ => const [AppColors.successJade, AppColors.successJade, AppColors.successJade],
    };
    final label = switch (score) {
      1 => AppStrings.passwordWeak,
      2 => AppStrings.passwordMedium,
      3 => AppStrings.passwordStrong,
      _ => '',
    };
    final labelColor = switch (score) {
      1 => AppColors.dangerCoral,
      2 => AppColors.warningSunset,
      3 => AppColors.successJade,
      _ => AppColors.muted,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: AppRadius.rFull,
                  ),
                ),
              ),
              if (i < 2) const SizedBox(width: AppSpacing.sp2),
            ],
            if (label.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sp3),
              Text(label,
                  style: AppTypography.caption.copyWith(color: labelColor)),
            ],
          ],
        ),
        if (showRequirements) ...[
          const SizedBox(height: AppSpacing.sp3),
          _Requirement(
            label: AppStrings.passwordRule1,
            met: Validators.hasMinLength(password),
          ),
          _Requirement(
            label: AppStrings.passwordRule2,
            met: Validators.hasDigit(password),
          ),
          _Requirement(
            label: AppStrings.passwordRule3,
            met: Validators.hasUppercase(password),
          ),
        ],
      ],
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp1),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? AppColors.successJade : AppColors.border,
            ),
            child: met
                ? const Icon(Icons.check_rounded,
                    size: 12, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.sp2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: met ? AppColors.successJade : AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// OTP енгізу: 4 шаршы ұяшық, авто-алға жылжу (handoff §3).
class OtpInput extends StatefulWidget {
  const OtpInput({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _nodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onDigit(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    widget.onChanged(_controllers.map((c) => c.text).join());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sp3),
          SizedBox(
            width: AppSizes.otpBox,
            height: AppSizes.otpBox,
            child: TextField(
              controller: _controllers[i],
              focusNode: _nodes[i],
              autofocus: i == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTypography.numberDisplay.copyWith(fontSize: 28),
              onChanged: (v) => _onDigit(i, v),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: _controllers[i].text.isNotEmpty
                    ? AppColors.tintBlue
                    : AppColors.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.rMd,
                  borderSide: BorderSide(
                    color: _controllers[i].text.isNotEmpty
                        ? AppColors.eagleBlue
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.rMd,
                  borderSide:
                      const BorderSide(color: AppColors.eagleBlue, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
