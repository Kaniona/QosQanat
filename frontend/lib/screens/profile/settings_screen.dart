import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/mastery_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/demo_seeder.dart';
import '../../widgets/avatar/avatar_selector.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/reward_toast.dart';

/// Баптаулар: Жалпы / Хабарландырулар / Аккаунт / Қосымша туралы / Шығу.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Серікті 30 күнде бір рет қана ауыстыруға болады.
  static const _assistantCooldown = Duration(days: 30);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sp5,
          AppSpacing.sp3,
          AppSpacing.sp5,
          AppSpacing.sp8,
        ),
        children: [
          // ---- Жалпы ----
          const _SectionLabel(AppStrings.sectionGeneral),
          _SettingsGroup(children: [
            _ValueRow(
              icon: Icons.language_rounded,
              label: AppStrings.settingLanguage,
              trailing: _LanguageToggle(
                language: settings.language,
                onChanged: notifier.setLanguage,
              ),
            ),
            _SwitchRow(
              icon: Icons.volume_up_rounded,
              label: AppStrings.settingSound,
              value: settings.soundOn,
              onChanged: notifier.toggleSound,
            ),
            _SwitchRow(
              icon: Icons.vibration_rounded,
              label: AppStrings.settingVibration,
              value: settings.vibrationOn,
              onChanged: notifier.toggleVibration,
            ),
            _SwitchRow(
              icon: Icons.animation_rounded,
              label: AppStrings.settingAnimations,
              value: settings.animationsOn,
              onChanged: notifier.toggleAnimations,
            ),
          ]),

          // ---- Хабарландырулар ----
          const _SectionLabel(AppStrings.sectionNotifications),
          _SettingsGroup(children: [
            _SwitchRow(
              icon: Icons.notifications_rounded,
              label: AppStrings.settingNotifications,
              value: settings.notificationsOn,
              onChanged: notifier.toggleNotifications,
            ),
            _ValueRow(
              icon: Icons.alarm_rounded,
              label: AppStrings.settingReminder,
              trailing: Text(
                '${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')}',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.eagleBlue,
                ),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: settings.reminderHour,
                    minute: settings.reminderMinute,
                  ),
                );
                if (picked != null) {
                  await notifier.setReminderTime(picked.hour, picked.minute);
                }
              },
            ),
          ]),

          // ---- Аккаунт ----
          const _SectionLabel(AppStrings.sectionAccount),
          _SettingsGroup(children: [
            _ValueRow(
              icon: Icons.edit_rounded,
              label: AppStrings.settingEditProfile,
              onTap: () => _editProfile(context, ref),
            ),
            _ValueRow(
              icon: Icons.face_rounded,
              label: AppStrings.settingChangeAssistant,
              subtitle: AppStrings.assistantCooldown,
              onTap: () => _changeAssistant(context, ref),
            ),
            _ValueRow(
              icon: Icons.copy_rounded,
              label: AppStrings.settingCopyId,
              subtitle: user?.qosqanatId,
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: user?.qosqanatId ?? ''),
                );
                RewardToast.show(
                  context,
                  message: AppStrings.copied,
                  icon: Icons.copy_rounded,
                  color: AppColors.eagleBlue,
                );
              },
            ),
          ]),

          // ---- Қосымша туралы ----
          const _SectionLabel(AppStrings.sectionAbout),
          _SettingsGroup(children: [
            _ValueRow(
              icon: Icons.info_outline_rounded,
              label: AppStrings.settingVersion,
              trailing: Text('2.0.0', style: TextStyle(color: AppColors.inkSoft)),
            ),
            _ValueRow(
              icon: Icons.description_outlined,
              label: AppStrings.settingTerms,
              onTap: () => _comingSoon(context, AppStrings.settingTerms),
            ),
            _ValueRow(
              icon: Icons.privacy_tip_outlined,
              label: AppStrings.settingPrivacy,
              onTap: () => _comingSoon(context, AppStrings.settingPrivacy),
            ),
            _ValueRow(
              icon: Icons.support_agent_rounded,
              label: AppStrings.settingSupport,
              onTap: () => _comingSoon(context, AppStrings.settingSupport),
            ),
          ]),

          // ---- Демо/презентация (тек демо-аккаунтта көрінеді) ----
          if (user?.id == DemoSeeder.demoUserId) ...[
            const _SectionLabel('ПРЕЗЕНТАЦИЯ'),
            _SettingsGroup(children: [
              _ValueRow(
                icon: Icons.restart_alt_rounded,
                label: AppStrings.demoResetTitle,
                subtitle: AppStrings.demoResetHint,
                onTap: () => _resetDemo(context, ref),
              ),
            ]),
          ],
          const SizedBox(height: AppSpacing.sp5),

          // ---- Шығу ----
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerCoral,
                side:
                    const BorderSide(color: AppColors.dangerCoral, width: 2),
              ),
              onPressed: () => _confirmLogout(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(AppStrings.logout),
            ),
          ),
        ]
            .animate(interval: 55.ms)
            .fadeIn(duration: 280.ms)
            .slideY(begin: .05, curve: Curves.easeOutCubic),
      ),
    );
  }

  /// Демо прогресін қалпына келтіру + барлық оқу провайдерлерін жаңарту.
  Future<void> _resetDemo(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).resetDemo();
    ref.invalidate(masteryProvider);
    ref.invalidate(gameProvider); // HUD қайта есептелген XP/монетаны оқысын
    for (final s in CurriculumData.subjects) {
      ref.invalidate(taskProvider(s.id));
    }
    if (context.mounted) {
      RewardToast.show(
        context,
        message: AppStrings.demoResetDone,
        icon: Icons.restart_alt_rounded,
        color: AppColors.steppeGold,
      );
    }
  }

  static void _comingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.comingSoon(title))),
    );
  }

  /// Аты мен мектебін өзгерту диалогы.
  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final nameController = TextEditingController(text: user.fullName);
    final schoolController = TextEditingController(text: user.school);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.settingEditProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: AppStrings.fullNameLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.sp3),
            TextField(
              controller: schoolController,
              decoration: const InputDecoration(
                labelText: AppStrings.schoolLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.done),
          ),
        ],
      ),
    );

    if (saved == true && nameController.text.trim().isNotEmpty) {
      await ref.read(authProvider.notifier).updateUser(user.copyWith(
            fullName: nameController.text.trim(),
            school: schoolController.text.trim(),
          ));
      if (context.mounted) {
        RewardToast.show(context, message: AppStrings.profileUpdated);
      }
    }
    nameController.dispose();
    schoolController.dispose();
  }

  /// Серік ауыстыру (30 күндік cooldown).
  Future<void> _changeAssistant(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final changedAt = user.assistantChangedAt;
    if (changedAt != null) {
      final elapsed = DateTime.now().difference(changedAt);
      if (elapsed < _assistantCooldown) {
        final daysLeft = (_assistantCooldown - elapsed).inDays + 1;
        RewardToast.show(
          context,
          message: AppStrings.assistantCooldownLeft(daysLeft),
          icon: Icons.hourglass_top_rounded,
          color: AppColors.warningSunset,
        );
        return;
      }
    }

    var selected = user.assistantType;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sp6,
            0,
            AppSpacing.sp6,
            AppSpacing.sp6 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppStrings.assistantTitle, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sp4),
              AvatarSelector(
                selected: selected,
                onSelect: (type) => setSheetState(() => selected = type),
              ),
              const SizedBox(height: AppSpacing.sp5),
              AppButton(
                label: AppStrings.assistantPicked,
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && selected != user.assistantType) {
      await ref.read(authProvider.notifier).updateUser(user.copyWith(
            assistantType: selected,
            assistantChangedAt: DateTime.now(),
          ));
      if (context.mounted) {
        RewardToast.show(
          context,
          message: AppStrings.nowYourAssistant(
            selected == AssistantType.nazym
                ? AppStrings.nazymName
                : AppStrings.bekturName,
          ),
        );
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.logout,
              style:
                  AppTypography.button.copyWith(color: AppColors.dangerCoral),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sp2,
        AppSpacing.sp5,
        AppSpacing.sp2,
        AppSpacing.sp2,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.caption.copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rLg,
        boxShadow: AppColors.sh1,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 56, endIndent: AppSpacing.sp4),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ValueRow(
      icon: icon,
      label: label,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rLg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4,
          vertical: AppSpacing.sp2,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.tintBlue,
                borderRadius: AppRadius.rSm,
              ),
              child: Icon(icon, size: 20, color: AppColors.eagleBlue),
            ),
            const SizedBox(width: AppSpacing.sp3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 22),
          ],
        ),
      ),
    );
  }
}

/// QAZ / RUS қосқышы (бірінші нұсқада тек QAZ белсенді).
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.language, required this.onChanged});

  final String language;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: AppRadius.rFull,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final lang in const ['QAZ', 'RUS'])
            GestureDetector(
              onTap: () {
                if (lang == 'RUS') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.rusComingSoon),
                    ),
                  );
                  return;
                }
                onChanged(lang);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp3,
                  vertical: AppSpacing.sp1,
                ),
                decoration: BoxDecoration(
                  gradient: language == lang ? AppColors.eagleGrad : null,
                  borderRadius: AppRadius.rFull,
                ),
                child: Text(
                  lang,
                  style: AppTypography.caption.copyWith(
                    color: language == lang
                        ? AppColors.white
                        : AppColors.inkSoft,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
