import 'dart:math';

import '../../models/enums.dart';
import '../../models/task_node.dart';

/// Ағылшын тілі сұрақ генераторы — ТЕКСЕРІЛГЕН етістік/сын есім тізімдерінен
/// (барлық форма қолмен тексерілген → қате жоқ). Қиындық деңгейі грамматика
/// түрін анықтайды; әр шақыруда жаңа, қайталанбайтын сұрақ.
///
/// light  — Present Simple (3-жақ -s)
/// easy   — Past Simple (бұрыс етістіктер)
/// medium — Present Continuous (is/are + V-ing)
/// hard   — Comparatives (-er / more)
/// complex/brainTeaser — Present Perfect (have/has + V3)

/// (base, 3rd person, past, past participle, -ing) — БАРЛЫҒЫ тексерілген.
const List<(String, String, String, String, String)> _verbs = [
  ('go', 'goes', 'went', 'gone', 'going'),
  ('eat', 'eats', 'ate', 'eaten', 'eating'),
  ('see', 'sees', 'saw', 'seen', 'seeing'),
  ('write', 'writes', 'wrote', 'written', 'writing'),
  ('take', 'takes', 'took', 'taken', 'taking'),
  ('give', 'gives', 'gave', 'given', 'giving'),
  ('speak', 'speaks', 'spoke', 'spoken', 'speaking'),
  ('drink', 'drinks', 'drank', 'drunk', 'drinking'),
  ('swim', 'swims', 'swam', 'swum', 'swimming'),
  ('sing', 'sings', 'sang', 'sung', 'singing'),
  ('drive', 'drives', 'drove', 'driven', 'driving'),
  ('break', 'breaks', 'broke', 'broken', 'breaking'),
  ('choose', 'chooses', 'chose', 'chosen', 'choosing'),
  ('wear', 'wears', 'wore', 'worn', 'wearing'),
  ('buy', 'buys', 'bought', 'bought', 'buying'),
  ('find', 'finds', 'found', 'found', 'finding'),
  ('make', 'makes', 'made', 'made', 'making'),
  ('do', 'does', 'did', 'done', 'doing'),
  ('teach', 'teaches', 'taught', 'taught', 'teaching'),
  ('sleep', 'sleeps', 'slept', 'slept', 'sleeping'),
  ('think', 'thinks', 'thought', 'thought', 'thinking'),
  ('bring', 'brings', 'brought', 'brought', 'bringing'),
  ('catch', 'catches', 'caught', 'caught', 'catching'),
  ('fall', 'falls', 'fell', 'fallen', 'falling'),
  ('feel', 'feels', 'felt', 'felt', 'feeling'),
  ('grow', 'grows', 'grew', 'grown', 'growing'),
  ('know', 'knows', 'knew', 'known', 'knowing'),
  ('leave', 'leaves', 'left', 'left', 'leaving'),
  ('meet', 'meets', 'met', 'met', 'meeting'),
  ('pay', 'pays', 'paid', 'paid', 'paying'),
  ('ride', 'rides', 'rode', 'ridden', 'riding'),
  ('send', 'sends', 'sent', 'sent', 'sending'),
  ('sit', 'sits', 'sat', 'sat', 'sitting'),
  ('stand', 'stands', 'stood', 'stood', 'standing'),
  ('win', 'wins', 'won', 'won', 'winning'),
  ('begin', 'begins', 'began', 'begun', 'beginning'),
  ('fly', 'flies', 'flew', 'flown', 'flying'),
  ('forget', 'forgets', 'forgot', 'forgotten', 'forgetting'),
  ('run', 'runs', 'ran', 'run', 'running'),
  ('come', 'comes', 'came', 'come', 'coming'),
];

/// (base, comparative, superlative) — тексерілген.
const List<(String, String, String)> _adjectives = [
  ('big', 'bigger', 'biggest'),
  ('small', 'smaller', 'smallest'),
  ('tall', 'taller', 'tallest'),
  ('fast', 'faster', 'fastest'),
  ('happy', 'happier', 'happiest'),
  ('easy', 'easier', 'easiest'),
  ('hot', 'hotter', 'hottest'),
  ('cold', 'colder', 'coldest'),
  ('strong', 'stronger', 'strongest'),
  ('young', 'younger', 'youngest'),
  ('long', 'longer', 'longest'),
  ('short', 'shorter', 'shortest'),
  ('old', 'older', 'oldest'),
  ('new', 'newer', 'newest'),
  ('clean', 'cleaner', 'cleanest'),
  ('cheap', 'cheaper', 'cheapest'),
  ('rich', 'richer', 'richest'),
  ('warm', 'warmer', 'warmest'),
  ('slow', 'slower', 'slowest'),
  ('heavy', 'heavier', 'heaviest'),
  ('busy', 'busier', 'busiest'),
  ('dark', 'darker', 'darkest'),
  ('deep', 'deeper', 'deepest'),
  ('weak', 'weaker', 'weakest'),
];

Question englishGenQuestion(
    String id, int grade, Random r, Difficulty difficulty) {
  switch (difficulty) {
    case Difficulty.light:
      final v = _verbs[r.nextInt(_verbs.length)];
      return _build(
        id,
        'He ___ every day. («${v.$1}»)',
        '3-жақ жекеше (he/she/it) → етістікке -s',
        v.$2,
        [v.$1, v.$5, v.$3],
        difficulty,
        r,
      );
    case Difficulty.easy:
      final v = _verbs[r.nextInt(_verbs.length)];
      return _build(
        id,
        'Yesterday she ___ . («${v.$1}»)',
        'Past Simple — бұрыс етістіктің 2-формасы',
        v.$3,
        ['${v.$1}ed', v.$1, v.$4, v.$5],
        difficulty,
        r,
      );
    case Difficulty.medium:
      final v = _verbs[r.nextInt(_verbs.length)];
      return _build(
        id,
        'Look! They ___ now. («${v.$1}»)',
        'Present Continuous — are + V-ing',
        'are ${v.$5}',
        ['are ${v.$2}', 'is ${v.$5}', 'are ${v.$3}'],
        difficulty,
        r,
      );
    case Difficulty.hard:
      final a = _adjectives[r.nextInt(_adjectives.length)];
      return _build(
        id,
        'An elephant is ___ than a cat. («${a.$1}»)',
        'Қысқа сын есім → -er than',
        a.$2,
        ['more ${a.$1}', a.$3, a.$1],
        difficulty,
        r,
      );
    case Difficulty.complex:
      final v = _verbs[r.nextInt(_verbs.length)];
      return _build(
        id,
        'She has ___ it already. («${v.$1}»)',
        'Present Perfect — has + V3 (3-форма)',
        v.$4,
        [v.$3, v.$5, v.$2, v.$1],
        difficulty,
        r,
      );
    case Difficulty.brainTeaser:
      final v = _verbs[r.nextInt(_verbs.length)];
      return _build(
        id,
        'They have just ___ . («${v.$1}»)',
        'have + V3 (өткен шақ есімшесі)',
        v.$4,
        [v.$3, v.$1, v.$5, v.$2],
        difficulty,
        r,
      );
  }
}

Question _build(String id, String text, String hint, String correct,
    List<String> wrongs, Difficulty d, Random r) {
  final opts = <String>[correct];
  for (final w in wrongs) {
    if (opts.length >= 4) break;
    if (!opts.contains(w)) opts.add(w);
  }
  const fillers = ['none', 'both', 'will'];
  var fi = 0;
  while (opts.length < 4) {
    final f = fillers[fi % fillers.length];
    fi++;
    if (!opts.contains(f)) opts.add(f);
  }
  opts.shuffle(r);
  return Question(
    id: id,
    text: text,
    options: opts,
    correctIndex: opts.indexOf(correct),
    hint: hint,
    difficulty: d,
  );
}
