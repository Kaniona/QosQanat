import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/quest_provider.dart';
import '../../widgets/avatar/avatar_base.dart';
import '../../widgets/game/news_card.dart';
import '../../widgets/ui/hud_bar.dart';
import '../../widgets/ui/reward_toast.dart';

/// Басты бет: HUD → сәлемдесу → күнделікті квесттер → жаңалықтар таспасы.
/// Сол жақ шетте drawer свайп-белгісі.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.greetingMorning;
    if (hour < 18) return AppStrings.greetingDay;
    return AppStrings.greetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final news = ref.watch(newsProvider);
    final quests = ref.watch(questProvider);

    return Stack(
      children: [
        Column(
          children: [
            const HudBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sp5,
                  AppSpacing.sp5,
                  AppSpacing.sp5,
                  AppSpacing.sp12,
                ),
                children: [
                  // ---- Сәлемдесу + серік ----
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting,
                              style: AppTypography.bodySmall
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${user?.firstName ?? ''}! 👋',
                              style: AppTypography.displayLarge
                                  .copyWith(fontSize: 26),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: user?.assistantType == AssistantType.nazym
                              ? AppColors.nazymRoseLight
                              : AppColors.eagleBlueLight,
                          borderRadius: AppRadius.rMd,
                          border: Border.all(
                            color: user?.assistantType == AssistantType.nazym
                                ? AppColors.nazymRose
                                : AppColors.eagleBlue,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AvatarBase(
                          assistant:
                              user?.assistantType ?? AssistantType.bektur,
                          size: 52,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: AppSpacing.sp6),

                  // ---- Күнделікті квесттер ----
                  if (quests.isNotEmpty) ...[
                    Text(AppStrings.dailyQuests,
                        style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.w900, fontSize: 20)),
                    const SizedBox(height: AppSpacing.sp3),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: quests.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sp3),
                        itemBuilder: (context, index) =>
                            _QuestCard(daily: quests[index]),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp6),
                  ],

                  // ---- Жаңалықтар ----
                  Text(AppStrings.newsSection,
                      style: AppTypography.h3
                          .copyWith(fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(height: AppSpacing.sp3),
                  if (news.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sp8),
                      child: Center(
                        child: Text(AppStrings.newsEmpty,
                            style: AppTypography.bodySmall),
                      ),
                    )
                  else
                    for (var i = 0; i < news.length; i++)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sp4),
                        child: NewsCard(
                          news: news[i],
                          onTap: () => _showNewsSheet(context, ref, i),
                        )
                            .animate()
                            .fadeIn(delay: (60 * i).ms, duration: 350.ms)
                            .slideY(begin: .08),
                      ),
                ],
              ),
            ),
          ],
        ),
        // ---- Сол жақ шеттегі drawer белгісі ----
        Positioned(
          left: 0,
          top: MediaQuery.sizeOf(context).height * .42,
          child: GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: RepaintBoundary(
              child: Container(
                width: 22,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: AppColors.eagleGrad,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(AppRadius.sm),
                  ),
                  boxShadow: AppColors.sh2,
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.white),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(begin: 0, end: 4, duration: 1200.ms),
            ),
          ),
        ),
      ],
    );
  }

  void _showNewsSheet(BuildContext context, WidgetRef ref, int index) {
    final news = ref.read(newsProvider)[index];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sp6,
          0,
          AppSpacing.sp6,
          AppSpacing.sp8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(news.title, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.sp3),
            Text(
              news.body.isEmpty ? news.preview : news.body,
              style: AppTypography.body.copyWith(color: AppColors.charcoal),
            ),
          ],
        ),
      ),
    );
  }
}

/// Квест картасы: icon тақташасы + атауы + прогресс жолағы + сыйлық чипі.
class _QuestCard extends ConsumerWidget {
  const _QuestCard({required this.daily});

  final DailyQuest daily;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complete = daily.isComplete;
    return Container(
      width: 172,
      padding: const EdgeInsets.all(AppSpacing.sp3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.rLg,
        border: complete
            ? Border.all(color: AppColors.successJade, width: 2)
            : null,
        boxShadow: AppColors.sh2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.eagleBlueLight,
                  borderRadius: AppRadius.rSm,
                ),
                child: Center(
                  child: Text(daily.quest.icon,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const Spacer(),
              if (!daily.progress.claimed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.steppeGoldLight,
                    borderRadius: AppRadius.rFull,
                  ),
                  child: Text(
                    '+${daily.quest.coinReward} 💰',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.steppeGoldDeep, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sp2),
          Expanded(
            child: Text(
              daily.quest.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.nightInk,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: AppRadius.rFull,
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: AppColors.cloudBorder),
                  FractionallySizedBox(
                    widthFactor: daily.fraction,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient:
                            complete ? null : AppColors.eagleGrad,
                        color: complete ? AppColors.successJade : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp2),
          if (daily.progress.claimed)
            Text(
              AppStrings.questClaimed,
              style: AppTypography.caption
                  .copyWith(color: AppColors.successJade, fontSize: 11),
            )
          else if (daily.canClaim)
            SizedBox(
              height: 30,
              width: double.infinity,
              child: GestureDetector(
                onTap: () async {
                  final ok = await ref
                      .read(questProvider.notifier)
                      .claimReward(daily.quest.id);
                  if (ok && context.mounted) {
                    RewardToast.show(
                      context,
                      message:
                          '${AppStrings.questClaimed} +${daily.quest.coinReward} 💰',
                      icon: Icons.card_giftcard_rounded,
                      color: AppColors.steppeGoldDeep,
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.goldSoar,
                    borderRadius: AppRadius.rFull,
                  ),
                  child: Center(
                    child: Text(
                      '${AppStrings.claim} +${daily.quest.coinReward} 💰',
                      style: AppTypography.caption
                          .copyWith(color: const Color(0xFF7A4A00)),
                    ),
                  ),
                ),
              ),
            )
          else
            Text(
              '${daily.progress.progress}/${daily.quest.target}',
              style: AppTypography.caption.copyWith(fontSize: 11),
            ),
        ],
      ),
    );
  }
}
