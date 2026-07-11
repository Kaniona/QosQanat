import '../models/achievement.dart';
import '../models/enums.dart';

/// Жетістік медальдары (30+).
abstract final class AchievementsData {
  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  static const List<Achievement> all = [
    // ---- v2.1 ----
    Achievement(id: 'ach_daily_perfect', title: 'Күн жауынгері', description: 'Күнделікті марафонды мінсіз өт', icon: '🔥', category: AchievementCategory.special, coinReward: 100, akylReward: 20, targetValue: 1),
    Achievement(id: 'ach_first_ubt', title: 'ҰБТ жолында', description: 'Алғашқы ҰБТ байқау сынағын тапсыр', icon: '📝', category: AchievementCategory.special, coinReward: 150, akylReward: 30, targetValue: 1),
    Achievement(id: 'ach_ubt_master', title: 'ҰБТ шебері', description: 'ҰБТ сынағында 80%+ жина', icon: '🎖️', category: AchievementCategory.special, coinReward: 400, akylReward: 80, targetValue: 1),

    // ---- Оқу ----
    Achievement(id: 'ach_first_task', title: 'Алғашқы қадам', description: 'Бірінші тапсырманы орында', icon: '🐣', category: AchievementCategory.learning, coinReward: 20, targetValue: 1),
    Achievement(id: 'ach_tasks_10', title: 'Білімқұмар', description: '10 тапсырма орында', icon: '📖', category: AchievementCategory.learning, coinReward: 50, targetValue: 10),
    Achievement(id: 'ach_tasks_50', title: 'Ізденуші', description: '50 тапсырма орында', icon: '📚', category: AchievementCategory.learning, coinReward: 100, akylReward: 20, targetValue: 50),
    Achievement(id: 'ach_tasks_100', title: 'Ғалым', description: '100 тапсырма орында', icon: '🎓', category: AchievementCategory.learning, coinReward: 200, akylReward: 50, targetValue: 100),
    Achievement(id: 'ach_tasks_300', title: 'Академик', description: '300 тапсырма орында', icon: '🏛️', category: AchievementCategory.learning, coinReward: 500, akylReward: 100, targetValue: 300),
    Achievement(id: 'ach_level_5', title: 'Қанат қақты', description: '5-деңгейге жет', icon: '🪽', category: AchievementCategory.learning, coinReward: 50, targetValue: 5),
    Achievement(id: 'ach_level_10', title: 'Самғау', description: '10-деңгейге жет', icon: '🦅', category: AchievementCategory.learning, coinReward: 100, targetValue: 10),
    Achievement(id: 'ach_level_25', title: 'Аспан биігі', description: '25-деңгейге жет', icon: '☁️', category: AchievementCategory.learning, coinReward: 250, akylReward: 50, targetValue: 25),
    Achievement(id: 'ach_level_50', title: 'Ғарышкер', description: '50-деңгейге жет', icon: '🚀', category: AchievementCategory.learning, coinReward: 500, akylReward: 100, targetValue: 50),
    Achievement(id: 'ach_level_100', title: 'Аңыз', description: '100-деңгейге жет', icon: '🌌', category: AchievementCategory.special, coinReward: 2000, akylReward: 500, targetValue: 100),
    Achievement(id: 'ach_perfect_10', title: 'Мерген', description: '10 тапсырманы қатесіз орында', icon: '🎯', category: AchievementCategory.learning, coinReward: 150, akylReward: 30, targetValue: 10),
    Achievement(id: 'ach_boss_5', title: 'Босс жеңуші', description: '5 босс-тапсырманы жең', icon: '👹', category: AchievementCategory.learning, coinReward: 200, akylReward: 40, targetValue: 5),
    Achievement(id: 'ach_grade_complete', title: 'Сынып чемпионы', description: 'Бір сыныпты толық аяқта', icon: '🏔️', category: AchievementCategory.learning, coinReward: 300, akylReward: 60, targetValue: 1),

    // ---- Батл ----
    Achievement(id: 'ach_first_battle', title: 'Алғашқы айқас', description: 'Бірінші батлға қатыс', icon: '⚔️', category: AchievementCategory.battle, coinReward: 30, targetValue: 1),
    Achievement(id: 'ach_battle_win', title: 'Алғашқы жеңіс', description: 'Батлда бірінші рет жең', icon: '🏆', category: AchievementCategory.battle, coinReward: 50, akylReward: 10, targetValue: 1),
    Achievement(id: 'ach_battles_10', title: 'Жауынгер', description: '10 батл ойна', icon: '🛡️', category: AchievementCategory.battle, coinReward: 100, targetValue: 10),
    Achievement(id: 'ach_battles_50', title: 'Батыр', description: '50 батл ойна', icon: '🗡️', category: AchievementCategory.battle, coinReward: 300, akylReward: 50, targetValue: 50),
    Achievement(id: 'ach_wins_10', title: 'Чемпион', description: '10 батлда жең', icon: '🥇', category: AchievementCategory.battle, coinReward: 200, akylReward: 40, targetValue: 10),
    Achievement(id: 'ach_wins_25', title: 'Гладиатор', description: '25 батлда жең', icon: '🏅', category: AchievementCategory.battle, coinReward: 400, akylReward: 80, targetValue: 25),
    Achievement(id: 'ach_win_streak_3', title: 'Жеңіс легі', description: 'Қатарынан 3 батлда жең', icon: '🔱', category: AchievementCategory.battle, coinReward: 150, akylReward: 30, targetValue: 3),

    // ---- Коллекция ----
    Achievement(id: 'ach_first_purchase', title: 'Алғашқы сатып алу', description: 'Дүкеннен бірінші зат ал', icon: '🛍️', category: AchievementCategory.collection, coinReward: 25, targetValue: 1),
    Achievement(id: 'ach_items_5', title: 'Сәнқой', description: '5 зат сатып ал', icon: '👕', category: AchievementCategory.collection, coinReward: 80, targetValue: 5),
    Achievement(id: 'ach_items_15', title: 'Коллекционер', description: '15 зат сатып ал', icon: '🎒', category: AchievementCategory.collection, coinReward: 200, targetValue: 15),
    Achievement(id: 'ach_first_pet', title: 'Жанашыр', description: 'Бірінші питомец сатып ал', icon: '🐾', category: AchievementCategory.collection, coinReward: 100, targetValue: 1),
    Achievement(id: 'ach_legendary', title: 'Аңыз иесі', description: 'Legendary зат сатып ал', icon: '💜', category: AchievementCategory.collection, coinReward: 300, akylReward: 50, targetValue: 1),
    Achievement(id: 'ach_coins_5000', title: 'Байлық', description: 'Барлығы 5000 монета жина', icon: '💰', category: AchievementCategory.collection, coinReward: 250, targetValue: 5000),

    // ---- Достар ----
    Achievement(id: 'ach_first_friend', title: 'Алғашқы дос', description: 'Бірінші досыңды қос', icon: '🤝', category: AchievementCategory.friends, coinReward: 30, targetValue: 1),
    Achievement(id: 'ach_friends_5', title: 'Көпшіл', description: '5 дос қос', icon: '👥', category: AchievementCategory.friends, coinReward: 100, targetValue: 5),
    Achievement(id: 'ach_friends_10', title: 'Достық алқасы', description: '10 дос қос', icon: '🫂', category: AchievementCategory.friends, coinReward: 200, akylReward: 30, targetValue: 10),

    // ---- Streak ----
    Achievement(id: 'ach_streak_3', title: 'Үш күн қатар', description: '3 күндік streak', icon: '🔥', category: AchievementCategory.streak, coinReward: 40, targetValue: 3),
    Achievement(id: 'ach_streak_7', title: 'Апта жалыны', description: '7 күндік streak', icon: '🔥', category: AchievementCategory.streak, coinReward: 100, akylReward: 20, targetValue: 7),
    Achievement(id: 'ach_streak_30', title: 'Ай жалыны', description: '30 күндік streak', icon: '🌋', category: AchievementCategory.streak, coinReward: 500, akylReward: 100, targetValue: 30),
    Achievement(id: 'ach_streak_100', title: 'Мәңгі жалын', description: '100 күндік streak', icon: '☄️', category: AchievementCategory.streak, coinReward: 2000, akylReward: 400, targetValue: 100),

    // ---- Арнайы ----
    Achievement(id: 'ach_early_bird', title: 'Ерте тұрған', description: 'Таңғы 7-ге дейін сабақ оқы', icon: '🌅', category: AchievementCategory.special, coinReward: 50, targetValue: 1),
    Achievement(id: 'ach_night_owl', title: 'Түнгі үкі', description: 'Түнгі 11-ден кейін сабақ оқы', icon: '🦉', category: AchievementCategory.special, coinReward: 50, targetValue: 1),
    Achievement(id: 'ach_tournament', title: 'Турнирші', description: 'Турнирге қатыс', icon: '🏟️', category: AchievementCategory.special, coinReward: 100, akylReward: 20, targetValue: 1),

    // ---- Шеберлік (бейімделетін оқыту) ----
    Achievement(id: 'ach_topic_master', title: 'Тақырып шебері', description: 'Бір тақырыпты «Шебер» деңгейіне жеткіз', icon: '🌟', category: AchievementCategory.learning, coinReward: 80, akylReward: 15, targetValue: 1),
    Achievement(id: 'ach_proven_5', title: 'Берік білім', description: '5 тақырыпты «Бекіді» деңгейіне жеткіз', icon: '💪', category: AchievementCategory.learning, coinReward: 120, akylReward: 25, targetValue: 5),
    Achievement(id: 'ach_topics_master_10', title: 'Білім зергері', description: '10 тақырыпты «Шебер» деңгейіне жеткіз', icon: '✨', category: AchievementCategory.learning, coinReward: 300, akylReward: 60, targetValue: 10),
    Achievement(id: 'ach_subject_master', title: 'Пән сұңқары', description: 'Бір пәнді толық «Шебер» деңгейіне жеткіз', icon: '👑', category: AchievementCategory.special, coinReward: 500, akylReward: 100, targetValue: 1),

    // ---- Батл шеберлігі ----
    Achievement(id: 'ach_battle_combo', title: 'Комбо шебері', description: 'Батлда қатарынан 5 рет дұрыс жауап бер', icon: '🔥', category: AchievementCategory.battle, coinReward: 100, akylReward: 25, targetValue: 5),
    Achievement(id: 'ach_battle_perfect', title: 'Мінсіз батл', description: 'Батлда барлық сұраққа дұрыс жауап бер', icon: '⭐', category: AchievementCategory.battle, coinReward: 150, akylReward: 40, targetValue: 1),
  ];
}
