import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/curriculum.dart';
import '../models/enums.dart';
import '../models/mastery.dart';
import '../models/task_node.dart';
import '../services/local_storage_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'game_provider.dart';

/// Бір сессияда берілген бір жауап (mastery движогіне азық).
typedef SessionAnswer = ({
  String questionId,
  String nodeId,
  bool correct,
  Difficulty difficulty,
});

/// Қайталау сессиясының бір картасы: сұрақ + ол шыққан node.
typedef ReviewCard = ({Question question, String nodeId});

/// Күн кілті (yyyy-M-d) — күнделікті есептегіштер үшін.
String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// Оқушының бейімделу суреті (UI осыдан оқиды).
class MasterySnapshot {
  const MasterySnapshot({this.skills = const {}, this.dueCount = 0});

  /// skillId -> SkillStat.
  final Map<String, SkillStat> skills;

  /// Қайталауға дайын (мерзімі жеткен) сұрақ саны.
  final int dueCount;

  /// Әлсіз тақырыптар — EMA өсу ретімен (ең әлсізі бірінші).
  List<SkillStat> get weakSkills {
    final list = skills.values.where((s) => s.isWeak).toList()
      ..sort((a, b) => a.ema.compareTo(b.ema));
    return list;
  }

  /// Ең әлсіз тақырып (бар болса).
  SkillStat? get weakest => weakSkills.isEmpty ? null : weakSkills.first;

  List<SkillStat> skillsForSubject(String subject) =>
      skills.values.where((s) => s.subject == subject).toList();

  SkillStat? statFor(String skillId) => skills[skillId];

  /// Жаттыққан тақырыптардың орташа дәлдігі (профиль/панель үшін), 0..1.
  double get overallAccuracy {
    final practiced = skills.values.where((s) => s.attempts > 0).toList();
    if (practiced.isEmpty) return 0;
    final sum = practiced.fold<double>(0, (a, s) => a + s.ema);
    return sum / practiced.length;
  }
}

/// Бейімделетін оқыту движогі: жауаптарды тіркеп, шеберлік пен қайталау
/// кезегін жаңартады. Толық офлайн (Hive).
class MasteryNotifier extends StateNotifier<MasterySnapshot> {
  MasteryNotifier(this._ref, this._storage, this._userId)
      : super(const MasterySnapshot()) {
    _load();
  }

  final Ref _ref;
  final LocalStorageService _storage;
  final String? _userId;

  void _load() {
    final uid = _userId;
    if (uid == null) {
      state = const MasterySnapshot();
      return;
    }
    try {
      final skills = _storage.getAllSkillStats(uid);
      final due = _storage.getDueReviews(uid, DateTime.now()).length;
      state = MasterySnapshot(skills: skills, dueCount: due);
    } catch (_) {
      state = const MasterySnapshot();
    }
  }

  /// Сессия жауаптарын тіркеу: тақырып шеберлігі (EMA) + қайталау кезегі (SRS).
  /// Тапсырманы аяқтағанда ДА, жүрегі бітіп шыққанда ДА шақырылады — әлсіз
  /// тұстың сигналы жоғалмауы үшін.
  Future<void> recordSession(List<SessionAnswer> answers) async {
    final uid = _userId;
    if (uid == null || answers.isEmpty) return;
    final now = DateTime.now();

    // Тек қозғалған тақырыптарды жаңартып, соларды ғана сақтаймыз.
    final working = <String, SkillStat>{};
    final originalLevel = <String, MasteryLevel>{};
    for (final a in answers) {
      final node = Curriculum.nodeById(a.nodeId);
      if (node == null) continue;
      final sid = skillIdFor(node.subject, node.grade, node.module);

      final stored = _storage.getSkillStat(uid, sid);
      originalLevel.putIfAbsent(sid, () => stored?.level ?? MasteryLevel.fresh);
      final base = working[sid] ??
          stored ??
          SkillStat.initial(node.subject, node.grade, node.module);
      working[sid] = base.record(a.correct, at: now);

      await _updateReview(uid, a, sid, now);
    }

    for (final stat in working.values) {
      await _storage.saveSkillStat(uid, stat);
    }
    await _storage.bumpDailyAnswered(uid, dateKey(now), answers.length);

    // Жаңадан «Шебер» болған тақырыпқа марапат (бір рет).
    final newlyMastered = working.entries
        .where((e) =>
            e.value.level == MasteryLevel.mastered &&
            originalLevel[e.key] != MasteryLevel.mastered)
        .length;
    if (newlyMastered > 0) {
      await _ref.read(gameProvider.notifier).addCoins(newlyMastered * 50);
      await _ref.read(gameProvider.notifier).addXp(newlyMastered * 30);
    }

    _load();
    await _checkMilestones(uid);
  }

  /// Шеберлік белестерін тексеру: тақырып/пән «Шебер» болғанда жетістік ашу
  /// (марапат пен toast `unlock` ішінде өңделеді; `unlock` идемпотентті).
  Future<void> _checkMilestones(String uid) async {
    try {
      final ach = _ref.read(achievementProvider.notifier);
      final skills = state.skills.values;
      final mastered =
          skills.where((s) => s.level == MasteryLevel.mastered).length;
      final provenPlus = skills
          .where((s) => s.level.index >= MasteryLevel.proven.index)
          .length;
      if (mastered >= 1) await ach.unlock('ach_topic_master');
      if (provenPlus >= 5) await ach.unlock('ach_proven_5');
      if (mastered >= 10) await ach.unlock('ach_topics_master_10');

      final user = _storage.getUser(uid);
      if (user != null) {
        for (final subject in const ['math', 'kazakh', 'english', 'physics', 'cs']) {
          final mc = Curriculum.moduleCount(subject, user.grade);
          if (mc == 0) continue;
          var allMastered = true;
          for (var m = 1; m <= mc; m++) {
            final st = state.skills[skillIdFor(subject, user.grade, m)];
            if (st == null || st.level != MasteryLevel.mastered) {
              allMastered = false;
              break;
            }
          }
          if (allMastered) {
            await ach.unlock('ach_subject_master');
            break;
          }
        }
      }
    } catch (_) {
      // Жетістік тексерісі оқуды бұзбауы тиіс.
    }
  }

  Future<void> _updateReview(
    String uid,
    SessionAnswer a,
    String skillId,
    DateTime now,
  ) async {
    final existing = _storage.getReviewItem(uid, a.questionId);
    if (a.correct) {
      // Тек бұрын қателескен сұрақтар кезекте тұрады.
      if (existing == null) return;
      final updated = existing.schedule(true, now: now);
      if (updated.graduated) {
        await _storage.deleteReviewItem(uid, a.questionId);
      } else {
        await _storage.saveReviewItem(uid, updated);
      }
    } else {
      final item = existing == null
          ? ReviewItem.create(a.questionId, a.nodeId, skillId, a.difficulty,
              now: now)
          : existing.schedule(false, now: now);
      await _storage.saveReviewItem(uid, item);
    }
  }

  /// Қайталау сессиясына сұрақтар құрастыру (мерзімі жеткендер, ең ескісі алда).
  /// questionId + nodeId арқылы нақты [Question]-ге шешіледі. Сәйкестендіру
  /// сұрақтары қайталауға кірмейді (бөлек механика).
  List<ReviewCard> buildReviewSession({int limit = 12}) {
    final uid = _userId;
    if (uid == null) return const [];
    final due = _storage.getDueReviews(uid, DateTime.now())
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    final out = <ReviewCard>[];
    for (final item in due) {
      final node = Curriculum.nodeById(item.nodeId);
      if (node == null) continue;
      final match = node.questions
          .where((q) => q.id == item.questionId && q.type != QuestionType.matchPairs);
      if (match.isEmpty) continue;
      out.add((question: match.first, nodeId: item.nodeId));
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Қайталау сессиясы үшін жетерлік сұрақ бар ма (UI шешімі).
  bool get hasReviewReady => state.dueCount > 0;
}

final masteryProvider =
    StateNotifierProvider<MasteryNotifier, MasterySnapshot>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return MasteryNotifier(ref, ref.watch(storageProvider), userId);
});

/// Ағымдағы оқушының БЕЛСЕНДІ ұстаз тапсырмалары (бекіген тақырыптар өзі
/// жабылады). Тапсырма қосылғанда `ref.invalidate(assignmentsProvider)`.
final assignmentsProvider = Provider<List<Assignment>>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  final snap = ref.watch(masteryProvider);
  final storage = ref.watch(storageProvider);
  if (userId == null) return const [];
  return storage.getAssignmentsForUser(userId).where((a) {
    final stat = snap.statFor(a.skillId);
    return stat == null || stat.level.index < MasteryLevel.proven.index;
  }).toList();
});
