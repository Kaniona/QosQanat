import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friends_provider.dart';
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
              Text('🏆 ${AppStrings.ratingTitle}', style: AppTypography.h1),
            ],
          ),
        ),

        // ---- Ауқым табтары ----
        SizedBox(
          height: 40,
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
                    color: active ? null : AppColors.white,
                    borderRadius: AppRadius.rFull,
                    border: active
                        ? null
                        : Border.all(color: AppColors.cloudBorder, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: active ? AppColors.white : AppColors.slate,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sp3),

        Expanded(
          child: schoolTooSmall
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sp8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_outlined,
                            size: 56, color: AppColors.mist),
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
                    0,
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
            height: 84,
            isMe: top3[1].id == meId,
          ),
        ),
        const SizedBox(width: AppSpacing.sp2),
        Expanded(
          child: _PodiumPlace(
            user: top3[0],
            rank: 1,
            ringColor: AppColors.goldBright,
            height: 112,
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
            height: 64,
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
        if (crowned) const Text('👑', style: TextStyle(fontSize: 22)),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 3),
            boxShadow: crowned ? AppColors.goldGlow : null,
          ),
          child: UserPhoto(
            photoPath: user.profilePhotoPath,
            size: crowned ? 64 : 52,
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
            color: isMe ? AppColors.eagleBlue : AppColors.nightInk,
          ),
        ),
        Text(
          '★ ${Formatters.number(user.akylPoints)}',
          style: AppTypography.caption
              .copyWith(color: AppColors.cosmicPurple, fontSize: 11),
        ),
        const SizedBox(height: AppSpacing.sp1),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ringColor.withValues(alpha: .85),
                ringColor.withValues(alpha: .45),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.md),
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: AppTypography.numberDisplay
                  .copyWith(color: AppColors.white, fontSize: 30),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp3,
        vertical: AppSpacing.sp2,
      ),
      decoration: BoxDecoration(
        color: isMe ? AppColors.eagleBlueLight : AppColors.white,
        borderRadius: AppRadius.rMd,
        border: isMe
            ? Border.all(color: AppColors.eagleBlue, width: 1.5)
            : null,
        boxShadow: AppColors.sh1,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.slate,
              ),
            ),
          ),
          UserPhoto(
            photoPath: user.profilePhotoPath,
            size: 38,
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
                    color: AppColors.nightInk,
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
                : (_movement < 0 ? AppColors.dangerCoral : AppColors.mist),
          ),
        ],
      ),
    );
  }
}
