import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/core/utils/formatters.dart';

void main() {
  group('Сан форматтаушы', () {
    test('мыңдықты үтірмен бөледі', () {
      expect(Formatters.number(0), '0');
      expect(Formatters.number(100), '100');
      expect(Formatters.number(1250), '1,250');
      expect(Formatters.number(1000000), '1,000,000');
    });
  });

  group('Телефон форматтаушы', () {
    test('11 цифрды маскаға келтіреді', () {
      expect(Formatters.phone('77012345678'), '+7 (701) 234-56-78');
    });

    test('цифр саны дұрыс емес болса өзгеріссіз қайтарады', () {
      expect(Formatters.phone('7701234'), '7701234');
    });

    test('маскаланған телефон ортасын жасырады', () {
      expect(
        Formatters.maskedPhone('+7 (701) 234-56-78'),
        '+7 (701) ***-**-78',
      );
    });
  });

  group('ЖСН маскасы', () {
    test('алғашқы 6 цифрды қалдырып қалғанын жасырады', () {
      expect(Formatters.maskedIin('030712500178'), '030712******');
    });

    test('12 таңба емес болса өзгеріссіз қалады', () {
      expect(Formatters.maskedIin('0307'), '0307');
    });
  });

  group('Таймер форматтаушы', () {
    test('секундты m:ss түрінде көрсетеді', () {
      expect(Formatters.timer(7), '0:07');
      expect(Formatters.timer(75), '1:15');
      expect(Formatters.timer(600), '10:00');
    });
  });

  group('Салыстырмалы уақыт', () {
    test('бір минуттан аз — «Жаңа ғана»', () {
      expect(Formatters.relativeTime(DateTime.now()), 'Жаңа ғана');
    });

    test('минуттар мен сағаттар дұрыс саналады', () {
      final now = DateTime.now();
      expect(
        Formatters.relativeTime(now.subtract(const Duration(minutes: 30))),
        '30 минут бұрын',
      );
      expect(
        Formatters.relativeTime(now.subtract(const Duration(hours: 3))),
        '3 сағат бұрын',
      );
    });

    test('кешегі күн — «Кеше»', () {
      // Кеше түскі шама — тәуліктің қай уақытында тест жүрсе де нақ бір
      // күнтізбелік күн бұрын болады (бұрын days:1+hours:2 түн жарымында
      // екі күнге өтіп, флаки болатын).
      final now = DateTime.now();
      final yesterdayNoon =
          DateTime(now.year, now.month, now.day).subtract(const Duration(hours: 12));
      expect(Formatters.relativeTime(yesterdayNoon), 'Кеше');
    });
  });
}
