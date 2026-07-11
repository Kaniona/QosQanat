import 'dart:math';

import '../models/enums.dart';
import '../models/task_node.dart';
import 'banks/bank_types.dart';
import 'banks/cs_bank.dart';
import 'banks/cs_bank2.dart';
import 'banks/english_bank.dart';
import 'banks/english_gen.dart';
import 'banks/kazakh_bank.dart';
import 'banks/kazakh_gen.dart';
import 'banks/math_bank.dart';
import 'banks/math_bank_advanced.dart';
import 'banks/math_bank_advanced2.dart';
import 'banks/math_bank_extra.dart';
import 'banks/math_bank_hard.dart';
import 'banks/math_bank_redbook.dart';
import 'banks/physics_bank.dart';
import 'banks/biology_bank.dart';
import 'banks/chemistry_bank.dart';
import 'banks/history_bank.dart';
import 'banks/history_bank2.dart';

/// Банк жазбасы: (мәтін, нұсқалар, дұрыс индекс, түсіндірме, қиындық).
typedef _Q = BankQ;

/// Сәйкестендіру жұбы: (сол жақ, оң жақ).
typedef _P = BankP;

/// Толық оқу бағдарламасы: 5 пән × 11 сынып × 2 модуль × 16 node.
/// Әр node-та 56 сұрақтық пул (6 деңгейлі тиер),
/// 4 формат: таңдау, дұрыс/бұрыс, бос орын, сәйкестендіру.
/// Сессияда пулдан кездейсоқ ~12 сұрақ іріктеледі — қайталау жаттанды
/// болмауы үшін. Барлығы offline, кодта сақталады.
abstract final class Curriculum {
  static const int modulesPerGrade = 2;
  static const int nodesPerModule = 160; // 16 × 10

  /// Математика тапсырмалары ГЕНЕРАТОРМЕН емес, нақты ТЕКСЕРІЛГЕН банк
  /// тақырыптарынан disjoint (қайталанбайтын) тілімделеді — дұрыс жауап
  /// есептелуі шарт болғандықтан. Банк тілімі шектеулі: сынып тақырыбы 6 node-қа
  /// бөлінеді (5–11), 1–4 сыныпта 2 node. Оны 5 есе созу бос тапсырма тудырар
  /// еді (сұрақ жетпейді), сондықтан математика толық сапалы деңгейде қалады.
  /// Өзге пәндер генератормен 80 node-ты (56 сұрақтық пул) толтыра алады.
  static const int mathNodesSenior = 6;
  static const int mathNodesJunior = 2;
  static int mathNodesFor(int grade) =>
      grade >= 5 ? mathNodesSenior : mathNodesJunior;

  /// Пән/сыныпқа қарай бір модульдегі node саны. Математикада тақырыптық банк
  /// disjoint тілімделетіндіктен аз (mathNodesFor) — көбейту бос node тудырар
  /// еді. Өзге пәндер (тарих қоса) генератор/56-пул жүйесінде — [nodesPerModule].
  static int nodesPerModuleFor(String subject, int grade) =>
      subject == 'math' ? mathNodesFor(grade) : nodesPerModule;

  /// Бір node-тағы сұрақ пулының (генератор пәндері) көлемі.
  static const int questionPoolSize = 56;

  /// Бір сессияда көрсетілетін сұрақтың ЕҢ КӨП саны (нақты саны node пулынан
  /// аспайды — математикада тілім ~4–8 сұрақ).
  static const int sessionSize = 12;
  static const int treasureSessionSize = 5;

  /// 80 node-тың түр өрнегі (5 × 16, соңғысы — босс).
  static const List<NodeType> _pattern = [
    NodeType.lesson, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.treasure, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.treasure,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.boss,
    // 2-ші итерация (16)
    NodeType.lesson, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.treasure, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.treasure,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.boss,
    // 3-ші итерация (16)
    NodeType.lesson, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.treasure, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.treasure,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.boss,
    // 4-ші итерация (16)
    NodeType.lesson, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.treasure, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.treasure,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.boss,
    // 5-ші итерация (16)
    NodeType.lesson, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.treasure, NodeType.lesson, NodeType.quiz, NodeType.lesson,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.treasure,
    NodeType.lesson, NodeType.quiz, NodeType.lesson, NodeType.boss,
  ];

  /// Математика 1–4 сынып өрнегі (2 node): сабақ → босс.
  static const List<NodeType> _mathPatternJunior = [
    NodeType.lesson, NodeType.boss,
  ];

  /// Математика 5–11 сынып өрнегі (6 node): әр тақырып — қиындық бойынша өсетін
  /// саяхат (жеңіл тілім → қиын тілім). n0 — теория сабағы, соңы — босс.
  /// Тек n0 сабақ (теория қажет); қалғаны тақырыптың сұрақ тілімдері.
  static const List<NodeType> _mathPatternSenior = [
    NodeType.lesson, NodeType.quiz, NodeType.quiz,
    NodeType.treasure, NodeType.quiz, NodeType.boss,
  ];

  static List<NodeType> _patternFor(String subject, int grade) =>
      subject == 'math'
          ? (grade >= 5 ? _mathPatternSenior : _mathPatternJunior)
          : _pattern;

  /// Кэш кілті — «пән:сынып». Тек қажет сынып қана құрастырылады.
  static final Map<String, List<TaskNode>> _gradeCache = {};

  /// ТЕК берілген сыныптың node-тары. Басқа сыныптар ешқашан қайтпайды.
  static List<TaskNode> nodesForGrade(String subject, int grade) =>
      _gradeCache.putIfAbsent(
        '$subject:$grade',
        () => _buildGrade(subject, grade),
      );

  /// Берілген пән/сыныптағы тақырып (модуль) саны. Математикада сыныбына
  /// қарай әртүрлі (толық таксономия), қалғанда — [modulesPerGrade].
  static int moduleCount(String subject, int grade) =>
      _moduleCountFor(subject, grade);

  /// 1-сыныптан берілген сыныпқа ДЕЙІН (қоса) барлық node — оқушыға
  /// өз сыныбы мен одан төменгілері ашық, жоғарғылары мүлде көрінбейді.
  static List<TaskNode> nodesUpToGrade(String subject, int grade) => [
        for (var g = 1; g <= grade.clamp(1, 11); g++)
          ...nodesForGrade(subject, g),
      ];

  /// id пішімі: subject_g8_m1_n3 — сынып id-ден оқылып, тек сол
  /// сыныптың тізімі құрастырылады.
  static TaskNode? nodeById(String id) {
    final parts = id.split('_');
    if (parts.length < 4 || !parts[1].startsWith('g')) return null;
    final grade = int.tryParse(parts[1].substring(1));
    if (grade == null || grade < 1 || grade > 11) return null;
    for (final node in nodesForGrade(parts.first, grade)) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// Сессия сұрақтары: пулдан кездейсоқ іріктеу (әр кіргенде әртүрлі),
  /// қиындық үлесі ~60/30/10, жеңілден қиынға қарай реттелген.
  static List<Question> sessionQuestions(TaskNode node, {int? count}) {
    final target = count ??
        (node.type == NodeType.treasure ? treasureSessionSize : sessionSize);
    final random = Random();
    final byDiff = {
      for (final d in Difficulty.values)
        d: node.questions.where((q) => q.difficulty == d).toList()
          ..shuffle(random),
    };
    // 6 деңгейге шамамен тең үлес — жеңілден басқатырғышқа дейінгі өрлемелі
    // қисық (target=12 → әр деңгейден 2). Қалдық орта деңгейлерге қосылады.
    final levels = Difficulty.values;
    final per = target ~/ levels.length;
    var extra = target - per * levels.length;
    final picked = <Question>[];
    for (final d in levels) {
      var n = per;
      if (extra > 0 && d != Difficulty.light && d != Difficulty.brainTeaser) {
        n++;
        extra--;
      }
      picked.addAll(byDiff[d]!.take(n));
    }
    // Топ жетіспей қалса — қалған пулдан толтырамыз.
    if (picked.length < target) {
      final rest = node.questions.where((q) => !picked.contains(q)).toList()
        ..shuffle(random);
      picked.addAll(rest.take(target - picked.length));
    }
    // Мотивация қисығы: жеңілден қиынға (топ ішіндегі рет кездейсоқ).
    return [
      for (final d in Difficulty.values)
        ...picked.where((q) => q.difficulty == d),
    ];
  }

  /// Батлға арналған сұрақтар жинағы (детерминистік seed-пен).
  /// Сұрақтар ОҚУШЫНЫҢ СЫНЫБЫНА сай: өз сыныбы + бір сынып төмен ғана —
  /// 11-сынып оқушысына бастауыш сұрақтары ешқашан түспейді.
  static List<Question> battleQuestions({
    String subject = 'all',
    required int count,
    required int seed,
    int grade = 7,
  }) {
    final g = grade.clamp(1, 11);
    final random = Random(seed);
    final subjects = subject == 'all'
        ? const [
            'math', 'kazakh', 'english', 'physics', 'cs', 'biology',
            'chemistry', 'history'
          ]
        : [subject];
    final grades = g > 1 ? [g - 1, g] : [g];
    final pool = <Question>[];
    for (final s in subjects) {
      if (s == 'math') continue; // математика — төмендегі генератордан
      for (final gr in grades) {
        pool.addAll(_bankFor(s, gr));
      }
    }
    // Математика: сыныпқа сай генерацияланған сұрақтар.
    if (subject == 'all' || subject == 'math') {
      final mathShare = subject == 'math' ? count : max(count ~/ 5, 3);
      // Сыныпқа сай нақты банк сұрақтары (өз сыныбы + бір төмен).
      final mathBank = [..._mathRaw(g), ..._mathRaw(g - 1)]..shuffle(random);
      for (final raw in mathBank.take(mathShare)) {
        pool.add(_bankQuestion('battle_mathbank_${pool.length}', raw));
      }
      for (var i = 0; i < mathShare * 2; i++) {
        pool.add(_mathQuestion(
          'battle_math_$i',
          g,
          random,
          Difficulty.values[random.nextInt(Difficulty.values.length)],
        ));
      }
    }
    pool.shuffle(random);
    if (pool.length >= count) return pool.take(count).toList();
    while (pool.length < count) {
      pool.add(_mathQuestion(
        'battle_extra_${pool.length}',
        g,
        random,
        Difficulty.medium,
      ));
    }
    return pool;
  }

  // ---------------- Құрастыру ----------------

  static List<TaskNode> _buildGrade(String subject, int grade) {
    final nodes = <TaskNode>[];
    // Модуль саны — сол пән/сыныптың тақырып атаулары тізімінің ұзындығы
    // (математикада 5–11 сыныпта 3: 2 алгебра/арифметика + 1 геометрия),
    // әйтпесе әдепкі [modulesPerGrade].
    final moduleCount = _moduleCountFor(subject, grade);
    final nodeCount = nodesPerModuleFor(subject, grade);
    final pattern = _patternFor(subject, grade);
    for (var module = 1; module <= moduleCount; module++) {
      final moduleTitle = _moduleTitle(subject, grade, module);
      for (var i = 0; i < nodeCount; i++) {
        // Node саны өрнек ұзындығынан асса, өрнек циклдік қайталанады
        // (RangeError болмайды) — тапсырма санын еркін көбейтуге мүмкіндік береді.
        final type = pattern[i % pattern.length];
        final id = '${subject}_g${grade}_m${module}_n$i';
        nodes.add(TaskNode(
          id: id,
          subject: subject,
          grade: grade,
          module: module,
          moduleTitle: moduleTitle,
          indexInModule: i,
          type: type,
          title: _nodeTitle(type, moduleTitle, i),
          questions: _buildPool(subject, grade, id),
          requiredGrade: grade,
          xpReward: _xpFor(type, grade, module, i),
          coinReward: _coinsFor(type, grade),
          akylReward: _akylFor(type, grade),
        ));
      }
    }
    return nodes;
  }

  static String _nodeTitle(NodeType type, String moduleTitle, int index) {
    switch (type) {
      case NodeType.lesson:
        return '$moduleTitle · ${index + 1}-сабақ';
      case NodeType.quiz:
        return 'Викторина · $moduleTitle';
      case NodeType.boss:
        return 'Босс: $moduleTitle';
      case NodeType.treasure:
        return 'Қазына сандығы';
    }
  }

  /// XP қисығы: сынып ішінде жол бойымен біртіндеп өседі —
  /// басында жеңіл ұпай, соңына қарай еңбек көбірек бағаланады.
  static int _xpFor(NodeType type, int grade, int module, int index) {
    final base = 18 + grade * 4 + (module - 1) * 10 + index;
    switch (type) {
      case NodeType.boss:
        return base * 3;
      case NodeType.quiz:
        return (base * 1.5).round();
      case NodeType.treasure:
        return base ~/ 2;
      case NodeType.lesson:
        return base;
    }
  }

  static int _coinsFor(NodeType type, int grade) {
    final base = 8 + grade * 2;
    switch (type) {
      case NodeType.boss:
        return base * 3;
      case NodeType.treasure:
        return base * 4;
      case NodeType.quiz:
        return (base * 1.5).round();
      case NodeType.lesson:
        return base;
    }
  }

  static int _akylFor(NodeType type, int grade) {
    switch (type) {
      case NodeType.boss:
        return 10 + grade * 2;
      case NodeType.quiz:
        return 5 + grade;
      case NodeType.treasure:
        return 2;
      case NodeType.lesson:
        return 3 + grade ~/ 2;
    }
  }

  // ---------------- Сұрақ пулын құрастыру ----------------

  /// 56 сұрақтық пул: 6 деңгейлі тиер (light 14 / easy 8 / medium 8 /
  /// hard 7 / complex 11 / brainTeaser 8).
  /// Форматтар: банк MCQ/бос орын + туынды дұрыс/бұрыс + сәйкестендіру.
  static List<Question> _buildPool(String subject, int grade, String nodeId) {
    final random = Random(nodeId.hashCode);
    // Генераторы бар пәндер — мыңдаған бірегей, деңгейлі сұрақ:
    // math/physics/cs жоғарғы тиерлерге (light/complex/brainTeaser) генератор,
    // ал бар банк/тақырып сұрақтары орта тиерлерге.
    if (subject == 'math') return _mathPool(nodeId, grade, random);
    if (subject == 'physics') {
      return _subjectPool('physics', grade, nodeId, random, _physicsQuestion);
    }
    if (subject == 'cs') {
      return _subjectPool('cs', grade, nodeId, random, _csQuestion);
    }
    if (subject == 'biology') {
      return _subjectPool('biology', grade, nodeId, random, null);
    }
    if (subject == 'chemistry') {
      return _subjectPool('chemistry', grade, nodeId, random, null);
    }
    if (subject == 'history') {
      return _subjectPool('history', grade, nodeId, random, null);
    }
    // Тіл пәндері (5–11) — енді ТЕКСЕРІЛГЕН генератормен (light/complex/
    // brainTeaser тиерлерін толтырады; орта тиерлер тақырып банкінен).
    // Қайталануды жояды. 1–4 сынып бұрынғыша банктен (генератор грамматикасы
    // кіші сыныпқа сай емес).
    if (subject == 'kazakh') {
      return _subjectPool(
          'kazakh', grade, nodeId, random, grade >= 5 ? kazakhGenQuestion : null);
    }
    if (subject == 'english') {
      return _subjectPool('english', grade, nodeId, random,
          grade >= 5 ? englishGenQuestion : null);
    }
    return _subjectPool(subject, grade, nodeId, random, null);
  }

  /// Жалпы 6-тиер пул (56 = light 14 / easy 8 / medium 8 / hard 7 / complex 11 /
  /// brainTeaser 8). Орта тиерлер — банктен (жетпесе Дұрыс/Бұрыс), medium-де
  /// 2 сәйкестендіру + 2 кепілді TF. [gen] берілсе — light/complex/brainTeaser
  /// тиерлері генератордан (физика/информатика: шынайы қиын, мыңдаған).
  static List<Question> _subjectPool(
    String subject,
    int grade,
    String nodeId,
    Random random,
    Question Function(String id, int grade, Random r, Difficulty d)? gen,
  ) {
    // Тақырып тазалығы: node өз МОДУЛІНІҢ тақырыбына сай банк сұрақтарын алады
    // (мыс. «Абай» модулінде есімдік сұрақтары шықпайды). Қиындық тиерлерінің
    // саны мен генератор/толтыру өзгермейді — тек банк дереккөзі модульге сай.
    final module = int.tryParse(
            RegExp(r'_m(\d+)_').firstMatch(nodeId)?.group(1) ?? '') ??
        1;
    final bank = _bankForModule(subject, grade, module);
    final pairBand = grade <= 4 ? 1 : (grade <= 7 ? 5 : 9);
    final pairs = _pairBanks[subject]?[pairBand] ?? const <_P>[];

    List<Question> byD(Difficulty d) =>
        bank.where((q) => q.difficulty == d).toList()..shuffle(random);
    final easy = byD(Difficulty.easy);
    final medium = byD(Difficulty.medium);
    final hard = byD(Difficulty.hard);
    final hardOrMed = hard.isNotEmpty ? hard : medium;

    final tfSource = List.of(bank)..shuffle(random);
    var tfIndex = 0;
    var seq = 0;
    String nextId() => '${nodeId}_q${seq++}';
    Question tf(Difficulty d) => _trueFalse(
        nextId(), tfSource[tfIndex++ % tfSource.length], random, d);
    Question reTag(Question q, Difficulty d) => Question(
          id: nextId(),
          text: q.text,
          options: q.options,
          correctIndex: q.correctIndex,
          hint: q.hint,
          type: q.type,
          difficulty: d,
        );

    final pool = <Question>[];
    // Пул ішінде сұрақ МӘТІНІ қайталанбауы тиіс — әйтпесе бір сессияға
    // бірдей сұрақ екі рет түсуі мүмкін. Генератор/TF дубликат берсе,
    // бірнеше рет қайта тартамыз (шектеулі — тұйықталмайды).
    final usedTexts = <String>{};
    void addUnique(Question q, Question Function()? retry) {
      var candidate = q;
      var tries = 0;
      while (!usedTexts.add(candidate.text) && retry != null && tries < 8) {
        candidate = retry();
        tries++;
      }
      pool.add(candidate);
    }

    void fill(Difficulty tier, int need, List<Question> src) {
      if (need <= 0) return;
      final useGen = gen != null &&
          (tier == Difficulty.light ||
              tier == Difficulty.complex ||
              tier == Difficulty.brainTeaser);
      if (useGen) {
        for (var i = 0; i < need; i++) {
          addUnique(gen(nextId(), grade, random, tier),
              () => gen(nextId(), grade, random, tier));
        }
        return;
      }
      // Банк сұрақтары ТҰТЫНЫЛАДЫ (removeAt) — light пен easy бір тізімді
      // басынан қайта оқымайды (бұрын пулда дубликат кепілді болатын).
      var added = 0;
      while (added < need && src.isNotEmpty) {
        addUnique(reTag(src.removeAt(0), tier), null);
        added++;
      }
      while (added < need) {
        addUnique(tf(tier), () => tf(tier));
        added++;
      }
    }

    fill(Difficulty.light, 14, easy);
    fill(Difficulty.easy, 8, easy);
    // medium (8) = match (мүмкін болса 2) + 2 кепілді TF + қалғаны банктен.
    final matchCount = pairs.length >= 4 ? 2 : 0;
    for (var m = 0; m < matchCount; m++) {
      pool.add(_match(nextId(), pairs, random));
    }
    addUnique(tf(Difficulty.medium), () => tf(Difficulty.medium));
    addUnique(tf(Difficulty.medium), () => tf(Difficulty.medium));
    fill(Difficulty.medium, 6 - matchCount, medium);
    fill(Difficulty.hard, 7, hardOrMed);
    fill(Difficulty.complex, 11, hardOrMed);
    fill(Difficulty.brainTeaser, 8, hardOrMed);
    return pool;
  }

  /// Банк сұрағынан «Дұрыс / Бұрыс» форматын тудыру.
  static Question _trueFalse(
    String id,
    Question src,
    Random random,
    Difficulty difficulty,
  ) {
    final showCorrect = random.nextBool() || src.options.length < 2;
    String shown;
    if (showCorrect) {
      shown = src.correctAnswer;
    } else {
      final wrongs = [
        for (var i = 0; i < src.options.length; i++)
          if (i != src.correctIndex) src.options[i],
      ];
      shown = wrongs[random.nextInt(wrongs.length)];
    }
    final isTrue = shown == src.correctAnswer;
    return Question(
      id: id,
      text: '${src.text}\nЖауап: «$shown». Бұл дұрыс па?',
      options: const ['Дұрыс ✓', 'Бұрыс ✗'],
      correctIndex: isTrue ? 0 : 1,
      hint: isTrue ? src.hint : 'Дұрысы: «${src.correctAnswer}»',
      type: QuestionType.trueFalse,
      difficulty: difficulty,
    );
  }

  /// Жұп банкінен 4 жұптық сәйкестендіру сұрағын құру.
  static Question _match(String id, List<_P> source, Random random) {
    final copy = List.of(source)..shuffle(random);
    final chosen = <_P>[];
    final usedRight = <String>{};
    for (final p in copy) {
      if (usedRight.add(p.$2)) chosen.add(p);
      if (chosen.length == 4) break;
    }
    return Question(
      id: id,
      text: 'Жұптарды сәйкестендір',
      options: const [],
      correctIndex: 0,
      type: QuestionType.matchPairs,
      difficulty: Difficulty.medium,
      pairs: [for (final p in chosen) MatchPair(p.$1, p.$2)],
    );
  }

  // ---------------- Математика пулы ----------------

  /// Математика пулы — бір node = бір ТАҚЫРЫПТЫҢ (модульдің) тілімі, араласу ЖОҚ.
  /// Сұрақтар тек осы тақырып банкінен (негізгі + кеңейтілген + «Қызыл кітап»)
  /// БІРЕГЕЙ түрде, қиындық бойынша өсу ретімен алынады. Банк [mathNodesFor]
  /// тең тілімге бөлінеді: node 0 — ең жеңіл тілім, соңғысы — ең қиын. Сонда бір
  /// модуль бойы қиындық біртіндеп өседі әрі сұрақ ҚАЙТАЛАНБАЙДЫ (тақырыптық
  /// тазалық). Тек банк БОС болғанда (1–4 сынып) генераторға ауысады.
  static List<Question> _mathPool(String nodeId, int grade, Random random) {
    var seq = 0;
    String nextId() => '${nodeId}_q${seq++}';

    // Тақырыпты (модульді) id-ден оқимыз: math_g5_m1_n3 → module = 1.
    final match = RegExp(r'_m(\d+)_').firstMatch(nodeId);
    final module = match != null ? int.parse(match.group(1)!) : 1;
    final topic = _topicBank(grade, module);

    // Тақырып банкі жоқ (1–4 сынып) — генератордан құраймыз.
    if (topic.isEmpty) return _mathGeneratedPool(nodeId, grade, random);

    final nodeIndex = int.tryParse(
            RegExp(r'_n(\d+)').firstMatch(nodeId)?.group(1) ?? '') ??
        0;
    final ordered = topic.toList()
      ..sort((a, b) {
        final d = a.$5.index.compareTo(b.$5.index);
        return d != 0 ? d : a.$1.hashCode.compareTo(b.$1.hashCode);
      });
    final b = ordered.length;
    final n = mathNodesFor(grade);
    final base = b ~/ n; // әр тілімнің негізгі мөлшері
    final rem = b % n; // алғашқы [rem] тілімге +1 сұрақ
    final idx = nodeIndex.clamp(0, n - 1);
    final start = idx * base + (idx < rem ? idx : rem);
    final size = base + (idx < rem ? 1 : 0);
    return [
      for (var k = 0; k < size; k++) _bankQuestion(nextId(), ordered[start + k]),
    ];
  }

  /// Тақырып банкі жоқ сыныптар (1–4) үшін генератор пулы (6 тиер, 56).
  static List<Question> _mathGeneratedPool(
      String nodeId, int grade, Random random) {
    var seq = 0;
    String nextId() => '${nodeId}_q${seq++}';
    Question gen(Difficulty d) => _mathQuestion(nextId(), grade, random, d);
    final pool = <Question>[];
    _fillMathTier(pool, const [], 10, nextId, () => gen(Difficulty.light));
    _fillMathTier(pool, const [], 7, nextId, () => gen(Difficulty.easy));
    pool
      ..add(_mathMatch(nextId(), grade, random))
      ..add(_mathMatch(nextId(), grade, random));
    _fillMathTier(pool, const [], 7, nextId, () => gen(Difficulty.medium));
    _fillMathTier(pool, const [], 9, nextId, () => gen(Difficulty.hard));
    _fillMathTier(pool, const [], 12, nextId, () => gen(Difficulty.complex));
    _fillMathTier(pool, const [], 9, nextId, () => gen(Difficulty.brainTeaser));
    return pool;
  }

  /// Пул тиерін [need] санға толтырады: банк сұрақтарын (керек болса
  /// айналдырып қайталап) пайдаланады; банк бос болса ғана [gen] шақырады.
  static void _fillMathTier(
    List<Question> pool,
    List<_Q> bank,
    int need,
    String Function() nextId,
    Question Function() gen,
  ) {
    if (bank.isEmpty) {
      // Генератор дубликат мәтін берсе — қайта тартамыз (пулда бір сұрақ
      // екі рет тұрмасын; шектеулі айналым — кіші кеңістікте тұйықталмайды).
      final usedTexts = pool.map((q) => q.text).toSet();
      for (var i = 0; i < need; i++) {
        var q = gen();
        var tries = 0;
        while (!usedTexts.add(q.text) && tries < 8) {
          q = gen();
          tries++;
        }
        pool.add(q);
      }
      return;
    }
    for (var i = 0; i < need; i++) {
      pool.add(_bankQuestion(nextId(), bank[i % bank.length]));
    }
  }

  /// Сәйкестендіру: өрнек → мән (сыныпқа лайық, мәндер қайталанбайды).
  static Question _mathMatch(String id, int grade, Random random) {
    final pairs = <MatchPair>[];
    final used = <int>{};
    while (pairs.length < 4) {
      int value;
      String expr;
      if (grade <= 2) {
        final a = 1 + random.nextInt(9);
        final b = 1 + random.nextInt(9);
        value = a + b;
        expr = '$a + $b';
      } else if (grade <= 4) {
        final a = 2 + random.nextInt(8);
        final b = 2 + random.nextInt(8);
        value = a * b;
        expr = '$a × $b';
      } else if (grade <= 6) {
        final a = 10 + random.nextInt(40);
        final b = 10 + random.nextInt(40);
        value = a + b;
        expr = '$a + $b';
      } else if (grade <= 8) {
        final a = 2 + random.nextInt(11);
        value = a * a;
        expr = '$a²';
      } else if (grade == 9) {
        final n = 2 + random.nextInt(5);
        value = 1 << n;
        expr = '2^$n';
      } else if (grade == 10) {
        final n = 1 + random.nextInt(6);
        value = n;
        expr = 'log₂ ${1 << n}';
      } else {
        final a = 2 + random.nextInt(5);
        value = a * a * a;
        expr = '$a³';
      }
      if (used.add(value)) {
        pairs.add(MatchPair(expr, '$value'));
      }
    }
    return Question(
      id: id,
      text: 'Өрнекті мәнімен сәйкестендір',
      options: const [],
      correctIndex: 0,
      type: QuestionType.matchPairs,
      difficulty: Difficulty.medium,
      pairs: pairs,
    );
  }

  static Question _mathQuestion(
    String id,
    int grade,
    Random random,
    Difficulty difficulty,
  ) {
    int correct;
    String text;
    String? hint;

    if (grade <= 2) {
      switch (difficulty) {
        case Difficulty.light:
          final a = 1 + random.nextInt(5);
          final b = 1 + random.nextInt(5);
          correct = a + b;
          text = '$a + $b = ?';
        case Difficulty.easy:
          final a = 1 + random.nextInt(9);
          final b = 1 + random.nextInt(9);
          correct = a + b;
          text = '$a + $b = ?';
        case Difficulty.medium:
          final a = 5 + random.nextInt(14);
          final b = 1 + random.nextInt(min(a, 10));
          correct = a - b;
          text = '$a − $b = ?';
        case Difficulty.hard:
          final a = 1 + random.nextInt(9);
          correct = 1 + random.nextInt(10);
          text = '$a + ? = ${a + correct}';
          hint = 'Қосындыдан $a-ны азайт';
        case Difficulty.complex:
          final a = 2 + random.nextInt(8);
          final b = 2 + random.nextInt(8);
          final c = 1 + random.nextInt(6);
          correct = a + b + c;
          text = '$a + $b + $c = ?';
          hint = 'Солдан оңға қарай қос';
        case Difficulty.brainTeaser:
          // Сан тізбегі: тұрақты қадаммен өседі — келесісін тап.
          final a = 1 + random.nextInt(4);
          final d = 2 + random.nextInt(3);
          correct = a + 3 * d;
          text = 'Заңдылықты тап: $a, ${a + d}, ${a + 2 * d}, ?';
          hint = 'Әр сан алдыңғыдан $d-ге көп';
      }
    } else if (grade <= 4) {
      switch (difficulty) {
        case Difficulty.light:
          final a = 2 + random.nextInt(4);
          final b = 2 + random.nextInt(4);
          correct = a * b;
          text = '$a × $b = ?';
          hint = 'Көбейту кестесі';
        case Difficulty.easy:
          final a = 2 + random.nextInt(8);
          final b = 2 + random.nextInt(8);
          correct = a * b;
          text = '$a × $b = ?';
          hint = 'Көбейту кестесін есіңе түсір';
        case Difficulty.medium:
          final a = 2 + random.nextInt(8);
          final b = 2 + random.nextInt(8);
          correct = a;
          text = '${a * b} ÷ $b = ?';
          hint = 'Бөлу — көбейтудің кері амалы';
        case Difficulty.hard:
          final a = 2 + random.nextInt(7);
          final b = 2 + random.nextInt(7);
          final c = 1 + random.nextInt(15);
          correct = a * b + c;
          text = '$a × $b + $c = ?';
          hint = 'Алдымен көбейт, сосын қос';
        case Difficulty.complex:
          // (a + b) × c — жақшаны алдымен.
          final a = 2 + random.nextInt(8);
          final b = 2 + random.nextInt(8);
          final c = 2 + random.nextInt(5);
          correct = (a + b) * c;
          text = '($a + $b) × $c = ?';
          hint = 'Алдымен жақша ішін есепте';
        case Difficulty.brainTeaser:
          // Бөлінгіштік: 1..n ішінде k-ға бөлінетін сан нешеу?
          final k = 2 + random.nextInt(3);
          final n = 12 + random.nextInt(20);
          correct = n ~/ k;
          text = '1-ден $n-ге дейінгі сандардың ішінде $k-ға '
              'бөлінетіні нешеу?';
          hint = '$n-ді $k-ға бөл (бүтін бөлік)';
      }
    } else if (grade <= 6) {
      switch (difficulty) {
        case Difficulty.light:
          final a = 1 + random.nextInt(9);
          final b = 1 + random.nextInt(9);
          correct = a + b;
          text = '$a + $b = ?';
        case Difficulty.easy:
          final a = 10 + random.nextInt(80);
          final b = 10 + random.nextInt(80);
          correct = a + b;
          text = '$a + $b = ?';
        case Difficulty.medium:
          if (random.nextBool()) {
            final a = 2 + random.nextInt(11);
            final b = 2 + random.nextInt(11);
            correct = a * b;
            text = '$a × $b = ?';
          } else {
            final a = 1 + random.nextInt(20);
            final b = 1 + random.nextInt(20);
            correct = a - b;
            text = '$a − $b = ?';
            hint = 'Теріс сан шығуы мүмкін';
          }
        case Difficulty.hard:
          final a = 2 + random.nextInt(15);
          final b = 2 + random.nextInt(9);
          final c = 2 + random.nextInt(9);
          correct = a + b * c;
          text = '$a + $b × $c = ?';
          hint = 'Алдымен көбейту орындалады';
        case Difficulty.complex:
          // a × b − c × d (амалдар реті).
          final a = 3 + random.nextInt(8);
          final b = 2 + random.nextInt(8);
          final c = 2 + random.nextInt(6);
          final d = 1 + random.nextInt(5);
          correct = a * b - c * d;
          text = '$a × $b − $c × $d = ?';
          hint = 'Әуелі екі көбейтуді, сосын азайтуды орында';
        case Difficulty.brainTeaser:
          // Қалдық: a-ны b-ге бөлгендегі қалдық.
          final b = 3 + random.nextInt(7);
          final a = 20 + random.nextInt(60);
          correct = a % b;
          text = '$a санын $b-ге бөлгендегі қалдық неше?';
          hint = '$a = $b × ${a ~/ b} + қалдық';
      }
    } else if (grade <= 8) {
      switch (difficulty) {
        case Difficulty.light:
          final a = 2 + random.nextInt(6);
          correct = a * a;
          text = '$a² = ?';
          hint = '$a × $a';
        case Difficulty.easy:
          if (random.nextBool()) {
            final a = 2 + random.nextInt(11);
            correct = a * a;
            text = '$a² = ?';
          } else {
            final base = (1 + random.nextInt(9)) * 10;
            final percent = (1 + random.nextInt(9)) * 10;
            correct = base * percent ~/ 100;
            text = '$base санының $percent%-ы неше?';
            hint = 'Пайыз = сан × процент ÷ 100';
          }
        case Difficulty.medium:
          final x = 2 + random.nextInt(12);
          final a = 2 + random.nextInt(8);
          final b = random.nextInt(20);
          correct = x;
          text = '$a·x + $b = ${a * x + b} болса, x = ?';
          hint = 'Екі жақтан $b азайтып, $a-ға бөл';
        case Difficulty.hard:
          final x = 2 + random.nextInt(10);
          final a = 2 + random.nextInt(6);
          final b = 1 + random.nextInt(15);
          correct = x;
          text = '$a·x − $b = ${a * x - b} болса, x = ?';
          hint = 'Екі жаққа $b қосып, $a-ға бөл';
        case Difficulty.complex:
          // ax + b = cx + d (x екі жақта да), түбірі бүтін.
          final x = 2 + random.nextInt(9);
          final a = 4 + random.nextInt(5);
          final c = 1 + random.nextInt(3);
          final b = 1 + random.nextInt(9);
          final d = (a - c) * x + b;
          correct = x;
          text = '${a}x + $b = ${c}x + $d, x = ?';
          hint = 'x-терді бір жаққа, сандарды екінші жаққа жина';
        case Difficulty.brainTeaser:
          // Қосынды мен айырмадан үлкен санды табу.
          final small = 3 + random.nextInt(20);
          final diff = 2 + random.nextInt(18);
          final big = small + diff;
          correct = big;
          text = 'Екі санның қосындысы ${big + small}, айырмасы $diff. '
              'Үлкен сан неше?';
          hint = 'Үлкені = (қосынды + айырма) ÷ 2';
      }
    } else if (grade == 9) {
      // Квадрат теңдеулер мен прогрессиялар.
      switch (difficulty) {
        case Difficulty.light:
          final n = 1 + random.nextInt(5);
          correct = 1 << n;
          text = '2^$n = ?';
          hint = '2-ні $n рет көбейт';
        case Difficulty.easy:
          if (random.nextBool()) {
            final n = 1 + random.nextInt(6);
            correct = 1 << n;
            text = '2^$n = ?';
            hint = '2-ні $n рет көбейт';
          } else {
            final x = 2 + random.nextInt(9);
            correct = x;
            text = 'x² = ${x * x} және x > 0 болса, x = ?';
            hint = 'Квадрат түбірді тап';
          }
        case Difficulty.medium:
          if (random.nextBool()) {
            // x² − (p+q)x + pq = 0, түбірлері p және q.
            final p = 1 + random.nextInt(6);
            final q = p + 1 + random.nextInt(5);
            correct = q;
            text = 'x² − ${p + q}x + ${p * q} = 0 теңдеуінің үлкен түбірі?';
            hint = 'Виет теоремасы: түбірлер қосындысы ${p + q}, '
                'көбейтіндісі ${p * q}';
          } else {
            // Арифметикалық прогрессияның n-мүшесі.
            final a1 = 1 + random.nextInt(9);
            final d = 2 + random.nextInt(5);
            final n = 4 + random.nextInt(5);
            correct = a1 + (n - 1) * d;
            text = 'Арифметикалық прогрессия: a₁ = $a1, d = $d. a$n = ?';
            hint = 'aₙ = a₁ + (n − 1)·d';
          }
        case Difficulty.hard:
          if (random.nextBool()) {
            // Дискриминант.
            final b = 3 + random.nextInt(6);
            final a = 1 + random.nextInt(2);
            final c = 1 + random.nextInt(4);
            correct = b * b - 4 * a * c;
            text = '${a}x² + ${b}x + $c = 0 теңдеуінің дискриминанты D = ?';
            hint = 'D = b² − 4ac';
          } else {
            // Геометриялық прогрессияның мүшесі.
            final b1 = 1 + random.nextInt(3);
            final q = 2 + random.nextInt(2);
            final n = 3 + random.nextInt(3);
            correct = b1 * pow(q, n - 1).toInt();
            text = 'Геометриялық прогрессия: b₁ = $b1, q = $q. b$n = ?';
            hint = 'bₙ = b₁ · qⁿ⁻¹';
          }
        case Difficulty.complex:
          // Арифм. прогрессияның алғашқы n мүшесінің қосындысы.
          final a1 = 1 + random.nextInt(8);
          final d = 1 + random.nextInt(5);
          final n = 5 + random.nextInt(6);
          correct = n * (2 * a1 + (n - 1) * d) ~/ 2;
          text = 'Арифм. прогрессия a₁=$a1, d=$d. Алғашқы $n мүшенің '
              'қосындысы Sₙ = ?';
          hint = 'Sₙ = n·(2a₁ + (n−1)d) / 2';
        case Difficulty.brainTeaser:
          // Виет: түбірлердің квадраттарының қосындысы x₁²+x₂².
          final p = 2 + random.nextInt(6);
          final q = p + 1 + random.nextInt(5);
          correct = p * p + q * q;
          text = 'x² − ${p + q}x + ${p * q} = 0. Түбірлердің '
              'квадраттарының қосындысы x₁² + x₂² = ?';
          hint = '(x₁+x₂)² − 2x₁x₂ = ${p + q}² − 2·${p * q}';
      }
    } else if (grade == 10) {
      // Туынды мен логарифмдер.
      switch (difficulty) {
        case Difficulty.light:
          final n = 1 + random.nextInt(5);
          correct = n;
          text = 'log₂ ${1 << n} = ?';
          hint = '2-ні неше рет көбейтсе ${1 << n} шығады?';
        case Difficulty.easy:
          if (random.nextBool()) {
            final n = 1 + random.nextInt(6);
            correct = n;
            text = 'log₂ ${1 << n} = ?';
            hint = '2 санын неше рет көбейтсе ${1 << n} шығады?';
          } else {
            final base = 3 + random.nextInt(3); // 3..5
            final n = 1 + random.nextInt(3);
            correct = n;
            text = 'log$base ${pow(base, n).toInt()} = ?';
            hint = 'logₐ aⁿ = n';
          }
        case Difficulty.medium:
          if (random.nextBool()) {
            // f(x) = x² туындысы нүктеде.
            final a = 2 + random.nextInt(9);
            correct = 2 * a;
            text = 'f(x) = x² болса, f′($a) = ?';
            hint = '(x²)′ = 2x';
          } else {
            // f(x) = ax + b туындысы.
            final a = 2 + random.nextInt(9);
            final b = 1 + random.nextInt(9);
            correct = a;
            text = 'f(x) = ${a}x + $b болса, f′(x) = ?';
            hint = 'Сызықтық функцияның туындысы — k коэффициенті';
          }
        case Difficulty.hard:
          if (random.nextBool()) {
            // f(x) = ax² туындысы нүктеде.
            final a = 2 + random.nextInt(4);
            final x0 = 1 + random.nextInt(5);
            correct = 2 * a * x0;
            text = 'f(x) = ${a}x² болса, f′($x0) = ?';
            hint = '(ax²)′ = 2ax';
          } else {
            // Логарифм қасиеті: log_a x + log_a y.
            final n = 1 + random.nextInt(3);
            final m = 1 + random.nextInt(3);
            correct = n + m;
            text = 'log₂ ${1 << n} + log₂ ${1 << m} = ?';
            hint = 'logₐ x + logₐ y = logₐ (x·y)';
          }
        case Difficulty.complex:
          // f(x) = ax² + bx + c туындысы нүктеде: 2ax₀ + b.
          final a = 2 + random.nextInt(4);
          final b = 1 + random.nextInt(9);
          final c = 1 + random.nextInt(9);
          final x0 = 1 + random.nextInt(5);
          correct = 2 * a * x0 + b;
          text = 'f(x) = ${a}x² + ${b}x + $c болса, f′($x0) = ?';
          hint = 'f′(x) = 2·${a}x + $b';
        case Difficulty.brainTeaser:
          // Экстремум нүктесі: f(x)=x²−2a·x, f′(x)=0 → x=a.
          final a = 2 + random.nextInt(8);
          correct = a;
          text = 'f(x) = x² − ${2 * a}x. f′(x) = 0 болғанда x = ?';
          hint = 'f′(x) = 2x − ${2 * a} = 0';
      }
    } else {
      // 11-сынып: интеграл мен ықтималдық.
      switch (difficulty) {
        case Difficulty.light:
          final a = 2 + random.nextInt(8);
          correct = a * a;
          text = '$a² = ?';
        case Difficulty.easy:
          if (random.nextBool()) {
            // Тиын/текше ықтималдығы пайызбен.
            correct = 50;
            text = 'Тиынды бір рет лақтырғанда елтаңба түсу ықтималдығы '
                'неше пайыз?';
            hint = 'Екі тең мүмкіндіктің бірі';
          } else {
            final a = 2 + random.nextInt(13);
            correct = a * a;
            text = '$a² = ?';
          }
        case Difficulty.medium:
          if (random.nextBool()) {
            // ∫₀^a 2x dx = a².
            final a = 2 + random.nextInt(7);
            correct = a * a;
            text = '∫₀$a 2x dx = ?';
            hint = '2x-тің алғашқы функциясы — x²';
          } else {
            // Текше: бөлінетін сандар саны → ықтималдық бөлімі.
            final favorable = 1 + random.nextInt(3);
            correct = favorable;
            text = 'Текшені лақтырғанда $favorable-ден кіші не тең сан '
                'түсетін жағдай нешеу?';
            hint = 'Қолайлы жағдайларды сана';
          }
        case Difficulty.hard:
          if (random.nextBool()) {
            // Комбинаторика: C(n, 2).
            final n = 4 + random.nextInt(6);
            correct = n * (n - 1) ~/ 2;
            text = '$n оқушыдан 2 адамдық жұпты неше тәсілмен құруға '
                'болады?';
            hint = 'C(n, 2) = n·(n − 1) / 2';
          } else {
            // ∫₀^a 3x² dx = a³.
            final a = 2 + random.nextInt(4);
            correct = a * a * a;
            text = '∫₀$a 3x² dx = ?';
            hint = '3x²-тің алғашқы функциясы — x³';
          }
        case Difficulty.complex:
          // Орналастыру: P(n,2) = n·(n − 1).
          final n = 4 + random.nextInt(7);
          correct = n * (n - 1);
          text = '$n түрлі кітаптан 2-уін сөреге қатарластыра неше '
              'тәсілмен қоюға болады?';
          hint = 'P(n,2) = n·(n − 1)';
        case Difficulty.brainTeaser:
          // Терулер: C(n,3) = n(n−1)(n−2)/6.
          final n = 5 + random.nextInt(4);
          correct = n * (n - 1) * (n - 2) ~/ 6;
          text = '$n адамнан 3 адамдық топты неше тәсілмен таңдауға '
              'болады?';
          hint = 'C(n,3) = n·(n−1)·(n−2) / 6';
      }
    }

    return _numeric(id, text, hint, correct, difficulty, random);
  }

  /// Сандық жауапты сұрақ: дұрыс мәнге жақын, қайталанбайтын 4 нұсқа.
  /// math/physics/cs генераторлары ортақ пайдаланады.
  static Question _numeric(String id, String text, String? hint, int correct,
      Difficulty difficulty, Random random) {
    final options = <int>{correct};
    while (options.length < 4) {
      final delta = 1 + random.nextInt(max(3, correct.abs() ~/ 3 + 2));
      options.add(random.nextBool() ? correct + delta : correct - delta);
    }
    final list = options.toList()..shuffle(random);
    return Question(
      id: id,
      text: text,
      options: list.map((v) => '$v').toList(),
      correctIndex: list.indexOf(correct),
      hint: hint,
      difficulty: difficulty,
    );
  }

  /// Физика генераторы — формулалы сандық есептер, 6 деңгейге өрлейді
  /// (мыңдаған бірегей; жауап есеппен есептеледі → дұрыстық кепілді).
  static Question _physicsQuestion(
      String id, int grade, Random random, Difficulty difficulty) {
    int correct;
    String text;
    String? hint;
    switch (difficulty) {
      case Difficulty.light:
        final t = 2 + random.nextInt(5);
        final v = 2 + random.nextInt(8);
        correct = v;
        text = 'Дене $t с ішінде ${v * t} м жол жүрді. Жылдамдығы неше м/с?';
        hint = 'v = s / t';
      case Difficulty.easy:
        final m = 2 + random.nextInt(8);
        final a = 2 + random.nextInt(8);
        correct = m * a;
        text = 'Массасы $m кг денеге $a м/с² үдеу беретін күш неше Н?';
        hint = 'F = m·a';
      case Difficulty.medium:
        final v0 = 2 + random.nextInt(8);
        final a = 1 + random.nextInt(5);
        final t = 2 + random.nextInt(5);
        correct = v0 + a * t;
        text = 'Бастапқы жылдамдық $v0 м/с, үдеу $a м/с², уақыт $t с. '
            'Соңғы жылдамдық v неше м/с?';
        hint = 'v = v₀ + a·t';
      case Difficulty.hard:
        final m = 1 + random.nextInt(9);
        final h = 2 + random.nextInt(8);
        correct = m * 10 * h;
        text = 'Массасы $m кг дене $h м биіктікте. Потенциалдық энергиясы '
            'Eₚ неше Дж? (g = 10 м/с²)';
        hint = 'Eₚ = m·g·h';
      case Difficulty.complex:
        final m = 2 * (1 + random.nextInt(4)); // жұп масса → бүтін жауап
        final v = 2 + random.nextInt(6);
        correct = m * v * v ~/ 2;
        text = 'Массасы $m кг дене $v м/с жылдамдықпен қозғалады. '
            'Кинетикалық энергиясы Eₖ неше Дж?';
        hint = 'Eₖ = m·v² / 2';
      case Difficulty.brainTeaser:
        final u = random.nextInt(6);
        final a = 1 + random.nextInt(5);
        final t = 2 + random.nextInt(4);
        final v = u + a * t;
        correct = a;
        text = 'Дене жылдамдығы $t с ішінде $u м/с-тан $v м/с-қа артты. '
            'Үдеуі неше м/с²?';
        hint = 'a = (v − u) / t';
    }
    return _numeric(id, text, hint, correct, difficulty, random);
  }

  /// Информатика генераторы — екілік/логика/алгоритм, 6 деңгейге өрлейді.
  static Question _csQuestion(
      String id, int grade, Random random, Difficulty difficulty) {
    int correct;
    String text;
    String? hint;
    switch (difficulty) {
      case Difficulty.light:
        // Кең ауқым (1..30) — 14 сұрақтық тиерге жеткілікті түрлілік.
        final n = 1 + random.nextInt(30);
        correct = n;
        text = 'Екілік сан ${n.toRadixString(2)}₂ ондық санақта неше?';
        hint = 'Разрядтарды 2-нің дәрежелерімен қос';
      case Difficulty.easy:
        final n = 1 + random.nextInt(8);
        correct = 1 << n;
        text = '$n биттік ұяшықта неше түрлі мән сақтауға болады?';
        hint = '2ⁿ';
      case Difficulty.medium:
        final a = 1 + random.nextInt(15);
        final b = 1 + random.nextInt(15);
        correct = a & b;
        text = '$a AND $b (биттік ЖӘНЕ) = ?';
        hint = 'Әр битте екеуі де 1 болса — 1';
      case Difficulty.hard:
        final a = 2 + random.nextInt(7);
        final b = 2 + random.nextInt(7);
        correct = a * b;
        text = 'Қос цикл: сыртқысы $a рет, ішкісі $b рет қайталанады. '
            'Ішкі дене барлығы неше рет орындалады?';
        hint = 'a × b';
      case Difficulty.complex:
        final a = 1 + random.nextInt(31);
        final b = 1 + random.nextInt(31);
        correct = a ^ b;
        text = '$a XOR $b (биттік ерекше НЕМЕСЕ) = ?';
        hint = 'Биттері әртүрлі болса — 1';
      case Difficulty.brainTeaser:
        // Екі нұсқа кезектеседі — 8 сұрақтық тиерге жеткілікті түрлілік
        // (жалғыз факториал шаблоны 4-ақ түрлі мәтін беретін).
        if (random.nextBool()) {
          final n = 3 + random.nextInt(4); // 3..6
          var f = 1;
          for (var i = 2; i <= n; i++) {
            f *= i;
          }
          correct = f;
          text =
              '$n түрлі файлды неше түрлі ретпен орналастыруға болады? (n!)';
          hint = 'n! = 1·2·…·$n';
        } else {
          // x XOR x = 0 «жойылу» қасиеті — криптографияның негізгі трюгі.
          final a = 2 + random.nextInt(29);
          final b = 1 + random.nextInt(30);
          correct = b;
          text = '$a XOR $b XOR $a = ?';
          hint = 'x XOR x = 0: бірдей сандар бірін-бірі жояды';
        }
    }
    return _numeric(id, text, hint, correct, difficulty, random);
  }

  // ---------------- Сұрақ банктері ----------------

  /// Бір тақырыптың (модульдің) толық банкі: негізгі + кеңейтілген +
  /// «Қызыл кітап» біріктіріледі ӘРІ мәтін бойынша ДЕДУПЛИКАЦИЯЛАНАДЫ
  /// (дереккөздер қабаттасса, бір сұрақ екі рет болмауы үшін — әйтпесе
  /// disjoint тілімдерде бірдей сұрақ қайталанып кетер еді).
  static List<_Q> _topicBank(int grade, int module) {
    final seen = <String>{};
    final out = <_Q>[];
    for (final q in [
      ...?mathBankByTopic[grade]?[module],
      ...?mathBankAdvanced[grade]?[module],
      ...?mathBankAdvanced2[grade]?[module],
      ...?mathBankHard[grade]?[module],
      ...?mathBankRedbook[grade]?[module],
      ...?mathBankExtra[grade]?[module],
    ]) {
      if (seen.add(q.$1)) out.add(q);
    }
    return out;
  }

  /// Осы сынып/модуль үшін математика тақырып банкі бар ма? Бар болса —
  /// node пулы ТЕК сол тақырыптан құралады (5–11 сынып); жоқ болса (1–4)
  /// генератор қолданылады.
  static bool hasTopicBank(int grade, int module) =>
      _topicBank(grade, module).isNotEmpty;

  /// Берілген сыныптың барлық математика банк сұрағы (барлық дереккөз қоса).
  static List<_Q> _mathRaw(int grade) => [
        for (final topic
            in mathBankByTopic[grade]?.values ?? const <List<_Q>>[])
          ...topic,
        for (final topic
            in mathBankAdvanced[grade]?.values ?? const <List<_Q>>[])
          ...topic,
        for (final topic
            in mathBankAdvanced2[grade]?.values ?? const <List<_Q>>[])
          ...topic,
        for (final topic
            in mathBankHard[grade]?.values ?? const <List<_Q>>[])
          ...topic,
        for (final topic
            in mathBankRedbook[grade]?.values ?? const <List<_Q>>[])
          ...topic,
        for (final topic
            in mathBankExtra[grade]?.values ?? const <List<_Q>>[])
          ...topic,
      ];

  /// ДӘЛ сыныптың банкі: негізгі (curriculum.dart) және кеңейтілген
  /// (banks/) банктер біріктіріледі. Жауап нұсқалары детерминистік
  /// түрде араластырылады — дұрыс жауап әрқашан бірінші тұрмауы үшін.
  static List<Question> _bankFor(String subject, int grade) {
    final raw = _rawBank(subject, grade);
    return [
      for (var i = 0; i < raw.length; i++)
        _bankQuestion('${subject}_g${grade}_b$i', raw[i]),
    ];
  }

  /// Сол МОДУЛЬДІҢ тақырыбына сай банк сұрақтары (тақырып тазалығы).
  static List<Question> _bankForModule(String subject, int grade, int module) {
    final raw = _moduleBucket(subject, grade, module);
    return [
      for (var i = 0; i < raw.length; i++)
        _bankQuestion('${subject}_g${grade}_m${module}_b$i', raw[i]),
    ];
  }

  /// Грейд банкін модульдің тақырыбы бойынша екіге бөледі (5–11 сынып). 2-модуль
  /// тақырыбының кілт сөздері сәйкес келсе — 2-модульге, әйтпесе 1-модульге.
  /// Бөліну азғантай (бір жағы &lt;8) болса немесе кілт сөз жоқ болса — бөлінбейді
  /// (барлық банк), сонда регрессия болмайды.
  static List<_Q> _moduleBucket(String subject, int grade, int module) {
    // Жаңа тақырыптық модульдер (3+): банк тікелей пән топик-картасынан —
    // кілт сөзбен бөлінбейді (1–2-модульдің жалпақ банкіне тимейді).
    final topic = _subjectTopicBanks[subject]?[grade]?[module];
    if (topic != null && topic.isNotEmpty) return topic;
    final raw = _rawBank(subject, grade);
    final kw = _module2Keywords[subject]?[grade];
    if (kw == null || raw.length < 16) return raw;
    final b1 = <_Q>[];
    final b2 = <_Q>[];
    for (final q in raw) {
      // Мәтін + нұсқалар + түсіндірме: бос орынды (___) сұрақта жауап сөзі
      // нұсқада тұрады, сондықтан оны да тексереміз.
      final t = '${q.$1} ${q.$2.join(' ')} ${q.$4 ?? ''}'.toLowerCase();
      (kw.any(t.contains) ? b2 : b1).add(q);
    }
    if (b1.length < 8 || b2.length < 8) return raw; // тым қисық — бөлмейміз
    return module >= 2 ? b2 : b1;
  }

  /// Пәннің ЖАҢА тақырыптық модульдерінің (3-модульден бастап) банктері:
  /// пән → сынып → модуль → сұрақтар. Атаулары [_moduleTitles]-пен үйлеседі.
  static const Map<String, Map<int, Map<int, List<_Q>>>> _subjectTopicBanks = {
    'history': historyTopicBanks,
    'cs': csTopicBanks,
  };

  /// Әр пәннің 2-МОДУЛІНІҢ (5–11 сынып) тақырып кілт сөздері. Банк сұрағының
  /// мәтіні осылардың біріне сай болса — 2-модуль тақырыбы, әйтпесе 1-модуль.
  /// Дереккөз: бар (тексерілген) банк сұрақтары — жаңа факт қосылмайды.
  static const Map<String, Map<int, List<String>>> _module2Keywords = {
    'kazakh': {
      5: ['септік', 'ілік', 'барыс', 'табыс', 'жатыс', 'шығыс', 'көмектес'],
      6: ['мақал', 'мәтел', 'нақыл'],
      7: ['абай', 'өлең', 'қара сөз', 'аудар', 'онегин', 'құнанбай'],
      8: ['сөйлем', 'бастауыш', 'баяндауыш', 'тұрлаулы', 'толықтауыш',
          'пысықтауыш', 'анықтауыш'],
      9: ['әдебиет', 'жыр', 'дастан', 'ақын', 'жазушы', 'эпопея', 'роман',
          'әуезов', 'махамбет', 'поэма'],
      10: ['метафора', 'теңеу', 'эпитет', 'троп', 'символ', 'көркемдегіш',
          'бейне'],
      11: ['шешен', 'би ', 'дау', 'төле', 'қазыбек', 'әйтеке'],
    },
    'english': {
      5: ['hobby', 'hobbies', 'enjoy', 'free time', 'collect', 'favourite'],
      6: ['travel', 'trip', 'abroad', 'ticket', 'luggage', 'passport',
          'journey', 'flight'],
      7: ['than', 'more', 'comparative', 'biggest', 'taller', 'better', 'best',
          'most', '-er'],
      8: ['must', 'can', 'should', 'have to', 'modal', 'may', 'ought'],
      9: ['if', 'conditional', 'would', 'unless'],
      10: ['phrasal', 'turn on', 'give up', 'look after', 'look for', 'put on',
          'take off', 'turn off'],
      11: ['academic', 'formal', 'furthermore', 'however', 'essay', 'argue'],
    },
    'physics': {
      5: ['өлше', 'бірлік', 'метр', 'килограмм', 'секунд', 'шама', 'эталон',
          'дәлдік'],
      6: ['энергия', 'потенциал', 'кинетик', 'сақталу'],
      7: ['күш', 'масса', 'ньютон', 'ауырлық', 'салмақ'],
      8: ['электр', 'ток', 'кернеу', 'ом', 'ампер', 'вольт', 'кедергі',
          'тізбек', 'изолятор', 'өткізгіш', 'найзағай', 'батарей', 'қуат',
          'розетка', 'сақтандырғыш', 'шам'],
      9: ['тербеліс', 'толқын', 'период', 'жиілік', 'герц', 'маятник'],
      10: ['термодинамика', 'ішкі энергия', 'цикл', 'газ заң', 'жұмыс'],
      11: ['астро', 'жұлдыз', 'галактика', 'планета', 'ғарыш', 'жарық жыл',
          'күн жүйес'],
    },
    'cs': {
      5: ['файл', 'папка', 'қалта', 'кеңейтім', '.jpg', '.txt', '.doc'],
      6: ['процессор', 'cpu', 'жад', 'ram', 'диск', 'құрылғы', 'монитор',
          'пернетақта', 'тінтуір'],
      7: ['scratch', 'спрайт', 'блок', 'жоба'],
      8: ['шарт', 'цикл', 'if', 'for', 'while', 'range', 'else'],
      9: ['тізім', 'list', 'сөздік', 'dict', 'индекс', 'массив'],
      10: ['дерекқор', 'database', 'sql', 'кесте', 'жазба', 'өріс'],
      11: ['жоба', 'презентация', 'команда', 'тест', 'өнім'],
    },
    'biology': {
      5: ['орта', 'бейімдел', 'мекен', 'тіршілік белгі'],
      6: ['тамыр', 'сабақ', 'жапырақ', 'гүл', 'жеміс', 'мүше'],
      7: ['жүйе', 'ас қорыту', 'қан айналым', 'тін', 'жүрек'],
      8: ['тыныс', 'өкпе', 'қан', 'жүрек', 'айналым'],
      9: ['популяция', 'экожүйе', 'қоректік тізбек', 'өндіруші'],
      10: ['бөліну', 'митоз', 'мейоз', 'хромосома'],
      11: ['экология', 'биосфера', 'зат айналым', 'ласта'],
    },
    'chemistry': {
      5: ['қоспа', 'таза зат', 'сүзу', 'буланд', 'дистил'],
      6: ['атом', 'молекула', 'бөлшек', 'күй', 'қатты'],
      7: ['элемент', 'таңба', 'металл', 'бейметалл'],
      8: ['байланыс', 'ионд', 'коваленттік', 'электрон'],
      9: ['қышқыл', 'негіз', 'тұз', 'бейтарап'],
      10: ['көмірсутек', 'алкан', 'алкен', 'метан'],
      11: ['тотығу', 'тотықсыздан', 'редокс', 'электрон беру'],
    },
    'history': {
      5: ['қола', 'металл', 'қорған', 'беғазы'],
      6: ['үйсін', 'қаңлы', 'жетісу', 'жібек'],
      7: ['қала', 'отырар', 'тараз', 'фараби', 'түркістан', 'кесене'],
      8: ['тәуке', 'жеті жарғы', ' би', 'төле', 'қасым', 'жүз'],
      9: ['отар', 'кенесары', 'ресей', 'көтеріліс', 'махамбет', 'патша'],
      10: ['соғыс', 'желтоқсан', 'бауыржан', '1986', 'момышұлы', 'панфилов'],
      11: ['астана', 'экспо', 'символ', 'елтаңба', 'елорда', 'рәміз'],
    },
  };

  static Question _bankQuestion(String id, _Q raw) {
    final correct = raw.$2[raw.$3];
    final options = List<String>.from(raw.$2)..shuffle(Random(id.hashCode));
    return Question(
      id: id,
      text: raw.$1,
      options: options,
      correctIndex: options.indexOf(correct),
      hint: raw.$4,
      difficulty: raw.$5,
      type: raw.$1.contains('___')
          ? QuestionType.fillBlank
          : QuestionType.multipleChoice,
    );
  }

  static List<_Q> _rawBank(String subject, int grade) {
    if (subject == 'math') return _mathRaw(grade);
    final (Map<int, List<_Q>> legacy, Map<int, List<_Q>> ext) = switch (subject) {
      'kazakh' => (_kazakhBank, kazakhBankExt),
      'english' => (_englishBank, englishBankExt),
      'physics' => (_physicsBank, physicsBankExt),
      'cs' => (_csBank, csBankExt),
      'biology' => (const <int, List<_Q>>{}, biologyBankExt),
      'chemistry' => (const <int, List<_Q>>{}, chemistryBankExt),
      'history' => (const <int, List<_Q>>{}, historyBankExt),
      _ => (_kazakhBank, kazakhBankExt),
    };
    final merged = [...?legacy[grade], ...?ext[grade]];
    if (merged.isNotEmpty) return merged;
    // Банк табылмаса — ұқсас сыныпқа шегіну (legacy + ext қоса).
    final fallback = grade <= 4 ? 1 : (grade <= 7 ? 5 : 9);
    return [...?legacy[fallback], ...?ext[fallback]];
  }

  static const Map<int, List<_Q>> _kazakhBank = {
    1: [
      ('«Кітап» сөзінде неше буын бар?', ['1', '2', '3', '4'], 1,
          'Кі-тап деп бөлеміз', Difficulty.easy),
      ('Қайсысы дауысты дыбыс?', ['б', 'а', 'к', 'т'], 1,
          'Дауысты дыбыстар кедергісіз айтылады', Difficulty.easy),
      ('«Үлкен» сөзінің антонимі қайсы?',
          ['биік', 'кішкентай', 'жуан', 'ұзын'], 1, null, Difficulty.easy),
      ('Сөйлем қалай басталады?',
          ['Кіші әріптен', 'Бас әріптен', 'Саннан', 'Үтірден'], 1, null,
          Difficulty.easy),
      ('«Ана» сөзінің синонимі қайсы?', ['әке', 'аға', 'шеше', 'іні'], 2,
          null, Difficulty.easy),
      ('Қайсысы зат есім?', ['бару', 'әдемі', 'мектеп', 'тез'], 2,
          'Зат есім «кім? не?» сұрағына жауап береді', Difficulty.medium),
      ('Дұрыс жазылған сөзді тап:', ['калам', 'қалам', 'kалам', 'қалaм'], 1,
          null, Difficulty.medium),
      ('«Жақсы» сөзінің антонимі қайсы?', ['тәтті', 'жаман', 'үлкен', 'жылы'],
          1, null, Difficulty.easy),
      ('Қазақ әліпбиінде неше әріп бар?', ['33', '42', '26', '40'], 1, null,
          Difficulty.medium),
      ('Қайсысы сын есім?', ['оқу', 'дәптер', 'әдемі', 'жазу'], 2,
          'Сын есім «қандай?» сұрағына жауап береді', Difficulty.medium),
      ('«Бала» сөзінің көпше түрі қайсы?',
          ['балалар', 'балалер', 'баладар', 'балар'], 0, null,
          Difficulty.easy),
      ('Қайсысы жыл мезгілі?', ['дүйсенбі', 'көктем', 'таң', 'кеше'], 1, null,
          Difficulty.easy),
      ('«Алма» сөзінде неше буын бар?', ['1', '2', '3', '4'], 1,
          'Ал-ма деп бөлеміз', Difficulty.easy),
      ('Қайсысы дауыссыз дыбыс?', ['а', 'ы', 'б', 'о'], 2, null,
          Difficulty.easy),
      ('«Суық» сөзінің антонимі:', ['ыстық', 'салқын', 'мұздай', 'желді'], 0,
          null, Difficulty.easy),
      ('Қайсысы үй жануары?', ['қасқыр', 'сиыр', 'түлкі', 'аю'], 1, null,
          Difficulty.easy),
      ('Аптада неше күн бар?', ['5', '6', '7', '8'], 2, null,
          Difficulty.easy),
      ('Хабарлы сөйлемнің соңында не қойылады?',
          ['үтір', 'нүкте', 'сызықша', 'қос нүкте'], 1, null,
          Difficulty.easy),
      ('«Оқушы» сөзінің түбірі қайсы?', ['оқушы', 'оқу', 'оқы', 'ушы'], 2,
          'Оқы + -у-шы', Difficulty.medium),
      ('Қайсысы сұраулы сөйлем?',
          ['Мен келдім.', 'Сен қайда барасың?', 'Күн ашық.', 'Кітап оқы!'],
          1, null, Difficulty.medium),
      ('Мен мектеп___ барамын.', ['ке', 'те', 'тен', 'нің'], 0, null,
          Difficulty.medium),
      ('Буын саны өзгеше сөзді тап:',
          ['ба-ла', 'да-ла', 'қа-ла', 'мек-теп-ке'], 3,
          '«Мектепке» — үш буын', Difficulty.hard),
      ('«Көл» сөзіне көптік жалғауын дұрыс жалға:',
          ['көлдар', 'көлдер', 'көлдыр', 'көллер'], 1,
          'Жіңішке сөзге -дер жалғанады', Difficulty.hard),
      ('Тасымалдауға болмайтын сөз қайсы?', ['бала', 'алма', 'ай', 'дала'],
          2, 'Бір буынды сөз тасымалданбайды', Difficulty.hard),
    ],
    5: [
      ('Зат есім дегеніміз не?',
          [
            'Заттың атын білдіретін сөз табы',
            'Қимылды білдіретін сөз табы',
            'Сапаны білдіретін сөз табы',
            'Санды білдіретін сөз табы'
          ],
          0,
          null, Difficulty.easy),
      ('«Мектепке» сөзі қай септікте тұр?',
          ['Атау', 'Барыс', 'Жатыс', 'Шығыс'], 1,
          '-ке жалғауы — барыс септіктің белгісі', Difficulty.medium),
      ('Қайсысы етістік?', ['кітап', 'оқыды', 'қызыл', 'бесеу'], 1, null,
          Difficulty.easy),
      ('«Кітаптар» сөзінің түбірі қайсы?',
          ['кітапта', 'кітап', 'кіт', 'тар'], 1, null, Difficulty.easy),
      ('Жіктеу есімдіктерін көрсет:',
          ['мен, сен, ол', 'бұл, сол, анау', 'кім, не', 'әркім, ешкім'], 0,
          null, Difficulty.medium),
      ('«Абай жолы» роман-эпопеясының авторы кім?',
          ['Мұхтар Әуезов', 'Сәбит Мұқанов', 'Ғабит Мүсірепов', 'Абай'], 0,
          null, Difficulty.easy),
      ('Қайсысы мақал?',
          [
            'Бүгін ауа райы жақсы',
            'Білім — таусылмас қазына',
            'Мен мектепке барамын',
            'Алматы — үлкен қала'
          ],
          1,
          null, Difficulty.easy),
      ('Ілік септіктің жалғауын көрсет:',
          ['-ға/-ге', '-ның/-нің', '-да/-де', '-дан/-ден'], 1, null,
          Difficulty.medium),
      ('«Тез» сөзі қай сөз табына жатады?',
          ['зат есім', 'сын есім', 'үстеу', 'етістік'], 2,
          'Үстеу «қалай?» сұрағына жауап береді', Difficulty.medium),
      ('Антоним жұпты тап:',
          ['биік — аласа', 'үлкен — зор', 'әдемі — сұлу', 'тез — жылдам'], 0,
          null, Difficulty.easy),
      ('Тәуелдік жалғау (менің): «көл» → ?',
          ['көлің', 'көлі', 'көлім', 'көліміз'], 2, null, Difficulty.medium),
      ('Қайсысы қыс мезгіліне қатысты сөз?',
          ['аяз', 'егін', 'жаңбыр', 'гүл'], 0, null, Difficulty.easy),
      ('Қайсысы сан есім?', ['бес', 'барды', 'көк', 'тез'], 0, null,
          Difficulty.easy),
      ('«Дос» сөзінің синонимі:', ['жолдас', 'жау', 'көрші', 'аға'], 0, null,
          Difficulty.easy),
      ('Қайсысы жалқы есім?', ['қала', 'Алматы', 'мектеп', 'өзен'], 1,
          'Жалқы есім бас әріппен жазылады', Difficulty.easy),
      ('Мен мектеп___ барамын.', ['ке', 'те', 'тен', 'тің'], 0,
          'Бағыт — барыс септік', Difficulty.easy),
      ('«Жүгіру» сөзі қай сұраққа жауап береді?',
          ['не істеу?', 'қандай?', 'қанша?', 'қайда?'], 0, null,
          Difficulty.easy),
      ('Көптік жалғауды тап: «терезе» → ?',
          ['терезелер', 'терезелар', 'терезедер', 'терезетер'], 0, null,
          Difficulty.easy),
      ('«Ағаштың жапырағы» тіркесіндегі «ағаштың» қай септікте?',
          ['атау', 'ілік', 'барыс', 'табыс'], 1,
          '-ның/-нің — ілік септік', Difficulty.medium),
      ('Қайсысы туынды сөз?', ['бала', 'оқушы', 'тау', 'көл'], 1,
          '«Оқы» түбіріне -ушы жұрнағы жалғанған', Difficulty.medium),
      ('«Кітапты оқыдым» — «кітапты» қай септікте?',
          ['табыс', 'барыс', 'жатыс', 'шығыс'], 0,
          '-ны/-ні, -ды/-ді — табыс септік', Difficulty.hard),
      ('Б-п дыбыс алмасуы бар тіркесті тап:',
          ['кітап → кітабы', 'қала → қаласы', 'көл → көлі', 'тау → тауы'], 0,
          null, Difficulty.hard),
      ('Үндестік заңына бағынбайтын қосымшаны тап:',
          ['-мен', '-лар', '-да', '-ға'], 0,
          '-мен жуан/жіңішке болып өзгермейді', Difficulty.hard),
    ],
    9: [
      ('Қазақ тілінде неше септік бар?', ['5', '6', '7', '8'], 2, null,
          Difficulty.easy),
      ('Құрмалас сөйлем дегеніміз не?',
          [
            'Бір сөзден тұратын сөйлем',
            'Екі не одан көп жай сөйлемнен құралған сөйлем',
            'Сұраулы сөйлем',
            'Тек етістіктен тұратын сөйлем'
          ],
          1,
          null, Difficulty.easy),
      ('Абайдың қара сөздері барлығы нешеу?', ['25', '37', '45', '50'], 2,
          null, Difficulty.medium),
      ('Қайсысы көсемше жұрнағы?',
          ['-ған/-ген', '-ып/-іп', '-са/-се', '-мақ/-мек'], 1, null,
          Difficulty.medium),
      ('Бастауыш қай сұраққа жауап береді?',
          ['кім? не?', 'қайда?', 'қашан?', 'не істеді?'], 0, null,
          Difficulty.easy),
      ('«Махаббат, қызық мол жылдар» романының авторы кім?',
          [
            'Әзілхан Нұршайықов',
            'Мұхтар Әуезов',
            'Ілияс Есенберлин',
            'Бердібек Соқпақбаев'
          ],
          0,
          null, Difficulty.medium),
      ('Сын есімнің шырайлары нешеу?', ['2', '3', '4', '5'], 2,
          'Жай, салыстырмалы, күшейтпелі, асырмалы', Difficulty.medium),
      ('«Қас пен көздің арасында» тұрақты тіркесінің мағынасы:',
          ['өте тез', 'өте жақын', 'өте әдемі', 'өте қауіпті'], 0, null,
          Difficulty.easy),
      ('Қайсысы омоним сөз?', ['ат', 'кітап', 'дәптер', 'мектеп'], 0,
          '«Ат» — есім қою және жылқы', Difficulty.medium),
      ('Жалғаулардың түрлерін көрсет:',
          [
            'көптік, тәуелдік, жіктік, септік',
            'түбір, қосымша',
            'жұрнақ, жалғау',
            'дауысты, дауыссыз'
          ],
          0,
          null, Difficulty.easy),
      ('«Мен қазақпын» өлеңінің авторы кім?',
          [
            'Жұбан Молдағалиев',
            'Қадыр Мырза Әли',
            'Мұқағали Мақатаев',
            'Олжас Сүлейменов'
          ],
          0,
          null, Difficulty.medium),
      ('Ы, і дыбыстары қандай дауыстылар?',
          ['жуан және жіңішке', 'еріндік', 'ашық', 'дифтонг'], 0,
          'Ы — жуан, І — жіңішке қысаң дауыстылар', Difficulty.hard),
      ('Сөйлемнің тұрлаулы мүшелері:',
          [
            'бастауыш пен баяндауыш',
            'анықтауыш пен пысықтауыш',
            'толықтауыш пен анықтауыш',
            'одағай мен шылау'
          ],
          0, null, Difficulty.easy),
      ('Қазақ тіліне тән төл дыбыс қайсы?', ['ә', 'в', 'ф', 'ц'], 0, null,
          Difficulty.easy),
      ('Синоним қатарды тап:',
          ['әдемі, сұлу, көркем', 'үлкен, кіші', 'ақ, қара', 'күн, түн'], 0,
          null, Difficulty.easy),
      ('Баяндауыш қай сұраққа жауап береді?',
          ['не істеді?', 'кім?', 'қандай?', 'қанша?'], 0, null,
          Difficulty.easy),
      ('«Біз» қай жақтағы есімдік?',
          ['1-жақ көпше', '2-жақ көпше', '3-жақ', '1-жақ жекеше'], 0, null,
          Difficulty.easy),
      ('Мақалды жалғастыр: «Еңбек етсең ерінбей, ...»',
          [
            'тояды қарның тіленбей',
            'білім аласың',
            'тау жығасың',
            'жол табасың'
          ],
          0, null, Difficulty.easy),
      ('Біріккен сөзді тап:', ['қолғап', 'қол', 'саусақ', 'білек'], 0,
          'Қол + қап', Difficulty.easy),
      ('Абай Құнанбайұлы қай жылы туған?',
          ['1845', '1835', '1855', '1865'], 0, null, Difficulty.easy),
      ('Қайсысы одағай?', ['алақай', 'кітап', 'оқыды', 'көк'], 0, null,
          Difficulty.easy),
      ('Салалас құрмаласты тап:',
          [
            'Күн ашық, біз серуенге шықтық.',
            'Дала қандай әдемі!',
            'Сен ертең келесің бе?',
            'Тез жүгір!'
          ],
          0, null, Difficulty.medium),
      ('«Оқыған сайын білімің артады» — «оқыған сайын» қандай мүше?',
          ['мезгіл пысықтауыш', 'бастауыш', 'анықтауыш', 'толықтауыш'], 0,
          null, Difficulty.hard),
      ('Төл сөзді төлеу сөзге дұрыс айналдыр: Ол: «Мен келемін», — деді.',
          [
            'Ол келетінін айтты.',
            'Ол келемін деді ме.',
            'Ол келді деді.',
            'Ол: келемін.'
          ],
          0, null, Difficulty.hard),
    ],
  };

  static const Map<int, List<_Q>> _englishBank = {
    1: [
      ('«Apple» сөзі нені білдіреді?', ['Алмұрт', 'Алма', 'Өрік', 'Жүзім'], 1,
          null, Difficulty.easy),
      ('«Red» қай түс?', ['Көк', 'Жасыл', 'Қызыл', 'Сары'], 2, null,
          Difficulty.easy),
      ('«Dog» сөзі нені білдіреді?', ['Мысық', 'Ит', 'Қоян', 'Тышқан'], 1,
          null, Difficulty.easy),
      ('One, two, ... — келесі сан қайсы?', ['five', 'four', 'three', 'six'],
          2, null, Difficulty.easy),
      ('«Hello» сөзі нені білдіреді?',
          ['Сау бол', 'Сәлем', 'Рақмет', 'Кешір'], 1, null, Difficulty.easy),
      ('«Cat» сөзі нені білдіреді?', ['Ит', 'Құс', 'Мысық', 'Балық'], 2, null,
          Difficulty.easy),
      ('«How old are you?» сұрағына дұрыс жауап:',
          ['I am ten', 'My name is Aru', 'I like cats', 'It is blue'], 0,
          null, Difficulty.medium),
      ('«Book» сөзі нені білдіреді?',
          ['Қалам', 'Кітап', 'Дәптер', 'Сөмке'], 1, null, Difficulty.easy),
      ('«Sun» сөзі нені білдіреді?', ['Ай', 'Жұлдыз', 'Күн', 'Бұлт'], 2, null,
          Difficulty.easy),
      ('Қайсысы «отбасы» сөзінің аудармасы?',
          ['friend', 'family', 'father', 'farm'], 1, null, Difficulty.easy),
      ('«Blue» қай түс?', ['Көк', 'Ақ', 'Қара', 'Қызғылт'], 0, null,
          Difficulty.easy),
      ('«Goodbye» сөзі нені білдіреді?',
          ['Сәлем', 'Сау бол', 'Жақсы', 'Иә'], 1, null, Difficulty.easy),
      ('«Milk» сөзі нені білдіреді?', ['сүт', 'су', 'шай', 'нан'], 0, null,
          Difficulty.easy),
      ('Қайсысы жануар?', ['table', 'horse', 'chair', 'door'], 1, null,
          Difficulty.easy),
      ('«Green» қай түс?', ['жасыл', 'сары', 'көк', 'ақ'], 0, null,
          Difficulty.easy),
      ('Five, six, ... — келесі сан қайсы?',
          ['seven', 'eight', 'nine', 'ten'], 0, null, Difficulty.easy),
      ('I ___ a pupil.', ['am', 'is', 'are', 'be'], 0, null,
          Difficulty.medium),
      ('This is my mother. ___ name is Aliya.',
          ['Her', 'His', 'Its', 'My'], 0, null, Difficulty.medium),
      ('«Ten» саны қанша?', ['8', '9', '10', '11'], 2, null,
          Difficulty.medium),
      ('How many legs does a cat have?',
          ['two', 'three', 'four', 'five'], 2, null, Difficulty.medium),
      ('We ___ football.', ['play', 'plays', 'playing', 'player'], 0, null,
          Difficulty.medium),
      ('Артық сөзді тап: apple, banana, dog, orange',
          ['apple', 'banana', 'dog', 'orange'], 2,
          'Dog — жануар, қалғаны — жеміс', Difficulty.hard),
      ('There ___ a book on the table.', ['is', 'are', 'am', 'be'], 0, null,
          Difficulty.hard),
      ('Дұрыс сөйлемді тап:',
          [
            'I like apples.',
            'I likes apples.',
            'Me like apples.',
            'I liking apples.'
          ],
          0, null, Difficulty.hard),
    ],
    5: [
      ('She ___ to school every day.', ['go', 'goes', 'going', 'gone'], 1,
          'Present Simple, 3-жақ жекеше: -es', Difficulty.easy),
      ('«Child» сөзінің көпше түрі:',
          ['childs', 'childes', 'children', 'childrens'], 2, null,
          Difficulty.medium),
      ('I ___ a student.', ['is', 'are', 'am', 'be'], 2, null,
          Difficulty.easy),
      ('«Big» сөзінің антонимі:', ['tall', 'small', 'long', 'wide'], 1, null,
          Difficulty.easy),
      ('«Yesterday» сөзі қай шақты білдіреді?',
          ['Present', 'Future', 'Past', 'Perfect'], 2, null,
          Difficulty.easy),
      ('Орынды сұрау үшін қай сұрақ сөзі қолданылады?',
          ['When', 'Who', 'Where', 'Why'], 2, null, Difficulty.easy),
      ('They ___ football now.',
          ['play', 'plays', 'are playing', 'played'], 2,
          '«Now» — Present Continuous белгісі', Difficulty.medium),
      ('Қайсысы реттік сан есім?', ['one', 'first', 'once', 'only'], 1, null,
          Difficulty.easy),
      ('How ___ water do you drink?', ['many', 'much', 'few', 'a lot'], 1,
          'Water — саналмайтын зат есім', Difficulty.medium),
      ('We ___ to Astana last summer.', ['go', 'goes', 'went', 'gone'], 2,
          'Past Simple', Difficulty.medium),
      ('«Beautiful» сөзі нені білдіреді?',
          ['үлкен', 'әдемі', 'жылдам', 'ақылды'], 1, null, Difficulty.easy),
      ('My brother is ___ than me.',
          ['tall', 'taller', 'tallest', 'more tall'], 1, null,
          Difficulty.medium),
      ('«Window» сөзі нені білдіреді?',
          ['есік', 'терезе', 'қабырға', 'еден'], 1, null, Difficulty.easy),
      ('Қайсысы апта күні?', ['Monday', 'May', 'Morning', 'Mother'], 0, null,
          Difficulty.easy),
      ('«I have got a dog» — аудармасы:',
          [
            'Менің итім бар.',
            'Мен итті көрдім.',
            'Ит үлкен.',
            'Менде мысық бар.'
          ],
          0, null, Difficulty.easy),
      ('«Always» сөзінің мағынасы:',
          ['әрқашан', 'ешқашан', 'кейде', 'жиі'], 0, null, Difficulty.easy),
      ('She is ___ doctor.', ['a', 'an', 'the', '—'], 0, null,
          Difficulty.easy),
      ('«Winter» — қай мезгіл?', ['қыс', 'жаз', 'көктем', 'күз'], 0, null,
          Difficulty.easy),
      ('«Can you swim?» — дұрыс жауап:',
          ['Yes, I can.', 'Yes, I am.', 'Yes, I swim can.', 'Yes, can.'], 0,
          null, Difficulty.easy),
      ('There are ___ apples in the basket.',
          ['some', 'any', 'a', 'an'], 0, 'Болымды сөйлемде some',
          Difficulty.medium),
      ('«Mice» қай сөздің көпше түрі?',
          ['mouse', 'mouth', 'moose', 'mice'], 0, null, Difficulty.medium),
      ('He ___ TV when I came.',
          ['was watching', 'watched', 'watches', 'is watching'], 0,
          'Past Continuous', Difficulty.hard),
      ('Дұрыс сұрақты тап:',
          [
            'Does she like music?',
            'Does she likes music?',
            'Do she like music?',
            'She does like music?'
          ],
          0, null, Difficulty.hard),
      ('«I have to wear a uniform» сөйлемінің мағынасы:',
          [
            'Форма киюім міндетті',
            'Форма кигім келеді',
            'Форма кие аламын',
            'Форма кимеймін'
          ],
          0, 'Have to — міндеттілік', Difficulty.hard),
    ],
    9: [
      ('I have already ___ my homework.', ['do', 'did', 'done', 'doing'], 2,
          'Present Perfect: have + V3', Difficulty.medium),
      ('The letter ___ written yesterday.', ['is', 'was', 'were', 'be'], 1,
          'Passive Voice, Past Simple', Difficulty.medium),
      ('If I ___ rich, I would travel the world.',
          ['am', 'was', 'were', 'be'], 2, 'Second Conditional: were',
          Difficulty.hard),
      ('«Give up» фразалық етістігінің мағынасы:',
          ['бастау', 'бас тарту', 'беру', 'көтеру'], 1, null,
          Difficulty.easy),
      ('She said that she ___ tired.', ['is', 'was', 'be', 'been'], 1,
          'Reported Speech: шақ бір қадам артқа', Difficulty.medium),
      ('___ John ___ Mary came to the party.',
          ['Neither / nor', 'Either / nor', 'Both / or', 'Not / and'], 0,
          null, Difficulty.hard),
      ('I enjoy ___ books in the evening.',
          ['read', 'to read', 'reading', 'reads'], 2,
          'Enjoy + V-ing', Difficulty.medium),
      ('«In spite of» тіркесінің мағынасы:',
          ['себебінен', 'қарамастан', 'арқасында', 'кейін'], 1, null,
          Difficulty.medium),
      ('This is ___ best film I have ever seen.',
          ['a', 'an', 'the', '—'], 2, 'Superlative алдында «the»',
          Difficulty.easy),
      ('By next year, I ___ school.',
          [
            'will finish',
            'will have finished',
            'finish',
            'am finishing'
          ],
          1,
          'Future Perfect', Difficulty.hard),
      ('«Sustainable» сөзіне жақын мағына:',
          ['тұрақты', 'қымбат', 'жылдам', 'сирек'], 0, null,
          Difficulty.medium),
      ('He suggested ___ to the museum.',
          ['go', 'to go', 'going', 'gone'], 2, 'Suggest + V-ing',
          Difficulty.medium),
      ('«Environment» сөзінің мағынасы:',
          ['қоршаған орта', 'үкімет', 'көлік', 'ғимарат'], 0, null,
          Difficulty.easy),
      ('I ___ born in Kazakhstan.', ['was', 'were', 'am', 'is'], 0, null,
          Difficulty.easy),
      ('Қайсысы саналмайтын зат есім?', ['water', 'apple', 'book', 'car'], 0,
          null, Difficulty.easy),
      ('«Famous» сөзінің синонимі:',
          ['well-known', 'unknown', 'funny', 'strange'], 0, null,
          Difficulty.easy),
      ('She is interested ___ music.', ['in', 'on', 'at', 'for'], 0, null,
          Difficulty.easy),
      ('How long ___ you lived here?', ['have', 'do', 'are', 'did'], 0,
          'Present Perfect', Difficulty.easy),
      ('«Library» дегеніміз:',
          ['кітапхана', 'дәріхана', 'асхана', 'спортзал'], 0, null,
          Difficulty.easy),
      ('We look forward to ___ you.', ['seeing', 'see', 'saw', 'seen'], 0,
          'To — мұнда предлог, кейін V-ing', Difficulty.easy),
      ('The capital of Great Britain is ___.',
          ['London', 'Paris', 'Berlin', 'Madrid'], 0, null, Difficulty.easy),
      ('If it rains, we ___ at home.',
          ['will stay', 'stayed', 'would stayed', 'staying'], 0,
          'First Conditional', Difficulty.medium),
      ('The book ___ by millions of people.',
          ['is read', 'reads', 'is reading', 'read'], 0, 'Passive Voice',
          Difficulty.medium),
      ('I wish I ___ more time.', ['had', 'have', 'will have', 'has'], 0,
          'Wish + Past Simple', Difficulty.hard),
    ],
  };

  static const Map<int, List<_Q>> _physicsBank = {
    1: [
      ('Су табиғатта неше күйде кездеседі?', ['1', '2', '3', '4'], 2,
          'Қатты, сұйық, газ', Difficulty.medium),
      ('Магнит нені тартады?',
          ['ағашты', 'темірді', 'қағазды', 'пластикті'], 1, null,
          Difficulty.easy),
      ('Жыл мезгілдері нешеу?', ['2', '3', '4', '5'], 2, null,
          Difficulty.easy),
      ('Күн жүйесінде неше ғаламшар бар?', ['7', '8', '9', '10'], 1, null,
          Difficulty.medium),
      ('Жер Күнді бір рет қанша уақытта айналады?',
          ['1 күн', '1 ай', '1 жыл', '1 апта'], 2, null, Difficulty.easy),
      ('Кемпірқосақта неше түс бар?', ['5', '6', '7', '8'], 2, null,
          Difficulty.easy),
      ('Түнде аспанда не жарқырайды?',
          ['Күн', 'Ай мен жұлдыздар', 'Бұлттар', 'Кемпірқосақ'], 1, null,
          Difficulty.easy),
      ('Мұз ерігенде неге айналады?', ['буға', 'суға', 'қарға', 'тасқа'], 1,
          null, Difficulty.easy),
      ('Дыбысты қай мүшемен естиміз?', ['көз', 'құлақ', 'мұрын', 'тіл'], 1,
          null, Difficulty.easy),
      ('Өсімдікке өсу үшін не қажет?',
          ['жарық пен су', 'тек қараңғы', 'тек жел', 'тек тас'], 0, null,
          Difficulty.easy),
      ('Жерден жоғары лақтырған доп неге түседі?',
          [
            'жел итереді',
            'тартылыс күші тартады',
            'ауа тартады',
            'өзі ауыр емес'
          ],
          1,
          null, Difficulty.medium),
      ('Қайсысы жарық көзі?', ['айна', 'Күн', 'терезе', 'көлеңке'], 1, null,
          Difficulty.easy),
      ('Қайсысы ең ыстық?', ['мұз', 'салқын су', 'қайнаған су', 'қар'], 2,
          null, Difficulty.easy),
      ('Жел дегеніміз не?',
          ['ауаның қозғалысы', 'судың ағысы', 'жердің дірілі', 'бұлт түсі'],
          0, null, Difficulty.easy),
      ('Қатты аязда су не болады?',
          ['мұзға айналады', 'буға айналады', 'жоғалады', 'ыстық болады'], 0,
          null, Difficulty.easy),
      ('Күн қай уақытта шығады?', ['таңертең', 'түсте', 'кешке', 'түнде'], 0,
          null, Difficulty.easy),
      ('Доп қай бетте алысқа домалайды?',
          ['тегіс бетте', 'құмда', 'қалың шөпте', 'балшықта'], 0, null,
          Difficulty.easy),
      ('Көлеңке қашан пайда болады?',
          [
            'жарық жолын зат бөгегенде',
            'жаңбыр жауғанда',
            'жел соққанда',
            'қар жауғанда'
          ],
          0, null, Difficulty.medium),
      ('Қайсысы табиғи жарық көзі?', ['шам', 'Күн', 'фонарь', 'теледидар'],
          1, null, Difficulty.medium),
      ('Темір мен ағаштың қайсысы суға батады?',
          ['темір', 'ағаш', 'екеуі де', 'ешқайсысы'], 0, null,
          Difficulty.medium),
      ('Дыбыс қайдан шығады?',
          ['заттың дірілінен', 'жарықтан', 'түстен', 'иістен'], 0, null,
          Difficulty.medium),
      ('Неге қыста терезе терлейді?',
          [
            'жылы бу суық әйнекке тиіп, суға айналады',
            'әйнек ериді',
            'жел үрлейді',
            'күн қыздырады'
          ],
          0, null, Difficulty.hard),
      ('Ай өзі жарық шығара ма?',
          [
            'жоқ, Күн жарығын шағылыстырады',
            'иә, өзі жанады',
            'тек қыста',
            'тек жазда'
          ],
          0, null, Difficulty.hard),
      ('Магнит қай заттарды тартпайды?',
          ['пластик пен ағашты', 'темірді', 'болатты', 'шегені'], 0, null,
          Difficulty.hard),
    ],
    5: [
      ('Жылдамдықтың формуласы қайсы?',
          ['v = s · t', 'v = s / t', 'v = t / s', 'v = s + t'], 1, null,
          Difficulty.medium),
      ('Күштің өлшем бірлігі:', ['Ватт', 'Джоуль', 'Ньютон', 'Паскаль'], 2,
          null, Difficulty.easy),
      ('Дене тыныштықта қалу қасиеті қалай аталады?',
          ['үдеу', 'инерция', 'қысым', 'жұмыс'], 1,
          'Ньютонның бірінші заңы', Difficulty.medium),
      ('Тығыздықтың формуласы:',
          ['ρ = m / V', 'ρ = V / m', 'ρ = m · V', 'ρ = m + V'], 0, null,
          Difficulty.medium),
      ('Дыбыс вакуумда тарай ма?',
          ['иә', 'жоқ', 'тек күндіз', 'тек суда'], 1,
          'Дыбысқа орта қажет', Difficulty.medium),
      ('Су қалыпты жағдайда неше градуста қайнайды?',
          ['90°C', '100°C', '110°C', '80°C'], 1, null, Difficulty.easy),
      ('Атмосфералық қысымды қандай құрал өлшейді?',
          ['термометр', 'барометр', 'спидометр', 'амперметр'], 1, null,
          Difficulty.medium),
      ('Ұзындықтың негізгі өлшем бірлігі (ХБЖ):',
          ['сантиметр', 'километр', 'метр', 'миллиметр'], 2, null,
          Difficulty.easy),
      ('Қайсысы жай механизм?', ['рычаг', 'компьютер', 'мотор', 'батарея'], 0,
          null, Difficulty.easy),
      ('Жарық көзінен шыққан сәуле қалай таралады?',
          ['қисық', 'түзу сызықпен', 'шеңбермен', 'кездейсоқ'], 1, null,
          Difficulty.easy),
      ('Массаның өлшем бірлігі (ХБЖ):',
          ['грамм', 'килограмм', 'тонна', 'фунт'], 1, null, Difficulty.easy),
      ('Температураны қандай құрал өлшейді?',
          ['барометр', 'термометр', 'динамометр', 'вольтметр'], 1, null,
          Difficulty.easy),
      ('Уақыттың негізгі өлшем бірлігі (ХБЖ):',
          ['секунд', 'сағат', 'минут', 'тәулік'], 0, null, Difficulty.easy),
      ('Мұз неше градуста ери бастайды?',
          ['0°C', '10°C', '100°C', '−10°C'], 0, null, Difficulty.easy),
      ('Жылдамдықтың өлшем бірлігі:', ['м/с', 'кг', 'м²', 'Н'], 0, null,
          Difficulty.easy),
      ('Көлемді қай бірлікпен өлшейді?',
          ['литр', 'метр', 'грамм', 'секунд'], 0, null, Difficulty.easy),
      ('Термометр нені өлшейді?',
          ['температураны', 'қысымды', 'массаны', 'уақытты'], 0, null,
          Difficulty.easy),
      ('Қайсысы жылу көзі?', ['от', 'мұз', 'қар', 'жел'], 0, null,
          Difficulty.easy),
      ('Бөлме температурасында су қандай күйде?',
          ['сұйық', 'қатты', 'газ', 'плазма'], 0, null, Difficulty.easy),
      ('80 км жолды 2 сағатта жүрген көліктің жылдамдығы:',
          ['40 км/сағ', '80 км/сағ', '160 км/сағ', '20 км/сағ'], 0,
          'v = s / t = 80 / 2', Difficulty.medium),
      ('Дыбыс қай ортада ең тез тарайды?',
          ['қатты денеде', 'ауада', 'суда', 'вакуумда'], 0, null,
          Difficulty.medium),
      ('Массасы 2 кг дененің салмағы шамамен (g ≈ 10 Н/кг):',
          ['20 Н', '2 Н', '200 Н', '10 Н'], 0, 'P = m · g',
          Difficulty.hard),
      ('Тығыздығы судан кіші зат суда не істейді?',
          ['қалқып жүреді', 'батады', 'ериді', 'буланады'], 0, null,
          Difficulty.hard),
      ('150 м жолды 30 секундта жүгірген оқушының жылдамдығы:',
          ['5 м/с', '4 м/с', '3 м/с', '6 м/с'], 0, 'v = 150 / 30',
          Difficulty.hard),
    ],
    9: [
      ('Ом заңының формуласы:',
          ['I = U / R', 'I = R / U', 'I = U · R', 'U = I / R'], 0, null,
          Difficulty.medium),
      ('Жарық жылдамдығы вакуумда шамамен:',
          ['300 000 км/с', '150 000 км/с', '3 000 км/с', '30 000 км/с'], 0,
          null, Difficulty.easy),
      ('E = mc² формуласының авторы:',
          ['Ньютон', 'Эйнштейн', 'Тесла', 'Бор'], 1, null, Difficulty.easy),
      ('Электр тогының күшінің өлшем бірлігі:',
          ['Вольт', 'Ом', 'Ампер', 'Ватт'], 2, null, Difficulty.easy),
      ('Еркін түсу үдеуі g шамамен:',
          ['9,8 м/с²', '8,9 м/с²', '10,8 м/с²', '6,7 м/с²'], 0, null,
          Difficulty.medium),
      ('Кулон заңы нені сипаттайды?',
          [
            'зарядтардың өзара әрекетін',
            'жылу алмасуды',
            'дыбыс таралуын',
            'жарық сынуын'
          ],
          0,
          null, Difficulty.medium),
      ('Энергияның сақталу заңы бойынша энергия...',
          [
            'жоғалады',
            'жоқтан пайда болады',
            'бір түрден екінші түрге ауысады',
            'тек артады'
          ],
          2,
          null, Difficulty.medium),
      ('Кернеудің өлшем бірлігі:', ['Ампер', 'Вольт', 'Ом', 'Джоуль'], 1,
          null, Difficulty.easy),
      ('Фотон дегеніміз не?',
          [
            'жарық кванты',
            'атом ядросы',
            'электр заряды',
            'дыбыс толқыны'
          ],
          0,
          null, Difficulty.medium),
      ('Кедергінің өлшем бірлігі:', ['Вольт', 'Ватт', 'Ом', 'Ампер'], 2,
          null, Difficulty.easy),
      ('Механикалық жұмыстың формуласы:',
          ['A = F · s', 'A = F / s', 'A = m · v', 'A = m · g'], 0, null,
          Difficulty.medium),
      ('Дыбыстың ауадағы жылдамдығы шамамен:',
          ['140 м/с', '340 м/с', '540 м/с', '1000 м/с'], 1, null,
          Difficulty.medium),
      ('Қуаттың өлшем бірлігі:', ['Ватт', 'Вольт', 'Ампер', 'Ом'], 0, null,
          Difficulty.easy),
      ('Ньютонның екінші заңы:',
          ['F = m·a', 'E = mc²', 'U = I·R', 'A = F·s'], 0, null,
          Difficulty.easy),
      ('Қысымның өлшем бірлігі:',
          ['Паскаль', 'Ньютон', 'Джоуль', 'Ватт'], 0, null, Difficulty.easy),
      ('Электр тогын жақсы өткізетін зат:',
          ['мыс', 'резеңке', 'шыны', 'ағаш'], 0, null, Difficulty.easy),
      ('Атом ядросы неден тұрады?',
          ['протон мен нейтроннан', 'электроннан', 'фотоннан', 'молекуладан'],
          0, null, Difficulty.easy),
      ('Энергияның өлшем бірлігі:', ['Джоуль', 'Ампер', 'Кельвин', 'Ом'], 0,
          null, Difficulty.easy),
      ('Жиіліктің өлшем бірлігі:', ['Герц', 'Ватт', 'Тесла', 'Вольт'], 0,
          null, Difficulty.easy),
      ('Тұрақты магниттің полюстері:',
          [
            'солтүстік және оңтүстік',
            'шығыс және батыс',
            'оң және сол',
            'жоғары және төмен'
          ],
          0, null, Difficulty.easy),
      ('Жылулық қозғалыс дегеніміз:',
          [
            'молекулалардың ретсіз қозғалысы',
            'дененің құлауы',
            'токтың ағуы',
            'жарықтың таралуы'
          ],
          0, null, Difficulty.easy),
      ('Кернеуі 12 В, кедергісі 4 Ом тізбектегі ток күші:',
          ['3 А', '48 А', '8 А', '0,3 А'], 0, 'I = U / R = 12 / 4',
          Difficulty.hard),
      ('10 м биіктіктегі 2 кг дененің потенциалдық энергиясы (g ≈ 10):',
          ['200 Дж', '20 Дж', '100 Дж', '2000 Дж'], 0, 'E = m·g·h',
          Difficulty.hard),
      ('Толқын ұзындығы 2 м, жиілігі 170 Гц дыбыстың жылдамдығы:',
          ['340 м/с', '85 м/с', '172 м/с', '680 м/с'], 0, 'v = λ · ν',
          Difficulty.hard),
    ],
  };

  static const Map<int, List<_Q>> _csBank = {
    1: [
      ('Компьютердің «миы» қалай аталады?',
          ['монитор', 'процессор', 'тінтуір', 'принтер'], 1, null,
          Difficulty.medium),
      ('Тінтуір не үшін қолданылады?',
          [
            'мәтін теру үшін',
            'экранда көрсеткішті басқару үшін',
            'дыбыс шығару үшін',
            'сурет басып шығару үшін'
          ],
          1,
          null, Difficulty.easy),
      ('Мәтін теруге арналған құрылғы:',
          ['пернетақта', 'монитор', 'динамик', 'камера'], 0, null,
          Difficulty.easy),
      ('Экранда ақпаратты қай құрылғы көрсетеді?',
          ['жүйелік блок', 'монитор', 'тінтуір', 'микрофон'], 1, null,
          Difficulty.easy),
      ('Интернет дегеніміз не?',
          [
            'компьютер ойыны',
            'дүниежүзілік компьютер желісі',
            'бағдарлама',
            'құрылғы'
          ],
          1,
          null, Difficulty.easy),
      ('Қайсысы компьютер бөлігі ЕМЕС?',
          ['монитор', 'пернетақта', 'қасық', 'тінтуір'], 2, null,
          Difficulty.easy),
      ('Сурет салуға арналған бағдарлама:',
          ['Paint', 'калькулятор', 'сағат', 'күнтізбе'], 0, null,
          Difficulty.easy),
      ('Компьютерде ойнауға болатын нәрсе:',
          ['ойын', 'тамақ', 'көлік', 'үй'], 0, null, Difficulty.easy),
      ('Қауіпсіз интернет ережесі:',
          [
            'бөтенге құпиясөз айтпау',
            'барлық сілтемені ашу',
            'жеке мәліметті бөлісу',
            'түнде отыру'
          ],
          0,
          null, Difficulty.easy),
      ('Планшетті қалай басқарамыз?',
          ['саусақпен', 'аяқпен', 'дауыспен ғана', 'қаламмен ғана'], 0, null,
          Difficulty.easy),
      ('Фотосурет түсіретін құрылғы:',
          ['камера', 'принтер', 'динамик', 'модем'], 0, null,
          Difficulty.easy),
      ('Компьютерді өшіру алдында не істеу керек?',
          [
            'бағдарламаларды жабу',
            'суға салу',
            'экранды сүрту',
            'тінтуірді алып тастау'
          ],
          0,
          null, Difficulty.medium),
      ('Қайсысы компьютер?', ['ноутбук', 'теледидар пульті', 'шам', 'кітап'],
          0, null, Difficulty.easy),
      ('Дыбысты қай құрылғыдан естиміз?',
          ['динамик', 'монитор', 'тінтуір', 'принтер'], 0, null,
          Difficulty.easy),
      ('Экрандағы кішкентай суреттер қалай аталады?',
          ['белгішелер', 'терезелер', 'түймелер', 'сызықтар'], 0, null,
          Difficulty.easy),
      ('Қағазға мәтін басып шығаратын құрылғы:',
          ['принтер', 'сканер', 'модем', 'динамик'], 0, null,
          Difficulty.easy),
      ('Файл дегеніміз не?',
          [
            'компьютерде сақталған ақпарат',
            'құрылғы',
            'сым',
            'экран'
          ],
          0, null, Difficulty.medium),
      ('Интернетте бейтаныс адамға нені айтуға болмайды?',
          [
            'мекенжайың мен құпиясөзіңді',
            'сүйікті түсіңді',
            'ертегіні',
            'сүйікті ойыныңды'
          ],
          0, null, Difficulty.medium),
      ('Планшет пен компьютердің ортақ қасиеті:',
          [
            'екеуінде де экран бар',
            'екеуі де қағаздан жасалған',
            'екеуі де домалақ',
            'екеуі де ұшады'
          ],
          0, null, Difficulty.medium),
      ('Бағдарлама дегеніміз не?',
          [
            'компьютерге арналған нұсқаулар',
            'қағаз кітап',
            'металл бөлшек',
            'сурет'
          ],
          0, null, Difficulty.medium),
      ('Экрандағы көрсеткішті жылжытатын құрылғы:',
          ['тінтуір', 'принтер', 'динамик', 'камера'], 0, null,
          Difficulty.easy),
      ('Компьютер қандай тілде «ойлайды»?',
          ['сандар тілінде (0 мен 1)', 'қазақша', 'сурет тілінде', 'ым тілінде'],
          0, null, Difficulty.hard),
      ('Қайсысында жады (память) бар?',
          ['компьютерде', 'қарындашта', 'қағазда', 'өшіргіште'], 0, null,
          Difficulty.hard),
      ('Робот нені орындайды?',
          ['берілген алгоритмді', 'өз қалауын', 'адамның ойын', 'ауа райын'],
          0, null, Difficulty.hard),
    ],
    5: [
      ('1 байтта неше бит бар?', ['4', '8', '16', '32'], 1, null,
          Difficulty.easy),
      ('Алгоритм дегеніміз не?',
          [
            'әрекеттердің нақты тізбегі',
            'компьютер бөлігі',
            'интернет желісі',
            'мәтіндік файл'
          ],
          0,
          null, Difficulty.easy),
      ('Қайсысы браузер?', ['Chrome', 'Word', 'Excel', 'Paint'], 0, null,
          Difficulty.easy),
      ('.jpg кеңейтімі қандай файлды білдіреді?',
          ['мәтін', 'сурет', 'дыбыс', 'видео'], 1, null, Difficulty.easy),
      ('Екілік санау жүйесінде қандай цифрлар қолданылады?',
          ['0 және 1', '1 және 2', '0-9', 'A-F'], 0, null, Difficulty.easy),
      ('1 КБ неше байтқа тең?', ['100', '512', '1024', '2048'], 2, null,
          Difficulty.medium),
      ('Қайсысы енгізу құрылғысы?',
          ['монитор', 'принтер', 'пернетақта', 'динамик'], 2, null,
          Difficulty.easy),
      ('Ақпаратты тұрақты сақтайтын құрылғы:',
          ['қатты диск', 'процессор', 'монитор', 'тінтуір'], 0, null,
          Difficulty.medium),
      ('Scratch бағдарламасында не жасайды?',
          [
            'анимация мен ойын',
            'кесте',
            'презентация ғана',
            'фотосурет'
          ],
          0,
          null, Difficulty.easy),
      ('Компьютердің операциялық жүйесі:',
          ['Windows', 'Google', 'YouTube', 'Wi-Fi'], 0, null,
          Difficulty.easy),
      ('Вирустан қорғайтын бағдарлама:',
          ['антивирус', 'браузер', 'архиватор', 'редактор'], 0, null,
          Difficulty.easy),
      ('Қайсысы шығару құрылғысы?',
          ['микрофон', 'сканер', 'принтер', 'пернетақта'], 2, null,
          Difficulty.easy),
      ('Қайсысы іздеу жүйесі?', ['Google', 'Paint', 'Word', 'Excel'], 0,
          null, Difficulty.easy),
      ('Мәтін теруге арналған бағдарлама:',
          ['Word', 'Paint', 'калькулятор', 'ойын'], 0, null,
          Difficulty.easy),
      ('Папка не үшін қажет?',
          [
            'файлдарды реттеп сақтау үшін',
            'сурет салу үшін',
            'музыка тыңдау үшін',
            'ойын ойнау үшін'
          ],
          0, null, Difficulty.easy),
      ('Қайсысы ақпарат сақтау құрылғысы?',
          ['флешка', 'монитор', 'тінтуір', 'динамик'], 0, null,
          Difficulty.easy),
      ('1 МБ неше КБ-қа тең?', ['1024', '100', '512', '2048'], 0, null,
          Difficulty.medium),
      ('Алгоритмнің қадамдары қалай орындалады?',
          ['рет-ретімен', 'кез келген ретпен', 'соңынан басына', 'бір мезгілде'],
          0, null, Difficulty.medium),
      ('Презентация жасайтын бағдарлама:',
          ['PowerPoint', 'Блокнот', 'Калькулятор', 'Проводник'], 0, null,
          Difficulty.medium),
      ('Компьютердің уақытша жады:',
          ['ОЗУ (RAM)', 'қатты диск', 'флешка', 'CD'], 0, null,
          Difficulty.medium),
      ('Спам дегеніміз не?',
          [
            'қажетсіз жарнамалық хаттар',
            'пайдалы бағдарлама',
            'ойын түрі',
            'файл форматы'
          ],
          0, null, Difficulty.medium),
      ('11₂ екілік саны ондық жүйеде:', ['3', '2', '11', '4'], 0,
          '2 + 1 = 3', Difficulty.hard),
      ('Қай құрылғы әрі енгізу, әрі шығару құрылғысы?',
          ['сенсорлық экран', 'пернетақта', 'принтер', 'микрофон'], 0, null,
          Difficulty.hard),
      ('100₂ екілік саны ондық жүйеде:', ['4', '100', '2', '8'], 0,
          '1·4 + 0·2 + 0·1 = 4', Difficulty.hard),
    ],
    9: [
    ],
  };

  // ---------------- Сәйкестендіру жұп банктері ----------------

  static const Map<String, Map<int, List<_P>>> _pairBanks = {
    'kazakh': {
      1: [
        ('үлкен', 'кіші'),
        ('ыстық', 'суық'),
        ('ақ', 'қара'),
        ('биік', 'аласа'),
        ('жақсы', 'жаман'),
        ('күн', 'түн'),
        ('ұзын', 'қысқа'),
        ('ауыр', 'жеңіл'),
        ('жаңа', 'ескі'),
        ('тәтті', 'ащы'),
        ('алыс', 'жақын'),
        ('жуан', 'жіңішке'),
      ],
      5: [
        ('Барыс септік', '-ға/-ге'),
        ('Жатыс септік', '-да/-де'),
        ('Шығыс септік', '-дан/-ден'),
        ('Ілік септік', '-ның/-нің'),
        ('Табыс септік', '-ны/-ні'),
        ('Көмектес септік', '-мен/-бен'),
        ('Көптік жалғау', '-лар/-лер'),
        ('Тәуелдік (менің)', '-ым/-ім'),
      ],
      9: [
        ('Мұхтар Әуезов', '«Абай жолы»'),
        ('Әзілхан Нұршайықов', '«Махаббат, қызық мол жылдар»'),
        ('Жұбан Молдағалиев', '«Мен қазақпын»'),
        ('Бердібек Соқпақбаев', '«Менің атым Қожа»'),
        ('Ілияс Есенберлин', '«Көшпенділер»'),
        ('Мұқағали Мақатаев', '«Аққулар ұйықтағанда»'),
        ('Ғабит Мүсірепов', '«Ұлпан»'),
        ('Сәбит Мұқанов', '«Ботагөз»'),
      ],
    },
    'english': {
      1: [
        ('dog', 'ит'),
        ('cat', 'мысық'),
        ('apple', 'алма'),
        ('book', 'кітап'),
        ('sun', 'күн'),
        ('red', 'қызыл'),
        ('blue', 'көк'),
        ('family', 'отбасы'),
        ('green', 'жасыл'),
        ('milk', 'сүт'),
        ('school', 'мектеп'),
        ('water', 'су'),
      ],
      5: [
        ('go', 'went'),
        ('see', 'saw'),
        ('eat', 'ate'),
        ('come', 'came'),
        ('take', 'took'),
        ('make', 'made'),
        ('write', 'wrote'),
        ('give', 'gave'),
        ('run', 'ran'),
        ('know', 'knew'),
      ],
      9: [
        ('give up', 'бас тарту'),
        ('look for', 'іздеу'),
        ('find out', 'анықтау'),
        ('put off', 'кейінге қалдыру'),
        ('carry on', 'жалғастыру'),
        ('turn down', 'қабылдамау'),
        ('get over', 'жеңу, айығу'),
        ('set up', 'құру, орнату'),
        ('come across', 'кездейсоқ табу'),
      ],
    },
    'physics': {
      1: [
        ('мұз', 'қатты күй'),
        ('су', 'сұйық күй'),
        ('бу', 'газ күйі'),
        ('Күн', 'жұлдыз'),
        ('Ай', 'Жердің серігі'),
        ('Жер', 'ғаламшар'),
        ('шам', 'жарық көзі'),
        ('пеш', 'жылу көзі'),
      ],
      5: [
        ('термометр', 'температура'),
        ('барометр', 'қысым'),
        ('спидометр', 'жылдамдық'),
        ('таразы', 'масса'),
        ('секундомер', 'уақыт'),
        ('динамометр', 'күш'),
        ('сызғыш', 'ұзындық'),
        ('мензурка', 'көлем'),
      ],
      9: [
        ('күш', 'Ньютон'),
        ('кернеу', 'Вольт'),
        ('ток күші', 'Ампер'),
        ('кедергі', 'Ом'),
        ('энергия', 'Джоуль'),
        ('қуат', 'Ватт'),
        ('қысым', 'Паскаль'),
        ('жиілік', 'Герц'),
        ('заряд', 'Кулон'),
      ],
    },
    'cs': {
      1: [
        ('пернетақта', 'мәтін теру'),
        ('тінтуір', 'көрсеткішті басқару'),
        ('монитор', 'көрсету'),
        ('принтер', 'басып шығару'),
        ('камера', 'сурет түсіру'),
        ('динамик', 'дыбыс шығару'),
        ('флешка', 'ақпарат тасу'),
      ],
      5: [
        ('.jpg', 'сурет'),
        ('.txt', 'мәтін'),
        ('.mp3', 'дыбыс'),
        ('.mp4', 'видео'),
        ('.exe', 'бағдарлама'),
        ('.zip', 'архив'),
        ('.pdf', 'құжат'),
        ('.html', 'веб-бет'),
      ],
      9: [
        ('print()', 'экранға шығару'),
        ('for', 'цикл'),
        ('if', 'шарт'),
        ('def', 'функция'),
        ('list', 'тізім'),
        ('input()', 'енгізу'),
        ('dict', 'сөздік'),
        ('append()', 'тізімге қосу'),
      ],
    },
    'biology': {
      5: [
        ('ядро', 'ДНҚ сақтау'),
        ('хлоропласт', 'фотосинтез'),
        ('тамыр', 'су сіңіру'),
        ('гүл', 'көбею'),
        ('желбезек', 'су ортасы'),
        ('жапырақ', 'қорек жасау'),
      ],
      9: [
        ('жүрек', 'қан айдау'),
        ('өкпе', 'оттегі алу'),
        ('бүйрек', 'қан сүзу'),
        ('ми', 'ағзаны басқару'),
        ('ген', 'белгі кодтау'),
        ('митоз', 'бірдей жасуша'),
        ('мейоз', 'жыныс жасушасы'),
      ],
    },
    'chemistry': {
      5: [
        ('атом', 'ең кіші бөлшек'),
        ('молекула', 'атомдар қосындысы'),
        ('H₂O', 'су'),
        ('таза зат', 'бір зат'),
        ('қоспа', 'бірнеше зат'),
        ('Fe', 'темір'),
      ],
      9: [
        ('қышқыл', 'H⁺ ион'),
        ('негіз', 'OH⁻ ион'),
        ('NaCl', 'ас тұзы'),
        ('иондық байланыс', 'электрон беру/алу'),
        ('коваленттік байланыс', 'электрон ортақтасу'),
        ('тотығу', 'электрон жоғалту'),
      ],
    },
    'history': {
      5: [
        ('Тас дәуірі', 'аңшылық'),
        ('Қола дәуірі', 'металл игеру'),
        ('Беғазы-Дәндібай', 'қола мәдениеті'),
        ('Неолит', 'егіншілік'),
        ('Қорған', 'көне зират'),
        ('Сақтар', 'алтын өңдеу'),
      ],
      9: [
        ('1465 жыл', 'Қазақ хандығы'),
        ('1723 жыл', 'Ақтабан шұбырынды'),
        ('1991 жыл', 'Тәуелсіздік'),
        ('Тәуке хан', 'Жеті Жарғы'),
        ('Кенесары', 'ұлт-азаттық көтеріліс'),
        ('Абылай хан', 'жоңғарға қарсы'),
      ],
    },
  };

  // ---------------- Модуль атаулары ----------------

  static String _moduleTitle(String subject, int grade, int module) {
    final titles = _moduleTitles[subject]?[grade];
    if (titles == null || module > titles.length) {
      return '$grade-сынып · $module-модуль';
    }
    return titles[module - 1];
  }

  /// Сол пән/сыныптағы модуль (тақырып) саны.
  static int _moduleCountFor(String subject, int grade) {
    final titles = _moduleTitles[subject]?[grade];
    if (titles != null) return titles.length;
    // Биология мен химия — тек 5–11 сыныпта (төменгі сыныпта мектеп
    // бағдарламасында жоқ, банкі де жоқ). 1–4-те node жасалмайды.
    if (subject == 'biology' ||
        subject == 'chemistry' ||
        subject == 'history') {
      return 0;
    }
    return modulesPerGrade;
  }

  static const Map<String, Map<int, List<String>>> _moduleTitles = {
    'math': {
      1: ['Сандар 1-10', 'Қосу мен азайту'],
      2: ['20-ға дейін санау', 'Ұзындық пен өлшем'],
      3: ['Көбейту кестесі', 'Бөлу амалы'],
      4: ['Көп таңбалы сандар', 'Геометрия негіздері'],
      // 5–11: 2 алгебра/арифметика тақырыбы + 1 геометрия (оқулыққа сай).
      5: [
        'Натурал сандар мен амалдар',
        'Жай бөлшектер',
        'Ондық бөлшектер мен пайыз',
        'Геометрия негіздері',
        'Өлшем бірліктері',
        'Мәтінді есептер'
      ],
      6: [
        'Ондық бөлшектермен амалдар',
        'Бүтін және рационал сандар',
        'Қатынас, пропорция, координата',
        'Пайыз бен пайыздық есептер',
        'Геометрия: аудан мен шеңбер',
        'Статистика мен диаграммалар'
      ],
      7: [
        'Алгебралық өрнектер мен дәреже',
        'Сызықтық теңдеулер мен көпмүшелер',
        'Геометрия: бұрыштар мен үшбұрыштар',
        'Теңдеулер жүйесі',
        'Сызықтық функциялар',
        'Статистика мен ықтималдық'
      ],
      8: [
        'Квадрат түбір мен нақты сандар',
        'Функциялар мен теңсіздіктер',
        'Геометрия: төртбұрыш, аудан, Пифагор',
        'Көпмүшелер мен көбейткіштерге жіктеу',
        'Квадрат теңдеулер',
        'Рационал өрнектер'
      ],
      9: [
        'Квадрат теңдеулер',
        'Прогрессиялар мен тригонометрия',
        'Геометрия: векторлар мен шеңбер',
        'Квадраттық функциялар',
        'Теңсіздіктер',
        'Ықтималдық пен комбинаторика'
      ],
      10: [
        'Тригонометрия',
        'Туынды және оның қолданысы',
        'Геометрия: стереометрия негіздері',
        'Дәреже мен түбірлер',
        'Логарифмдер',
        'Аналитикалық геометрия'
      ],
      11: [
        'Интеграл',
        'Логарифм, көрсеткіш, ықтималдық',
        'Геометрия: денелер мен көлемдер',
        'Туынды (толық)',
        'Функцияны зерттеу',
        'Тригонометриялық теңдеулер'
      ],
    },
    'kazakh': {
      1: ['Әліппе', 'Буын және сөз'],
      2: ['Дыбыстар әлемі', 'Сөйлем құрау'],
      3: ['Зат есім', 'Сын есім'],
      4: ['Етістік', 'Мәтін түрлері'],
      5: ['Сөз құрамы', 'Септік жалғаулары'],
      6: ['Сөз таптары', 'Мақал-мәтелдер'],
      7: ['Есімдік пен үстеу', 'Абай шығармашылығы'],
      8: ['Сөз тіркесі', 'Жай сөйлем'],
      9: ['Құрмалас сөйлем', 'Қазақ әдебиеті'],
      10: ['Стилистика', 'Көркем мәтін талдауы'],
      11: ['Тіл мәдениеті', 'Шешендік өнер'],
    },
    'english': {
      1: ['Alphabet & Sounds', 'Colors & Numbers'],
      2: ['My Family', 'Animals'],
      3: ['School Things', 'Food & Drinks'],
      4: ['My Day', 'Weather & Seasons'],
      5: ['Present Simple', 'My Hobbies'],
      6: ['Past Simple', 'Travelling'],
      7: ['Future Forms', 'Comparatives'],
      8: ['Present Perfect', 'Modal Verbs'],
      9: ['Passive Voice', 'Conditionals'],
      10: ['Reported Speech', 'Phrasal Verbs'],
      11: ['Advanced Grammar', 'Academic English'],
    },
    'physics': {
      1: ['Қоршаған әлем', 'Табиғат құбылыстары'],
      2: ['Су және ауа', 'Жарық пен көлеңке'],
      3: ['Магниттер', 'Дыбыс әлемі'],
      4: ['Күн жүйесі', 'Қозғалыс негіздері'],
      5: ['Заттар мен денелер', 'Өлшеулер'],
      6: ['Жылу құбылыстары', 'Энергия дегеніміз не'],
      7: ['Механикалық қозғалыс', 'Күш және масса'],
      8: ['Жылу физикасы', 'Электр негіздері'],
      9: ['Электромагнетизм', 'Тербелістер мен толқындар'],
      10: ['Молекулалық физика', 'Термодинамика'],
      11: ['Кванттық физика', 'Астрофизика'],
    },
    'cs': {
      1: ['Компьютермен танысу', 'Тінтуір мен пернетақта'],
      2: ['Графикалық редактор', 'Қауіпсіз интернет'],
      3: ['Мәтін теру', 'Презентация жасау'],
      4: ['Алгоритм дегеніміз не', 'Scratch негіздері'],
      5: ['Ақпарат әлемі', 'Файлдар мен папкалар',
          'Компьютер қауіпсіздігі', 'Мәтін редакторы'],
      6: ['Екілік жүйе', 'Компьютер құрылысы',
          'Интернет пен желілер', 'Компьютерлік графика'],
      7: ['Алгоритмдер', 'Scratch жобалары',
          'Электрондық кестелер', 'Ақпаратты өлшеу: бит пен байт'],
      8: ['Python негіздері', 'Шарт пен цикл',
          'Python: жолдар мен мәтін', 'Кибергигиена мен қауіпсіздік'],
      9: ['Python функциялары', 'Деректер құрылымы',
          'Іздеу мен сұрыптау алгоритмдері', 'Логикалық алгебра'],
      10: ['Веб-әзірлеу негіздері', 'Деректер қоры',
          'Желілер мен хаттамалар', 'Криптография негіздері'],
      11: ['Жасанды интеллект', 'Жобалық жұмыс',
          'Бұлттық технологиялар мен IT-мамандықтар',
          'Цифрлық этика мен қоғам'],
    },
    'biology': {
      5: ['Жасуша — тіршілік негізі', 'Тірі ағза мен орта'],
      6: ['Өсімдіктер дүниесі', 'Өсімдік мүшелері'],
      7: ['Жануарлар дүниесі', 'Мүшелер жүйесі'],
      8: ['Адам ағзасының жүйелері', 'Тыныс алу мен қан айналым'],
      9: ['Генетика негіздері', 'Популяция мен экожүйе'],
      10: ['Зат пен энергия алмасу', 'Жасуша бөлінуі'],
      11: ['Эволюция ілімі', 'Экология және биосфера'],
    },
    'chemistry': {
      5: ['Заттар және қасиеттері', 'Таза зат пен қоспа'],
      6: ['Физикалық және химиялық құбылыстар', 'Заттың құрылысы'],
      7: ['Атом мен молекула', 'Химиялық элементтер'],
      8: ['Периодтық жүйе', 'Химиялық байланыс'],
      9: ['Химиялық реакциялар', 'Қышқыл, негіз, тұз'],
      10: ['Органикалық химия негіздері', 'Көмірсутектер'],
      11: ['Металдар мен бейметалдар', 'Тотығу-тотықсыздану'],
    },
    'history': {
      5: ['Тас дәуірі', 'Қола дәуірі', 'Темір дәуірі',
          'Ежелгі өнер мен наным-сенім'],
      6: ['Сақтар мен ғұндар', 'Үйсін мен қаңлы', 'Сарматтар',
          'Ежелгі көшпелілер өркениеті'],
      7: ['Түркі қағанаты', 'Ортағасырлық қалалар', 'Қарахан мемлекеті',
          'Алтын Орда'],
      8: ['Қазақ хандығының құрылуы', 'Хандар мен билер',
          'Жыраулар мен күй өнері', 'Көшпелі өмір салты мен дәстүрлер'],
      9: ['Жоңғар шапқыншылығы', 'Отарлау мен көтерілістер',
          'Қазақ ағартушылары', 'ХХ ғасыр басы мен 1916 жылғы көтеріліс'],
      10: ['Кеңес дәуірі', 'Ұлы Отан соғысы мен Желтоқсан',
          'Индустрияландыру мен тың игеру', 'Байқоңыр мен ғылым'],
      11: ['Тәуелсіздік', 'Қазіргі Қазақстан',
          'Сыртқы саясат пен әлемдік қауымдастық',
          'Рухани жаңғыру мен мәдени мұра'],
    },
  };
}
