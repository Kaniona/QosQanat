import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
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
          (AppColors.cosmicPurpleLight, AppColors.cosmicPurple),
        NewsCategory.update => (AppColors.eagleBlueLight, AppColors.eagleBlue),
        NewsCategory.tip =>
          (AppColors.steppeGoldLight, AppColors.steppeGoldDeep),
        NewsCategory.event => (AppColors.sunsetLight, AppColors.warningSunset),
      };

  @override
  Widget build(BuildContext context) {
    final (tagBg, tagFg) = _tagColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: AppRadius.rLg,
          boxShadow: AppColors.sh2,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.hasCover)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.ascension,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_rounded,
                      size: 42,
                      color: AppColors.white.withValues(alpha: .55),
                    ),
                  ),
                ),
              ),
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
