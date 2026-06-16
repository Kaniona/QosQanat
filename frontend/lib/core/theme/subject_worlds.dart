import 'package:flutter/material.dart';

/// Әр пәннің оқу картасы — өз «әлемі».
enum SubjectWorld {
  /// Қазақ тілі: дала таңы, киіз үйлер, ою-өрнек, қыран.
  steppe,

  /// Математика: геометриялық пішіндер, тор, шоқжұлдыз сызықтары.
  geometry,

  /// Ағылшын: әуе шарлары, бұлттар, қала силуэті.
  skyTravel,

  /// Физика: ғарыш, ғаламшарлар, орбиталар, атом.
  cosmos,

  /// Информатика: микросхема жолдары, чиптер, жарқыраған сигналдар.
  circuit,
}

/// Пән әлемінің көрнекі параметрлері: аспан градиенті + декор реңктері.
class SubjectWorldTheme {
  const SubjectWorldTheme({
    required this.world,
    required this.skyColors,
    required this.skyStops,
    required this.isDark,
  });

  final SubjectWorld world;

  /// Төменнен жоғары қарай аспан түстері.
  final List<Color> skyColors;
  final List<double> skyStops;

  /// Қараңғы әлемдерде (ғарыш, схема) жол нүктелері ашығырақ болады.
  final bool isDark;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: skyColors,
        stops: skyStops,
      );

  static SubjectWorldTheme of(String subjectId) =>
      _bySubject[subjectId] ?? _bySubject['kazakh']!;

  static final Map<String, SubjectWorldTheme> _bySubject = {
    'kazakh': const SubjectWorldTheme(
      world: SubjectWorld.steppe,
      skyColors: [Color(0xFFFFE9C2), Color(0xFFE9F0FF), Color(0xFFC7D8FF)],
      skyStops: [0, .45, 1],
      isDark: false,
    ),
    'math': const SubjectWorldTheme(
      world: SubjectWorld.geometry,
      skyColors: [Color(0xFFDCE9FF), Color(0xFFEFF4FF), Color(0xFFBFD4FF)],
      skyStops: [0, .5, 1],
      isDark: false,
    ),
    'english': const SubjectWorldTheme(
      world: SubjectWorld.skyTravel,
      skyColors: [Color(0xFFFFE3B8), Color(0xFFFFF1DC), Color(0xFFB8D9FF)],
      skyStops: [0, .35, 1],
      isDark: false,
    ),
    'physics': const SubjectWorldTheme(
      world: SubjectWorld.cosmos,
      skyColors: [Color(0xFF3A2580), Color(0xFF231A5E), Color(0xFF0F0C33)],
      skyStops: [0, .5, 1],
      isDark: true,
    ),
    'cs': const SubjectWorldTheme(
      world: SubjectWorld.circuit,
      skyColors: [Color(0xFF2B2160), Color(0xFF1E1850), Color(0xFF131038)],
      skyStops: [0, .5, 1],
      isDark: true,
    ),
  };
}
