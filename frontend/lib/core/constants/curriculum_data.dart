import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Оқу бағдарламасының құрылымдық константалары: 5 пән, 1-11 сынып.
abstract final class CurriculumData {
  static const subjects = [
    SubjectInfo(
      id: 'math',
      title: 'Математика',
      icon: Icons.calculate_rounded,
      accent: AppColors.accentMath,
      accentLight: AppColors.eagleBlueLight,
    ),
    SubjectInfo(
      id: 'kazakh',
      title: 'Қазақ тілі',
      icon: Icons.menu_book_rounded,
      accent: AppColors.accentKazakh,
      accentLight: Color(0xFFE0FAF2),
    ),
    SubjectInfo(
      id: 'english',
      title: 'Ағылшын',
      icon: Icons.language_rounded,
      accent: AppColors.accentEng,
      accentLight: AppColors.steppeGoldLight,
    ),
    SubjectInfo(
      id: 'physics',
      title: 'Физика',
      icon: Icons.bolt_rounded,
      accent: AppColors.accentPhysics,
      accentLight: AppColors.nazymRoseLight,
    ),
    SubjectInfo(
      id: 'cs',
      title: 'Информатика',
      icon: Icons.computer_rounded,
      accent: AppColors.accentCS,
      accentLight: AppColors.cosmicPurpleLight,
    ),
    SubjectInfo(
      id: 'biology',
      title: 'Биология',
      icon: Icons.biotech_rounded,
      accent: Color(0xFF00A86B),
      accentLight: Color(0xFFE0F7EA),
    ),
    SubjectInfo(
      id: 'chemistry',
      title: 'Химия',
      icon: Icons.science_rounded,
      accent: Color(0xFF8B4789),
      accentLight: Color(0xFFF3E5F5),
    ),
    SubjectInfo(
      id: 'history',
      title: 'Қазақстан тарихы',
      icon: Icons.history_edu_rounded,
      accent: Color(0xFFB8860B),
      accentLight: Color(0xFFF6ECD2),
    ),
  ];

  static const int minGrade = 1;
  static const int maxGrade = 11;

  /// Аймақтар: Дала (1-3), Аспан (4-8), Ғарыш (9-11).
  static String zoneForGrade(int grade) {
    if (grade <= 3) return 'Дала';
    if (grade <= 8) return 'Аспан';
    return 'Ғарыш';
  }

  static SubjectInfo subjectById(String id) =>
      subjects.firstWhere((s) => s.id == id, orElse: () => subjects.first);

  /// Тіркелуге арналған қалалар тізімі.
  static const cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Қарағанды',
    'Ақтөбе',
    'Тараз',
    'Павлодар',
    'Өскемен',
    'Семей',
    'Атырау',
    'Қостанай',
    'Қызылорда',
    'Орал',
    'Петропавл',
    'Ақтау',
    'Теміртау',
    'Түркістан',
    'Көкшетау',
    'Талдықорған',
    'Екібастұз',
  ];
}

/// Пән туралы көрнекі ақпарат.
class SubjectInfo {
  const SubjectInfo({
    required this.id,
    required this.title,
    required this.icon,
    required this.accent,
    required this.accentLight,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color accent;
  final Color accentLight;
}
