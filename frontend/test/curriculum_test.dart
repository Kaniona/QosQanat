import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/data/banks/kazakh_bank.dart';
import 'package:qosqanat/data/banks/math_bank.dart';
import 'package:qosqanat/data/banks/math_bank_advanced.dart';
import 'package:qosqanat/data/banks/math_bank_advanced2.dart';
import 'package:qosqanat/data/banks/math_bank_extra.dart';
import 'package:qosqanat/data/banks/math_bank_hard.dart';
import 'package:qosqanat/data/banks/math_bank_redbook.dart';
import 'package:qosqanat/data/curriculum.dart';
import 'package:qosqanat/models/enums.dart';

void main() {
  const subjects = ['math', 'kazakh', 'english', 'physics', 'cs', 'biology', 'chemistry', 'history'];

  // Модуль (тақырып) саны пән/сыныпқа қарай әртүрлі: математикада толық
  // таксономия (сыныбына қарай 3–7 тақырып), қалғанда [modulesPerGrade].
  // Нақты санды Curriculum.moduleCount-тан аламыз — таксономия өссе де тест
  // тұрақты.
  int expectedModules(String subject, int grade) =>
      Curriculum.moduleCount(subject, grade);

  group('Сыныптық оқшаулау', () {
    test('nodesForGrade ТЕК сұралған сыныптың node-тарын қайтарады', () {
      for (final subject in subjects) {
        for (final grade in [1, 5, 8, 11]) {
          final nodes = Curriculum.nodesForGrade(subject, grade);
          expect(
              nodes.length,
              expectedModules(subject, grade) *
                  Curriculum.nodesPerModuleFor(subject, grade));
          for (final node in nodes) {
            expect(node.grade, grade,
                reason: '$subject картасына бөтен сынып кірді');
          }
        }
      }
    });

    test('nodesUpToGrade 1-ден өз сыныбына дейін қайтарады, жоғарысы жоқ', () {
      final nodes = Curriculum.nodesUpToGrade('math', 5);
      final grades = nodes.map((n) => n.grade).toSet();
      expect(grades, {1, 2, 3, 4, 5});
      expect(
          nodes.length,
          [1, 2, 3, 4, 5].fold<int>(
              0,
              (sum, g) =>
                  sum +
                  expectedModules('math', g) *
                      Curriculum.nodesPerModuleFor('math', g)));
      // Реті: сынып өспелі.
      var last = 0;
      for (final n in nodes) {
        expect(n.grade, greaterThanOrEqualTo(last));
        last = n.grade;
      }
      // 11-сынып оқушысына барлық 11 сынып ашық.
      expect(
          Curriculum.nodesUpToGrade('kazakh', 11).map((n) => n.grade).toSet(),
          {for (var g = 1; g <= 11; g++) g});
    });

    test('nodeById сынып бөлігін id-ден дұрыс оқиды', () {
      final node = Curriculum.nodeById('math_g8_m1_n1');
      expect(node, isNotNull);
      expect(node!.grade, 8);
      expect(node.module, 1);
      expect(Curriculum.nodeById('math_g99_m1_n0'), isNull);
      expect(Curriculum.nodeById('bogus'), isNull);
    });
  });

  group('Сұрақ пулы', () {
    test('пул деңгейлерге дұрыс бөлінген (математика — тақырыптық, өзгелер — 6 тиер)',
        () {
      for (final subject in subjects) {
        for (final grade in [2, 6, 9]) {
          for (final node in Curriculum.nodesForGrade(subject, grade)) {
            int count(Difficulty d) =>
                node.questions.where((q) => q.difficulty == d).length;
            final banked =
                subject == 'math' && Curriculum.hasTopicBank(grade, node.module);
            if (banked) {
              // Тақырыптық disjoint тілім: бос емес; `light` (генератордың ең
              // жеңіл тиері) болмайды, бірақ банкте hard/Күрделі/Басқатырғыш бар.
              expect(node.questions, isNotEmpty, reason: node.id);
              expect(count(Difficulty.light), 0, reason: node.id);
            } else {
              // Генератор пулы: 56 сұрақ, 6 деңгей.
              final expected = subject == 'math'
                  ? const [10, 7, 9, 9, 12, 9]
                  : const [14, 8, 8, 7, 11, 8];
              expect(node.questions.length, Curriculum.questionPoolSize,
                  reason: node.id);
              expect(count(Difficulty.light), expected[0], reason: node.id);
              expect(count(Difficulty.easy), expected[1], reason: node.id);
              expect(count(Difficulty.medium), expected[2], reason: node.id);
              expect(count(Difficulty.hard), expected[3], reason: node.id);
              expect(count(Difficulty.complex), expected[4], reason: node.id);
              expect(
                  count(Difficulty.brainTeaser), expected[5], reason: node.id);
            }
          }
        }
      }
    });

    test('пулда форматтар бар (математика тақырыптық: сәйкестендірусіз)', () {
      for (final subject in subjects) {
        final node = Curriculum.nodesForGrade(subject, 8).first;
        final types = node.questions.map((q) => q.type).toSet();
        if (subject == 'math') {
          // Тақырып тазалығы үшін математикада жалпы (тақырыптан тыс)
          // сәйкестендіру қолданылмайды.
          expect(types.contains(QuestionType.matchPairs), isFalse,
              reason: 'математикада тақырыптан тыс сәйкестендіру болмауы тиіс');
        } else {
          expect(types.contains(QuestionType.matchPairs), isTrue,
              reason: '$subject: сәйкестендіру жоқ');
          expect(types.contains(QuestionType.trueFalse), isTrue,
              reason: '$subject: дұрыс/бұрыс жоқ');
        }
      }
    });

    test('математика: әр node ТЕК өз тақырыбының сұрақтарынан тұрады (араласу жоқ)',
        () {
      for (final grade in [5, 6, 7, 8, 9, 10, 11]) {
        for (final node in Curriculum.nodesForGrade('math', grade)) {
          // Осы модульдің рұқсат етілген мәтіндері (3 дереккөз қоса).
          final allowed = <String>{
            ...?mathBankByTopic[grade]?[node.module]?.map((q) => q.$1),
            ...?mathBankAdvanced[grade]?[node.module]?.map((q) => q.$1),
            ...?mathBankAdvanced2[grade]?[node.module]?.map((q) => q.$1),
            ...?mathBankHard[grade]?[node.module]?.map((q) => q.$1),
            ...?mathBankRedbook[grade]?[node.module]?.map((q) => q.$1),
            ...?mathBankExtra[grade]?[node.module]?.map((q) => q.$1),
          };
          if (allowed.isEmpty) continue; // банкі жоқ модуль (5–11-де болмауы тиіс)
          for (final q in node.questions) {
            expect(allowed.contains(q.text), isTrue,
                reason: '${node.id}: «${q.text}» осы тақырыпқа жатпайды');
          }
        }
      }
    });

    test('математика: бір модульдің деңгейлерінде сұрақ ҚАЙТАЛАНБАЙДЫ (disjoint)',
        () {
      for (final grade in [5, 6, 7, 8, 9, 10, 11]) {
        final nodes = Curriculum.nodesForGrade('math', grade);
        for (final module in nodes.map((n) => n.module).toSet()) {
          final seen = <String>{};
          for (final node in nodes.where((n) => n.module == module)) {
            for (final q in node.questions) {
              // seen.add → false болса, бұл мәтін басқа деңгейде кездескен.
              expect(seen.add(q.text), isTrue,
                  reason:
                      'g$grade m$module: «${q.text}» бірнеше деңгейде қайталанды');
            }
          }
        }
      }
    });

    test('математика: әр node-та сұрақ бар (тақырыптық тілім, кемінде 4)', () {
      for (final grade in [5, 6, 7, 8, 9, 10, 11]) {
        for (final node in Curriculum.nodesForGrade('math', grade)) {
          expect(node.questions.length, greaterThanOrEqualTo(4),
              reason: '${node.id}: ${node.questions.length} сұрақ (4-тен аз)');
        }
      }
    });

    test('математика 7–11: босс node-ында шынайы қиын сұрақтар бар', () {
      for (final grade in [7, 8, 9, 10, 11]) {
        final nodes = Curriculum.nodesForGrade('math', grade);
        for (final module in nodes.map((n) => n.module).toSet()) {
          // Соңғы node (босс) — қиын жарты: hard/Күрделі/Басқатырғыш болуы тиіс.
          final boss = nodes.lastWhere((n) => n.module == module);
          final hardCount = boss.questions
              .where((q) =>
                  q.difficulty == Difficulty.hard ||
                  q.difficulty == Difficulty.complex ||
                  q.difficulty == Difficulty.brainTeaser)
              .length;
          expect(hardCount, greaterThanOrEqualTo(3),
              reason: 'g$grade m$module боссында қиын сұрақ аз: $hardCount');
        }
      }
    });

    test('сұрақтар валидті: дұрыс индекс шегінде, жұптар 4-тен', () {
      for (final subject in subjects) {
        for (final node in Curriculum.nodesForGrade(subject, 5)) {
          for (final q in node.questions) {
            if (q.type == QuestionType.matchPairs) {
              expect(q.pairs.length, 4, reason: q.id);
              // Оң жақ мәндер қайталанбауы керек — әйтпесе екіұшты.
              expect(q.pairs.map((p) => p.right).toSet().length, 4,
                  reason: q.id);
            } else {
              expect(q.options, isNotEmpty, reason: q.id);
              expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1),
                  reason: q.id);
            }
          }
        }
      }
    });
  });

  group('Сессия іріктеу', () {
    test('сессияда 12 сұрақ, жеңілден басқатырғышқа қарай, 6 деңгей де бар',
        () {
      final node = Curriculum.nodesForGrade('kazakh', 8).first;
      final session = Curriculum.sessionQuestions(node);
      expect(session.length, Curriculum.sessionSize);
      // Реті: жеңілден қиынға (index өспелі).
      var maxSeen = 0;
      for (final q in session) {
        expect(q.difficulty.index, greaterThanOrEqualTo(maxSeen));
        maxSeen = q.difficulty.index;
      }
      // Әр деңгейден ~2 — 6 деңгейдің бәрі сессияда болады.
      final levels = session.map((q) => q.difficulty).toSet();
      expect(levels.length, Difficulty.values.length,
          reason: 'сессияда 6 деңгейдің бәрі болуы тиіс');
      // Шынайы қиын (Басқатырғыш) деңгей міндетті түрде кездеседі.
      expect(
          session.where((q) => q.difficulty == Difficulty.brainTeaser).length,
          greaterThanOrEqualTo(1));
    });

    test('қазына node-ында 5 сұрақ', () {
      final treasure = Curriculum.nodesForGrade('physics', 4)
          .firstWhere((n) => n.type == NodeType.treasure);
      expect(Curriculum.sessionQuestions(treasure).length,
          Curriculum.treasureSessionSize);
    });

    test('екі сессия әртүрлі болуы ықтимал (кездейсоқ іріктеу)', () {
      final node = Curriculum.nodesForGrade('english', 9).first;
      final a = Curriculum.sessionQuestions(node).map((q) => q.id).toList();
      final b = Curriculum.sessionQuestions(node).map((q) => q.id).toList();
      final c = Curriculum.sessionQuestions(node).map((q) => q.id).toList();
      // Үш сессияның кемінде екеуі өзгеше болуы тиіс.
      expect(a.toString() == b.toString() && b.toString() == c.toString(),
          isFalse);
    });
  });

  group('Батл сұрақтары', () {
    test('детерминистік seed және сәйкестендірусіз форматтар', () {
      final a = Curriculum.battleQuestions(count: 10, seed: 42);
      final b = Curriculum.battleQuestions(count: 10, seed: 42);
      expect(a.map((q) => q.id).toList(), b.map((q) => q.id).toList());
      for (final q in a) {
        expect(q.type, isNot(QuestionType.matchPairs));
        expect(q.options, isNotEmpty);
      }
    });

    test('11-сынып батлына бастауыш сұрақтары түспейді', () {
      final grade1Texts = {
        for (final q in Curriculum.nodesForGrade('kazakh', 1)
            .expand((n) => n.questions))
          q.text,
      };
      final battle =
          Curriculum.battleQuestions(count: 20, seed: 7, grade: 11);
      for (final q in battle) {
        expect(grade1Texts.contains(q.text), isFalse,
            reason: '11-сынып батлында 1-сынып сұрағы: «${q.text}»');
      }
    });
  });

  group('Сыныпқа сай мазмұн', () {
    test('әр пәнде 1-11 сыныптың әрқайсысына толық пул құрылады', () {
      for (final subject in subjects) {
        for (var grade = 1; grade <= 11; grade++) {
          final nodes = Curriculum.nodesForGrade(subject, grade);
          for (final node in nodes.take(2)) {
            // Математикада disjoint тілім (бос емес, банк көлемінде);
            // өзгелерінде — толық 42-лік генератор пулы.
            if (subject == 'math' &&
                Curriculum.hasTopicBank(grade, node.module)) {
              expect(node.questions, isNotEmpty, reason: '$subject g$grade');
            } else {
              expect(node.questions.length,
                  greaterThanOrEqualTo(Curriculum.questionPoolSize),
                  reason: '$subject g$grade пулы кем');
            }
          }
        }
      }
    });

    test('11-сынып пулы өз банкінен құрылады, 1-сынып банкінен емес', () {
      final grade11Bank = {for (final q in kazakhBankExt[11]!) q.$1};
      final pool = Curriculum.nodesForGrade('kazakh', 11).first.questions;
      // Кем дегенде бір сұрақ 11-сынып банкінен тікелей келеді.
      expect(pool.any((q) => grade11Bank.contains(q.text)), isTrue);
      // Бірде-бір сұрақ 1-сынып банкінің мәтінінен басталмайды
      // (дұрыс/бұрыс туындылары да дереккөз мәтінінен басталады).
      final grade1Bank = Curriculum.nodesForGrade('kazakh', 1)
          .first.questions
          .map((q) => q.text.split('\n').first)
          .toSet();
      for (final q in pool) {
        if (q.type == QuestionType.matchPairs) continue; // жалпы мәтін
        expect(grade1Bank.contains(q.text.split('\n').first), isFalse,
            reason: '11-сынып пулында 1-сынып сұрағы: «${q.text}»');
      }
    });

    test('жауап нұсқалары араласқан — дұрысы әрқашан бірінші емес', () {
      for (final subject in ['kazakh', 'english', 'physics', 'cs']) {
        final indexes = <int>{};
        for (final node in Curriculum.nodesForGrade(subject, 7).take(3)) {
          for (final q in node.questions) {
            if (q.type == QuestionType.multipleChoice) {
              indexes.add(q.correctIndex);
            }
          }
        }
        expect(indexes.length, greaterThan(1),
            reason: '$subject: дұрыс жауап бір позицияда қалып қойған');
      }
    });

    test('тақырып тазалығы: модуль сұрақтары өз тақырыбында (non-math)', () {
      String texts(String subject, int grade, int module) =>
          Curriculum.nodesForGrade(subject, grade)
              .where((n) => n.module == module)
              .expand((n) => n.questions)
              .map((q) => q.text.toLowerCase())
              .join(' | ');

      // Қазақ 7: 2-модуль = Абай шығармашылығы, 1-модуль = есімдік/үстеу.
      // Бөліну белсенді болғанда Абай сұрағы тек 2-модульде болады.
      expect(texts('kazakh', 7, 2).contains('абай'), isTrue,
          reason: 'Абай модулінде Абай сұрағы жоқ');
      expect(texts('kazakh', 7, 1).contains('абай'), isFalse,
          reason: '1-модульге (есімдік) Абай сұрағы кіріп кеткен');
    });

    test('10-11 математикада туынды/логарифм/интеграл тақырыптары бар', () {
      final texts10 = Curriculum.nodesForGrade('math', 10)
          .expand((n) => n.questions)
          .map((q) => q.text)
          .join(' ');
      expect(texts10.contains('log') || texts10.contains('f′'), isTrue);
      final texts11 = Curriculum.nodesForGrade('math', 11)
          .expand((n) => n.questions)
          .map((q) => q.text)
          .join(' ');
      expect(texts11.contains('∫') || texts11.contains('ықтималды'), isTrue);
    });
  });
}
