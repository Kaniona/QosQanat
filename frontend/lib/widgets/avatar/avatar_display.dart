import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/enums.dart';
import '../../models/shop_item.dart';
import 'avatar_base.dart';

/// Маскот көңіл-күйі мен анимациясы.
enum AvatarMood { idle, celebrate, sad, wave }

/// Анимацияланған маскот: idle (қалқу), celebrate (секіру),
/// sad (төмендеу), wave (қол бұлғау орнына шайқалу).
class AvatarDisplay extends StatelessWidget {
  const AvatarDisplay({
    super.key,
    required this.assistant,
    this.mood = AvatarMood.idle,
    this.size = 160,
    this.equipped = const [],
    this.animationsOn = true,
  });

  final AssistantType assistant;
  final AvatarMood mood;
  final double size;
  final List<ShopItem> equipped;
  final bool animationsOn;

  @override
  Widget build(BuildContext context) {
    final expression = switch (mood) {
      AvatarMood.celebrate => AvatarExpression.celebrate,
      AvatarMood.sad => AvatarExpression.sad,
      _ => AvatarExpression.happy,
    };

    // RepaintBoundary: маскот бір рет растрленіп, қалқу/секіру кезінде
    // тек кэштелген қабат жылжиды — әр кадрда қайта салынбайды (FPS).
    // Мұнда қозғалыс көзі — көңіл-күй анимациясы (idle/celebrate/…), сондықтан
    // AvatarBase-тың ішкі «тыныс алуы» өшірулі (қос қозғалыс болмауы үшін).
    final base = RepaintBoundary(
      child: AvatarBase(
        assistant: assistant,
        size: size,
        equipped: equipped,
        expression: expression,
        animate: false,
      ),
    );

    if (!animationsOn) return base;

    return switch (mood) {
      AvatarMood.idle => base
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: 2200.ms, curve: Curves.easeInOut),
      AvatarMood.celebrate => base
          .animate(onPlay: (c) => c.repeat())
          .moveY(begin: 0, end: -14, duration: 360.ms, curve: Curves.easeOut)
          .then()
          .moveY(begin: -14, end: 0, duration: 360.ms, curve: Curves.bounceOut)
          .then(delay: 300.ms),
      AvatarMood.sad => base
          .animate()
          .moveY(begin: 0, end: 6, duration: 500.ms, curve: Curves.easeOut)
          .scaleXY(begin: 1, end: .97, duration: 500.ms),
      AvatarMood.wave => base
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(begin: -.02, end: .02, duration: 700.ms, curve: Curves.easeInOut),
    };
  }
}
