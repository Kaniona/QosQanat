/// Форма валидаторлары (offline режім — тек формат тексеру).
abstract final class Validators {
  /// Телефон: +7 (XXX) XXX-XX-XX маскасынан 11 цифр шығуы керек.
  static bool isValidPhone(String masked) {
    final digits = masked.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 && digits.startsWith('7');
  }

  /// ЖСН: 12 цифр + туған күн дұрыстығы + ресми бақылау цифры.
  /// Құрылым: ЖЖААКК (туған күн) + ғасыр/жыныс (1-6) + 4 цифр + чексум.
  static bool isValidIin(String value) {
    final iin = value.trim();
    if (!RegExp(r'^\d{12}$').hasMatch(iin)) return false;
    final digits = iin.split('').map(int.parse).toList();

    // Туған күн: ай 1-12, күн 1-31.
    final month = digits[2] * 10 + digits[3];
    final day = digits[4] * 10 + digits[5];
    if (month < 1 || month > 12 || day < 1 || day > 31) return false;

    // Ғасыр/жыныс коды: 1-6.
    if (digits[6] < 1 || digits[6] > 6) return false;

    // Бақылау цифры (ҚР стандарты): екі салмақ кезеңі, mod 11.
    const w1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    const w2 = [3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2];
    var sum = 0;
    for (var i = 0; i < 11; i++) {
      sum += digits[i] * w1[i];
    }
    var control = sum % 11;
    if (control == 10) {
      sum = 0;
      for (var i = 0; i < 11; i++) {
        sum += digits[i] * w2[i];
      }
      control = sum % 11;
      if (control == 10) return false;
    }
    return control == digits[11];
  }

  /// Аты-жөні: кемінде 2 сөз, әр сөз 2+ әріп.
  static bool isValidFullName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    return parts.length >= 2 && parts.every((p) => p.length >= 2);
  }

  // ---- Құпиясөз ережелері (handoff §3) ----
  static bool hasMinLength(String p) => p.length >= 8;
  static bool hasDigit(String p) => RegExp(r'\d').hasMatch(p);
  static bool hasUppercase(String p) => RegExp('[A-ZА-ЯӘҒҚҢӨҰҮҺІ]').hasMatch(p);

  /// 0..3 балл: орындалған ережелер саны.
  static int passwordScore(String p) {
    if (p.isEmpty) return 0;
    var score = 0;
    if (hasMinLength(p)) score++;
    if (hasDigit(p)) score++;
    if (hasUppercase(p)) score++;
    return score;
  }

  static bool isStrongPassword(String p) => passwordScore(p) == 3;

  /// QQ-ID форматы: QQ-XXXXXXXXX (9 әріп-сан).
  static bool isValidQqId(String value) =>
      RegExp(r'^QQ-[A-Z0-9]{9}$').hasMatch(value.trim().toUpperCase());

  /// OTP: 4 цифр.
  static bool isValidOtp(String value) => RegExp(r'^\d{4}$').hasMatch(value);
}
