import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/achievements.dart';
import '../../models/battle.dart';
import '../../models/enums.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/battle_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shop_provider.dart';
import '../../services/image_picker_service.dart';
import '../../widgets/avatar/avatar_display.dart';
import '../../widgets/game/xp_bar.dart';
import '../../widgets/ui/reward_toast.dart';
import '../../widgets/ui/user_photo.dart';

/// Профиль: hero (маскот + сурет + камера) → статистика → жетістіктер →
/// белсенділік heatmap → соңғы батлдар → шығу.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final result = await ImagePickerService.instance.pickProfilePhoto(
      user.id,
      previousPath: user.profilePhotoPath,
    );
    switch (result.status) {
      case PickPhotoStatus.cancelled:
        return;
      case PickPhotoStatus.failed:
        if (context.mounted) {
          RewardToast.show(context, message: AppStrings.photoFailed);
        }
      case PickPhotoStatus.success:
        await ref
            .read(authProvider.notifier)
            .updateUser(user.copyWith(profilePhotoPath: result.path));
        if (context.mounted) {
          RewardToast.show(context, message: AppStrings.photoUpdated);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final game = ref.watch(gameProvider);
    final unlocked =
        ref.watch(achievementProvider.select((s) => s.unlockedIds));
    final friendsCount =
        ref.watch(friendsProvider.select((s) => s.friends.length));
    final battles = ref.watch(recentBattlesProvider);
    final animationsOn =
        ref.watch(settingsProvider.select((s) => s.animationsOn));
    ref.watch(shopProvider); // киім ауысқанда қайта салу
    final equipped = ref.read(shopProvider.notifier).equippedItems;

    if (user == null) {
      return Center(
        child: Text(AppStrings.loading, style: AppTypography.body),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sp5,
        AppSpacing.sp4,
        AppSpacing.sp5,
        AppSpacing.sp12,
      ),
      children: [
        // ---- Header жолы ----
        Row(
          children: [
            Text(AppStrings.profileTitle, style: AppTypography.h1),
            const Spacer(),
            IconButton(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_rounded,
                  color: AppColors.slate),
            ),
          ],
        ),

        // ---- Hero: маскот + сурет + камера ----
        Center(
          child: Column(
            children: [
              // Барлық элемент Stack ШЕГІНДЕ тұруы маңызды: шекарадан тыс
              // Positioned элементтер көрінгенімен басылмайды (hit-test).
              SizedBox(
                width: 150 + 54,
                height: 154,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      child: AvatarDisplay(
                        assistant: user.assistantType,
                        size: 150,
                        equipped: equipped,
                        animationsOn: animationsOn,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _pickPhoto(context, ref),
                        child: SizedBox(
                          width: 76,
                          height: 76,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: UserPhoto(
                                  photoPath: user.profilePhotoPath,
                                  size: 64,
                                  ringWidth: 2.5,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    gradient: AppColors.eagleGrad,
                                    shape: BoxShape.circle,
                                    boxShadow: AppColors.sh2,
                                  ),
                                  child: const Icon(
                                      Icons.photo_camera_rounded,
                                      size: 15,
                                      color: AppColors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sp3),
              Text(user.fullName, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sp2),
              // QQ-ID pill (көшіру)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: user.qosqanatId));
                  RewardToast.show(
                    context,
                    message: AppStrings.copied,
                    icon: Icons.copy_rounded,
                    color: AppColors.eagleBlue,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp3,
                    vertical: AppSpacing.sp1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.eagleBlueLight,
                    borderRadius: AppRadius.rFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.qosqanatId,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.eagleBlue,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sp1),
                      const Icon(Icons.copy_rounded,
                          size: 13, color: AppColors.eagleBlue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms),
        const SizedBox(height: AppSpacing.sp5),

        // ---- Деңгей + XP жолағы ----
        Container(
          padding: const EdgeInsets.all(AppSpacing.sp4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.rLg,
            boxShadow: AppColors.sh1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp3,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldSoar,
                      borderRadius: AppRadius.rFull,
                    ),
                    child: Text(
                      '${game.level} LVL',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '🔥 ${game.currentStreak} күн',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.warningSunset),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp3),
              XpBar(
                progress: game.levelProgress,
                xpIntoLevel: game.xpIntoLevel,
                xpForNextLevel: game.xpForNextLevel,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sp4),

        // ---- 2x3 статистика торы ----
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sp2,
          crossAxisSpacing: AppSpacing.sp2,
          childAspectRatio: 1.35,
          children: [
            _StatCard(
              icon: '★',
              value: Formatters.number(game.akylPoints),
              label: AppStrings.statAkyl,
              color: AppColors.cosmicPurple,
            ),
            _StatCard(
              icon: '💰',
              value: Formatters.number(game.coins),
              label: AppStrings.statCoins,
              color: AppColors.steppeGoldDeep,
            ),
            _StatCard(
              icon: '👥',
              value: '$friendsCount',
              label: AppStrings.statFriends,
              color: AppColors.eagleBlue,
            ),
            _StatCard(
              icon: '🔥',
              value: '${game.currentStreak}',
              label: AppStrings.statStreak,
              color: AppColors.warningSunset,
            ),
            _StatCard(
              icon: '✓',
              value: '${user.tasksCompleted}',
              label: AppStrings.statTasks,
              color: AppColors.successJade,
            ),
            _StatCard(
              icon: '⚔️',
              value: '${user.battlesWon}/${user.battlesTotal}',
              label: AppStrings.statBattles,
              color: AppColors.dangerCoral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp6),

        // ---- Жетістіктер ----
        Row(
          children: [
            Text(AppStrings.achievements, style: AppTypography.h3),
            const Spacer(),
            Text(
              '${unlocked.length}/${AchievementsData.all.length} ${AppStrings.unlockedOf}',
              style: AppTypography.caption,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp3),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sp2,
          crossAxisSpacing: AppSpacing.sp2,
          childAspectRatio: 1.05,
          children: [
            for (final ach in AchievementsData.all)
              _AchievementTile(
                icon: ach.icon,
                title: ach.title,
                description: ach.description,
                unlocked: unlocked.contains(ach.id),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp6),

        // ---- Белсенділік heatmap (4 апта) ----
        Text(AppStrings.activity, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sp3),
        _ActivityHeatmap(activityDays: user.activityDays.toSet()),
        const SizedBox(height: AppSpacing.sp6),

        // ---- Соңғы батлдар ----
        if (battles.isNotEmpty) ...[
          Text(AppStrings.recentBattles, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sp3),
          for (final battle in battles)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sp2),
              child: _BattleRow(battle: battle),
            ),
          const SizedBox(height: AppSpacing.sp4),
        ],

        // ---- Шығу ----
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dangerCoral,
              side: const BorderSide(color: AppColors.dangerCoral, width: 2),
            ),
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(AppStrings.logout),
          ),
        ),
      ],
    );
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final String icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.rMd,
        boxShadow: AppColors.sh1,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String icon;
  final String title;
  final String description;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: description,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sp2),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.steppeGoldLight : AppColors.white,
          borderRadius: AppRadius.rMd,
          border: Border.all(
            color: unlocked ? AppColors.steppeGold : AppColors.cloudBorder,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: unlocked ? 1 : .35,
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: AppSpacing.sp1),
            Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: unlocked ? AppColors.nightInk : AppColors.mist,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// GitHub стиліндегі 4 апталық белсенділік торы (7x4).
class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.activityDays});

  final Set<String> activityDays;

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // 28 күн: ескіден жаңаға, апта бағаналарымен.
    final days = List.generate(
      28,
      (i) => DateTime(today.year, today.month, today.day - 27 + i),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.rLg,
        boxShadow: AppColors.sh1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var week = 0; week < 4; week++)
            Column(
              children: [
                for (var day = 0; day < 7; day++)
                  Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: activityDays
                                .contains(_key(days[week * 7 + day]))
                            ? AppColors.successJade
                            : AppColors.cloudBorder.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BattleRow extends StatelessWidget {
  const _BattleRow({required this.battle});

  final Battle battle;

  @override
  Widget build(BuildContext context) {
    final won = battle.result == BattleResult.win;
    final draw = battle.result == BattleResult.draw;
    final color = won
        ? AppColors.successJade
        : (draw ? AppColors.steppeGoldDeep : AppColors.dangerCoral);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp3,
        vertical: AppSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.rMd,
        boxShadow: AppColors.sh1,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                won ? 'W' : (draw ? 'D' : 'L'),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Text(
              battle.opponentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.nightInk,
              ),
            ),
          ),
          Text(
            '${battle.myScore} : ${battle.opponentScore}',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.sp2),
          Text(
            Formatters.relativeTime(battle.createdAt),
            style: AppTypography.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
