import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/curriculum.dart';
import '../models/enums.dart';
import '../models/task_node.dart';
import '../services/local_storage_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'game_provider.dart';
import 'quest_provider.dart';

/// Карта экранына дайын node көрінісі.
class NodeView {
  const NodeView({
    required this.node,
    required this.status,
    required this.stars,
    required this.isCurrent,
  });

  final TaskNode node;
  final NodeStatus status;
  final int stars;

  /// Жолдағы келесі (алтын, пульсті) node.
  final bool isCurrent;
}

/// Тапсырманы аяқтау нәтижесі (result экранына).
class TaskResult {
  const TaskResult({
    required this.scorePercent,
    required this.stars,
    required this.xp,
    required this.coins,
    required this.akyl,
    required this.passed,
    required this.firstCompletion,
  });

  final int scorePercent;
  final int stars;
  final int xp;
  final int coins;
  final int akyl;
  final bool passed;
  final bool firstCompletion;
}

/// Бір пәннің оқу прогресі (family: пән id).
class TaskNotifier extends StateNotifier<Map<String, NodeProgress>> {
  TaskNotifier(this._ref, this._storage, this._userId, this.subject)
      : super(const {}) {
    _load();
  }

  final Ref _ref;
  final LocalStorageService _storage;
  final String? _userId;
  final String subject;

  void _load() {
    if (_userId == null) return;
    try {
      final all = _storage.getAllNodeProgress(_userId);
      state = {
        for (final entry in all.entries)
          if (entry.key.startsWith('${subject}_')) entry.key: entry.value,
      };
    } catch (_) {
      state = const {};
    }
  }

  /// Қолданушының өз сыныбы — картада ТЕК осы сынып көрсетіледі.
  int get currentGradeLevel {
    if (_userId == null) return 1;
    return _storage.getUser(_userId)?.grade ?? 1;
  }

  /// 1-сыныптан қолданушы сыныбына дейінгі node күйлері (реттелген).
  /// Жоғарғы сыныптар тізімге мүлде кірмейді. Қолжетімді сыныптарда
  /// құлып жоқ: барлығы ашық. Ағымдағы (алтын) node — ӨЗ сыныбындағы
  /// алғашқы аяқталмаған; өз сыныбы біткен болса — жалпы алғашқысы.
  List<NodeView> nodeViews() {
    final userGrade = currentGradeLevel;
    final nodes = Curriculum.nodesUpToGrade(subject, userGrade);

    bool isDone(String id) {
      final p = state[id];
      return p != null &&
          (p.status == NodeStatus.completed ||
              p.status == NodeStatus.mastered);
    }

    String? currentId;
    for (final node in nodes) {
      if (node.grade == userGrade && !isDone(node.id)) {
        currentId = node.id;
        break;
      }
    }
    if (currentId == null) {
      for (final node in nodes) {
        if (!isDone(node.id)) {
          currentId = node.id;
          break;
        }
      }
    }

    return [
      for (final node in nodes)
        NodeView(
          node: node,
          status: isDone(node.id)
              ? state[node.id]!.status
              : NodeStatus.available,
          stars: state[node.id]?.stars ?? 0,
          isCurrent: node.id == currentId,
        ),
    ];
  }

  /// Тапсырманы аяқтау: ұпай есептеу, марапат беру, прогресс сақтау.
  Future<TaskResult> completeTask(
    String nodeId, {
    required int correctCount,
    required int totalCount,
  }) async {
    final node = Curriculum.nodeById(nodeId);
    if (node == null || _userId == null || totalCount == 0) {
      return const TaskResult(
        scorePercent: 0, stars: 0, xp: 0, coins: 0, akyl: 0,
        passed: false, firstCompletion: false,
      );
    }

    final percent = (correctCount * 100 / totalCount).round();
    final stars = percent >= 90 ? 3 : (percent >= 70 ? 2 : (percent >= 50 ? 1 : 0));
    final passed = stars > 0;

    final existing = state[nodeId];
    final wasCompleted = existing != null &&
        (existing.status == NodeStatus.completed ||
            existing.status == NodeStatus.mastered);
    final firstCompletion = passed && !wasCompleted;

    // Марапат: алғаш аяқтаса толық, қайталаса 30% XP ғана.
    var xp = 0;
    var coins = 0;
    var akyl = 0;
    if (firstCompletion) {
      xp = node.xpReward;
      coins = node.coinReward;
      akyl = node.akylReward;
    } else if (passed) {
      xp = (node.xpReward * 0.3).round();
    }

    if (passed) {
      final newStars =
          existing == null ? stars : (stars > existing.stars ? stars : existing.stars);
      final newBest = existing == null
          ? percent
          : (percent > existing.bestScore ? percent : existing.bestScore);
      final progress = NodeProgress(
        nodeId: nodeId,
        status: newStars == 3 ? NodeStatus.mastered : NodeStatus.completed,
        stars: newStars,
        bestScore: newBest,
        completedAt: DateTime.now(),
      );
      await _storage.saveNodeProgress(_userId, progress);
      state = {...state, nodeId: progress};
    }

    // Марапаттар мен статистика.
    final game = _ref.read(gameProvider.notifier);
    if (xp > 0) await game.addXp(xp);
    if (coins > 0) await game.addCoins(coins);
    if (akyl > 0) await game.addAkylPoints(akyl);

    if (passed) {
      final user = _storage.getUser(_userId);
      if (user != null) {
        await _storage.saveUser(user.copyWith(
          tasksCompleted: user.tasksCompleted + 1,
          perfectTasks: user.perfectTasks + (percent == 100 ? 1 : 0),
          bossesDefeated: user.bossesDefeated +
              (node.type == NodeType.boss && firstCompletion ? 1 : 0),
        ));
        _ref.read(authProvider.notifier).refreshUser();
      }
      final quests = _ref.read(questProvider.notifier);
      await quests.track(QuestType.completeTasks);
      if (percent == 100) await quests.track(QuestType.perfectTask);
      if (xp > 0) await quests.track(QuestType.earnXp, xp);

      final achievements = _ref.read(achievementProvider.notifier);
      // Сынып чемпионы: осы пәндегі сыныптың барлық node-ы аяқталды ма?
      if (firstCompletion && _isGradeComplete(node.grade)) {
        await achievements.unlock('ach_grade_complete');
      }
      await achievements.evaluate();
    }

    return TaskResult(
      scorePercent: percent,
      stars: stars,
      xp: xp,
      coins: coins,
      akyl: akyl,
      passed: passed,
      firstCompletion: firstCompletion,
    );
  }

  /// Берілген сыныптың осы пәндегі барлық node-тары аяқталған ба.
  bool _isGradeComplete(int grade) {
    for (final node in Curriculum.nodesForGrade(subject, grade)) {
      final progress = state[node.id];
      final done = progress != null &&
          (progress.status == NodeStatus.completed ||
              progress.status == NodeStatus.mastered);
      if (!done) return false;
    }
    return true;
  }
}

final taskProvider = StateNotifierProvider.family<TaskNotifier,
    Map<String, NodeProgress>, String>((ref, subject) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  return TaskNotifier(ref, ref.watch(storageProvider), userId, subject);
});

/// Пән бойынша прогресс үлесі (subject_select сақиналары үшін) —
/// тек қолданушы сыныбының node-тары есептеледі.
final subjectProgressProvider = Provider.family<double, String>((ref, subject) {
  ref.watch(taskProvider(subject));
  final notifier = ref.read(taskProvider(subject).notifier);
  final views = notifier.nodeViews();
  if (views.isEmpty) return 0;
  final done = views
      .where((v) =>
          v.status == NodeStatus.completed || v.status == NodeStatus.mastered)
      .length;
  return (done / views.length).clamp(0, 1).toDouble();
});
