import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/news.dart';

/// Жаңалық картасы: cover (16:9 плейсхолдер) + категория тегі +
/// тақырып + 2 жолдық кіріспе + дата · «Толығырақ →».
class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.news, this.onTap});

  final News news;
  final VoidCallback? onTap;

  (Color, Color) get _tagColors => switch (news.category) {
        NewsCategory.tournament =>
          (AppColors.tintPurple, AppColors.cosmicPurple),
        NewsCategory.update => (AppColors.tintBlue, AppColors.eagleBlue),
        NewsCategory.tip =>
          (AppColors.tintGold, AppColors.steppeGoldDeep),
        NewsCategory.event => (AppColors.tintSunset, AppColors.warningSunset),
      };

  @override
  Widget build(BuildContext context) {
    final (tagBg, tagFg) = _tagColors;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.rLg,
          boxShadow: AppColors.sh2,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.hasCover) _NewsCover(category: news.category),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sp4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp3,
                      vertical: AppSpacing.sp1,
                    ),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: AppRadius.rFull,
                    ),
                    child: Text(
                      news.category.label,
                      style: AppTypography.caption.copyWith(color: tagFg),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                  Text(
                    news.title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sp2),
                  Text(
                    news.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.sp3),
                  Row(
                    children: [
                      Text(
                        Formatters.relativeTime(news.publishedAt),
                        style: AppTypography.caption,
                      ),
                      const Spacer(),
                      Text(
                        AppStrings.readMore,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.eagleBlue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Жаңалық cover-і: «сурет жоқ» плейсхолдердің орнына — категорияға сай
/// безендірілген тақырыпша (фирмалық градиент + ірі мотив белгіше + frosted чип).
class _NewsCover extends StatelessWidget {
  const _NewsCover({required this.category});

  final NewsCategory category;

  (Gradient, IconData) get _style => switch (category) {
        NewsCategory.tournament =>
          (AppColors.cosmicNight, Icons.emoji_events_rounded),
        NewsCategory.update =>
          (AppColors.heroEagle, Icons.rocket_launch_rounded),
        NewsCategory.tip => (AppColors.heroGold, Icons.lightbulb_rounded),
        NewsCategory.event => (AppColors.heroRose, Icons.celebration_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final (gradient, icon) = _style;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ірі мотив — шеттен сәл шығып тұрады (декор).
            Positioned(
              right: -18,
              bottom: -24,
              child: Icon(
                icon,
                size: 150,
                color: AppColors.white.withValues(alpha: .16),
              ),
            ),
            // Жұмсақ төменгі скрим — астындағы мәтінмен жіктеледі.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x1F000000)],
                ),
              ),
            ),
            // Frosted белгіше чипі.
            Positioned(
              left: AppSpacing.sp4,
              top: AppSpacing.sp4,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: .2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: .35),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: AppColors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
