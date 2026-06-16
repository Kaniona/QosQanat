import 'enums.dart';

/// Қолданушы моделі — барлық деректер Hive-та сақталады.
class User {
  const User({
    required this.id,
    required this.qosqanatId,
    required this.fullName,
    required this.phone,
    this.iin = '',
    this.city = '',
    this.school = '',
    this.grade = 7,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.akylPoints = 0,
    this.assistantType = AssistantType.bektur,
    this.profilePhotoPath,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLoginDate,
    this.assistantChangedAt,
    this.tasksCompleted = 0,
    this.perfectTasks = 0,
    this.bossesDefeated = 0,
    this.battlesTotal = 0,
    this.battlesWon = 0,
    this.winStreak = 0,
    this.passwordHash,
    this.equippedItems = const [],
    this.purchasedItems = const [],
    this.unlockedAchievements = const [],
    this.activityDays = const [],
    required this.createdAt,
  });

  final String id;

  /// QQ-XXXXXXXXX форматындағы көпшілік ID.
  final String qosqanatId;
  final String fullName;
  final String phone;
  final String iin;
  final String city;
  final String school;

  /// Оқушы сыныбы (1-11) — оқу картасының төбесін анықтайды.
  final int grade;
  final int level;

  /// Жалпы жинақталған XP.
  final int xp;
  final int coins;
  final int akylPoints;
  final AssistantType assistantType;
  final String? profilePhotoPath;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;
  final DateTime? assistantChangedAt;
  final int tasksCompleted;

  /// 100% дәлдікпен орындалған тапсырмалар саны (Мерген жетістігі).
  final int perfectTasks;

  /// Жеңілген босс-тапсырмалар саны (Босс жеңуші жетістігі).
  final int bossesDefeated;
  final int battlesTotal;
  final int battlesWon;

  /// Қатарынан жеңген батлдар (жеңіліс/тең нәтижеде 0-ге түседі).
  final int winStreak;

  /// SHA-256 құпиясөз хэші (null = ескі аккаунт, алғашқы кіруде орнатылады).
  final String? passwordHash;
  final List<String> equippedItems;
  final List<String> purchasedItems;
  final List<String> unlockedAchievements;

  /// Белсенділік heatmap-ы үшін «yyyy-MM-dd» күндер.
  final List<String> activityDays;
  final DateTime createdAt;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  User copyWith({
    String? fullName,
    String? phone,
    String? iin,
    String? city,
    String? school,
    int? grade,
    int? level,
    int? xp,
    int? coins,
    int? akylPoints,
    AssistantType? assistantType,
    String? profilePhotoPath,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    DateTime? assistantChangedAt,
    int? tasksCompleted,
    int? perfectTasks,
    int? bossesDefeated,
    int? battlesTotal,
    int? battlesWon,
    int? winStreak,
    String? passwordHash,
    List<String>? equippedItems,
    List<String>? purchasedItems,
    List<String>? unlockedAchievements,
    List<String>? activityDays,
  }) {
    return User(
      id: id,
      qosqanatId: qosqanatId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      iin: iin ?? this.iin,
      city: city ?? this.city,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      akylPoints: akylPoints ?? this.akylPoints,
      assistantType: assistantType ?? this.assistantType,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      assistantChangedAt: assistantChangedAt ?? this.assistantChangedAt,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      perfectTasks: perfectTasks ?? this.perfectTasks,
      bossesDefeated: bossesDefeated ?? this.bossesDefeated,
      battlesTotal: battlesTotal ?? this.battlesTotal,
      battlesWon: battlesWon ?? this.battlesWon,
      winStreak: winStreak ?? this.winStreak,
      passwordHash: passwordHash ?? this.passwordHash,
      equippedItems: equippedItems ?? this.equippedItems,
      purchasedItems: purchasedItems ?? this.purchasedItems,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      activityDays: activityDays ?? this.activityDays,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'qosqanat_id': qosqanatId,
        'full_name': fullName,
        'phone': phone,
        'iin': iin,
        'city': city,
        'school': school,
        'grade': grade,
        'level': level,
        'xp': xp,
        'coins': coins,
        'akyl_points': akylPoints,
        'assistant_type': assistantType.name,
        'profile_photo_path': profilePhotoPath,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_login_date': lastLoginDate?.toIso8601String(),
        'assistant_changed_at': assistantChangedAt?.toIso8601String(),
        'tasks_completed': tasksCompleted,
        'perfect_tasks': perfectTasks,
        'bosses_defeated': bossesDefeated,
        'battles_total': battlesTotal,
        'battles_won': battlesWon,
        'win_streak': winStreak,
        'password_hash': passwordHash,
        'equipped_items': equippedItems,
        'purchased_items': purchasedItems,
        'unlocked_achievements': unlockedAchievements,
        'activity_days': activityDays,
        'created_at': createdAt.toIso8601String(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        qosqanatId: json['qosqanat_id'] as String,
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        iin: json['iin'] as String? ?? '',
        city: json['city'] as String? ?? '',
        school: json['school'] as String? ?? '',
        grade: json['grade'] as int? ?? 7,
        level: json['level'] as int? ?? 1,
        xp: json['xp'] as int? ?? 0,
        coins: json['coins'] as int? ?? 0,
        akylPoints: json['akyl_points'] as int? ?? 0,
        assistantType:
            AssistantType.fromName(json['assistant_type'] as String?),
        profilePhotoPath: json['profile_photo_path'] as String?,
        currentStreak: json['current_streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        lastLoginDate: json['last_login_date'] != null
            ? DateTime.tryParse(json['last_login_date'] as String)
            : null,
        assistantChangedAt: json['assistant_changed_at'] != null
            ? DateTime.tryParse(json['assistant_changed_at'] as String)
            : null,
        tasksCompleted: json['tasks_completed'] as int? ?? 0,
        perfectTasks: json['perfect_tasks'] as int? ?? 0,
        bossesDefeated: json['bosses_defeated'] as int? ?? 0,
        battlesTotal: json['battles_total'] as int? ?? 0,
        battlesWon: json['battles_won'] as int? ?? 0,
        winStreak: json['win_streak'] as int? ?? 0,
        passwordHash: json['password_hash'] as String?,
        equippedItems: List<String>.from(json['equipped_items'] as List? ?? []),
        purchasedItems:
            List<String>.from(json['purchased_items'] as List? ?? []),
        unlockedAchievements:
            List<String>.from(json['unlocked_achievements'] as List? ?? []),
        activityDays: List<String>.from(json['activity_days'] as List? ?? []),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
