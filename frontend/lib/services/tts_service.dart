import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Дауыспен оқу қызметі — құрылғының TTS қозғалтқышын пайдаланады.
///
/// САҚТЫҚ: қазақ (kk-KZ) дауысы барлық құрылғыда бола бермейді. Сондықтан
/// қызмет «мүмкіндікке қарай» жұмыс істейді: kk-KZ → ru-RU → жоқ болса
/// [available] = false болып, батырма МҮЛДЕ көрінбейді. Осылайша көрсетілім
/// кезінде ешқашан «сынбайды». Барлық қателер жұтылады (offline-ге қауіпсіз).
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  FlutterTts? _tts;
  bool _initStarted = false;

  /// Дауыс қолжетімді ме (init аяқталған соң белгілі болады).
  final ValueNotifier<bool> available = ValueNotifier(false);

  /// Қазір оқып тұр ма — батырманың play/stop күйі.
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  /// Бір рет инициализация: тіл табу + параметрлер. Қайта шақырса — өтеді.
  Future<void> ensureInit() async {
    if (_initStarted) return;
    _initStarted = true;
    try {
      final tts = FlutterTts();
      final raw = await tts.getLanguages;
      final codes = (raw is List)
          ? raw.map((e) => e.toString().toLowerCase()).toList()
          : const <String>[];

      bool has(String prefix) => codes.any((c) => c.startsWith(prefix));
      final pick = has('kk') ? 'kk-KZ' : (has('ru') ? 'ru-RU' : null);
      if (pick == null) {
        available.value = false;
        return;
      }

      await tts.setLanguage(pick);
      await tts.setSpeechRate(0.45); // балаға ыңғайлы, баяулау қарқын
      await tts.setPitch(1.0);
      await tts.awaitSpeakCompletion(true);
      tts.setCompletionHandler(() => speaking.value = false);
      tts.setCancelHandler(() => speaking.value = false);
      tts.setErrorHandler((_) => speaking.value = false);

      _tts = tts;
      available.value = true;
    } catch (_) {
      available.value = false;
    }
  }

  /// Мәтінді дауыстап оқу (алдыңғы оқуды тоқтатып).
  Future<void> speak(String text) async {
    final tts = _tts;
    final clean = text.trim();
    if (tts == null || clean.isEmpty) return;
    try {
      await tts.stop();
      speaking.value = true;
      await tts.speak(clean);
    } catch (_) {
      // елемейміз
    } finally {
      speaking.value = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {
      // елемейміз
    }
    speaking.value = false;
  }
}
