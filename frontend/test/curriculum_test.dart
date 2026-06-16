import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat_2_0/data/banks/kazakh_bank.dart';
import 'package:qosqanat_2_0/data/curriculum.dart';
import 'package:qosqanat_2_0/models/enums.dart';

void main() {
  const subjects = ['math', 'kazakh', 'english', 'physics', 'cs'];

  group('Сыныптық оқшаулау', () {
    test('nodesForGrade ТЕК сұралған сыныптың node-тарын қайтарады', () {
      for (final subject in subjects) {
        for (final grade in [1, 5, 8, 11]) {
          final nodes = Curriculum.nodesForGrade(subject, grade);
          expect(nodes.length,
              Curriculum.modulesPerGrade * Curriculum.nodesPerModule);
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
      expect(nodes.length,
          5 * Curriculum.modulesPerGrade * Curriculum.nodesPerModule);
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
      final node = Curriculum.nodeById('math_g8_m1_n3');
      expect(node, isNotNull);
      expect(node!.grade, 8);
      expect(node.module, 1);
      expect(Curriculum.nodeById('math_g99_m1_n0'), isNull);
      expect(Curriculum.nodeById('bogus'), isNull);
    });
  });

  group('Сұрақ пулы', () {
    test('әр node-та 42 сұрақ, үлес ~60/30/10', () {
      for (final subject in subjects) {
        for (final grade in [2, 6, 9]) {
          for (final node in Curriculum.nodesForGrade(subject, grade)) {
            expect(node.questions.length, Curriculum.questionPoolSize,
                reason: '${node.id} пулы толық емес');
            final easy = node.questions
                .where((q) => q.difficulty == Difficulty.easy)
                .length;
            final medium = node.questions
                .where((q) => q.difficulty == Difficulty.medium)
                .length;
            final hard = node.questions
                .where((q) => q.difficulty == Difficulty.hard)
                .length;
            expect(easy, 25);
            expect(medium, 12);
            expect(hard, 5);
          }
        }
      }
    });

    test('пулда бірнеше формат бар (TF + match міндетті)', () {
      for (final subject in subjects) {
        final node = Curriculum.nodesForGrade(subject, 8).first;
        final types = node.questions.map((q) => q.type).toSet();
        expect(types.contains(QuestionType.matchPairs), isTrue,
            reason: '$subject: сәйкестендіру жоқ');
        if (subject != 'math') {
          expect(types.contains(QuestionType.trueFalse), isTrue,
              reason: '$subject: дұрыс/бұрыс жоқ');
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
    test('сессияда 12 сұрақ, жеңілден қиынға қарай', () {
      final node = Curriculum.nodesForGrade('kazakh', 8).first;
      final session = Curriculum.sessionQuestions(node);
      expect(session.length, Curriculum.sessionSize);
      // Реті: easy ≤ medium ≤ hard.
      var maxSeen = 0;
      for (final q in session) {
        expect(q.difficulty.index, greaterThanOrEqualTo(maxSeen));
        maxSeen = q.difficulty.index;
      }
      final easy =
          session.where((q) => q.difficulty == Difficulty.easy).length;
      expect(easy, 7); // 12 × 0.6
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
            expect(node.questions.length,
                greaterThanOrEqualTo(Curriculum.questionPoolSize),
                reason: '$subject g$grade пулы кем');
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
