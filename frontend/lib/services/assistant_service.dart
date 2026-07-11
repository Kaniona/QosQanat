import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../data/lessons/math_lessons.dart';
import '../models/chat_message.dart';
import '../models/enums.dart';
import 'ml_service.dart';

/// Серіктің (Бектұр/Назым) жауабын дайындайтын сервис.
///
/// Backend ([AppConfig.apiBaseUrl]) берілсе — `POST /api/chat` арқылы Claude-қа
/// (бэкенд proxy) сұрау жібереді. API кілті ЕШҚАШАН қосымшада тұрмайды — тек
/// серверде. Желі болмаса немесе сұрау сәтсіз болса, қосымша автоматты түрде
/// құрылғыдағы кілт сөзге негізделген персона-логикаға ауысады (offline-first).
///
/// Сұхбат тарихын backend [studentId] бойынша өзі сақтайды, сондықтан клиент
/// әр сұрауда тек соңғы хабарламаны жібереді.
class AssistantService {
  AssistantService({http.Client? client, String? baseUrl, MlService? ml})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _ml = ml ?? MlService(client: client);

  final http.Client _client;
  final String _baseUrl;

  /// ML RAG ұстазы (онлайн күшейту; жоқ болса офлайн логика).
  final MlService _ml;

  static final _rng = Random();

  bool get _hasBackend => _baseUrl.isNotEmpty;

  /// Серіктің есімі.
  String name(AssistantType a) => a == AssistantType.nazym ? 'Назым' : 'Бектұр';

  /// Оқушының сұрағына жауап қайтарады.
  ///
  /// Backend қолжетімді болса — содан, болмаса (немесе қате болса) офлайн
  /// логикадан жауап береді. [history] backend-те сервер жағында сақталады.
  Future<String> reply({
    required AssistantType assistant,
    required String studentId,
    required String studentName,
    required int grade,
    required List<ChatMessage> history,
    required String prompt,
    String subject = 'Жалпы',
    String? weakTopic,
    int dueCount = 0,
  }) async {
    final clean = prompt.trim();

    // 1) Claude proxy backend (ең қуатты, деплойланса).
    if (_hasBackend) {
      try {
        return await _remoteReply(
          assistant: assistant,
          studentId: studentId,
          grade: grade,
          subject: subject,
          prompt: clean,
        );
      } catch (_) {
        // Желі/сервер қатесі — келесі қабатқа ауысамыз (offline-first).
      }
    }

    // 2) ML RAG ұстазы (оқу бағдарламасына негізделген, семантикалық іздеу).
    if (_ml.available) {
      final mlAnswer = await _ml.askTutor(clean, grade: grade.clamp(1, 11));
      if (mlAnswer != null) return mlAnswer;
    }

    // 3) Офлайн логика — «ойлану» сезімін имитациялау.
    await Future<void>.delayed(
      Duration(milliseconds: 500 + _rng.nextInt(700)),
    );
    return _offlineReply(
      assistant: assistant,
      name: studentName,
      grade: grade,
      prompt: clean,
      weakTopic: weakTopic,
      dueCount: dueCount,
    );
  }

  // ---- Backend (Claude proxy) ----

  Future<String> _remoteReply({
    required AssistantType assistant,
    required String studentId,
    required int grade,
    required String subject,
    required String prompt,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat');
    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'student_id': studentId.isEmpty ? 'anonymous' : studentId,
            // Backend 5–11 сыныпты ғана қабылдайды.
            'grade': grade.clamp(5, 11),
            'subject': subject,
            'message': prompt,
            'assistant_type': assistant.name,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('chat failed: ${res.statusCode}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final reply = (data['reply'] as String?)?.trim();
    if (reply == null || reply.isEmpty) {
      throw const FormatException('empty reply');
    }
    return reply;
  }

  /// Сервисті жабу (http клиентін босату).
  void dispose() {
    _client.close();
    _ml.dispose();
  }

  // ---- Офлайн персона-логика ----

  String _offlineReply({
    required AssistantType assistant,
    required String name,
    required int grade,
    required String prompt,
    String? weakTopic,
    int dueCount = 0,
  }) {
    final p = prompt.toLowerCase();
    final isNazym = assistant == AssistantType.nazym;

    bool has(List<String> keys) => keys.any(p.contains);

    // Жеке коуч: «маған не қиын / нені қайталайын / көмектес» — нақты әлсіз
    // тұсты атап, қайталауды ұсынады (mastery деректі офлайн оқиды).
    if (has([
      'не қиын',
      'қиынырақ',
      'нені қайтала',
      'нені оқи',
      'неден баста',
      'әлсіз',
      'кеңес бер',
      'неге көмектес',
      'маған көмектес',
    ])) {
      if (weakTopic != null && weakTopic.isNotEmpty) {
        final review = dueCount > 0
            ? '$dueCount сұрақ қайталауға дайын — басты беттегі «Қайталау» түймесін бас 🔁'
            : 'Картадан осы тақырыпты тағы бір жаттық.';
        return isNazym
            ? 'Байқағаным, «$weakTopic» сәл қиынырақ тиіп жүр, $name 🌸 '
                'Кел, осыны бекітейік. $review'
            : 'Дерегіңе қарасам, «$weakTopic» — қазір ең әлсіз тұсың, $name! 💪 '
                'Соны бағындырайық. $review';
      }
      return isNazym
          ? 'Әзірге әлсіз тұсыңды көрсететін дерек аз 🌸 Бірер тапсырма жаса, '
              'сосын саған нақты не қиынын айтып, қайталауды ұсынамын.'
          : 'Алдымен бірнеше тапсырма жасайық, $name! 🔥 Сосын әлсіз тұсыңды '
              'дәл тауып, бірге бекітеміз.';
    }

    // Тақырыптық сұрақ — 98 сабақтың сәйкесінен НАҚТЫ түсіндіреміз (офлайн
    // «ұстаз»: тексерілген теорияны қайтарады).
    final lesson = findLessonByTopic(prompt);
    if (lesson != null) {
      final f = lesson.formula != null ? '\n\n📐 ${lesson.formula}' : '';
      final lead = isNazym
          ? 'Жақсы сұрақ, $name 🌸'
          : 'О, қызық тақырып, $name! 🔥';
      return '$lead «${lesson.title}» туралы қысқаша:\n\n${lesson.intro}$f\n\n'
          'Толығырақ әрі жаттығу — Оқу картасынан осы тақырыпты ашсаң болады 📚';
    }

    // Сәлемдесу (тек нақты сәлемдесу сөздері — «қалай» жалғыз тұрса басқа
    // сұрақты ұрламауы үшін алынды).
    if (has(['сәлем', 'салам', 'привет', 'қалайсың', 'сәлеметсің'])) {
      final hint = weakTopic != null && weakTopic.isNotEmpty
          ? ' Бүгін «$weakTopic» тақырыбын бекітсек қалай?'
          : '';
      return isNazym
          ? 'Сәлем, $name 🌸 Көңіл-күйің қалай?$hint'
          : 'Сәлем, $name! 🔥 Дайынсың ба?$hint Кәне, бір тақырыпты бағындырайық!';
    }

    // Алғыс.
    if (has(['рахмет', 'рақмет', 'спасибо', 'thanks'])) {
      return isNazym
          ? 'Әрқашан көмектесуге дайынмын ✨ Жақсы оқып жүр!'
          : 'Оқасы жоқ! 💪 Алға, тоқтамаймыз!';
    }

    // Жігерлендіру / көңіл-күй.
    if (has(['жігер', 'мотив', 'шарша', 'қиын', 'болмай', 'көңіл', 'қорқам'])) {
      return isNazym
          ? 'Сабырлы бол, $name 🌸 Әр кішкене қадам — үлкен жетістікке апарады. '
              'Бүгін бір ғана тапсырма жаса, қалғаны өзі жалғасады.'
          : 'Қане, басыңды көтер, $name! 🔥 Чемпиондар да құлап, қайта тұрады. '
              'Бір тапсырма — бір жеңіс. Бастайық!';
    }

    // Қосымшаны қалай қолдану (нақты «қалай қолдану» тіркесі — жалғыз «қалай»
    // алынды, ол тақырыптық сұрақтарда жиі кездеседі).
    if (has(['қалай қолдан', 'қалай ойна', 'қалай жұмыс', 'батл', 'дүкен',
        'монета', 'қосымша қалай'])) {
      return 'Оқу картасынан тапсырмаларды орында → XP пен монета жина → '
          'Дүкеннен сыйлық ал, достарыңмен батлда жарыс. '
          'Қай бөлімді көрсетейін?';
    }

    // Математика.
    if (has(['матем', 'есеп', 'санда', 'теңдеу', 'бөлшек', 'формула'])) {
      return isNazym
          ? 'Жақсы сұрақ 🌸 Алдымен есептің берілгенін айтшы: нені тауып жатырмыз? '
              'Бірге қадам-қадаммен шешейік.'
          : 'Математика — менің сүйікті алаңым! 💪 Есепті жаз, бірге шешеміз. '
              'Алдымен: не белгілі, не белгісіз?';
    }

    // Қазақ тілі / әдебиет.
    if (has(['қазақ тіл', 'грамматик', 'емле', 'сөйлем', 'жазыл', 'әдебиет'])) {
      return 'Қазақ тілі — байлығымыз 🇰🇿 Қай ережеге тоқталайық: '
          'септік, жалғау, әлде емле ме? Мысал жазсаң, бірге талдаймыз.';
    }

    // Ағылшын тілі.
    if (has(['ағылш', 'english', 'ingliz', 'грамматика англ'])) {
      return isNazym
          ? 'English is fun ✨ Қай тақырып: tenses, words, әлде сөйлеу ме? '
              'Кішкене мысалмен бастайық.'
          : "Let's go! 🔥 Ағылшыннан қай жерде тұрып қалдың? Бірге жаттығайық.";
    }

    // Физика.
    if (has(['физик', 'күш', 'жылдамдық', 'энергия', 'қозғал'])) {
      return 'Физика — табиғаттың тілі ⚡ Қай тақырып: механика, жылу, әлде ток па? '
          'Құбылысты сипаттап берсең, формуласын бірге табамыз.';
    }

    // Информатика.
    if (has(['информат', 'код', 'программа', 'компьютер', 'алгоритм'])) {
      return isNazym
          ? 'Информатика қызық 💻 Алгоритмді қадамдарға бөліп жазып көрейік. '
              'Не істегің келеді?'
          : 'Кодтайық! 💪 Алгоритм деген — қадамдар тізбегі. Мақсатыңды айт, '
              'бірге құрастырамыз.';
    }

    // Сәйкес сабақ та, кілт сөз де табылмады. ОЙДАН ЖАУАП ШЫҒАРМАЙМЫЗ — адал
    // боламыз: офлайн режимде тек оқу бағдарламасы тақырыптарын түсіндіре аламыз,
    // ал толық AI интернет қосулы кезде істейді.
    return isNazym
        ? 'Кешір, $name 🌸 Бұл сұраққа офлайн режимде дәл жауап бере алмаймын — '
            'ойдан шығарғым келмейді. Оқу бағдарламасындағы тақырыпты сұрасаң '
            '(мыс. «бөлшек дегеніміз не?») — нақты түсіндіремін. Толық AI үшін '
            'интернетке қосыл 🌐'
        : 'Шынымды айтсам, $name — бұл сұраққа офлайн режимде нақты жауабым жоқ, '
            'ал ойдан айтқым келмейді. Оқу тақырыбын сұра (мыс. «теңдеу қалай '
            'шешіледі?») — бірден түсіндіремін. Толық жауап үшін интернет керек 🌐';
  }
}
