import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/ui/ambient_backdrop.dart';
import '../../widgets/ui/app_button.dart';

/// Жобаны 30 секундта таныстыратын құндылық карусельі (қазылар/қонақтар үшін).
/// 4 слайд: мақсат → офлайн → бейімделу → геймификация. Өткізуге де, артқа
/// қайтуға да болады (мәжбүрлі тур емес).
class _Slide {
  const _Slide({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Gradient gradient;
  final IconData icon;
  final String title;
  final String body;
}

const _slides = <_Slide>[
  _Slide(
    gradient: AppColors.heroEagle,
    icon: Icons.auto_stories_rounded,
    title: AppStrings.intro1Title,
    body: AppStrings.intro1Body,
  ),
  _Slide(
    gradient: AppColors.heroJade,
    icon: Icons.wifi_off_rounded,
    title: AppStrings.intro2Title,
    body: AppStrings.intro2Body,
  ),
  _Slide(
    gradient: AppColors.heroRose,
    icon: Icons.auto_awesome_rounded,
    title: AppStrings.intro3Title,
    body: AppStrings.intro3Body,
  ),
  _Slide(
    gradient: AppColors.heroGold,
    icon: Icons.rocket_launch_rounded,
    title: AppStrings.intro4Title,
    body: AppStrings.intro4Body,
  ),
];

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slides.length - 1;

  void _next(bool animate) {
    if (_isLast) {
      context.pop();
      return;
    }
    if (animate) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpToPage(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animate = ref.watch(settingsProvider.select((s) => s.animationsOn));

    return Scaffold(
      body: Stack(
        children: [
          // Премиум тереңдік — кіру экранымен біртұтас тірі фон.
          const AmbientBackdrop(
            colors: [
              AppColors.eagleBlue,
              AppColors.cosmicPurple,
              AppColors.steppeGold,
            ],
            opacity: .14,
          ),
          SafeArea(
            child: Column(
              children: [
                // Жоғарғы жол: артқа + Өткізу.
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        opacity: _index > 0 ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: IconButton(
                          onPressed: _index > 0
                              ? () => _controller.previousPage(
                                    duration:
                                        const Duration(milliseconds: 240),
                                    curve: Curves.easeOutCubic,
                                  )
                              : null,
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: AppStrings.back,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(AppStrings.introSkip),
                      ),
                      const SizedBox(width: AppSpacing.sp2),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                  ),
                ),
                // Бет нүктелері.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: i == _index ? AppColors.eagleGrad : null,
                          color: i == _index ? null : AppColors.border,
                          borderRadius: AppRadius.rFull,
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sp5),
                  child: AppButton(
                    label:
                        _isLast ? AppStrings.introDone : AppStrings.introNext,
                    variant: _isLast
                        ? AppButtonVariant.gold
                        : AppButtonVariant.primary,
                    onPressed: () => _next(animate),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final accent = (slide.gradient as LinearGradient).colors.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Градиентті «орб»: артында слайд түсті аура + жұмсақ қалқу.
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: .28),
                        accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    gradient: slide.gradient,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow:
                        AppColors.glow(accent, opacity: .4, blur: 34, y: 14),
                  ),
                  child: Icon(slide.icon, size: 60, color: AppColors.white),
                ),
              ],
            ),
          )
              .animate(key: ValueKey(slide.title))
              .scale(
                begin: const Offset(.8, .8),
                duration: 500.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 300.ms)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -6, end: 6, duration: 2800.ms, curve: Curves.easeInOut),
          const SizedBox(height: AppSpacing.sp8),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTypography.displayLarge.copyWith(fontSize: 27),
          )
              .animate(key: ValueKey('t${slide.title}'))
              .fadeIn(delay: 120.ms)
              .slideY(begin: .15),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          )
              .animate(key: ValueKey('b${slide.title}'))
              .fadeIn(delay: 240.ms)
              .slideY(begin: .15),
        ],
      ),
    );
  }
}
