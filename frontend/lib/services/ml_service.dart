import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

/// QosQanat ML микросервисінің клиенті (DKT болжам, RAG ұстаз, рекомендер,
/// емтиханға дайындық, ашық жауапты бағалау, интервал).
///
/// OFFLINE-FIRST: [AppConfig.mlBaseUrl] бос болса немесе сұрау сәтсіз болса —
/// барлық метод `null` қайтарады, сонда қосымша өзінің офлайн логикасына
/// (EMA/SM-2/кілт сөз) кедергісіз ауысады.
class MlService {
  MlService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.mlBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const _timeout = Duration(seconds: 12);

  bool get available => _baseUrl.isNotEmpty;

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    if (!available) return null;
    try {
      final res = await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// RAG ұстаз — оқу бағдарламасына негізделген жауап (онлайн күшейту).
  Future<String?> askTutor(String question, {int grade = 8}) async {
    final data = await _post('/tutor/ask', {'question': question, 'grade': grade});
    final answer = data?['answer'] as String?;
    return (answer != null && answer.trim().isNotEmpty) ? answer : null;
  }

  /// Емтиханға дайындық болжамы (оқу қисығы).
  Future<({double readiness, int readyTopics, int total, double? days})?>
      readiness(List<double> mastery, {double target = 0.8}) async {
    final data = await _post('/forecast/readiness', {
      'mastery': mastery,
      'target': target,
    });
    if (data == null) return null;
    return (
      readiness: (data['readiness'] as num?)?.toDouble() ?? 0,
      readyTopics: (data['ready_topics'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      days: (data['days_to_ready'] as num?)?.toDouble(),
    );
  }

  /// Интервалды қайталау мерзімі (HLR — жадының жартылай ыдырауы).
  Future<({double intervalDays, double halfLifeDays})?> spacingInterval(
    int nCorrect,
    int nIncorrect, {
    double targetRecall = 0.9,
  }) async {
    final data = await _post('/spacing/interval', {
      'n_correct': nCorrect,
      'n_incorrect': nIncorrect,
      'target_recall': targetRecall,
    });
    if (data == null) return null;
    return (
      intervalDays: (data['interval_days'] as num?)?.toDouble() ?? 0,
      halfLifeDays: (data['half_life_days'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Ашық жауапты семантикалық бағалау (бос орын/еркін мәтін сұрақтары үшін).
  Future<({double score, String verdict, String feedback})?> gradeAnswer(
    String studentAnswer,
    String correctAnswer,
  ) async {
    final data = await _post('/nlp/grade', {
      'student_answer': studentAnswer,
      'correct_answer': correctAnswer,
    });
    if (data == null) return null;
    return (
      score: (data['score'] as num?)?.toDouble() ?? 0,
      verdict: data['verdict'] as String? ?? 'incorrect',
      feedback: data['feedback'] as String? ?? '',
    );
  }

  /// DKT меңгеру болжамы (skill индекстерімен). skill_vocab синхрондалғанда.
  Future<List<double>?> predictMastery(
    List<({int skill, bool correct})> interactions, {
    int topK = 3,
  }) async {
    final data = await _post('/dkt/predict', {
      'interactions': [
        for (final i in interactions) {'skill': i.skill, 'correct': i.correct ? 1 : 0},
      ],
      'top_k': topK,
    });
    final mastery = data?['mastery'] as List?;
    return mastery?.map((e) => (e as num).toDouble()).toList();
  }

  void dispose() => _client.close();
}
