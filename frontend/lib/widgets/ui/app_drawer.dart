import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/game_provider.dart';
import 'oyu_ornament.dart';
import 'user_photo.dart';

/// Сол жақтан свайппен ашылатын меню: қолданушы header-і (cosmicNight),
/// негізгі жолдар (Турнир/Достар/Баптаулар), қосалқы сілтемелер, Шығу.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final game = ref.watch(gameProvider);
    final incomingCount = ref.watch(
      friendsProvider.select((s) => s.incoming.length),
    );

    return Drawer(
      width: MediaQuery.sizeOf(context).width * .78,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          // ---- Қолданушы header ----
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.cosmicNight,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(AppRadius.xl),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OyuDashBand(opacity: .7),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sp5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserPhoto(
                          photoPath: user?.profilePhotoPath,
                          size: 62,
                          ringWidth: 2.5,
                        ),
                        const SizedBox(height: AppSpacing.sp3),
                        Text(
                          user?.fullName ?? '',
                          style: AppTypography.h2
                              .copyWith(color: AppColors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.sp2),
                        _QqIdPill(qqId: user?.qosqanatId ?? ''),
                        const SizedBox(height: AppSpacing.sp4),
                        Row(
                          children: [
                            _StatTile(
                              value: '${game.level}',
                              label: AppStrings.statLevel,
                            ),
                            const SizedBox(width: AppSpacing.sp2),
                            _StatTile(
                              value: '★ ${Formatters.number(game.akylPoints)}',
                              label: AppStrings.statAkyl,
                            ),
                            const SizedBox(width: AppSpacing.sp2),
                            _StatTile(
                              value: Formatters.number(game.coins),
                              label: AppStrings.statCoins,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ---- Негізгі навигация ----
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp3),
              children: [
                _DrawerRow(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.steppeGoldDeep,
                  iconBg: AppColors.tintGold,
                  label: AppStrings.drawerTournament,
                  badge: const _Badge(
                    text: AppStrings.drawerActive,
                    color: AppColors.successJade,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/tournament');
                  },
                ),
                _DrawerRow(
                  icon: Icons.group_rounded,
                  iconColor: AppColors.eagleBlue,
                  iconBg: AppColors.tintBlue,
                  label: AppStrings.drawerFriends,
                  badge: incomingCount > 0
                      ? _Badge(
                          text: '$incomingCount',
                          color: AppColors.dangerCoral,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/friends');
                  },
                ),
                _DrawerRow(
                  icon: Icons.settings_rounded,
                  iconColor: AppColors.cosmicPurple,
                  iconBg: AppColors.tintPurple,
                  label: AppStrings.drawerSettings,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                _DrawerRow(
                  icon: Icons.insights_rounded,
                  iconColor: AppColors.successJade,
                  iconBg: AppColors.successJade.withValues(alpha: .14),
                  label: AppStrings.guardianMenu,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/guardian');
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp5,
                    vertical: AppSpacing.sp3,
                  ),
                  child: Divider(),
                ),
                _SecondaryLink(
                  label: AppStrings.drawerSupport,
                  onTap: () => _showInfoSnack(context, AppStrings.drawerSupport),
                ),
                _SecondaryLink(
                  label: AppStrings.drawerAbout,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/about');
                  },
                ),
              ],
            ),
          ),
          // ---- Footer: Шығу ----
          SafeArea(
            top: false,
            child: Column(
              children: [
                _DrawerRow(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.dangerCoral,
                  iconBg: AppColors.dangerCoral.withValues(alpha: .14),
                  label: AppStrings.drawerLogout,
                  labelColor: AppColors.dangerCoral,
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text(AppStrings.drawerLogout),
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
                              style: AppTypography.button
                                  .copyWith(color: AppColors.dangerCoral),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sp3),
                  child: Text(
                    AppStrings.appVersion,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.muted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _showInfoSnack(BuildContext context, String title) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.comingSoon(title))),
    );
  }
}

class _QqIdPill extends StatelessWidget {
  const _QqIdPill({required this.qqId});

  final String qqId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: qqId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.copied)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp3,
          vertical: AppSpacing.sp1,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .12),
          borderRadius: AppRadius.rFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              qqId,
              style: AppTypography.caption.copyWith(
                color: AppColors.steppeGold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.sp1),
            Icon(Icons.copy_rounded,
                size: 12, color: AppColors.white.withValues(alpha: .6)),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp2),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: .10),
          borderRadius: AppRadius.rSm,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.body.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.white.withValues(alpha: .55),
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.labelColor,
    this.badge,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final Color? labelColor;
  final Widget? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadius.rSm,
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sp4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: labelColor ?? AppColors.ink,
                  ),
                ),
              ),
              if (badge != null) ...[
                badge!,
                const SizedBox(width: AppSpacing.sp2),
              ],
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: AppColors.white,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _SecondaryLink extends StatelessWidget {
  const _SecondaryLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp5,
          vertical: AppSpacing.sp3,
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(color: AppColors.inkSoft),
        ),
      ),
    );
  }
}
