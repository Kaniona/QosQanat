import 'package:flutter/material.dart';

/// Әр пәннің оқу картасы — өз «әлемі».
enum SubjectWorld {
  /// Қазақ тілі: дала таңы, киіз үйлер, таулар, ою-өрнек, қыран.
  steppe,

  /// Математика: геометриялық қала, тор, шоқжұлдыз сызықтары.
  geometry,

  /// Ағылшын: әуе шарлары, бұлттар, қала силуэті (саяхат аспаны).
  skyTravel,

  /// Физика: ғарыш, сақиналы ғаламшар, орбиталар, ай, жұлдыздар.
  cosmos,

  /// Информатика: микросхема жолдары, чиптер, жарқыраған сигналдар.
  circuit,

  /// Биология: гүлденген алқап, өсімдіктер, жапырақтар, ДНҚ спиралі.
  flora,

  /// Химия: зертхана, колбалар, көпіршіктер, молекула торы.
  lab,

  /// Қазақстан тарихы: алтын дала, балбал тас, шаңырақ, тарихи ту.
  heritage,
}

/// Пән әлемінің көрнекі параметрлері: аспан градиенті + көкжиек реңктері.
class SubjectWorldTheme {
  const SubjectWorldTheme({
    required this.world,
    required this.skyColors,
    required this.skyStops,
    required this.isDark,
    required this.horizonGlow,
    required this.scenery,
  });

  final SubjectWorld world;

  /// Төменнен жоғары қарай аспан түстері.
  final List<Color> skyColors;
  final List<double> skyStops;

  /// Қараңғы әлемдерде (ғарыш, схема) жол нүктелері ашығырақ болады.
  final bool isDark;

  /// Көкжиектегі атмосфералық жарқыл (таң шапағы / нева шуағы).
  final Color horizonGlow;

  /// Көкжиек силуэттерінің негізгі реңкі.
  final Color scenery;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: skyColors,
        stops: skyStops,
      );

  static SubjectWorldTheme of(String subjectId) =>
      _bySubject[subjectId] ?? _bySubject['kazakh']!;

  // Премиум кинематографиялық градиенттер: төменде қанық көкжиек шапағы →
  // ортада ауа → жоғарыда тереңдік. Жарық әлемдерде жол/тиындар, қараңғыда
  // жұлдыз-орбтар бөлектенеді. Көкжиекте пәнге сай силуэт тұрады.
  static final Map<String, SubjectWorldTheme> _bySubject = {
    // Дала таңы: жылы алтын шапақ → шабдалы → лаванда аспан.
    'kazakh': const SubjectWorldTheme(
      world: SubjectWorld.steppe,
      skyColors: [
        Color(0xFFF7C56E),
        Color(0xFFF7D9BE),
        Color(0xFFDFE0F8),
        Color(0xFFC7DAFB),
      ],
      skyStops: [0, .3, .68, 1],
      isDark: false,
      horizonGlow: Color(0xFFFFD27A),
      scenery: Color(0xFF9C7A45),
    ),
    // Геометрия: жарық көкжиек → көк сызба аспаны (тереңдеу жоғары).
    'math': const SubjectWorldTheme(
      world: SubjectWorld.geometry,
      skyColors: [
        Color(0xFFD2E4FF),
        Color(0xFFE9F1FF),
        Color(0xFFB7CDF6),
        Color(0xFF96B2EC),
      ],
      skyStops: [0, .3, .7, 1],
      isDark: false,
      horizonGlow: Color(0xFFEAF3FF),
      scenery: Color(0xFF6E8BD0),
    ),
    // Саяхат аспаны: батар күн шапағы → жылы цитрус → көк биіктік.
    'english': const SubjectWorldTheme(
      world: SubjectWorld.skyTravel,
      skyColors: [
        Color(0xFFFFC98E),
        Color(0xFFFFE6CC),
        Color(0xFFD9E7FB),
        Color(0xFFB8D5F5),
      ],
      skyStops: [0, .3, .7, 1],
      isDark: false,
      horizonGlow: Color(0xFFFFCF95),
      scenery: Color(0xFFCE8F61),
    ),
    // Ғарыш: тереңдеген күлгін небула → түнгі түпсіз.
    'physics': const SubjectWorldTheme(
      world: SubjectWorld.cosmos,
      skyColors: [
        Color(0xFF4A3597),
        Color(0xFF2C2169),
        Color(0xFF181140),
        Color(0xFF0C0925),
      ],
      skyStops: [0, .4, .74, 1],
      isDark: true,
      horizonGlow: Color(0xFF7659D6),
      scenery: Color(0xFF8E76E8),
    ),
    // Микросхема түні: терең индиго → жасыл-көгілдір сигнал шапағы.
    'cs': const SubjectWorldTheme(
      world: SubjectWorld.circuit,
      skyColors: [
        Color(0xFF2E2A78),
        Color(0xFF1E1B59),
        Color(0xFF131140),
        Color(0xFF0B0A2A),
      ],
      skyStops: [0, .4, .74, 1],
      isDark: true,
      horizonGlow: Color(0xFF2BC6C6),
      scenery: Color(0xFF36D0C4),
    ),
    // Гүлденген алқап: жылы жасыл шапақ → ашық көк аспан (өмір, табиғат).
    'biology': const SubjectWorldTheme(
      world: SubjectWorld.flora,
      skyColors: [
        Color(0xFFBFEBC6),
        Color(0xFFE2F6E0),
        Color(0xFFCDE9F5),
        Color(0xFF9FD3EC),
      ],
      skyStops: [0, .32, .7, 1],
      isDark: false,
      horizonGlow: Color(0xFFA7E88C),
      scenery: Color(0xFF4E9B5F),
    ),
    // Зертхана: көгілдір-көк колба реңкі → жеңіл күлгін аспан.
    'chemistry': const SubjectWorldTheme(
      world: SubjectWorld.lab,
      skyColors: [
        Color(0xFF9CE0E8),
        Color(0xFFCDEFF3),
        Color(0xFFDAD2F2),
        Color(0xFFBBA8E4),
      ],
      skyStops: [0, .32, .7, 1],
      isDark: false,
      horizonGlow: Color(0xFF66D8D0),
      scenery: Color(0xFF5E86BE),
    ),
    // Тарихи дала: алтын шапақ → жылы құм реңкі (көне, шежіре).
    'history': const SubjectWorldTheme(
      world: SubjectWorld.heritage,
      skyColors: [
        Color(0xFFF3D6A0),
        Color(0xFFF8E7C6),
        Color(0xFFEAD3AC),
        Color(0xFFCDB183),
      ],
      skyStops: [0, .3, .68, 1],
      isDark: false,
      horizonGlow: Color(0xFFF2C877),
      scenery: Color(0xFF8A6A3B),
    ),
  };
}
