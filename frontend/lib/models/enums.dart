/// Жоба бойынша ортақ enum-дар.
library;

/// AI серік түрі.
enum AssistantType {
  bektur,
  nazym;

  static AssistantType fromName(String? name) =>
      name == 'nazym' ? AssistantType.nazym : AssistantType.bektur;
}

/// Оқу картасындағы node түрі.
enum NodeType {
  lesson,
  quiz,
  boss,
  treasure;

  static NodeType fromName(String? name) => NodeType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => NodeType.lesson,
      );
}

/// Сұрақтың қиындық деңгейі — 6 деңгей, ӨСУ реті бойынша
/// (`Difficulty.values` реті = жеңілден қиынға). Ескі банк жазбалары
/// `easy/medium/hard` күйінде қала береді (Оңай/Орташа/Қиын болып оқылады),
/// ал `light` (одан жеңіл) мен `complex`/`brainTeaser` (одан қиын) — жаңа.
enum Difficulty {
  light, // Жеңіл
  easy, // Оңай
  medium, // Орташа
  hard, // Қиын
  complex, // Күрделі
  brainTeaser; // Басқатырғыш

  /// Қазақша атауы (UI badge осыдан оқиды).
  String get label => switch (this) {
        Difficulty.light => 'Жеңіл',
        Difficulty.easy => 'Оңай',
        Difficulty.medium => 'Орташа',
        Difficulty.hard => 'Қиын',
        Difficulty.complex => 'Күрделі',
        Difficulty.brainTeaser => 'Басқатырғыш',
      };

  static Difficulty fromName(String? name) => Difficulty.values.firstWhere(
        (e) => e.name == name,
        orElse: () => Difficulty.easy,
      );
}

/// Сұрақ форматы.
enum QuestionType {
  multipleChoice,
  trueFalse,
  fillBlank,
  matchPairs;

  static QuestionType fromName(String? name) =>
      QuestionType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => QuestionType.multipleChoice,
      );
}

/// Node күйі.
enum NodeStatus {
  locked,
  available,
  completed,
  mastered;

  static NodeStatus fromName(String? name) => NodeStatus.values.firstWhere(
        (e) => e.name == name,
        orElse: () => NodeStatus.locked,
      );
}

/// Зат сиректігі.
enum Rarity {
  common,
  rare,
  epic,
  legendary;

  static Rarity fromName(String? name) => Rarity.values.firstWhere(
        (e) => e.name == name,
        orElse: () => Rarity.common,
      );
}

/// Дүкен категориясы.
enum ShopCategory {
  top,
  bottom,
  hat,
  accessory,
  pet;

  static ShopCategory fromName(String? name) =>
      ShopCategory.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ShopCategory.top,
      );
}

/// Батл нәтижесі (ағымдағы қолданушы тұрғысынан).
enum BattleResult {
  win,
  lose,
  draw,
  pending;

  static BattleResult fromName(String? name) =>
      BattleResult.values.firstWhere(
        (e) => e.name == name,
        orElse: () => BattleResult.pending,
      );
}

/// Жаңалық категориясы.
enum NewsCategory {
  tournament('Турнир'),
  update('Жаңарту'),
  tip('Кеңес'),
  event('Іс-шара');

  const NewsCategory(this.label);
  final String label;

  static NewsCategory fromName(String? name) =>
      NewsCategory.values.firstWhere(
        (e) => e.name == name,
        orElse: () => NewsCategory.tip,
      );
}

/// Квест мақсатының түрі.
enum QuestType {
  login,
  completeTasks,
  perfectTask,
  battle,
  battleWin,
  purchase,
  addFriend,
  streak,
  earnXp;

  static QuestType fromName(String? name) => QuestType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => QuestType.completeTasks,
      );
}

/// Жетістік санаты.
enum AchievementCategory {
  learning,
  battle,
  collection,
  friends,
  streak,
  special;

  static AchievementCategory fromName(String? name) =>
      AchievementCategory.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AchievementCategory.special,
      );
}

/// Дос өтінімінің күйі.
enum FriendRequestStatus {
  pending,
  accepted,
  declined;

  static FriendRequestStatus fromName(String? name) =>
      FriendRequestStatus.values.firstWhere(
        (e) => e.name == name,
        orElse: () => FriendRequestStatus.pending,
      );
}
