/// Сабақ мазмұны — баланы ТЕКСЕРМЕЙ, алдымен ҮЙРЕТУ үшін.
/// Әр модульдің (тақырыптың) теориясы: түсіндірме + формула + қадаммен
/// шешілген үлгі есептер (worked examples) + тірек қорытынды.
library;

/// Үлгі есептің бір шешу қадамы.
class ExampleStep {
  const ExampleStep(this.text);

  /// Қадам түсіндірмесі (мыс. «Бөлімдер бірдей — алымдарды қосамыз: 3 + 1 = 4»).
  final String text;
}

/// Қадаммен шешілген үлгі есеп.
class WorkedExample {
  const WorkedExample({
    required this.problem,
    required this.steps,
    required this.answer,
    this.choices = const [],
  });

  /// Есеп шарты (мыс. «¾ + ¼»).
  final String problem;

  /// Шешу қадамдары (бір-бірлеп ашылады).
  final List<ExampleStep> steps;

  /// Соңғы жауап (мыс. «1»).
  final String answer;

  /// Интерактив «болжам» нұсқалары (дұрысын қоса). Бос болмаса — бала алдымен
  /// жауапты болжайды, сосын қадамдық шешім ашылады (белсенді еске түсіру).
  final List<String> choices;
}

/// Сабақтың тұжырымдамалық визуалы — ұғымды СУРЕТПЕН бірден түсіндіреді
/// (мәтіннен бұрын көзге түседі). Бос болса — көрсетілмейді (graceful).
sealed class LessonVisual {
  const LessonVisual();
}

/// Бөлшек/пайыз көрнекісі: [parts] тең бөлікке бөлінген жолақ, алғашқы [shaded]
/// бөлігі боялған (мыс. ¾ → parts 4, shaded 3; 0,5 → parts 10, shaded 5).
class FractionBar extends LessonVisual {
  const FractionBar({required this.parts, required this.shaded, this.caption});

  final int parts;
  final int shaded;
  final String? caption;
}

/// Сан осі: [min]..[max] аралығы белгілермен; [points] — ерекшеленетін мәндер
/// (мыс. теріс сандар, координата). Аралық шағын болғаны жөн (≤ 12 белгі).
class NumberLineVisual extends LessonVisual {
  const NumberLineVisual({
    required this.min,
    required this.max,
    this.step = 1,
    this.points = const [],
    this.caption,
  });

  final int min;
  final int max;

  /// Белгі қою қадамы (үлкен аралықта әр [step] сайын: 0,20,40,…).
  final int step;
  final List<int> points;
  final String? caption;
}

/// Тікбұрышты үшбұрыш (Пифагор / геометрия): [aLabel], [bLabel] — катеттер,
/// [cLabel] — гипотенуза. Тік бұрыш белгіленеді. Белгілер «a»/«3» боп келе береді.
class RightTriangleVisual extends LessonVisual {
  const RightTriangleVisual({
    required this.aLabel,
    required this.bLabel,
    required this.cLabel,
    this.caption,
  });

  final String aLabel;
  final String bLabel;
  final String cLabel;
  final String? caption;
}

/// Баған диаграммасы (статистика): [bars] — (белгі, мән) жұптары. [markValue]
/// берілсе — сол деңгейде пунктир сызық (мыс. орташа мән) + [markLabel] белгісі.
class BarChartVisual extends LessonVisual {
  const BarChartVisual({
    required this.bars,
    this.markValue,
    this.markLabel,
    this.caption,
  });

  final List<(String, double)> bars;
  final double? markValue;
  final String? markLabel;
  final String? caption;
}

/// Процесс/реакция тізбегі: [steps] — қораптар, солдан оңға көрсеткішпен
/// жалғасады (мыс. фотосинтез: «CO₂ + H₂O» → «жарық» → «глюкоза + O₂»;
/// қоректік тізбек: «өсімдік» → «қоян» → «бөрі»). Биология/химия/физика
/// үдерістерін СУРЕТПЕН түсіндіреді. [highlightLast] — соңғы қорап (нәтиже)
/// акцент түсімен ерекшеленеді.
class ProcessFlowVisual extends LessonVisual {
  const ProcessFlowVisual({
    required this.steps,
    this.highlightLast = true,
    this.caption,
  });

  final List<String> steps;
  final bool highlightLast;
  final String? caption;
}

/// Белгіленген бөліктер тізімі: [parts] — (атау, рөлі) жұптары, әрқайсысы
/// түрлі-түсті нүктемен көрсетіледі (мыс. жасуша: «ядро» — «ДНҚ сақтау»;
/// атом: «протон» — «оң заряд»). Құрылымды бөлшектеп түсіндіреді.
class LabeledPartsVisual extends LessonVisual {
  const LabeledPartsVisual({required this.parts, this.title, this.caption});

  final List<(String, String)> parts;
  final String? title;
  final String? caption;
}

/// Бір модульдің (тақырыптың) сабағы.
class Lesson {
  const Lesson({
    required this.title,
    this.hook,
    required this.intro,
    this.explainSteps = const [],
    this.formula,
    this.whyFormula,
    this.visual,
    this.examples = const [],
    this.commonMistake,
    required this.takeaway,
  });

  /// Тақырып атауы.
  final String title;

  /// Өмірден кіріспе — ұстаз сабақты таныс жағдаяттан бастайды (мыс. «Нанды
  /// 4 доспен тең бөлдің — әрқайсысына қанша тиеді?»). Серік айтып береді.
  final String? hook;

  /// Негізгі идея — тақырыптың мәні БІР ауыз сөзбен (қарапайым тілмен).
  final String intro;

  /// Ұғымды қадам-қадаммен құру: әр элемент — бір шағын ой (1–2 сөйлем).
  /// Мықты ұстаз тақтаға бір ойдан жазғандай, бала бірінен соң бірін оқиды.
  final List<String> explainSteps;

  /// Негізгі ереже / формула (ерекшеленіп көрсетіледі).
  final String? formula;

  /// «Неге солай?» — формуланың СЕБЕБІ (жаттанды емес, түсініп есте сақтау).
  final String? whyFormula;

  /// Тұжырымдамалық визуал (бөлшек жолағы / сан осі) — болса, суретпен түсіндіру.
  final LessonVisual? visual;

  /// Қадаммен шешілген үлгі есептер.
  final List<WorkedExample> examples;

  /// «Жиі қателік» — оқушылар жиі жіберетін қате (ескерту картасы).
  final String? commonMistake;

  /// Тірек қорытынды (есте сақтайтын негізгі ой).
  final String takeaway;
}
