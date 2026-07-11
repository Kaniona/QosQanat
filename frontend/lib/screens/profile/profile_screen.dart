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
import '../../models/shop_item.dart';
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
import '../../widgets/ui/panels.dart';
import '../../widgets/ui/reward_toast.dart';
import '../../widgets/ui/user_photo.dart';

/// Профиль: градиент hero (маскот + сурет) → деңгей/XP → статистика →
/// жетістіктер → белсенділік heatmap → соңғы батлдар → шығу.
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
        // ---- Градиент hero: маскот + сурет + аты + QQ-ID ----
        _ProfileHero(
          fullName: user.fullName,
          qosqanatId: user.qosqanatId,
          assistant: user.assistantType,
          photoPath: user.profilePhotoPath,
          equipped: equipped,
          animationsOn: animationsOn,
          onSettings: () => context.push('/settings'),
          onPickPhoto: () => _pickPhoto(context, ref),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: .05),
        const SizedBox(height: AppSpacing.sp5),

        // ---- Деңгей + XP жолағы ----
        PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp3,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldSoar,
                      borderRadius: AppRadius.rFull,
                      boxShadow: AppColors.glow(AppColors.steppeGold,
                          opacity: .35, blur: 12, y: 4),
                    ),
                    child: Text(
                      '${game.level} LVL',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.local_fire_department_rounded,
                      size: 18, color: AppColors.warningSunset),
                  const SizedBox(width: 4),
                  Text(
                    '${game.currentStreak} ${AppStrings.daysShort}',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.warningSunset,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sp4),
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
          mainAxisSpacing: AppSpacing.sp3,
          crossAxisSpacing: AppSpacing.sp3,
          childAspectRatio: 0.92,
          children: [
            _StatCard(
              icon: Icons.star_rounded,
              value: Formatters.number(game.akylPoints),
              label: AppStrings.statAkyl,
              color: AppColors.cosmicPurple,
            ),
            _StatCard(
              icon: Icons.monetization_on_rounded,
              value: Formatters.number(game.coins),
              label: AppStrings.statCoins,
              color: AppColors.steppeGoldDeep,
            ),
            _StatCard(
              icon: Icons.people_alt_rounded,
              value: '$friendsCount',
              label: AppStrings.statFriends,
              color: AppColors.eagleBlue,
            ),
            _StatCard(
              icon: Icons.local_fire_department_rounded,
              value: '${game.currentStreak}',
              label: AppStrings.statStreak,
              color: AppColors.warningSunset,
            ),
            _StatCard(
              icon: Icons.check_circle_rounded,
              value: '${user.tasksCompleted}',
              label: AppStrings.statTasks,
              color: AppColors.successJade,
            ),
            _StatCard(
              icon: Icons.sports_kabaddi_rounded,
              value: '${user.battlesWon}/${user.battlesTotal}',
              label: AppStrings.statBattles,
              color: AppColors.dangerCoral,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp6),

        // ---- Менің прогресім ----
        PanelCard(
          onTap: () => context.push('/progress'),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.eagleBlue.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_rounded,
                    color: AppColors.eagleBlue, size: 24),
              ),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.progressTitle,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w900)),
                    Text(AppStrings.progressSubjectsTitle,
                        style: AppTypography.caption),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sp6),

        // ---- Жетістіктер ----
        SectionHeader(
          title: AppStrings.achievements,
          trailing: Text(
            '${unlocked.length}/${AchievementsData.all.length}',
            style: AppTypography.caption,
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sp3,
          crossAxisSpacing: AppSpacing.sp3,
          childAspectRatio: 1.0,
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
        SectionHeader(title: AppStrings.activity),
        _ActivityHeatmap(activityDays: user.activityDays.toSet()),
        const SizedBox(height: AppSpacing.sp6),

        // ---- Соңғы батлдар ----
        if (battles.isNotEmpty) ...[
          SectionHeader(title: AppStrings.recentBattles),
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

/// Градиент hero картасы: параметрлер баптауы, маскот + сурет, аты, QQ-ID.
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.fullName,
    required this.qosqanatId,
    required this.assistant,
    required this.photoPath,
    required this.equipped,
    required this.animationsOn,
    required this.onSettings,
    required this.onPickPhoto,
  });

  final String fullName;
  final String qosqanatId;
  final AssistantType assistant;
  final String? photoPath;
  final List<ShopItem> equipped;
  final bool animationsOn;
  final VoidCallback onSettings;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final isNazym = assistant == AssistantType.nazym;
    final gradient = isNazym ? AppColors.heroRose : AppColors.heroEagle;
    final accent = isNazym ? AppColors.nazymRose : AppColors.eagleBlue;

    return PanelCard(
      gradient: gradient,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sp5, AppSpacing.sp3, AppSpacing.sp5, AppSpacing.sp5),
      shadow: AppColors.glow(accent, opacity: .38, blur: 30, y: 14),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Semantics(
                button: true,
                label: AppStrings.settingsTitle,
                child: GestureDetector(
                  onTap: onSettings,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: .2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.white.withValues(alpha: .35)),
                    ),
                    child: const Icon(Icons.settings_rounded,
                        size: 20, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
          // Маскот + сурет/камера. Барлық элемент Stack ШЕГІНДЕ — hit-test
          // шекарадан тыс басылмайды.
          SizedBox(
            width: 132 + 48,
            height: 136,
            child: Stack(
              children: [
                // Маскот артындағы жұмсақ жарық ореол — градиент фонда бөлектейді.
                Positioned(
                  left: -9,
                  top: -2,
                  child: IgnorePointer(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.white.withValues(alpha: .20),
                            AppColors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: AvatarDisplay(
                    assistant: assistant,
                    size: 132,
                    equipped: equipped,
                    animationsOn: animationsOn,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPickPhoto,
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            child: UserPhoto(
                              photoPath: photoPath,
                              size: 60,
                              ringWidth: 2.5,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppColors.sh2,
                              ),
                              child: Icon(Icons.photo_camera_rounded,
                                  size: 15, color: accent),
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
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.sp2),
          // QQ-ID frosted pill (көшіру)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: qosqanatId));
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
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: .22),
                borderRadius: AppRadius.rFull,
                border:
                    Border.all(color: AppColors.white.withValues(alpha: .35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    qosqanatId,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp1),
                  const Icon(Icons.copy_rounded,
                      size: 13, color: AppColors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp3),
      radius: AppRadius.lg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpacing.sp2),
          FittedBox(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 2),
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
      child: PanelCard(
        padding: const EdgeInsets.all(AppSpacing.sp2),
        radius: AppRadius.lg,
        gradient: unlocked ? AppColors.heroGold : null,
        shadow: unlocked
            ? AppColors.glow(AppColors.steppeGold, opacity: .3, blur: 14, y: 5)
            : AppColors.cardShadow,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: unlocked ? 1 : .3,
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: AppSpacing.sp1),
            Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: unlocked ? AppColors.white : AppColors.muted,
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

    return PanelCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var week = 0; week < 4; week++)
            Column(
              children: [
                for (var day = 0; day < 7; day++)
                  Builder(builder: (_) {
                    final active = activityDays
                        .contains(_key(days[week * 7 + day]));
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: active ? null : AppColors.border.withValues(alpha: .6),
                          gradient: active ? AppColors.heroJade : null,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: active
                              ? AppColors.glow(AppColors.successJade,
                                  opacity: .45, blur: 7, y: 1)
                              : null,
                        ),
                      ),
                    );
                  }),
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

    return PanelCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp3,
        vertical: AppSpacing.sp3,
      ),
      radius: AppRadius.lg,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
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
                color: AppColors.ink,
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
