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

/// Сұрақтың қиындық деңгейі (easy 60% / medium 30% / hard 10%).
enum Difficulty {
  easy,
  medium,
  hard;

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
