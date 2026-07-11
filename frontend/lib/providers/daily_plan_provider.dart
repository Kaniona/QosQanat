import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../data/curriculum.dart';
import 'auth_provider.dart';
import 'mastery_provider.dart';

/// «Бүгінгі жоспардың» бір қадамы — mastery күйінен есептеледі.
class DailyStep {
  const DailyStep({
    required this.label,
    required this.icon,
    required this.route,
    required this.done,
    this.extra,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool done;

  /// Қосымша белгі (тақырып аты немесе «3/10» прогресі).
  final String? extra;
}

/// Күнделікті жеке мақсат — қайталау + әлсіз тұс + күндік норма.
class DailyPlan {
  const DailyPlan(this.steps);
  final List<DailyStep> steps;

  int get doneCount => steps.where((s) => s.done).length;
  bool get allDone => steps.isNotEmpty && doneCount == steps.length;
  double get progress => steps.isEmpty ? 0 : doneCount / steps.length;
}

const int dailyGoalTarget = 10;

/// Бүгінгі жоспар: бала жаттыққан сайын қадамдар өзі белгіленеді.
final dailyPlanProvider = Provider<DailyPlan>((ref) {
  final snap = ref.watch(masteryProvider);
  final user = ref.watch(currentUserProvider);
  final storage = ref.watch(storageProvider);
  final uid = user?.id;
  final answered =
      uid == null ? 0 : storage.dailyAnswered(uid, dateKey(DateTime.now()));

  final weak = snap.weakest;
  final weakTopic =
      weak == null ? null : Curriculum.nodeById('${weak.skillId}_n0')?.moduleTitle;

  return DailyPlan([
    DailyStep(
      label: AppStrings.dailyPlanReview,
      icon: Icons.refresh_rounded,
      route: '/learn/review',
      done: snap.dueCount == 0,
      extra: snap.dueCount > 0 ? '${snap.dueCount}' : null,
    ),
    DailyStep(
      label: AppStrings.dailyPlanWeak,
      icon: Icons.trending_up_rounded,
      route: weak == null ? '/learn' : '/learn/map/${weak.subject}',
      done: weak == null,
      extra: weakTopic,
    ),
    DailyStep(
      label: AppStrings.dailyPlanGoal,
      icon: Icons.flag_rounded,
      route: '/learn',
      done: answered >= dailyGoalTarget,
      extra: '$answered/$dailyGoalTarget',
    ),
  ]);
});
