/// Жобаның құрастыру (build) конфигурациясы.
///
/// Құпия кілттер ЕШҚАШАН қосымшаға салынбайды. Тек backend proxy-дің ашық
/// мекенжайы беріледі — ол да build кезінде --dart-define арқылы енгізіледі:
///
///   flutter run --dart-define=QOSQANAT_API_URL=https://api.qosqanat.kz
///
/// [apiBaseUrl] бос болса — қосымша толық офлайн режимде жұмыс істейді
/// (AI серік құрылғыдағы персона-логикаға ауысады). Бұл offline-first қағидасы.
abstract final class AppConfig {
  static const String apiBaseUrl =
      String.fromEnvironment('QOSQANAT_API_URL', defaultValue: '');

  /// AI ML микросервисінің мекенжайы (DKT/RAG/рекомендер/болжау). Бос болса —
  /// қосымша офлайн логикасын қолданады (offline-first бұзылмайды):
  ///   flutter run --dart-define=QOSQANAT_ML_URL=https://ml.qosqanat.kz
  static const String mlBaseUrl =
      String.fromEnvironment('QOSQANAT_ML_URL', defaultValue: '');

  /// Backend қолжетімді ме (URL берілген бе).
  static bool get hasBackend => apiBaseUrl.isNotEmpty;

  /// ML микросервисі қолжетімді ме.
  static bool get hasMlService => mlBaseUrl.isNotEmpty;
}
