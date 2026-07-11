import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qosqanat/core/constants/app_strings.dart';
import 'package:qosqanat/models/enums.dart';
import 'package:qosqanat/models/lesson.dart';
import 'package:qosqanat/models/task_node.dart';
import 'package:qosqanat/providers/task_provider.dart';
import 'package:qosqanat/widgets/game/map_overlays.dart';

/// Жасанды түйін көрінісін құрады (тестке арналған).
NodeView _view(
  int grade,
  int module,
  int idx, {
  NodeStatus status = NodeStatus.locked,
  int stars = 0,
  bool current = false,
  NodeType type = NodeType.quiz,
}) {
  return NodeView(
    node: TaskNode(
      id: 'math_g${grade}_m${module}_n$idx',
      subject: 'math',
      grade: grade,
      module: module,
      moduleTitle: '$module-модуль тақырыбы',
      indexInModule: idx,
      type: type,
      title: '$grade.$module.$idx түйіні',
      questions: const [],
    ),
    status: status,
    stars: stars,
    isCurrent: current,
  );
}

/// Екі сыныптық, әрқайсысы екі модульді шағын саяхат (аралас күйлер).
List<NodeView> _sampleViews() => [
  _view(5, 1, 0, status: NodeStatus.mastered, stars: 3),
  _view(5, 1, 1, status: NodeStatus.completed, stars: 2),
  _view(5, 2, 0, status: NodeStatus.completed, stars: 1),
  _view(5, 2, 1, status: NodeStatus.available, current: true),
  _view(6, 1, 0),
  _view(6, 1, 1, type: NodeType.boss),
  _view(6, 2, 0, type: NodeType.treasure),
];

void main() {
  group('buildJourney — views → сынып/модуль ағашы', () {
    test('сыныптар мен модульдерді дұрыс топтайды', () {
      final j = buildJourney(_sampleViews());
      expect(j.length, 2);
      expect(j[0].grade, 5);
      expect(j[1].grade, 6);
      expect(j[0].modules.length, 2);
      expect(j[0].total, 4);
      // 5-сыныпта 3 түйін аяқталған (mastered + 2 completed).
      expect(j[0].done, 3);
      expect(j[0].mastered, 1);
      expect(j[0].stars, 6); // 3 + 2 + 1
      expect(j[0].hasCurrent, isTrue);
      // 6-сынып әлі толық жабық.
      expect(j[1].done, 0);
      expect(j[1].modules.first.locked, isTrue);
    });

    test('frac пен complete дұрыс есептеледі', () {
      final j = buildJourney(_sampleViews());
      expect(j[0].frac, closeTo(3 / 4, 1e-9));
      expect(j[0].complete, isFalse);
      expect(j[1].frac, 0);
    });
  });

  group('MapLegendSheet рендерленеді', () {
    testWidgets('түр/күй анықтамалары көрінеді', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MapLegendSheet(accent: Colors.blue)),
        ),
      );
      // «Ағымдағы» түйіннің пульсі шексіз қайталанады → pumpAndSettle емес.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(AppStrings.mapLegendTitle), findsOneWidget);
      expect(find.text(AppStrings.legendLesson), findsOneWidget);
      expect(find.text(AppStrings.legendMastered), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('JourneyOverviewSheet рендерленеді', () {
    testWidgets('тақырып, статистика және сынып карточкалары шығады', (
      tester,
    ) async {
      var jumpedGrade = -1;
      int? jumpedModule = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JourneyOverviewSheet(
              journey: buildJourney(_sampleViews()),
              userGrade: 5,
              subjectTitle: 'Математика',
              accent: Colors.blue,
              onJump: (g, m) {
                jumpedGrade = g;
                jumpedModule = m;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.mapOverviewTitle), findsOneWidget);
      expect(find.text(AppStrings.mapJourneyStats), findsOneWidget);
      // Кемінде бір сынып суффиксі (5-сынып / 6-сынып) көрінеді.
      expect(find.textContaining(AppStrings.mapGradeSuffix), findsWidgets);
      expect(tester.takeException(), isNull);

      // Модуль қатарын түрту → onJump шақырылады.
      await tester.tap(find.text('1-модуль тақырыбы').first);
      await tester.pumpAndSettle();
      expect(jumpedGrade, isNonNegative);
      expect(jumpedModule, isNotNull);
    });
  });

  group('GradeJumpRail рендерленеді', () {
    testWidgets('сынып нөмірлерін көрсетеді әрі түртуге жауап береді', (
      tester,
    ) async {
      var tapped = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: GradeJumpRail(
                grades: buildJourney(_sampleViews()),
                currentGrade: 5,
                accent: Colors.blue,
                onJump: (g, m) => tapped = g,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      await tester.tap(find.text('6'));
      await tester.pump();
      expect(tapped, 6);
      expect(tester.takeException(), isNull);
    });

    testWidgets('бір ғана сынып болса — жасырын', (tester) async {
      final oneGrade = [
        _view(5, 1, 0, status: NodeStatus.available, current: true),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GradeJumpRail(
              grades: buildJourney(oneGrade),
              currentGrade: 5,
              accent: Colors.blue,
              onJump: (g, m) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('5'), findsNothing);
    });
  });

  group('MapControls', () {
    testWidgets('шолу мен белгілер түймелері жұмыс істейді', (tester) async {
      var overview = 0;
      var legend = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapControls(
              accent: Colors.blue,
              onOverview: () => overview++,
              onLegend: () => legend++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.map_rounded));
      await tester.tap(find.byIcon(Icons.help_outline_rounded));
      await tester.pump();
      expect(overview, 1);
      expect(legend, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('NodeFacts', () {
    TaskNode nodeWith(List<Difficulty> diffs) => TaskNode(
      id: 'n',
      subject: 'math',
      grade: 5,
      module: 1,
      moduleTitle: 'm',
      indexInModule: 0,
      type: NodeType.quiz,
      title: 't',
      questions: [
        for (var i = 0; i < diffs.length; i++)
          Question(
            id: 'q$i',
            text: 'сұрақ $i',
            options: const ['a', 'b'],
            correctIndex: 0,
            difficulty: diffs[i],
          ),
      ],
    );

    testWidgets('сұрақ саны мен қиындық таралымын көрсетеді', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFacts(
              node: nodeWith([
                Difficulty.easy,
                Difficulty.easy,
                Difficulty.hard,
              ]),
              questionCount: 12,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('12'), findsWidgets);
      expect(
        find.text(AppStrings.mapDifficultyMix.toUpperCase()),
        findsOneWidget,
      );
      expect(find.textContaining(Difficulty.easy.label), findsWidgets);
      expect(find.textContaining(Difficulty.hard.label), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('бір ғана қиындық болса — таралым жолағы жасырын', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NodeFacts(
              node: nodeWith([Difficulty.easy, Difficulty.easy]),
              questionCount: 5,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppStrings.mapDifficultyMix.toUpperCase()),
        findsNothing,
      );
    });
  });

  group('LessonPreview', () {
    testWidgets('тірек ой, формула және үлгі есеп санын көрсетеді', (
      tester,
    ) async {
      const lesson = Lesson(
        title: 'Бөлшектер',
        intro: 'intro',
        formula: 'a/b + c/b = (a+c)/b',
        examples: [
          WorkedExample(
            problem: '¾ + ¼',
            steps: [ExampleStep('алымдарды қос')],
            answer: '1',
          ),
        ],
        takeaway: 'Бөлімдер бірдей болса — алымдарды қосамыз',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LessonPreview(lesson: lesson)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.mapWillLearn), findsOneWidget);
      expect(find.text(lesson.takeaway), findsOneWidget);
      expect(find.text(lesson.formula!), findsOneWidget);
      expect(find.textContaining(AppStrings.mapExamplesCount), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('формуласыз сабақта формула блогы жоқ', (tester) async {
      const lesson = Lesson(
        title: 'Оқу',
        intro: 'intro',
        takeaway: 'Негізгі ой',
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LessonPreview(lesson: lesson)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.mapFormula.toUpperCase()), findsNothing);
      expect(find.text('Негізгі ой'), findsOneWidget);
    });
  });

  group('StreakChip', () {
    testWidgets('streak санын көрсетеді', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: StreakChip(streak: 7))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
