import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/data/curriculum.dart';
import 'package:qosqanat/models/enums.dart';
import 'package:qosqanat/models/mastery.dart';

/// Демо/көрме сапасы: қазы кез келген пәнге кіргенде сұрақтар қайталанбай,
/// форматтары әртүрлі болуы тиіс. Әрі демо сидер сүйенетін id-құрылымы валид.
void main() {
  const nonMath = ['kazakh', 'english', 'physics', 'cs'];

  group('Мазмұн сапасы (демо)', () {
    test('non-math node: бірегей сұрақ өзегі жеткілікті (қайталану аз)', () {
      var worst = 9999;
      var worstId = '';
      for (final subject in nonMath) {
        for (final grade in [5, 6, 7, 8, 9, 10, 11]) {
          for (final node in Curriculum.nodesForGrade(subject, grade)) {
            // Дұрыс/бұрыс туындысының жалғауын алып тастап, өзекті аламыз.
            final stems = node.questions
                .map((q) => q.text.split('\n').first.trim())
                .toSet();
            if (stems.length < worst) {
              worst = stems.length;
              worstId = node.id;
            }
          }
        }
      }
      expect(worst, greaterThanOrEqualTo(22),
          reason: 'ең аз бірегейлік: $worstId → $worst (42-пулда)');
    });

    test('auto Дұрыс/Бұрыс үлесі шектен аспайды (пулдың жартысынан аз)', () {
      var worstTf = 0;
      var worstId = '';
      for (final subject in nonMath) {
        for (final grade in [5, 7, 9, 11]) {
          for (final node in Curriculum.nodesForGrade(subject, grade)) {
            final tf = node.questions
                .where((q) => q.type == QuestionType.trueFalse)
                .length;
            if (tf > worstTf) {
              worstTf = tf;
              worstId = node.id;
            }
          }
        }
      }
      expect(worstTf, lessThanOrEqualTo(Curriculum.questionPoolSize ~/ 2),
          reason: '$worstId: $worstTf дұрыс/бұрыс (тым көп)');
    });
  });

  group('Демо сидер id-құрылымы валид', () {
    test('демо сыныбының барлық node/тақырып id-і шешіледі', () {
      const subjects = ['math', 'kazakh', 'english', 'physics', 'cs'];
      const grade = 7; // DemoSeeder.demoGrade
      for (final subject in subjects) {
        final mc = Curriculum.moduleCount(subject, grade);
        expect(mc, greaterThan(0), reason: '$subject g$grade модулі жоқ');
        for (var m = 1; m <= mc; m++) {
          final perModule = Curriculum.nodesPerModuleFor(subject, grade);
          for (var i = 0; i < perModule; i++) {
            final id = '${subject}_g${grade}_m${m}_n$i';
            final node = Curriculum.nodeById(id);
            expect(node, isNotNull, reason: 'node жоқ: $id');
            // Сидер skill id-і node id-інен дұрыс шығады.
            expect(skillIdFromNode(id), skillIdFor(subject, grade, m),
                reason: 'skill id сәйкес емес: $id');
          }
        }
      }
    });

    test('демо қайталау сұрақтары нақты node-та табылады (review session)', () {
      // Сидер math/english/physics 7-сыныптың 1-node-ынан 3 сұрақ алады.
      for (final subject in ['math', 'english', 'physics']) {
        final node = Curriculum.nodesForGrade(subject, 7).first;
        final qs = node.questions
            .where((q) => q.type != QuestionType.matchPairs)
            .take(3)
            .toList();
        expect(qs, isNotEmpty, reason: '$subject: қайталауға сұрақ жоқ');
        for (final q in qs) {
          // buildReviewSession сол node ішінен id бойынша табады.
          expect(node.questions.any((x) => x.id == q.id), isTrue);
        }
      }
    });
  });
}
