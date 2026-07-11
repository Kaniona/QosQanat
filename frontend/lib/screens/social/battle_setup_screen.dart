import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/curriculum_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/user.dart';
import '../../providers/battle_provider.dart';
import '../../providers/friends_provider.dart';
import '../../widgets/ui/app_button.dart';
import '../../widgets/ui/user_photo.dart';

/// Батл баптауы: қарсылас картасы + сұрақ саны + пән фильтрі.
/// Қарсылас extra арқылы келеді; келмесе — соңғы дос таңдалады.
class BattleSetupScreen extends ConsumerStatefulWidget {
  const BattleSetupScreen({super.key});

  @override
  ConsumerState<BattleSetupScreen> createState() => _BattleSetupScreenState();
}

class _BattleSetupScreenState extends ConsumerState<BattleSetupScreen> {
  static const _counts = [15, 20, 25, 40, 50];

  int _questionCount = 20;
  String _subject = 'all';
  User? _opponent;
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _opponent ??= GoRouterState.of(context).extra as User?;
  }

  Future<void> _start(User opponent) async {
    if (_starting) return;
    setState(() => _starting = true);
    await ref.read(battleProvider.notifier).createBattle(
          opponent: opponent,
          questionCount: _questionCount,
          subject: _subject,
        );
    if (mounted) context.pushReplacement('/battle');
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider.select((s) => s.friends));
    final opponent = _opponent ?? (friends.isNotEmpty ? friends.first : null);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.battleSetupTitle)),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Қарсылас картасы ----
              if (opponent == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sp5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.rLg,
                    boxShadow: AppColors.sh1,
                  ),
                  child: Text(
                    AppStrings.noFriends,
                    style: AppTypography.bodySmall,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sp4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.rLg,
                    border: Border.all(color: AppColors.eagleBlue, width: 2),
                    boxShadow: AppColors.sh2,
                  ),
                  child: Row(
                    children: [
                      UserPhoto(
                        photoPath: opponent.profilePhotoPath,
                        size: 56,
                      ),
                      const SizedBox(width: AppSpacing.sp3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opponent.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${opponent.level} LVL · ★ ${Formatters.number(opponent.akylPoints)}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const Text('⚔️', style: TextStyle(fontSize: 28)),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: .08),
              const SizedBox(height: AppSpacing.sp6),

              // ---- Сұрақ саны ----
              Text(AppStrings.questionCount, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sp3),
              Wrap(
                spacing: AppSpacing.sp2,
                children: [
                  for (final count in _counts)
                    _Pill(
                      label: '$count',
                      active: count == _questionCount,
                      onTap: () => setState(() => _questionCount = count),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp6),

              // ---- Пән фильтрі ----
              Text(AppStrings.subjectFilter, style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sp3),
              Wrap(
                spacing: AppSpacing.sp2,
                runSpacing: AppSpacing.sp2,
                children: [
                  _Pill(
                    label: AppStrings.allSubjects,
                    active: _subject == 'all',
                    onTap: () => setState(() => _subject = 'all'),
                  ),
                  for (final subject in CurriculumData.subjects)
                    _Pill(
                      label: subject.title,
                      active: _subject == subject.id,
                      onTap: () => setState(() => _subject = subject.id),
                    ),
                ],
              ),
              const Spacer(),
              AppButton(
                label: _starting ? AppStrings.loading : AppStrings.startBattle,
                variant: AppButtonVariant.gold,
                onPressed: opponent == null || _starting
                    ? null
                    : () => _start(opponent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4,
          vertical: AppSpacing.sp2,
        ),
        decoration: BoxDecoration(
          gradient: active ? AppColors.eagleGrad : null,
          color: active ? null : AppColors.surface,
          borderRadius: AppRadius.rFull,
          border: active
              ? null
              : Border.all(color: AppColors.border, width: 1.5),
          boxShadow: active ? AppColors.sh2 : null,
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w800,
            color: active ? AppColors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
