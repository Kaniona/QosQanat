import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/battle.dart';
import '../models/exam.dart';
import '../models/flagged_question.dart';
import '../models/friend.dart';
import '../models/mastery.dart';
import '../models/news.dart';
import '../models/quest.dart';
import '../models/task_node.dart';
import '../models/tournament.dart';
import '../models/user.dart';

/// Hive + SharedPreferences орамдауы — барлық деректер локальде.
class LocalStorageService {
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  static const _usersBox = 'users';
  static const _sessionBox = 'session';
  static const _progressBox = 'progress';
  static const _questsBox = 'quests';
  static const _battlesBox = 'battles';
  static const _friendsBox = 'friends';
  static const _newsBox = 'news';
  static const _tournamentsBox = 'tournaments';
  static const _skillsBox = 'skills';
  static const _reviewsBox = 'reviews';
  static const _assignmentsBox = 'assignments';
  static const _flaggedBox = 'flagged';
  static const _examsBox = 'exams';

  late SharedPreferences prefs;

  /// Бүкіл boxes ашу — main()-да бір рет шақырылады.
  Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(_usersBox),
      Hive.openBox<String>(_sessionBox),
      Hive.openBox<Map>(_progressBox),
      Hive.openBox<Map>(_questsBox),
      Hive.openBox<Map>(_battlesBox),
      Hive.openBox<Map>(_friendsBox),
      Hive.openBox<Map>(_newsBox),
      Hive.openBox<Map>(_tournamentsBox),
      Hive.openBox<Map>(_skillsBox),
      Hive.openBox<Map>(_reviewsBox),
      Hive.openBox<Map>(_assignmentsBox),
      Hive.openBox<Map>(_flaggedBox),
      Hive.openBox<Map>(_examsBox),
    ]);
    prefs = await SharedPreferences.getInstance();
  }

  Box<Map> get _users => Hive.box<Map>(_usersBox);
  Box<String> get _session => Hive.box<String>(_sessionBox);
  Box<Map> get _progress => Hive.box<Map>(_progressBox);
  Box<Map> get _quests => Hive.box<Map>(_questsBox);
  Box<Map> get _battles => Hive.box<Map>(_battlesBox);
  Box<Map> get _friends => Hive.box<Map>(_friendsBox);
  Box<Map> get _news => Hive.box<Map>(_newsBox);
  Box<Map> get _tournaments => Hive.box<Map>(_tournamentsBox);
  Box<Map> get _skills => Hive.box<Map>(_skillsBox);
  Box<Map> get _reviews => Hive.box<Map>(_reviewsBox);
  Box<Map> get _assignments => Hive.box<Map>(_assignmentsBox);
  Box<Map> get _flagged => Hive.box<Map>(_flaggedBox);
  Box<Map> get _exams => Hive.box<Map>(_examsBox);

  static Map<String, dynamic> _cast(Map raw) => Map<String, dynamic>.from(raw);

  // ---------------- Қолданушылар ----------------

  Future<void> saveUser(User user) => _users.put(user.id, user.toJson());

  User? getUser(String id) {
    final raw = _users.get(id);
    return raw == null ? null : User.fromJson(_cast(raw));
  }

  List<User> getAllUsers() =>
      _users.values.map((raw) => User.fromJson(_cast(raw))).toList();

  User? findUserByPhone(String phoneDigits) {
    final clean = phoneDigits.replaceAll(RegExp(r'\D'), '');
    for (final raw in _users.values) {
      final user = User.fromJson(_cast(raw));
      if (user.phone.replaceAll(RegExp(r'\D'), '') == clean) return user;
    }
    return null;
  }

  User? findUserByQqId(String qqId) {
    final normalized = qqId.trim().toUpperCase();
    for (final raw in _users.values) {
      final user = User.fromJson(_cast(raw));
      if (user.qosqanatId.toUpperCase() == normalized) return user;
    }
    return null;
  }

  // ---------------- Сеанс ----------------

  String? get currentUserId => _session.get('current_user_id');

  Future<void> setCurrentUserId(String? id) async {
    if (id == null) {
      await _session.delete('current_user_id');
    } else {
      await _session.put('current_user_id', id);
    }
  }

  // ---------------- Оқу прогресі ----------------

  String _progressKey(String userId, String nodeId) => '$userId|$nodeId';

  Future<void> saveNodeProgress(String userId, NodeProgress progress) =>
      _progress.put(_progressKey(userId, progress.nodeId), progress.toJson());

  /// Көп node прогресін бір амалмен сақтау (демо көрмесін тұқымдау үшін —
  /// жүздеген жазба бір `putAll`-ге сыяды, бірінші іске қосу жылдам болады).
  Future<void> saveNodeProgressBatch(
    String userId,
    Iterable<NodeProgress> items,
  ) =>
      _progress.putAll({
        for (final p in items) _progressKey(userId, p.nodeId): p.toJson(),
      });

  NodeProgress? getNodeProgress(String userId, String nodeId) {
    final raw = _progress.get(_progressKey(userId, nodeId));
    return raw == null ? null : NodeProgress.fromJson(_cast(raw));
  }

  /// Қолданушының барлық node прогрестері: nodeId -> NodeProgress.
  Map<String, NodeProgress> getAllNodeProgress(String userId) {
    final result = <String, NodeProgress>{};
    for (final key in _progress.keys) {
      final k = key as String;
      if (k.startsWith('$userId|')) {
        final p = NodeProgress.fromJson(_cast(_progress.get(k)!));
        result[p.nodeId] = p;
      }
    }
    return result;
  }

  // ---------------- Бейімделетін оқыту (mastery) ----------------

  String _scoped(String userId, String key) => '$userId|$key';

  // Тақырып шеберлігі (SkillStat) ---

  Future<void> saveSkillStat(String userId, SkillStat stat) =>
      _skills.put(_scoped(userId, stat.skillId), stat.toJson());

  /// Көп тақырып шеберлігін бір амалмен сақтау (демо тұқымдау).
  Future<void> saveSkillStatBatch(String userId, Iterable<SkillStat> stats) =>
      _skills.putAll({
        for (final s in stats) _scoped(userId, s.skillId): s.toJson(),
      });

  SkillStat? getSkillStat(String userId, String skillId) {
    final raw = _skills.get(_scoped(userId, skillId));
    return raw == null ? null : SkillStat.fromJson(_cast(raw));
  }

  /// Қолданушының барлық тақырып шеберліктері: skillId -> SkillStat.
  Map<String, SkillStat> getAllSkillStats(String userId) {
    final result = <String, SkillStat>{};
    final prefix = '$userId|';
    for (final key in _skills.keys) {
      final k = key as String;
      if (k.startsWith(prefix)) {
        final s = SkillStat.fromJson(_cast(_skills.get(k)!));
        result[s.skillId] = s;
      }
    }
    return result;
  }

  // Қайталау кезегі (ReviewItem) ---

  Future<void> saveReviewItem(String userId, ReviewItem item) =>
      _reviews.put(_scoped(userId, item.questionId), item.toJson());

  Future<void> deleteReviewItem(String userId, String questionId) =>
      _reviews.delete(_scoped(userId, questionId));

  ReviewItem? getReviewItem(String userId, String questionId) {
    final raw = _reviews.get(_scoped(userId, questionId));
    return raw == null ? null : ReviewItem.fromJson(_cast(raw));
  }

  List<ReviewItem> getAllReviewItems(String userId) {
    final result = <ReviewItem>[];
    final prefix = '$userId|';
    for (final key in _reviews.keys) {
      final k = key as String;
      if (k.startsWith(prefix)) {
        result.add(ReviewItem.fromJson(_cast(_reviews.get(k)!)));
      }
    }
    return result;
  }

  /// Мерзімі жеткен (қайталауға дайын) сұрақтар.
  List<ReviewItem> getDueReviews(String userId, DateTime now) =>
      getAllReviewItems(userId).where((r) => r.isDue(now)).toList();

  // Ұстаз тапсырмалары (Assignment) ---

  Future<void> saveAssignment(Assignment a) =>
      _assignments.put(a.id, a.toJson());

  Future<void> deleteAssignment(String assignmentId) =>
      _assignments.delete(assignmentId);

  List<Assignment> getAssignmentsForUser(String studentId) {
    final result = <Assignment>[];
    for (final raw in _assignments.values) {
      final a = Assignment.fromJson(_cast(raw));
      if (a.studentId == studentId) result.add(a);
    }
    return result;
  }

  // «Қате» деп белгіленген сұрақтар (контент QA) ---

  Future<void> saveFlag(FlaggedQuestion flag) =>
      _flagged.put(flag.id, flag.toJson());

  List<FlaggedQuestion> getAllFlags() =>
      _flagged.values.map((raw) => FlaggedQuestion.fromJson(_cast(raw))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  bool isFlagged(String questionId) => _flagged.containsKey(questionId);

  // Ұстаз/ата-ана PIN коды (бір құрылғыға ортақ) ---

  String? get guardianPin => prefs.getString('guardian_pin');

  Future<void> setGuardianPin(String pin) =>
      prefs.setString('guardian_pin', pin);

  // Орналастыру диагностикасы өтілді ме (бір оқушыға) ---

  bool placementDone(String userId) =>
      prefs.getBool('placement_done_$userId') ?? false;

  Future<void> setPlacementDone(String userId) =>
      prefs.setBool('placement_done_$userId', true);

  // «Бүгінгі жоспар» қай күні аяқталды (yyyy-MM-dd) ---

  String? dailyPlanDone(String userId) =>
      prefs.getString('daily_plan_$userId');

  Future<void> setDailyPlanDone(String userId, String dateKey) =>
      prefs.setString('daily_plan_$userId', dateKey);

  /// Бүгін берілген жауап саны (күн ауысса нөлден басталады).
  int dailyAnswered(String userId, String dateKey) {
    final raw = prefs.getString('daily_ans_$userId');
    if (raw == null) return 0;
    final parts = raw.split('|');
    if (parts.length != 2 || parts[0] != dateKey) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  Future<void> bumpDailyAnswered(String userId, String dateKey, int by) {
    final current = dailyAnswered(userId, dateKey);
    return prefs.setString('daily_ans_$userId', '$dateKey|${current + by}');
  }

  /// Күнделікті марафон нәтижесі: 'yyyy-MM-dd|score' (күніне бір рет).
  String? getDailyQuizResult(String userId) =>
      prefs.getString('daily_quiz_$userId');

  Future<bool> setDailyQuizResult(String userId, String value) =>
      prefs.setString('daily_quiz_$userId', value);

  /// Апталық жиналған XP: 'дүйсенбіKey|xp' (апта ауысса нөлден).
  String? getWeeklyXp(String userId) => prefs.getString('weekly_xp_$userId');

  Future<bool> setWeeklyXp(String userId, String value) =>
      prefs.setString('weekly_xp_$userId', value);

  /// Апталық XP мақсаты (қойылмаса — null).
  int? getWeeklyGoal(String userId) => prefs.getInt('weekly_goal_$userId');

  Future<bool> setWeeklyGoal(String userId, int value) =>
      prefs.setInt('weekly_goal_$userId', value);

  /// «Не жаңалық» картасы жабылды ма (нұсқаға байланған).
  bool whatsNewDismissed(String version) =>
      prefs.getBool('whatsnew_$version') ?? false;

  Future<bool> dismissWhatsNew(String version) =>
      prefs.setBool('whatsnew_$version', true);

  // ---------------- Күнделікті квесттер ----------------

  /// key: userId|yyyy-MM-dd -> {'quest_ids': [...], 'progress': {id: json}}
  Future<void> saveDailyQuests(
    String userId,
    String dateKey,
    List<String> questIds,
    Map<String, QuestProgress> progress,
  ) =>
      _quests.put('$userId|$dateKey', {
        'quest_ids': questIds,
        'progress': progress.map((id, p) => MapEntry(id, p.toJson())),
      });

  ({List<String> questIds, Map<String, QuestProgress> progress})?
      getDailyQuests(String userId, String dateKey) {
    final raw = _quests.get('$userId|$dateKey');
    if (raw == null) return null;
    final data = _cast(raw);
    final progressRaw = Map<String, dynamic>.from(data['progress'] as Map? ?? {});
    return (
      questIds: List<String>.from(data['quest_ids'] as List? ?? []),
      progress: progressRaw.map((id, p) => MapEntry(
          id, QuestProgress.fromJson(Map<String, dynamic>.from(p as Map)))),
    );
  }

  // ---------------- Батлдар ----------------

  Future<void> saveBattle(Battle battle) =>
      _battles.put(battle.id, battle.toJson());

  Battle? getBattle(String id) {
    final raw = _battles.get(id);
    return raw == null ? null : Battle.fromJson(_cast(raw));
  }

  List<Battle> getBattlesForUser(String userId) {
    final list = _battles.values
        .map((raw) => Battle.fromJson(_cast(raw)))
        .where((b) => b.challengerId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ---------------- Достар ----------------

  Future<void> saveFriendRequest(FriendRequest request) =>
      _friends.put(request.id, request.toJson());

  List<FriendRequest> getAllFriendRequests() =>
      _friends.values.map((raw) => FriendRequest.fromJson(_cast(raw))).toList();

  // ---------------- Жаңалықтар ----------------

  Future<void> saveNews(News news) => _news.put(news.id, news.toJson());

  List<News> getAllNews() {
    final list = _news.values.map((raw) => News.fromJson(_cast(raw))).toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return list;
  }

  // ---------------- Турнирлер ----------------

  Future<void> saveTournament(Tournament tournament) =>
      _tournaments.put(tournament.id, tournament.toJson());

  List<Tournament> getAllTournaments() => _tournaments.values
      .map((raw) => Tournament.fromJson(_cast(raw)))
      .toList();

  // ---------------- Байқау сынақтары ----------------

  static const _examHistoryLimit = 30;

  /// Сынақ әрекетін сақтау; тарих [_examHistoryLimit]-пен шектеледі
  /// (ең ескілері өшіріледі). Кілт: userId|millis — лексика реті = уақыт реті.
  Future<void> saveExamAttempt(String userId, ExamAttempt attempt) async {
    await _exams.put('$userId|${attempt.id}', attempt.toJson());
    final keys = _exams.keys
        .whereType<String>()
        .where((k) => k.startsWith('$userId|'))
        .toList()
      ..sort();
    if (keys.length > _examHistoryLimit) {
      await _exams.deleteAll(keys.take(keys.length - _examHistoryLimit));
    }
  }

  /// Қолданушының сынақ тарихы (соңғысы бірінші).
  List<ExamAttempt> getExamAttempts(String userId) {
    final attempts = <ExamAttempt>[];
    for (final key in _exams.keys.whereType<String>()) {
      if (!key.startsWith('$userId|')) continue;
      final raw = _exams.get(key);
      if (raw == null) continue;
      try {
        attempts.add(ExamAttempt.fromJson(_cast(raw)));
      } catch (_) {
        // Бүлінген жазба тарихты құлатпайды.
      }
    }
    attempts.sort((a, b) => b.date.compareTo(a.date));
    return attempts;
  }

  // ---------------- Жалпы ----------------

  bool get isSeeded => prefs.getBool('mock_data_seeded') ?? false;

  Future<void> markSeeded() => prefs.setBool('mock_data_seeded', true);

  /// Бір қолданушының БҮКІЛ оқу деректерін өшіру (node прогресі, тақырып
  /// шеберлігі, қайталау кезегі). Демо режимін келушілер арасында қалпына
  /// келтіруге қолданылады — аккаунттың өзі (профиль, монета) сақталады.
  Future<void> clearLearningDataForUser(String userId) async {
    final prefix = '$userId|';
    Future<void> wipe(Box<Map> box) async {
      final keys =
          box.keys.where((k) => (k as String).startsWith(prefix)).toList();
      if (keys.isNotEmpty) await box.deleteAll(keys);
    }

    await wipe(_progress);
    await wipe(_skills);
    await wipe(_reviews);
    await prefs.remove('daily_ans_$userId');
    await prefs.remove('daily_plan_$userId');
    await prefs.remove('daily_quiz_$userId');
  }
}
