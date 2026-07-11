import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';

/// Inline «белгіше + сан» — валюта/ұпай көрсеткіштерінің бірыңғай көрінісі.
/// Эмодзи орнына вектор белгіше; reward чиптерінде, нәтиже карталарында қолданылады.
class StatLabel extends StatelessWidget {
  const StatLabel({
    super.key,
    required this.icon,
    required this.text,
    this.color,
    this.style,
    this.iconSize = 16,
    this.gap = 3,
    this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final Color? iconColor;
  final TextStyle? style;
  final double iconSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final ts = (style ?? AppTypography.caption).copyWith(
      color: color ?? style?.color,
      fontWeight: FontWeight.w800,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: iconColor ?? color ?? ts.color),
        SizedBox(width: gap),
        Flexible(
          child: Text(text,
              style: ts, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
