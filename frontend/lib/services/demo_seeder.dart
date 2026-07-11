import 'dart:math';

import '../data/curriculum.dart';
import '../models/enums.dart';
import '../models/mastery.dart';
import '../models/task_node.dart';
import 'local_storage_service.dart';

/// Көрме/презентация режимі үшін «тірі» демо-аккаунтты тұқымдау.
///
/// [MockDataService] тек профильді (Әлихан) + рейтинг/жаңалықтарды құрады, бірақ
/// оқу картасы мен шеберлік (mastery) БОС қалатын — стендте карта «жаңа
/// қолданушыдай» көрінетін. Бұл сидер сол олқылықты толтырады:
///   • 1–6 сыныптар толық аяқталған (ұзын алтын жол),
///   • 7-сынып (оқушының өз сыныбы) жартылай — ағымдағы «алтын» node нақ сонда,
///   • тақырып шеберлігі әртүрлі (Шебер/Бекіді/Үйренуде — жылу-карта шынайы),
///   • қайталау кезегінде нақты сұрақтар (review CTA жұмыс істейді),
///   • профиль бас көрсеткіштері (XP/деңгей/тапсырма) осы көлемге сай қайта
///     есептеледі — демо ішкі қайшылықсыз әрі әсерлі болады.
///
/// Толық офлайн әрі детерминистік (Random(7)) — әр стендте бірдей көрініс.
class DemoSeeder {
  DemoSeeder._();
  static final DemoSeeder instance = DemoSeeder._();

  /// [MockDataService] жасайтын демо қолданушының id-і.
  static const demoUserId = 'u_demo_alikhan';

  /// Демо оқушының сыныбы — карта мен ағымдағы node осы сыныпқа бағытталады.
  static const demoGrade = 7;

  static const _subjects = ['math', 'kazakh', 'english', 'physics', 'cs'];

  /// Сид нұсқасы — өзгерткенде келесі іске қосуда автоматты қайта тұқымдалады.
  static const _flag = 'demo_showcase_v1';

  /// Алғашқы іске қосуда (немесе нұсқа жаңарғанда) бір рет тұқымдау.
  Future<void> ensureSeeded() async {
    final storage = LocalStorageService.instance;
    if (storage.prefs.getBool(_flag) ?? false) return;
    if (storage.getUser(demoUserId) == null) return; // профиль әлі жоқ
    await _populate(storage);
    await storage.prefs.setBool(_flag, true);
  }

  /// Демо прогресін толық қалпына келтіру (стендте келушілер арасында).
  /// Аккаунттың өзі (профиль, монета — қайта есептеледі) сақталады.
  Future<void> reset() async {
    final storage = LocalStorageService.instance;
    await storage.clearLearningDataForUser(demoUserId);
    await _populate(storage);
    await storage.prefs.setBool(_flag, true);
  }

  Future<void> _populate(LocalStorageService storage) async {
    final rng = Random(7);
    final now = DateTime.now();
    final progress = <NodeProgress>[];
    final skills = <SkillStat>[];

    var xp = 0;
    var completed = 0;
    var perfect = 0;
    var bosses = 0;

    for (final subject in _subjects) {
      for (var grade = 1; grade <= demoGrade; grade++) {
        final nodes = Curriculum.nodesForGrade(subject, grade);
        if (nodes.isEmpty) continue;
        final perModule = Curriculum.nodesPerModuleFor(subject, grade);
        // Өз сыныбында әр модульдің ~60%-ы аяқталған (ағымдағы node — ортасы).
        final completeUpTo =
            grade < demoGrade ? perModule : (perModule * 0.6).ceil();

        for (final node in nodes) {
          if (node.indexInModule >= completeUpTo) continue;
          final roll = rng.nextDouble();
          final stars = roll < 0.6 ? 3 : (roll < 0.9 ? 2 : 1);
          final score = switch (stars) {
            3 => 90 + rng.nextInt(11),
            2 => 72 + rng.nextInt(16),
            _ => 52 + rng.nextInt(16),
          };
          // Уақыт мөрі: ескі сыныптар бұрынырақ, өз сыныбы — соңғы күндер.
          final baseDaysAgo = grade < demoGrade
              ? (90 - grade * 11 - node.indexInModule)
              : (8 - node.indexInModule ~/ 2);
          progress.add(NodeProgress(
            nodeId: node.id,
            status: stars == 3 ? NodeStatus.mastered : NodeStatus.completed,
            stars: stars,
            bestScore: score,
            completedAt: now.subtract(Duration(
              days: baseDaysAgo.clamp(1, 160),
              hours: rng.nextInt(13),
            )),
          ));

          xp += node.xpReward;
          completed++;
          if (stars == 3) perfect++;
          if (node.type == NodeType.boss) bosses++;
        }
      }

      // Тақырып шеберлігі — модуль басына, әртүрлі деңгеймен (жылу-карта тірі).
      for (var grade = 1; grade <= demoGrade; grade++) {
        final mc = Curriculum.moduleCount(subject, grade);
        for (var m = 1; m <= mc; m++) {
          final sid = skillIdFor(subject, grade, m);
          final band = sid.hashCode.abs() % 100;
          final double ema;
          final int attempts;
          if (grade >= demoGrade) {
            // Өз сыныбы — әлі шыңдалуда (кейбірі әлсіз → коуч/қайталау мәнді).
            ema = band < 32 ? 0.55 : (band < 72 ? 0.74 : 0.9);
            attempts = 4 + band % 6;
          } else {
            // Өткен сыныптар — негізінен бекіген/шебер.
            ema = band < 14 ? 0.62 : (band < 46 ? 0.79 : 0.93);
            attempts = 7 + band % 10;
          }
          final correct = (ema * attempts).round().clamp(0, attempts);
          skills.add(SkillStat(
            skillId: sid,
            subject: subject,
            grade: grade,
            module: m,
            attempts: attempts,
            correct: correct,
            ema: ema,
            lastPracticed: now.subtract(Duration(
              days: grade >= demoGrade ? 1 + band % 3 : 9 + band % 24,
            )),
          ));
        }
      }
    }

    await storage.saveNodeProgressBatch(demoUserId, progress);
    await storage.saveSkillStatBatch(demoUserId, skills);
    await _seedReviews(storage, now);
    await storage.setPlacementDone(demoUserId);

    // Бас көрсеткіштерді нақты көлемге сай қайта есептеу (ішкі үйлесім).
    final user = storage.getUser(demoUserId);
    if (user != null) {
      await storage.saveUser(user.copyWith(
        xp: xp,
        level: GameLevel.fromXp(xp),
        coins: 1200 + completed * 14,
        akylPoints: 800 + completed * 9,
        tasksCompleted: completed,
        perfectTasks: perfect,
        bossesDefeated: bosses,
      ));
    }
  }

  /// Қайталау кезегі: нақты node-тардан нақты сұрақтар (мерзімі жеткен).
  Future<void> _seedReviews(LocalStorageService storage, DateTime now) async {
    for (final subject in const ['math', 'english', 'physics']) {
      final nodes = Curriculum.nodesForGrade(subject, demoGrade);
      if (nodes.isEmpty) continue;
      final node = nodes.first;
      final sid = skillIdFor(subject, demoGrade, node.module);
      final qs = node.questions
          .where((q) => q.type != QuestionType.matchPairs)
          .take(3);
      for (final q in qs) {
        await storage.saveReviewItem(
          demoUserId,
          ReviewItem.create(
            q.id,
            node.id,
            sid,
            q.difficulty,
            now: now.subtract(const Duration(days: 1)),
          ),
        );
      }
    }
  }
}

/// Деңгей қисығы (game_provider-дегі формуламен бірдей: 50·L·(L−1)).
/// Сидер game_provider-ге тәуелді болмауы үшін осында қайталанады.
abstract final class GameLevel {
  static int xpToReach(int level) => 50 * level * (level - 1);

  static int fromXp(int xp) {
    var level = 1;
    while (level < 100 && xp >= xpToReach(level + 1)) {
      level++;
    }
    return level;
  }
}
