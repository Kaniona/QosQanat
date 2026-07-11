import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/league_provider.dart';
import '../../widgets/ui/panels.dart';
import '../../widgets/ui/user_photo.dart';

enum _RatingScope { global, city, school, friends }

/// Рейтинг ауқымына сай сұрыпталған тізім (ақыл ұпайы бойынша).
final _ratingListProvider =
    Provider.family<List<User>, _RatingScope>((ref, scope) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  final all = ref.watch(storageProvider).getAllUsers();

  final filtered = switch (scope) {
    _RatingScope.global => all,
    _RatingScope.city => all.where((u) => u.city == me.city).toList(),
    _RatingScope.school => all
        .where((u) => u.school == me.school && u.city == me.city)
        .toList(),
    _RatingScope.friends => [
        me,
        ...ref.watch(friendsProvider.select((s) => s.friends)),
      ],
  };
  return filtered..sort((a, b) => b.akylPoints.compareTo(a.akylPoints));
});

/// Рейтинг: 4 ауқым табы + TOP-3 подиум + тізім.
class RatingScreen extends ConsumerStatefulWidget {
  const RatingScreen({super.key});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  _RatingScope _scope = _RatingScope.global;

  static const _scopes = [
    (_RatingScope.global, AppStrings.scopeGlobal),
    (_RatingScope.city, AppStrings.scopeCity),
    (_RatingScope.school, AppStrings.scopeSchool),
    (_RatingScope.friends, AppStrings.scopeFriends),
  ];

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final list = ref.watch(_ratingListProvider(_scope));
    final schoolTooSmall =
        _scope == _RatingScope.school && list.length < 10;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sp5,
            AppSpacing.sp4,
            AppSpacing.sp5,
            AppSpacing.sp3,
          ),
          child: Row(
            children: [
              const OyuDiamond(size: 13),
              const SizedBox(width: AppSpacing.sp3),
              Text(AppStrings.ratingTitle, style: AppTypography.h1),
              const SizedBox(width: AppSpacing.sp2),
              const Icon(AppIcons.trophy,
                  size: 24, color: AppColors.steppeGold),
            ],
          ),
        ),

        // ---- Ауқым табтары ----
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp5),
            itemCount: _scopes.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sp2),
            itemBuilder: (context, index) {
              final (scope, label) = _scopes[index];
              final active = scope == _scope;
              return GestureDetector(
                onTap: () => setState(() => _scope = scope),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sp4),
                  decoration: BoxDecoration(
                    gradient: active ? AppColors.eagleGrad : null,
                    color: active ? null : AppColors.surface,
                    borderRadius: AppRadius.rFull,
                    border: active
                        ? null
                        : Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: active
                        ? AppColors.glow(AppColors.eagleBlue,
                            opacity: .3, blur: 12, y: 4)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.white : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sp3),

        // ---- Лига дәрежесі ----
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.sp5, 0, AppSpacing.sp5, AppSpacing.sp3),
          child: const _LeagueCard(),
        ),

        Expanded(
          child: schoolTooSmall
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sp8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 56, color: AppColors.muted),
                        const SizedBox(height: AppSpacing.sp3),
                        Text(
                          AppStrings.schoolRatingEmpty,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  key: ValueKey(_scope),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sp5,
                    AppSpacing.sp2,
                    AppSpacing.sp5,
                    AppSpacing.sp12,
                  ),
                  children: [
                    // ---- TOP-3 подиум ----
                    if (list.length >= 3)
                      _Podium(top3: list.take(3).toList(), meId: me?.id)
                          .animate()
                          .fadeIn(duration: 350.ms),
                    const SizedBox(height: AppSpacing.sp4),

                    // ---- 4-орыннан бастап тізім ----
                    for (var i = list.length >= 3 ? 3 : 0;
                        i < list.length;
                        i++)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sp2),
                        child: _RankRow(
                          rank: i + 1,
                          user: list[i],
                          isMe: list[i].id == me?.id,
                        )
                            .animate()
                            .fadeIn(delay: (30 * (i % 12)).ms, duration: 250.ms),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// TOP-3 подиум: 1-орын ортада биік (алтын), 2-сол (күміс), 3-оң (қола).
class _Podium extends StatelessWidget {
  const _Podium({required this.top3, required this.meId});

  final List<User> top3;
  final String? meId;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumPlace(
            user: top3[1],
            rank: 2,
            ringColor: const Color(0xFFB0B7C3),
            height: 88,
            isMe: top3[1].id == meId,
          ),
        ),
        const SizedBox(width: AppSpacing.sp2),
        Expanded(
          child: _PodiumPlace(
            user: top3[0],
            rank: 1,
            ringColor: AppColors.goldBright,
            height: 120,
            isMe: top3[0].id == meId,
            crowned: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sp2),
        Expanded(
          child: _PodiumPlace(
            user: top3[2],
            rank: 3,
            ringColor: const Color(0xFFCD7F32),
            height: 68,
            isMe: top3[2].id == meId,
          ),
        ),
      ],
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  const _PodiumPlace({
    required this.user,
    required this.rank,
    required this.ringColor,
    required this.height,
    required this.isMe,
    this.crowned = false,
  });

  final User user;
  final int rank;
  final Color ringColor;
  final double height;
  final bool isMe;
  final bool crowned;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (crowned)
          const Text('👑', style: TextStyle(fontSize: 24))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -4, duration: 1400.ms),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 3),
            boxShadow: crowned
                ? AppColors.glow(AppColors.steppeGold, opacity: .55, blur: 18)
                : null,
          ),
          child: UserPhoto(
            photoPath: user.profilePhotoPath,
            size: crowned ? 66 : 52,
            showRing: false,
          ),
        ),
        const SizedBox(height: AppSpacing.sp1),
        Text(
          user.firstName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w800,
            color: isMe ? AppColors.eagleBlue : AppColors.ink,
          ),
        ),
        Text(
          '★ ${Formatters.number(user.akylPoints)}',
          style: AppTypography.caption
              .copyWith(color: AppColors.cosmicPurple, fontSize: 11),
        ),
        const SizedBox(height: AppSpacing.sp2),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ringColor.withValues(alpha: .9),
                ringColor.withValues(alpha: .5),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md),
            ),
            boxShadow: crowned
                ? AppColors.glow(AppColors.steppeGold, opacity: .35, blur: 16)
                : null,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: AppTypography.numberDisplay
                  .copyWith(color: AppColors.white, fontSize: 32),
            ),
          ),
        ),
      ],
    );
  }
}

/// Тізім жолы: орын, аватар, аты, деңгей, ақыл, қозғалыс (↑↓).
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.user,
    required this.isMe,
  });

  final int rank;
  final User user;
  final bool isMe;

  /// Offline режімдегі детерминистік қозғалыс белгісі.
  int get _movement => (user.id.hashCode % 3) - 1;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp3,
        vertical: AppSpacing.sp3,
      ),
      radius: AppRadius.lg,
      color: isMe ? AppColors.tintBlue : null,
      border: isMe ? Border.all(color: AppColors.eagleBlue, width: 1.5) : null,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          UserPhoto(
            photoPath: user.profilePhotoPath,
            size: 40,
            showRing: false,
          ),
          const SizedBox(width: AppSpacing.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${user.fullName} (${AppStrings.you})' : user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text('${user.level} LVL', style: AppTypography.caption),
              ],
            ),
          ),
          Text(
            '★ ${Formatters.number(user.akylPoints)}',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.cosmicPurple,
            ),
          ),
          const SizedBox(width: AppSpacing.sp2),
          Icon(
            _movement > 0
                ? Icons.arrow_drop_up_rounded
                : (_movement < 0
                    ? Icons.arrow_drop_down_rounded
                    : Icons.remove_rounded),
            size: _movement == 0 ? 14 : 24,
            color: _movement > 0
                ? AppColors.successJade
                : (_movement < 0 ? AppColors.dangerCoral : AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Лига дәрежесінің картасы — рейтинг бетінің жоғарғы блогы.
class _LeagueCard extends ConsumerWidget {
  const _LeagueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(leagueProvider);
    final tier = s.tier;
    return PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tier.color.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(tier.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: AppSpacing.sp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier.label,
                        style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w900, color: tier.color)),
                    Text(
                      s.next == null
                          ? 'Ең жоғары лига 👑'
                          : 'Келесі лигаға ${s.toNext} ақыл',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              Text('★ ${Formatters.number(s.points)}',
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: AppSpacing.sp3),
          ClipRRect(
            borderRadius: AppRadius.rFull,
            child: LinearProgressIndicator(
              value: s.progress,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(tier.color),
            ),
          ),
        ],
      ),
    );
  }
}
