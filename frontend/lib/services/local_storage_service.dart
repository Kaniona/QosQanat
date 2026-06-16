import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/battle.dart';
import '../models/friend.dart';
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

  // ---------------- Жалпы ----------------

  bool get isSeeded => prefs.getBool('mock_data_seeded') ?? false;

  Future<void> markSeeded() => prefs.setBool('mock_data_seeded', true);
}
