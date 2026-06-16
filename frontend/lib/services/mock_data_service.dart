import 'dart:math';

import '../models/enums.dart';
import '../models/friend.dart';
import '../models/news.dart';
import '../models/tournament.dart';
import '../models/user.dart';
import 'local_storage_service.dart';

/// Mock деректерді өндіру: демо қолданушылар, жаңалықтар, турнир.
/// Offline режімде «сервер» рөлін осы seed атқарады.
class MockDataService {
  MockDataService._();
  static final MockDataService instance = MockDataService._();

  static const _qqChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// QQ-XXXXXXXXX форматындағы жаңа ID.
  static String generateQqId([Random? random]) {
    final r = random ?? Random();
    final code =
        List.generate(9, (_) => _qqChars[r.nextInt(_qqChars.length)]).join();
    return 'QQ-$code';
  }

  static String generateUserId([Random? random]) {
    final r = random ?? Random();
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final salt = r.nextInt(0xFFFFFF).toRadixString(36);
    return 'u_${stamp}_$salt';
  }

  /// Алғашқы іске қосуда бір рет шақырылады.
  Future<void> seedMockData() async {
    final storage = LocalStorageService.instance;
    if (storage.isSeeded) return;

    final random = Random(42);
    final now = DateTime.now();

    // ---- Демо қолданушы: Әлихан ----
    final alikhan = User(
      id: 'u_demo_alikhan',
      qosqanatId: 'QQ-A7K9M2P4X',
      fullName: 'Әлихан Серіков',
      phone: '+7 (701) 234-56-78',
      iin: '091231550123',
      city: 'Алматы',
      school: '№25 мектеп-гимназия',
      grade: 7,
      level: 12,
      xp: 7150,
      coins: 1250,
      akylPoints: 890,
      assistantType: AssistantType.bektur,
      currentStreak: 7,
      longestStreak: 12,
      lastLoginDate: now,
      tasksCompleted: 86,
      battlesTotal: 14,
      battlesWon: 9,
      unlockedAchievements: const [
        'ach_first_task',
        'ach_tasks_10',
        'ach_tasks_50',
        'ach_level_5',
        'ach_level_10',
        'ach_streak_3',
        'ach_streak_7',
        'ach_first_battle',
        'ach_battle_win',
        'ach_battles_10',
        'ach_first_friend',
        'ach_first_purchase',
      ],
      activityDays: List.generate(18, (i) {
        final d = now.subtract(Duration(days: i * 2 ~/ 1 + (i % 3 == 0 ? 1 : 0)));
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }),
      createdAt: now.subtract(const Duration(days: 64)),
    );
    await storage.saveUser(alikhan);

    // ---- 24 сұхбатты қолданушы (рейтинг / достар / батл үшін) ----
    const names = [
      'Аружан Қайратқызы', 'Дәулет Нұрланұлы', 'Айзере Болатқызы',
      'Алдияр Сейітұлы', 'Томирис Ержанқызы', 'Нұрасыл Бекзатұлы',
      'Інжу Маратқызы', 'Санжар Талғатұлы', 'Аяла Думанқызы',
      'Бекарыс Қанатұлы', 'Мадина Асылқызы', 'Темірлан Ғалымұлы',
      'Жібек Айдосқызы', 'Алинур Серікұлы', 'Камила Бауыржанқызы',
      'Ерасыл Жандосұлы', 'Аяжан Олжасқызы', 'Диас Әділетұлы',
      'Назерке Қуанышқызы', 'Арлан Мейірұлы', 'Әсем Жарасқызы',
      'Ислам Нұрсұлтанұлы', 'Балауса Еркінқызы', 'Айсұлтан Дарханұлы',
    ];
    const cities = ['Алматы', 'Астана', 'Шымкент', 'Қарағанды', 'Алматы',
      'Алматы', 'Тараз', 'Астана'];
    const schools = [
      '№25 мектеп-гимназия', '№12 лицей', 'НЗМ ФМБ', '№7 орта мектеп',
      '№25 мектеп-гимназия', 'БІЛ', '№25 мектеп-гимназия', '№48 гимназия',
    ];

    for (var i = 0; i < names.length; i++) {
      final level = 3 + random.nextInt(28);
      final user = User(
        id: 'u_mock_$i',
        qosqanatId: generateQqId(random),
        fullName: names[i],
        phone: '+7 (70${random.nextInt(9)}) ${100 + random.nextInt(899)}-'
            '${10 + random.nextInt(89)}-${10 + random.nextInt(89)}',
        city: cities[i % cities.length],
        school: schools[i % schools.length],
        grade: 5 + random.nextInt(7),
        level: level,
        xp: level * level * 50,
        coins: 100 + random.nextInt(3000),
        akylPoints: 50 + random.nextInt(2600),
        assistantType:
            random.nextBool() ? AssistantType.bektur : AssistantType.nazym,
        currentStreak: random.nextInt(20),
        longestStreak: 5 + random.nextInt(40),
        tasksCompleted: 10 + random.nextInt(300),
        battlesTotal: random.nextInt(60),
        battlesWon: random.nextInt(30),
        createdAt: now.subtract(Duration(days: 10 + random.nextInt(180))),
      );
      await storage.saveUser(user);
    }

    // ---- Жаңалықтар (handoff §5.2 нақты көшірмесі) ----
    final newsItems = [
      News(
        id: 'news_1',
        category: NewsCategory.tournament,
        title: 'Көктемгі Ақыл Кубогі басталды!',
        preview:
            '500 000 ₸ жүлде қоры. Мектебіңді чемпион ет, достарыңды шақыр — '
            'әр батл ақыл ұпайын әкеледі.',
        publishedAt: now.subtract(const Duration(hours: 2)),
        hasCover: true,
        body:
            'Көктемгі Ақыл Кубогі — QosQanat-тың ең үлкен турнирі. Қатысу үшін '
            'батлдарда жеңіп, ақыл ұпайын жина. Үздік 100 оқушы финалға өтеді. '
            'Жүлде қоры — 500 000 ₸, мектебіңе арнайы кубок!',
      ),
      News(
        id: 'news_2',
        category: NewsCategory.update,
        title: 'v2.0 — Offline режім келді!',
        preview:
            'Енді QosQanat интернетсіз де жұмыс істейді. Барлық сабақтар мен '
            'тапсырмалар телефоныңда сақталады.',
        publishedAt: now.subtract(const Duration(hours: 11)),
        body:
            'QosQanat 2.0 жаңартуында қосымша толық offline режімге көшті. '
            'Сабақтар, квесттер, дүкен — бәрі интернетсіз қолжетімді.',
      ),
      News(
        id: 'news_3',
        category: NewsCategory.tip,
        title: 'Күн сайын 15 минут — нәтиже айқын',
        preview:
            'Зерттеу: қысқа әрі тұрақты сабақтар ұзақ отырудан 3 есе тиімді. '
            'Streak-ті үзбе!',
        publishedAt: now.subtract(const Duration(days: 1)),
        body:
            'Ғалымдардың зерттеуі бойынша күнделікті қысқа сабақтар білімді '
            'ұзақ мерзімге бекітеді. Күн сайын кемінде бір тапсырма орында — '
            'streak сақталады және қосымша сыйлық береді.',
      ),
      News(
        id: 'news_4',
        category: NewsCategory.event,
        title: 'Алматыда офлайн кездесу — 14 маусым',
        preview:
            'Топ-100 оқушы бір жерде! Викториналар, сыйлықтар және жаңа '
            'достар күтеді.',
        publishedAt: now.subtract(const Duration(days: 2)),
        hasCover: true,
        body:
            '14 маусымда Алматыда QosQanat қауымдастығының офлайн кездесуі '
            'өтеді. Рейтингтегі топ-100 оқушы шақырылады.',
      ),
      News(
        id: 'news_5',
        category: NewsCategory.tip,
        title: 'Босс-тапсырмаларға қалай дайындалу керек?',
        preview:
            'Әр модуль соңындағы босс 3 есе көп XP береді. Алдыңғы сабақтарды '
            'қайталап шық — жұлдыздар көмектеседі.',
        publishedAt: now.subtract(const Duration(days: 4)),
        body:
            'Босс-тапсырмалар модульдің барлық тақырыбын қамтиды. Дайындалу '
            'үшін: 1) барлық сабақты 3 жұлдызға аяқта, 2) қателескен '
            'сұрақтарды қайтала, 3) жүректеріңді үнемде.',
      ),
      News(
        id: 'news_6',
        category: NewsCategory.update,
        title: 'Дүкенге жаңа питомецтер келді 🐾',
        preview:
            'Барыс, бүркіт және айдаһар! Legendary питомецтер тек жоғары '
            'деңгейлі оқушыларға.',
        publishedAt: now.subtract(const Duration(days: 6)),
        body:
            'Дүкеннің «Питомец» бөлімінде жаңа серіктер: мысық, бүркіт, ақ '
            'барыс және айдаһар. Әрқайсысының өз сиректік деңгейі бар.',
      ),
    ];
    for (final news in newsItems) {
      await storage.saveNews(news);
    }

    // ---- Демо қолданушының достары мен өтінімдері ----
    for (var i = 0; i < 5; i++) {
      await storage.saveFriendRequest(FriendRequest(
        id: 'fr_seed_$i',
        fromUserId: 'u_mock_$i',
        toUserId: alikhan.id,
        status: FriendRequestStatus.accepted,
        createdAt: now.subtract(Duration(days: 30 - i * 3)),
      ));
    }
    for (var i = 5; i < 8; i++) {
      await storage.saveFriendRequest(FriendRequest(
        id: 'fr_seed_$i',
        fromUserId: 'u_mock_$i',
        toUserId: alikhan.id,
        createdAt: now.subtract(Duration(hours: i)),
      ));
    }

    // ---- Турнир ----
    await storage.saveTournament(Tournament(
      id: 'tour_spring_cup',
      title: 'Көктемгі Ақыл Кубогі',
      description:
          'Батлдарда жеңіп, ақыл ұпайын жина. Үздік 100 оқушы финалға өтеді. '
          'Мектебің үшін күрес!',
      prizePool: 500000,
      startsAt: now.subtract(const Duration(days: 3)),
      endsAt: now.add(const Duration(days: 18)),
      participants: 4218,
    ));

    await storage.markSeeded();
  }
}
