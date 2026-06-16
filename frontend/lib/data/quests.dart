import '../models/enums.dart';
import '../models/quest.dart';

/// Күнделікті квесттер пулы (60+). Күн сайын осы пулдан
/// детерминистік түрде 5 квест таңдалады.
abstract final class QuestsData {
  static Quest? byId(String id) {
    for (final q in pool) {
      if (q.id == id) return q;
    }
    return null;
  }

  static const List<Quest> pool = [
    // ---- Кіру ----
    Quest(id: 'q_login', title: 'Бүгін қосымшаға кір', type: QuestType.login, target: 1, coinReward: 10, icon: '👋'),
    Quest(id: 'q_login_morning', title: 'Таңертең сабақ баста', type: QuestType.login, target: 1, coinReward: 15, icon: '🌅'),

    // ---- Тапсырмалар ----
    Quest(id: 'q_task_1', title: '1 тапсырма орында', type: QuestType.completeTasks, target: 1, coinReward: 15, xpReward: 10, icon: '📖'),
    Quest(id: 'q_task_2', title: '2 тапсырма орында', type: QuestType.completeTasks, target: 2, coinReward: 25, xpReward: 15, icon: '📖'),
    Quest(id: 'q_task_3', title: '3 тапсырма орында', type: QuestType.completeTasks, target: 3, coinReward: 30, xpReward: 20, icon: '📚'),
    Quest(id: 'q_task_4', title: '4 тапсырма орында', type: QuestType.completeTasks, target: 4, coinReward: 40, xpReward: 25, icon: '📚'),
    Quest(id: 'q_task_5', title: '5 тапсырма орында', type: QuestType.completeTasks, target: 5, coinReward: 50, xpReward: 30, icon: '🎓'),
    Quest(id: 'q_task_7', title: '7 тапсырма орында', type: QuestType.completeTasks, target: 7, coinReward: 70, xpReward: 40, icon: '🎓'),
    Quest(id: 'q_task_10', title: '10 тапсырма орында', type: QuestType.completeTasks, target: 10, coinReward: 100, xpReward: 60, akylReward: 10, icon: '🏔️'),

    // ---- Мінсіз тапсырма ----
    Quest(id: 'q_perfect_1', title: 'Қатесіз тапсырма орында', type: QuestType.perfectTask, target: 1, coinReward: 30, akylReward: 5, icon: '💎'),
    Quest(id: 'q_perfect_2', title: '2 тапсырманы қатесіз орында', type: QuestType.perfectTask, target: 2, coinReward: 50, akylReward: 10, icon: '💎'),
    Quest(id: 'q_perfect_3', title: '3 тапсырманы қатесіз орында', type: QuestType.perfectTask, target: 3, coinReward: 80, akylReward: 15, icon: '👑'),

    // ---- Батл ----
    Quest(id: 'q_battle_1', title: '1 батл ойна', type: QuestType.battle, target: 1, coinReward: 20, icon: '⚔️'),
    Quest(id: 'q_battle_2', title: '2 батл ойна', type: QuestType.battle, target: 2, coinReward: 35, icon: '⚔️'),
    Quest(id: 'q_battle_3', title: '3 батл ойна', type: QuestType.battle, target: 3, coinReward: 50, akylReward: 5, icon: '⚔️'),
    Quest(id: 'q_battle_win_1', title: 'Батлда жең', type: QuestType.battleWin, target: 1, coinReward: 40, akylReward: 10, icon: '🏆'),
    Quest(id: 'q_battle_win_2', title: '2 батлда жең', type: QuestType.battleWin, target: 2, coinReward: 70, akylReward: 20, icon: '🏆'),
    Quest(id: 'q_battle_win_3', title: '3 батлда жең', type: QuestType.battleWin, target: 3, coinReward: 100, akylReward: 30, icon: '🥇'),

    // ---- Дүкен ----
    Quest(id: 'q_purchase_1', title: 'Дүкеннен зат сатып ал', type: QuestType.purchase, target: 1, coinReward: 20, icon: '🛍️'),
    Quest(id: 'q_purchase_2', title: '2 зат сатып ал', type: QuestType.purchase, target: 2, coinReward: 40, icon: '🛍️'),

    // ---- Достар ----
    Quest(id: 'q_friend_1', title: 'Жаңа дос қос', type: QuestType.addFriend, target: 1, coinReward: 30, icon: '👥'),
    Quest(id: 'q_friend_2', title: '2 жаңа дос қос', type: QuestType.addFriend, target: 2, coinReward: 55, icon: '👥'),

    // ---- Streak ----
    Quest(id: 'q_streak_3', title: '3 күндік streak ұста', type: QuestType.streak, target: 3, coinReward: 40, akylReward: 5, icon: '🔥'),
    Quest(id: 'q_streak_5', title: '5 күндік streak ұста', type: QuestType.streak, target: 5, coinReward: 60, akylReward: 10, icon: '🔥'),
    Quest(id: 'q_streak_7', title: '7 күндік streak ұста', type: QuestType.streak, target: 7, coinReward: 100, akylReward: 20, icon: '🔥'),

    // ---- XP жинау ----
    Quest(id: 'q_xp_50', title: '50 XP жина', type: QuestType.earnXp, target: 50, coinReward: 20, icon: '⚡'),
    Quest(id: 'q_xp_100', title: '100 XP жина', type: QuestType.earnXp, target: 100, coinReward: 35, icon: '⚡'),
    Quest(id: 'q_xp_150', title: '150 XP жина', type: QuestType.earnXp, target: 150, coinReward: 50, icon: '⚡'),
    Quest(id: 'q_xp_200', title: '200 XP жина', type: QuestType.earnXp, target: 200, coinReward: 70, akylReward: 10, icon: '🌟'),
    Quest(id: 'q_xp_300', title: '300 XP жина', type: QuestType.earnXp, target: 300, coinReward: 100, akylReward: 15, icon: '🌟'),

    // ---- Пәндік тапсырмалар (тақырыптық нұсқалар) ----
    Quest(id: 'q_math_1', title: 'Математикадан тапсырма орында', type: QuestType.completeTasks, target: 1, coinReward: 20, icon: '➗'),
    Quest(id: 'q_math_2', title: 'Математикадан 2 тапсырма орында', type: QuestType.completeTasks, target: 2, coinReward: 35, icon: '➗'),
    Quest(id: 'q_kazakh_1', title: 'Қазақ тілінен тапсырма орында', type: QuestType.completeTasks, target: 1, coinReward: 20, icon: '🗣️'),
    Quest(id: 'q_kazakh_2', title: 'Қазақ тілінен 2 тапсырма орында', type: QuestType.completeTasks, target: 2, coinReward: 35, icon: '🗣️'),
    Quest(id: 'q_english_1', title: 'Ағылшыннан тапсырма орында', type: QuestType.completeTasks, target: 1, coinReward: 20, icon: '🇬🇧'),
    Quest(id: 'q_english_2', title: 'Ағылшыннан 2 тапсырма орында', type: QuestType.completeTasks, target: 2, coinReward: 35, icon: '🇬🇧'),
    Quest(id: 'q_physics_1', title: 'Физикадан тапсырма орында', type: QuestType.completeTasks, target: 1, coinReward: 20, icon: '🔬'),
    Quest(id: 'q_physics_2', title: 'Физикадан 2 тапсырма орында', type: QuestType.completeTasks, target: 2, coinReward: 35, icon: '🔬'),
    Quest(id: 'q_cs_1', title: 'Информатикадан тапсырма орында', type: QuestType.completeTasks, target: 1, coinReward: 20, icon: '💻'),
    Quest(id: 'q_cs_2', title: 'Информатикадан 2 тапсырма орында', type: QuestType.completeTasks, target: 2, coinReward: 35, icon: '💻'),

    // ---- Аралас күрделі ----
    Quest(id: 'q_combo_1', title: 'Тапсырма орында және батл ойна', type: QuestType.completeTasks, target: 1, coinReward: 45, icon: '🎯'),
    Quest(id: 'q_boss_1', title: 'Босс-тапсырманы жең', type: QuestType.perfectTask, target: 1, coinReward: 60, akylReward: 15, icon: '👹'),
    Quest(id: 'q_quiz_1', title: 'Викторина өт', type: QuestType.completeTasks, target: 1, coinReward: 25, icon: '❓'),
    Quest(id: 'q_quiz_2', title: '2 викторина өт', type: QuestType.completeTasks, target: 2, coinReward: 45, icon: '❓'),
    Quest(id: 'q_treasure_1', title: 'Қазына сандығын аш', type: QuestType.completeTasks, target: 1, coinReward: 30, icon: '🎁'),

    // ---- XP қосымша ----
    Quest(id: 'q_xp_75', title: '75 XP жина', type: QuestType.earnXp, target: 75, coinReward: 28, icon: '⚡'),
    Quest(id: 'q_xp_120', title: '120 XP жина', type: QuestType.earnXp, target: 120, coinReward: 42, icon: '⚡'),
    Quest(id: 'q_xp_250', title: '250 XP жина', type: QuestType.earnXp, target: 250, coinReward: 85, akylReward: 12, icon: '🌟'),

    // ---- Тапсырма қосымша ----
    Quest(id: 'q_task_6', title: '6 тапсырма орында', type: QuestType.completeTasks, target: 6, coinReward: 60, xpReward: 35, icon: '📚'),
    Quest(id: 'q_task_8', title: '8 тапсырма орында', type: QuestType.completeTasks, target: 8, coinReward: 80, xpReward: 45, icon: '🎓'),
    Quest(id: 'q_perfect_4', title: '4 тапсырманы қатесіз орында', type: QuestType.perfectTask, target: 4, coinReward: 100, akylReward: 20, icon: '👑'),
    Quest(id: 'q_battle_4', title: '4 батл ойна', type: QuestType.battle, target: 4, coinReward: 65, akylReward: 8, icon: '⚔️'),
    Quest(id: 'q_battle_win_4', title: '4 батлда жең', type: QuestType.battleWin, target: 4, coinReward: 130, akylReward: 40, icon: '🥇'),
    Quest(id: 'q_streak_10', title: '10 күндік streak ұста', type: QuestType.streak, target: 10, coinReward: 150, akylReward: 30, icon: '🔥'),
    Quest(id: 'q_streak_14', title: '14 күндік streak ұста', type: QuestType.streak, target: 14, coinReward: 200, akylReward: 40, icon: '🔥'),
    Quest(id: 'q_purchase_pet', title: 'Питомец сатып ал', type: QuestType.purchase, target: 1, coinReward: 50, icon: '🐾'),
    Quest(id: 'q_friend_3', title: '3 жаңа дос қос', type: QuestType.addFriend, target: 3, coinReward: 80, icon: '👥'),
    Quest(id: 'q_login_evening', title: 'Кешке қайталау жаса', type: QuestType.login, target: 1, coinReward: 12, icon: '🌙'),
    Quest(id: 'q_task_repeat', title: 'Өткен сабақты қайтала', type: QuestType.completeTasks, target: 1, coinReward: 18, icon: '🔄'),
    Quest(id: 'q_boss_2', title: '2 босс-тапсырманы жең', type: QuestType.perfectTask, target: 2, coinReward: 120, akylReward: 25, icon: '👹'),
    Quest(id: 'q_quiz_3', title: '3 викторина өт', type: QuestType.completeTasks, target: 3, coinReward: 65, icon: '❓'),
    Quest(id: 'q_treasure_2', title: '2 қазына сандығын аш', type: QuestType.completeTasks, target: 2, coinReward: 55, icon: '🎁'),
  ];
}
