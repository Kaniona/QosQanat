import '../../models/enums.dart';

/// Банк жазбасы: (мәтін, нұсқалар, дұрыс индекс, түсіндірме, қиындық).
typedef BankQ = (String, List<String>, int, String?, Difficulty);

/// Сәйкестендіру жұбы: (сол жақ, оң жақ).
typedef BankP = (String, String);
