import 'package:flutter/services.dart';

/// Haptic кері байланыс — баптаулардағы «Дірiл» қосқышына бағынады.
/// SettingsNotifier жүктелгенде/өзгергенде [enabled] синхрондалады.
abstract final class AppHaptics {
  static bool enabled = true;

  /// Батырма басу.
  static void tap() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Жауап таңдау (жеңіл).
  static void select() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Қате жауап / маңызды оқиға.
  static void heavy() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
