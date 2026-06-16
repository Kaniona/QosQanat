import 'package:flutter/services.dart';

/// Сан, дата және телефон форматтаушылары.
abstract final class Formatters {
  /// 1250 -> «1,250»
  static String number(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// «77012345678» -> «+7 (701) 234-56-78»
  static String phone(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return digits;
    return '+7 (${d.substring(1, 4)}) ${d.substring(4, 7)}-${d.substring(7, 9)}-${d.substring(9)}';
  }

  /// «+7 (701) 234-56-78» -> «+7 (701) ***-**-78»
  static String maskedPhone(String masked) {
    final d = masked.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return masked;
    return '+7 (${d.substring(1, 4)}) ***-**-${d.substring(9)}';
  }

  /// ЖСН: «030712******»
  static String maskedIin(String iin) {
    if (iin.length != 12) return iin;
    return '${iin.substring(0, 6)}******';
  }

  /// Салыстырмалы уақыт: «2 сағат бұрын», «Бүгін», «Кеше», «3 күн бұрын».
  static String relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Жаңа ғана' : '${diff.inMinutes} минут бұрын';
    }
    if (diff.inHours < 12) return '${diff.inHours} сағат бұрын';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final dayDiff = today.difference(day).inDays;
    if (dayDiff == 0) return 'Бүгін';
    if (dayDiff == 1) return 'Кеше';
    return '$dayDiff күн бұрын';
  }

  /// Таймер: 7 -> «0:07»
  static String timer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Телефон енгізу маскасы: +7 (XXX) XXX-XX-XX.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('8')) digits = '7${digits.substring(1)}';
    if (digits.isNotEmpty && !digits.startsWith('7')) digits = '7$digits';
    if (digits.length > 11) digits = digits.substring(0, 11);

    final buf = StringBuffer();
    if (digits.isNotEmpty) buf.write('+7');
    if (digits.length > 1) buf.write(' (${digits.substring(1, digits.length.clamp(1, 4))}');
    if (digits.length >= 4) buf.write(')');
    if (digits.length > 4) buf.write(' ${digits.substring(4, digits.length.clamp(4, 7))}');
    if (digits.length > 7) buf.write('-${digits.substring(7, digits.length.clamp(7, 9))}');
    if (digits.length > 9) buf.write('-${digits.substring(9)}');

    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
