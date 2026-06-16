/// Барлық UI мәтіндері — қазақша (кириллица).
abstract final class AppStrings {
  // ---- Жалпы ----
  static const appName = 'QosQanat';
  static const appVersion = 'QosQanat v2.0.0';
  static const loading = 'Жүктелуде...';
  static const continueBtn = 'Жалғастыру';
  static const cancel = 'Болдырмау';
  static const done = 'Дайын';
  static const choose = 'Таңдау';
  static const back = 'Артқа';
  static const retry = 'Қайталау';
  static const error = 'Қате орын алды';
  static const copied = 'Көшірілді!';

  // ---- Қош келдің ----
  static const welcomeTitle = 'QosQanat-қа қош келдің!';
  static const welcomeSubtitle =
      'Серігіңмен бірге оқы. Даладан аспанға шарықта — бүркіт қанатымен.';
  static const startBtn = 'Бастау';
  static const haveAccount = 'Аккаунтым бар →';

  // ---- Кіру ----
  static const loginTitle = 'Қайта қош келдің!';
  static const loginSubtitle = 'Аккаунтыңа кіріп, оқуды жалғастыр.';
  static const phoneLabel = 'Телефон нөмірі';
  static const phoneHint = '+7 (___) ___-__-__';
  static const passwordLabel = 'Құпиясөз';
  static const passwordHint = 'Құпиясөзіңді енгіз';
  static const loginBtn = 'Кіру';
  static const forgotPassword = 'Құпиясөзді ұмыттың ба?';
  static const noAccount = 'Аккаунтың жоқ па? Тіркелу';
  static const loginError = 'Телефон немесе құпиясөз қате';
  static const userNotFound = 'Бұл нөмірмен аккаунт табылмады';

  // ---- Тіркелу ----
  static const registerTitle = 'Тіркелу';
  static const step1Title = 'Өзің туралы';
  static const step1Subtitle = 'Танысып алайық!';
  static const fullNameLabel = 'Аты-жөні';
  static const fullNameHint = 'Мысалы: Әлихан Серіков';
  static const iinLabel = 'ЖСН (12 сан)';
  static const iinHint = '____________';
  static const step2Title = 'Құпиясөз жаса';
  static const step2Subtitle = 'Аккаунтыңды қорғайтын мықты құпиясөз.';
  static const confirmPasswordLabel = 'Құпиясөзді қайтала';
  static const passwordWeak = 'Әлсіз';
  static const passwordMedium = 'Орташа';
  static const passwordStrong = 'Күшті';
  static const passwordRule1 = 'Кемінде 8 таңба';
  static const passwordRule2 = 'Бір сан';
  static const passwordRule3 = 'Бір бас әріп';
  static const passwordsMatch = 'Құпиясөздер сәйкес';
  static const passwordsMismatch = 'Құпиясөздер сәйкес емес';
  static const step3Title = 'Мектебің туралы';
  static const step3Subtitle = 'Рейтингте мектебіңді көрсетеміз.';
  static const cityLabel = 'Қала';
  static const schoolLabel = 'Мектеп атауы';
  static const schoolHint = 'Мысалы: №25 мектеп-гимназия';
  static const gradeLabel = 'Сынып';
  static const step4Title = 'Тексеріп шық';
  static const step4Subtitle = 'Барлығы дұрыс па?';
  static const agreement1 = 'Қолдану шарттарымен келісемін';
  static const agreement2 = 'Құпиялылық саясатымен келісемін';
  static const registerBtn = 'Тіркелу';
  static const phoneTaken = 'Бұл нөмір тіркеліп қойған';

  // ---- Құпиясөзді қалпына келтіру ----
  static const forgotTitle = 'Құпиясөзді қалпына келтіру';
  static const forgotSubtitle = 'Телефон нөміріңді енгіз — растау кодын жібереміз.';
  static const sendCode = 'Код жіберу';
  static const otpTitle = 'Растау коды';
  static const otpResend = 'Код келмеді ме? Қайта жіберу';
  static const verify = 'Растау';
  static const newPasswordLabel = 'Жаңа құпиясөз';
  static const resetSuccess = 'Құпиясөз жаңартылды!';
  static const otpWrong = 'Код қате, қайта тексер';

  // ---- Серік таңдау ----
  static const assistantTitle = 'Серігіңді таңда';
  static const assistantSubtitle = 'Ол сенімен бірге оқиды, жеңісте қуанады.';
  static const bekturName = 'Бектұр';
  static const bekturDesc = 'Қайратты · мотивациялаушы';
  static const nazymName = 'Назым';
  static const nazymDesc = 'Мейірімді · сабырлы';
  static const assistantPicked = 'Таңдадым';
  static const welcomeGiftTitle = 'Қош келдің сыйлығы!';
  static const welcomeGiftDesc = '100 монета саған сыйға!';
  static const enterApp = 'Қосымшаға кіру';

  // ---- Басты бет ----
  static const greetingMorning = 'Қайырлы таң,';
  static const greetingDay = 'Қайырлы күн,';
  static const greetingEvening = 'Қайырлы кеш,';
  static const newsSection = '📢 Жаңалықтар';
  static const readMore = 'Толығырақ →';
  static const newsEmpty = 'Әзірге жаңалық жоқ';

  // ---- Навигация ----
  static const tabHome = 'Басты бет';
  static const tabRating = 'Рейтинг';
  static const tabLearn = 'Оқу';
  static const tabShop = 'Shop';
  static const tabProfile = 'Профиль';

  // ---- Drawer ----
  static const drawerTournament = 'Турнир';
  static const drawerFriends = 'Достар';
  static const drawerSettings = 'Баптаулар';
  static const drawerSupport = 'Қолдау';
  static const drawerAbout = 'QosQanat туралы';
  static const drawerLogout = 'Шығу';
  static const drawerActive = 'Белсенді';
  static const statLevel = 'ДЕҢГЕЙ';
  static const statAkyl = 'АҚЫЛ';
  static const statCoins = 'МОНЕТА';

  // ---- Оқу ----
  static const learnTitle = 'Қай пәнді оқимыз?';
  static const subjectMath = 'Математика';
  static const subjectKazakh = 'Қазақ тілі';
  static const subjectEnglish = 'Ағылшын';
  static const subjectPhysics = 'Физика';
  static const subjectCS = 'Информатика';
  static const nodeStart = 'Бастау';
  static const nodeRepeat = 'Қайталау';
  static const mapDone = 'аяқталды';
  static const moduleWord = 'Модуль';
  static const gradeMaterial = '-сынып материалы';
  static const questionWord = 'сұрақ';
  static const bestResult = 'Үздік нәтиже';

  // ---- Тапсырма ----
  static const questionCounter = 'Сұрақ';
  static const correctAnswer = 'Дұрыс! 🎉';
  static const wrongAnswer = 'Қате. Дұрыс жауап:';
  static const taskComplete = 'Тапсырма аяқталды!';
  static const nextUnlocked = 'Жаңа биік бағындырылды! 🦅';
  static const matchTitle = 'Жұптарды сәйкестендір';
  static const matchHint = 'Сол жақтан карточканы, сосын оң жақтан сыңарын таңда';
  static const typeChoice = 'Дұрыс жауапты таңда';
  static const typeTrueFalse = 'Дұрыс / Бұрыс';
  static const typeFillBlank = 'Бос орынды толтыр';
  static const diffEasy = 'Оңай';
  static const diffMedium = 'Орташа';
  static const diffHard = 'Қиын';
  static const accuracy = 'Дәлдік';
  static const rewards = 'Сыйлықтар';
  static const heartsOut = 'Жүрек таусылды! Қайтадан көр.';

  // ---- Дүкен ----
  static const shopTitle = '🛍️ Дүкен';
  static const catTop = 'Жоғарғы';
  static const catBottom = 'Төменгі';
  static const catHat = 'Бас киім';
  static const catAccessory = 'Аксессуар';
  static const catPet = 'Питомец';
  static const equipped = 'КИГЕН ✓';
  static const purchased = 'АЛЫНДЫ';
  static const itemNew = 'ЖАҢА';
  static const buy = 'Сатып алу';
  static const tryOn = 'Аватарда көру';
  static const boughtToast = 'Алынды! ✓';
  static const notEnoughCoins = '💰 Монета жетімсіз!';
  static const levelRequired = 'деңгей қажет';

  // ---- Достар ----
  static const friendsTitle = 'Достар';
  static const tabMyFriends = 'Достарым';
  static const tabRequests = 'Өтінімдер';
  static const tabSearch = 'Іздеу';
  static const searchHint = 'QQ-XXXXXXXXX';
  static const searchBtn = 'Іздеу';
  static const addFriend = 'Дос қос +';
  static const requestSent = 'Өтінім жіберілді ✓';
  static const accept = 'Қабылдау';
  static const decline = 'Бас тарту';
  static const noFriends = 'Әзірге дос жоқ. Іздеп тауып, қос!';
  static const noRequests = 'Жаңа өтінім жоқ';
  static const notFoundUser = 'Қолданушы табылмады';
  static const battleBtn = '⚔️ Батл';

  // ---- Батл ----
  static const battleSetupTitle = 'Батл баптауы';
  static const questionCount = 'Сұрақ саны';
  static const subjectFilter = 'Пән';
  static const allSubjects = 'Барлығы';
  static const startBattle = '⚔️ Батл бастау!';
  static const battleWin = 'ЖЕҢІС! 🏆';
  static const battleLose = 'Келесіде жеңесің! 💪';
  static const battleDraw = 'Тең нәтиже!';
  static const rebattle = 'Қайта батл';
  static const toHome = 'Басты бетке';
  static const you = 'Сен';
  static const battleQuitTitle = 'Батлдан шығасың ба?';
  static const battleQuitBody =
      'Шықсаң, батл есептелмейді және марапат берілмейді.';
  static const battleQuitConfirm = 'Шығу';
  static const battleQuitStay = 'Қалу';

  // ---- Рейтинг ----
  static const ratingTitle = 'Рейтинг';
  static const scopeGlobal = '🌍 Жалпы';
  static const scopeCity = '🏙️ Қалам';
  static const scopeSchool = '🏫 Мектебім';
  static const scopeFriends = '👥 Достарым';
  static const schoolRatingEmpty =
      'Мектеп рейтингі 10+ оқушы тіркелгенде ашылады';

  // ---- Профиль ----
  static const profileTitle = 'Профиль';
  static const achievements = 'Жетістіктер';
  static const unlockedOf = 'ашылды';
  static const activity = 'Белсенділік';
  static const recentBattles = 'Соңғы батлдар';
  static const statTasks = 'Тапсырма';
  static const statBattles = 'Батл';
  static const statFriends = 'Дос';
  static const statStreak = 'Күн streak';
  static const logoutConfirm = 'Шынымен шыққың келе ме?';
  static const logout = 'Шығу';

  // ---- Баптаулар ----
  static const settingsTitle = 'Баптаулар';
  static const sectionGeneral = 'Жалпы';
  static const settingLanguage = 'Тіл';
  static const settingSound = 'Дыбыс';
  static const settingVibration = 'Дірiл';
  static const settingAnimations = 'Анимациялар';
  static const sectionNotifications = 'Хабарландырулар';
  static const settingNotifications = 'Хабарландыру';
  static const settingReminder = 'Күнделікті еске салу';
  static const sectionAccount = 'Аккаунт';
  static const settingEditProfile = 'Профильді өзгерту';
  static const settingChangeAssistant = 'Серікті ауыстыру';
  static const assistantCooldown = '30 күнде бір рет ауыстыруға болады';
  static const settingCopyId = 'QQ-ID көшіру';
  static const sectionAbout = 'Қосымша туралы';
  static const settingVersion = 'Нұсқа';
  static const settingTerms = 'Қолдану шарттары';
  static const settingPrivacy = 'Құпиялылық саясаты';
  static const settingSupport = 'Қолдау қызметі';

  // ---- Турнир ----
  static const tournamentTitle = 'Турнир';
  static const tournamentPrize = 'Жүлде қоры';
  static const tournamentJoin = 'Қатысу';
  static const tournamentJoined = 'Қатысып жатырсың ✓';
  static const tournamentEnds = 'Аяқталуына';

  // ---- Квесттер ----
  static const dailyQuests = 'Күнделікті тапсырмалар';
  static const claim = 'Алу';
  static const questClaimed = 'Сыйлық алынды!';

  // ---- Геймификация ----
  static const levelUp = 'Жаңа деңгей!';
  static const streakKept = 'Streak жалғасты! 🔥';
  static const achievementUnlocked = 'Жаңа жетістік! 🏅';
  static const xpShort = 'XP';

  // ---- Параметрлі хабарламалар ----
  static const appTagline = '«Бүркіт қанаты»';
  static const photoUpdated = 'Профиль суреті жаңартылды! 📸';
  static const photoFailed = 'Сурет таңдау сәтсіз болды. Қайталап көр';
  static const profileUpdated = 'Профиль жаңартылды ✓';
  static const rusComingSoon = 'Орыс тілі — жақында!';
  static const tournamentEmpty = 'Әзірге белсенді турнир жоқ';
  static const participants = 'Қатысушы';
  static const daysShort = 'күн';

  static String comingSoon(String feature) => '$feature — жақында!';
  static String levelUpBody(int level) =>
      'Сен енді $level-деңгейдесің! Жаңа биіктер күтеді 🦅';
  static String nowYourFriend(String name) => '$name — енді досың! 🤝';
  static String nowYourAssistant(String name) => '$name — енді серігің! 🦅';
  static String assistantCooldownLeft(int days) =>
      'Серікті $days күннен кейін ауыстыра аласың';
  static String tournamentJoinedToast(String title) =>
      '$title — қатысып жатырсың! 🏟️';
}
