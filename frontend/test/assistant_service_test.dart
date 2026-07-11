import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qosqanat/models/enums.dart';
import 'package:qosqanat/services/assistant_service.dart';

void main() {
  group('AssistantService — офлайн режим (backend жоқ)', () {
    final service = AssistantService(baseUrl: '');

    test('сәлемдесуге бос емес, есімді қамтитын жауап қайтарады', () async {
      final reply = await service.reply(
        assistant: AssistantType.bektur,
        studentId: '',
        studentName: 'Әли',
        grade: 7,
        history: const [],
        prompt: 'Сәлем!',
      );
      expect(reply, isNotEmpty);
      expect(reply, contains('Әли'));
    });

    test('Назым мен Бектұр персонасы әртүрлі жауап береді', () async {
      final nazym = await service.reply(
        assistant: AssistantType.nazym,
        studentId: '',
        studentName: 'А',
        grade: 7,
        history: const [],
        prompt: 'сәлем',
      );
      final bektur = await service.reply(
        assistant: AssistantType.bektur,
        studentId: '',
        studentName: 'А',
        grade: 7,
        history: const [],
        prompt: 'сәлем',
      );
      expect(nazym, isNot(equals(bektur)));
    });

    test('жеке коуч: «не қиын?» сұрағына нақты әлсіз тақырыпты атайды', () async {
      final reply = await service.reply(
        assistant: AssistantType.bektur,
        studentId: '',
        studentName: 'Әли',
        grade: 6,
        history: const [],
        prompt: 'маған не қиын?',
        weakTopic: 'Жай бөлшектер',
        dueCount: 8,
      );
      expect(reply, contains('Жай бөлшектер'));
      expect(reply, contains('8'));
    });

    test('коуч: дерек жоқта жаттығуды ұсынады (әлсіз тақырып null)', () async {
      final reply = await service.reply(
        assistant: AssistantType.nazym,
        studentId: '',
        studentName: 'Әли',
        grade: 6,
        history: const [],
        prompt: 'нені қайталайын?',
      );
      expect(reply, isNotEmpty);
      expect(reply, isNot(contains('null')));
    });

    test('тақырыптық сұраққа нақты сабақтан түсіндіреді', () async {
      final reply = await service.reply(
        assistant: AssistantType.bektur,
        studentId: '',
        studentName: 'Әли',
        grade: 5,
        history: const [],
        prompt: 'септік дегеніміз не?',
      );
      // «Септік жалғаулары» сабағының мазмұнын қайтаруы тиіс.
      expect(reply.toLowerCase(), contains('септік'));
      expect(reply, contains('📚'));
    });

    test('жалғаулы (түбірлес) сұрақ сабаққа сәйкес келеді (қазақ морфологиясы)',
        () async {
      final reply = await service.reply(
        assistant: AssistantType.bektur,
        studentId: '',
        studentName: 'Әли',
        grade: 5,
        history: const [],
        prompt: 'бөлшекті қалай қосады?', // «бөлшекті» ≠ «бөлшектер», бірақ түбірлес
      );
      expect(reply.toLowerCase(), contains('бөлшек'));
      // Сәлемдесу немесе кездейсоқ жауап БОЛМАУЫ керек.
      expect(reply.toLowerCase(), isNot(contains('дайынсың')));
    });

    test('белгісіз сұраққа АДАЛ жауап (ойдан шығармайды)', () async {
      final reply = await service.reply(
        assistant: AssistantType.nazym,
        studentId: '',
        studentName: 'Әли',
        grade: 7,
        history: const [],
        prompt: 'Ньютон ғарышқа ұшты ма?', // бағдарламадан тыс
      );
      // Адал «офлайн/интернет» жауабы — жалған сенімді жауап емес.
      expect(reply.toLowerCase(), contains('интернет'));
    });
  });

  group('AssistantService — backend (Claude proxy)', () {
    test('200 жауаптан reply мәтінін қайтарады әрі сұрауды дұрыс құрады',
        () async {
      late http.Request captured;
      final mock = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({'reply': 'Бұл — серверден келген жауап ✨'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = AssistantService(
        baseUrl: 'https://api.example.com',
        client: mock,
      );

      final reply = await service.reply(
        assistant: AssistantType.nazym,
        studentId: 'QQ-12345',
        studentName: 'Әли',
        grade: 9,
        history: const [],
        prompt: 'Фотосинтез дегеніміз не?',
      );

      expect(reply, 'Бұл — серверден келген жауап ✨');
      expect(captured.url.toString(), 'https://api.example.com/api/chat');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['assistant_type'], 'nazym');
      expect(body['student_id'], 'QQ-12345');
      expect(body['grade'], 9);
      expect(body['message'], 'Фотосинтез дегеніміз не?');
    });

    test('сынып 5–11 аралығына қысылады (grade < 5 → 5)', () async {
      late http.Request captured;
      final mock = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'reply': 'ok'}), 200);
      });
      final service =
          AssistantService(baseUrl: 'https://x.test', client: mock);

      await service.reply(
        assistant: AssistantType.bektur,
        studentId: 'x',
        studentName: 'A',
        grade: 2,
        history: const [],
        prompt: 'сұрақ',
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['grade'], 5);
    });

    test('бос student_id → "anonymous" болып жіберіледі', () async {
      late http.Request captured;
      final mock = MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'reply': 'ok'}), 200);
      });
      final service =
          AssistantService(baseUrl: 'https://x.test', client: mock);

      await service.reply(
        assistant: AssistantType.bektur,
        studentId: '',
        studentName: 'A',
        grade: 8,
        history: const [],
        prompt: 'сұрақ',
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['student_id'], 'anonymous');
    });

    test('сервер қатесінде (503) офлайн логикаға ауысады', () async {
      final mock = MockClient((req) async => http.Response('err', 503));
      final service =
          AssistantService(baseUrl: 'https://x.test', client: mock);

      final reply = await service.reply(
        assistant: AssistantType.bektur,
        studentId: 'x',
        studentName: 'Сая',
        grade: 7,
        history: const [],
        prompt: 'Сәлем',
      );

      // Офлайн сәлемдесу жауабы — бос емес әрі есімді қамтиды.
      expect(reply, isNotEmpty);
      expect(reply, contains('Сая'));
    });
  });
}
