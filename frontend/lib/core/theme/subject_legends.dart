/// Әр пәннің оқу картасының фонында сол пәнге қатысты **ұлы тұлғалар**
/// (duotone портреттер, нәзік сейіп тұрады) мен **формула/символдар** қалқиды.
///
/// Тұлғалар суреттері — қоғамдық игіліктегі (Wikimedia Commons) портреттер,
/// `assets/legends/<subject>/<slug>.webp` ретінде пәннің реңкінде бірыңғай
/// duotone стиліне келтірілген (төменгі жиегі мөлдірлене сейіледі — «тұрған»
/// әсері). Дереккөз: tool/scripts арқылы жүктеліп өңделген.
library;

/// Бір пәннің «даналар галереясы»: портрет ассеттері + қалқыған символдар.
class LegendSet {
  const LegendSet({required this.figures, required this.glyphs});

  /// Портрет ассеттерінің жолдары (duotone webp).
  final List<String> figures;

  /// Фонда қалқитын формула / символ / әріп жолдары.
  final List<String> glyphs;
}

const String _base = 'assets/legends';

/// Пән id → даналар жинағы.
const Map<String, LegendSet> _sets = {
  'math': LegendSet(
    figures: [
      '$_base/math/pythagoras.webp',
      '$_base/math/al_khwarizmi.webp',
      '$_base/math/euler.webp',
      '$_base/math/gauss.webp',
      '$_base/math/newton.webp',
    ],
    glyphs: [
      'a² + b² = c²',
      'E = mc²',
      'πr²',
      '∫ f(x)dx',
      'x = (−b ± √(b²−4ac)) / 2a',
      'φ = (1+√5)/2',
      'sin²θ + cos²θ = 1',
      '∑',
      '√2',
      '∞',
    ],
  ),
  'physics': LegendSet(
    figures: [
      '$_base/physics/einstein.webp',
      '$_base/physics/newton.webp',
      '$_base/physics/tesla.webp',
      '$_base/physics/curie.webp',
      '$_base/physics/bohr.webp',
    ],
    glyphs: [
      'E = mc²',
      'F = ma',
      'E = hf',
      'F = G·m₁m₂ / r²',
      'pV = nRT',
      'λ = h / p',
      'v = v₀ + at',
      '½ m v²',
      'c = 3·10⁸ м/с',
    ],
  ),
  'kazakh': LegendSet(
    figures: [
      '$_base/kazakh/abai.webp',
      '$_base/kazakh/al_farabi.webp',
      '$_base/kazakh/baitursynov.webp',
      '$_base/kazakh/altynsarin.webp',
      '$_base/kazakh/walikhanov.webp',
    ],
    glyphs: [
      'Ә',
      'Ң',
      'Ғ',
      'Ү',
      'Ұ',
      'Қ',
      'Ө',
      'І',
      '«Білім — таусылмас қазына»',
      'әліппе',
      'сөз өнері',
    ],
  ),
  'english': LegendSet(
    figures: [
      '$_base/english/shakespeare.webp',
      '$_base/english/dickens.webp',
      '$_base/english/twain.webp',
      '$_base/english/austen.webp',
      '$_base/english/wilde.webp',
    ],
    glyphs: [
      'To be, or not to be',
      'A B C',
      'Knowledge is power',
      'Once upon a time',
      'Aa  Bb  Cc',
      'Noun · Verb',
      '“ … ”',
      'grammar',
    ],
  ),
  'cs': LegendSet(
    figures: [
      '$_base/cs/turing.webp',
      '$_base/cs/lovelace.webp',
      '$_base/cs/babbage.webp',
      '$_base/cs/von_neumann.webp',
      '$_base/cs/hopper.webp',
    ],
    glyphs: [
      '0 1',
      '{ }',
      '</>',
      'if (x) { … }',
      'for (i = 0; i < n; i++)',
      '01000001',
      '#include',
      '=>',
      '&& ||',
      'print()',
    ],
  ),
  // Биология: тіршілік символдары мен формулалары (портретсіз — glyphs қалқиды).
  'biology': LegendSet(
    figures: [],
    glyphs: [
      'DNA',
      'H₂O',
      'CO₂ + H₂O → O₂',
      'C₆H₁₂O₆',
      'ATP',
      '♀ ♂',
      'жасуша',
      '☘',
      'O₂',
      'ген',
    ],
  ),
  // Химия: элементтер, формулалар мен реакция таңбалары.
  'chemistry': LegendSet(
    figures: [],
    glyphs: [
      'H₂O',
      'NaCl',
      'CO₂',
      'H⁺  OH⁻',
      'CH₄',
      'pH',
      'Fe',
      '⚗',
      'O₂',
      '2H₂ + O₂ → 2H₂O',
    ],
  ),
  // Қазақстан тарихы: маңызды даталар, тұлғалар мен ұғымдар.
  'history': LegendSet(
    figures: [],
    glyphs: [
      '1465',
      '1723',
      '1991',
      '552',
      'Абылай хан',
      'Керей — Жәнібек',
      '«Жеті Жарғы»',
      'Алтын адам',
      'Тұмар',
      'Тәуелсіздік',
    ],
  ),
};

/// Пән id бойынша даналар жинағын береді (белгісіз болса — математика).
LegendSet legendsFor(String subjectId) => _sets[subjectId] ?? _sets['math']!;
