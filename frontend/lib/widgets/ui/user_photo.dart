import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Қолданушы суреті: алтын сақиналы дөңгелек аватар.
/// Сурет жоқ болса — әдепкі user-icon.
class UserPhoto extends StatelessWidget {
  const UserPhoto({
    super.key,
    this.photoPath,
    this.size = 44,
    this.ringWidth = 2,
    this.showRing = true,
  });

  final String? photoPath;
  final double size;
  final double ringWidth;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final innerSize = size - ringWidth * 2;
    // Декод өлшемін шектеу — 800px суретті 44px аватарға толық ашпау
    // (жад + тізім скроллындағы FPS).
    final cacheSize =
        (innerSize * MediaQuery.devicePixelRatioOf(context)).round();

    final placeholder = Container(
      width: innerSize,
      height: innerSize,
      color: AppColors.tintBlue,
      child: Icon(
        Icons.person_rounded,
        size: innerSize * .6,
        color: AppColors.eagleBlue,
      ),
    );

    final inner = ClipOval(
      // Файл бар-жоғын синхронды тексермейміз (build ішінде диск I/O —
      // қату көзі); жоқ/бүлінген файлда errorBuilder placeholder береді.
      child: photoPath == null
          ? placeholder
          : Image.file(
              File(photoPath!),
              width: innerSize,
              height: innerSize,
              fit: BoxFit.cover,
              cacheWidth: cacheSize,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );

    if (!showRing) return SizedBox(width: size, height: size, child: inner);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: const BoxDecoration(
        gradient: AppColors.goldSoar,
        shape: BoxShape.circle,
      ),
      child: inner,
    );
  }
}
