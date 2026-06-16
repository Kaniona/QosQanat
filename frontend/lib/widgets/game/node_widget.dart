import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/enums.dart';
import '../../providers/task_provider.dart';

/// Оқу картасының node дөңгелегі — балалар ойынындағыдай толық түсті:
/// completed — жасыл (#00C48C) + ақ галочка + 3 жұлдыз,
/// current — алтын градиент + пульс + glow (картада 2x масштабталады),
/// available — көк. Босс/қазына — алтын, өлшемі үлкенірек.
class NodeWidget extends StatelessWidget {
  const NodeWidget({
    super.key,
    required this.view,
    required this.accent,
    required this.onTap,
    this.animationsOn = true,
  });

  final NodeView view;

  /// Пәннің акцент түсі (available node-тардың негізі).
  final Color accent;
  final VoidCallback onTap;
  final bool animationsOn;

  bool get _done =>
      view.status == NodeStatus.completed ||
      view.status == NodeStatus.mastered;
  bool get _boss => view.node.type == NodeType.boss;

  static IconData typeIcon(NodeType type) => switch (type) {
        NodeType.lesson => Icons.menu_book_rounded,
        NodeType.quiz => Icons.bolt_rounded,
        NodeType.boss => Icons.local_fire_department_rounded,
        NodeType.treasure => Icons.diamond_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final size = _boss ? AppSizes.bossNodeSize : AppSizes.nodeSize;

    final Color fill;
    final Gradient? gradient;
    if (_done) {
      fill = AppColors.successJade;
      gradient = null;
    } else if (view.isCurrent) {
      fill = AppColors.steppeGold;
      gradient = AppColors.goldSoar;
    } else if (_boss || view.node.type == NodeType.treasure) {
      fill = AppColors.steppeGold;
      gradient = AppColors.goldSoar;
    } else {
      fill = accent;
      gradient = null;
    }

    final icon = _done ? Icons.check_rounded : typeIcon(view.node.type);

    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gradient == null ? fill : null,
        gradient: gradient,
        shape: BoxShape.circle,
        // Төменгі «қалың жиек» — балалар ойынындағы көлемді түйме әсері.
        border: Border.all(color: AppColors.white, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: .45),
            offset: const Offset(0, 5),
            blurRadius: view.isCurrent ? 18 : 8,
          ),
        ],
      ),
      child: Icon(icon, size: size * .48, color: AppColors.white),
    );

    // Ағымдағы node: кеңейетін алтын сақина пульсі (1.8с цикл).
    // RepaintBoundary — пульс тек өз қабатын жаңартады, көрші
    // коннектор/жол элементтері әр кадрда қайта салынбайды.
    if (view.isCurrent && animationsOn) {
      circle = Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.steppeGold, width: 2.5),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scaleXY(begin: 1, end: 1.55, duration: 1800.ms)
                .fadeOut(duration: 1800.ms),
          ),
          circle,
        ],
      );
    }

    return Semantics(
      button: true,
      label: view.node.title,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size + 22,
              height: size + 22,
              child: Center(child: circle),
            ),
            if (_done)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: i < view.stars
                          ? AppColors.goldBright
                          : AppColors.mist.withValues(alpha: .45),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
