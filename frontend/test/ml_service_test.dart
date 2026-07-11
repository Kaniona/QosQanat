import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qosqanat/models/enums.dart';
import 'package:qosqanat/services/assistant_service.dart';
import 'package:qosqanat/services/ml_service.dart';

http.Response _json(Object body, [int code = 200]) => http.Response(
      jsonEncode(body), code,
      headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('MlService', () {
    test('URL жоқта available=false', () {
      expect(MlService(baseUrl: '').available, isFalse);
    });

    test('askTutor /tutor/ask жауабын қайтарады', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/tutor/ask');
        return _json({'answer': '«Септік жалғаулары» туралы...', 'grounded': true});
      });
      final ml = MlService(client: client, baseUrl: 'https://ml.test');
      final ans = await ml.askTutor('септік деген не', grade: 5);
      expect(ans, contains('Септік'));
    });

    test('readiness болжамды парстайды', () async {
      final client = MockClient((req) async => _json(
          {'readiness': 0.7, 'ready_topics': 3, 'total': 5, 'days_to_ready': 12.0}));
      final ml = MlService(client: client, baseUrl: 'https://ml.test');
      final r = await ml.readiness([0.9, 0.8, 0.5, 0.3, 0.2]);
      expect(r, isNotNull);
      expect(r!.readyTopics, 3);
      expect(r.days, 12.0);
    });

    test('spacingInterval HLR интервалын парстайды', () async {
      final client = MockClient((req) async =>
          _json({'interval_days': 3.5, 'half_life_days': 10.2}));
      final ml = MlService(client: client, baseUrl: 'https://ml.test');
      final s = await ml.spacingInterval(3, 1);
      expect(s!.intervalDays, 3.5);
    });

    test('сервер қатесінде graceful null (offline-first)', () async {
      final client = MockClient((req) async => http.Response('err', 500));
      final ml = MlService(client: client, baseUrl: 'https://ml.test');
      expect(await ml.askTutor('x'), isNull);
      expect(await ml.readiness([0.5]), isNull);
    });
  });

  group('AssistantService — ML қабатын қолдану', () {
    test('Claude жоқ, ML бар → ML RAG ұстазы қолданылады', () async {
      final client = MockClient((req) async {
        if (req.url.path == '/tutor/ask') {
          return _json({'answer': 'ML RAG жауабы ✅'});
        }
        return http.Response('no', 404);
      });
      final ml = MlService(client: client, baseUrl: 'https://ml.test');
      final svc = AssistantService(baseUrl: '', ml: ml);
      final reply = await svc.reply(
        assistant: AssistantType.bektur,
        studentId: '',
        studentName: 'Әли',
        grade: 7,
        history: const [],
        prompt: 'жасушаны түсіндірші',
      );
      expect(reply, 'ML RAG жауабы ✅');
    });

    test('ML де жоқ → офлайн логика (қосымша жұмыс істей береді)', () async {
      final svc = AssistantService(baseUrl: '', ml: MlService(baseUrl: ''));
      final reply = await svc.reply(
        assistant: AssistantType.nazym,
        studentId: '',
        studentName: 'Әли',
        grade: 7,
        history: const [],
        prompt: 'сәлем',
      );
      expect(reply, isNotEmpty);
    });
  });
}
