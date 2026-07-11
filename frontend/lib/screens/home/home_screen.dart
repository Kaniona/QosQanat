import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/enums.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/mastery_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/quest_provider.dart';
import '../learn/daily_challenge_screen.dart' show DailyChallengeCard;
import '../../widgets/ui/v2_home_cards.dart';
import '../../widgets/avatar/avatar_base.dart';
import '../../widgets/game/news_card.dart';
import '../../widgets/ui/coach_card.dart';
import '../../widgets/ui/daily_plan_card.dart';
import '../../widgets/ui/hud_bar.dart';
import '../../widgets/ui/panels.dart';
import '../../widgets/ui/reward_toast.dart';
import '../../widgets/ui/stat_label.dart';

/// Басты бет: HUD → серік hero картасы → күнделікті квесттер → жаңалықтар.
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
    final game = ref.watch(gameProvider);
    final news = ref.watch(newsProvider);
    final quests = ref.watch(questProvider);

    // Жетістік ашылса — үй бетке оралғанда мерекелі toast көрсетеміз.
    final pendingAch = ref.watch(achievementProvider.select((s) => s.pendingToasts));
    if (pendingAch.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final ach = pendingAch.first;
        RewardToast.show(
          context,
          message: '${ach.icon} ${ach.title}',
          icon: Icons.emoji_events_rounded,
          color: AppColors.steppeGoldDeep,
        );
        ref.read(achievementProvider.notifier).consumeToast();
      });
    }

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
                  // ---- Серік hero картасы ----
                  _GreetingHero(
                    greeting: _greeting,
                    firstName: user?.firstName ?? '',
                    streak: game.currentStreak,
                    level: game.level,
                    levelProgress: game.levelProgress,
                    xpInto: game.xpIntoLevel,
                    xpFor: game.xpForNextLevel,
                    assistant: user?.assistantType ?? AssistantType.bektur,
                    onTalk: () => context.push('/assistant'),
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: .06),
                  const SizedBox(height: AppSpacing.sp4),

                  // ---- Жеке коуч (бейімделетін оқыту) ----
                  const CoachCard()
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 350.ms)
                      .slideY(begin: .06),
                  const SizedBox(height: AppSpacing.sp4),

                  // ---- Күнделікті марафон (v2) ----
                  const DailyChallengeCard()
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 350.ms)
                      .slideY(begin: .06),
                  const SizedBox(height: AppSpacing.sp4),

                  // ---- Апталық мақсат (v2.1) ----
                  const WeeklyGoalCard()
                      .animate()
                      .fadeIn(delay: 180.ms, duration: 350.ms)
                      .slideY(begin: .06),

                  // ---- Не жаңалық — 2.1 (бір рет көрінеді) ----
                  const WhatsNewCard()
                      .animate()
                      .fadeIn(delay: 210.ms, duration: 350.ms),

                  // ---- Бүгінгі жоспар (mastery деректі болғанда) ----
                  if (ref.watch(masteryProvider).skills.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sp4),
                    const DailyPlanCard()
                        .animate()
                        .fadeIn(delay: 180.ms, duration: 350.ms)
                        .slideY(begin: .06),
                  ],
                  const SizedBox(height: AppSpacing.sp6),

                  // ---- Күнделікті квесттер ----
                  if (quests.isNotEmpty) ...[
                    SectionHeader(title: AppStrings.dailyQuests),
                    SizedBox(
                      height: 162,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
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
                  SectionHeader(title: AppStrings.newsSection),
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
              style: AppTypography.body.copyWith(color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

/// Серік hero картасы: серіктің түсімен боялған градиент, сәлемдесу,
/// streak чипі және сөйлесуге шақыратын маскот.
class _GreetingHero extends StatelessWidget {
  const _GreetingHero({
    required this.greeting,
    required this.firstName,
    required this.streak,
    required this.level,
    required this.levelProgress,
    required this.xpInto,
    required this.xpFor,
    required this.assistant,
    required this.onTalk,
  });

  final String greeting;
  final String firstName;
  final int streak;
  final int level;
  final double levelProgress;
  final int xpInto;
  final int xpFor;
  final AssistantType assistant;
  final VoidCallback onTalk;

  @override
  Widget build(BuildContext context) {
    final isNazym = assistant == AssistantType.nazym;
    final gradient = isNazym ? AppColors.heroRose : AppColors.heroEagle;
    final accent = isNazym ? AppColors.nazymRose : AppColors.eagleBlue;

    return PanelCard(
      onTap: onTalk,
      gradient: gradient,
      padding: const EdgeInsets.all(AppSpacing.sp5),
      shadow: AppColors.glow(accent, opacity: .38, blur: 30, y: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: .9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$firstName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.displayLarge.copyWith(
                    fontSize: 26,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp3),
                _FrostChip(
                  icon: AppIcons.streak,
                  text: '$streak ${AppStrings.daysShort}',
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp3),
              _MascotButton(assistant: assistant),
            ],
          ),
          const SizedBox(height: AppSpacing.sp4),
          _XpBar(
            level: level,
            progress: levelProgress,
            xpInto: xpInto,
            xpFor: xpFor,
          ),
        ],
      ),
    );
  }
}

/// Greeting hero ішіндегі деңгей + XP прогресі — гейм циклін көрнекі етеді.
class _XpBar extends StatelessWidget {
  const _XpBar({
    required this.level,
    required this.progress,
    required this.xpInto,
    required this.xpFor,
  });

  final int level;
  final double progress;
  final int xpInto;
  final int xpFor;

  @override
  Widget build(BuildContext context) {
    final maxed = xpFor <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${AppStrings.a11yLevel} $level',
              style: AppTypography.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              maxed
                  ? 'MAX'
                  : '$xpInto / $xpFor ${AppStrings.xpShort} · ${AppStrings.homeToNextLevel}',
              style: AppTypography.caption.copyWith(
                color: AppColors.white.withValues(alpha: .85),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.rFull,
          child: LinearProgressIndicator(
            value: maxed ? 1 : progress,
            minHeight: 8,
            backgroundColor: AppColors.white.withValues(alpha: .25),
            valueColor: const AlwaysStoppedAnimation(AppColors.goldBright),
          ),
        ),
      ],
    );
  }
}

/// Hero ішіндегі мөлдір ақ «frosted» чип.
class _FrostChip extends StatelessWidget {
  const _FrostChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .22),
        borderRadius: AppRadius.rFull,
        border: Border.all(color: AppColors.white.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.caption.copyWith(
              color: AppColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Маскот + чат белгісі — серікпен сөйлесуге шақырады.
class _MascotButton extends StatelessWidget {
  const _MascotButton({required this.assistant});

  final AssistantType assistant;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: .2),
            borderRadius: AppRadius.rLg,
            border: Border.all(color: AppColors.white.withValues(alpha: .45),
                width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          // Сыртта moveY «шақыру» қозғалысы бар → маскоттың ішкі қозғалысы
          // өшірулі (қос қозғалыс болмауы үшін).
          child: AvatarBase(assistant: assistant, size: 58, animate: false),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: AppColors.sh2,
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              size: 13,
              color: assistant == AssistantType.nazym
                  ? AppColors.nazymRose
                  : AppColors.eagleBlue,
            ),
          ),
        ),
      ],
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -4, duration: 1600.ms, curve: Curves.easeInOut);
  }
}

/// Квест картасы: icon тақташасы + атауы + прогресс жолағы + сыйлық чипі.
class _QuestCard extends ConsumerWidget {
  const _QuestCard({required this.daily});

  final DailyQuest daily;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complete = daily.isComplete;
    return SizedBox(
      width: 178,
      child: PanelCard(
        padding: const EdgeInsets.all(AppSpacing.sp4),
        radius: AppRadius.lg,
        border: complete
            ? Border.all(color: AppColors.successJade, width: 2)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: complete
                        ? AppColors.heroJade
                        : AppColors.eagleGrad,
                    borderRadius: AppRadius.rMd,
                    boxShadow: AppColors.glow(
                      complete ? AppColors.successJade : AppColors.eagleBlue,
                      opacity: .3,
                      blur: 12,
                      y: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(daily.quest.icon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const Spacer(),
                if (complete)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.successJade, size: 22),
              ],
            ),
            const SizedBox(height: AppSpacing.sp3),
            Expanded(
              child: Text(
                daily.quest.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp2),
            ClipRRect(
              borderRadius: AppRadius.rFull,
              child: SizedBox(
                height: 9,
                child: Stack(
                  children: [
                    Container(color: AppColors.border),
                    FractionallySizedBox(
                      widthFactor: daily.fraction,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient:
                              complete ? AppColors.heroJade : AppColors.eagleGrad,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sp2),
            if (daily.progress.claimed)
              Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 14, color: AppColors.successJade),
                  const SizedBox(width: 4),
                  Text(
                    AppStrings.questClaimed,
                    style: AppTypography.caption.copyWith(
                        color: AppColors.successJade, fontSize: 11),
                  ),
                ],
              )
            else if (daily.canClaim)
              SizedBox(
                height: 32,
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
                            '${AppStrings.questClaimed} +${daily.quest.coinReward}',
                        icon: Icons.card_giftcard_rounded,
                        color: AppColors.steppeGoldDeep,
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.goldSoar,
                      borderRadius: AppRadius.rFull,
                      boxShadow: AppColors.glow(AppColors.steppeGold,
                          opacity: .4, blur: 12, y: 4),
                    ),
                    child: Center(
                      child: StatLabel(
                        icon: AppIcons.coin,
                        text: '${AppStrings.claim} +${daily.quest.coinReward}',
                        color: const Color(0xFF7A4A00),
                        iconSize: 15,
                        style: AppTypography.caption,
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
      ),
    );
  }
}
