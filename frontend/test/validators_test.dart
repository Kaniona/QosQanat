import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/core/utils/validators.dart';

void main() {
  group('Телефон валидаторы', () {
    test('дұрыс +7 нөмір қабылданады', () {
      expect(Validators.isValidPhone('+7 (701) 234-56-78'), isTrue);
    });

    test('8-ден басталатын нөмір қабылданбайды (7 болуы керек)', () {
      expect(Validators.isValidPhone('8 (701) 234-56-78'), isFalse);
    });

    test('цифр саны жетпесе қабылданбайды', () {
      expect(Validators.isValidPhone('+7 (701) 234-56'), isFalse);
    });
  });

  group('ЖСН валидаторы (ҚР checksum)', () {
    test('дұрыс checksum-мен ЖСН қабылданады', () {
      // 030712 (туған күн) + 5 (ғасыр/жыныс) + 0017 + 8 (бақылау цифры).
      expect(Validators.isValidIin('030712500178'), isTrue);
    });

    test('бақылау цифры қате болса қабылданбайды', () {
      expect(Validators.isValidIin('030712500179'), isFalse);
    });

    test('12 цифр емес мән қабылданбайды', () {
      expect(Validators.isValidIin('12345'), isFalse);
      expect(Validators.isValidIin('03071250017a'), isFalse);
    });

    test('жарамсыз ай/күн қабылданбайды', () {
      expect(Validators.isValidIin('031312500170'), isFalse); // ай 13
      expect(Validators.isValidIin('030700500170'), isFalse); // күн 00
    });

    test('ғасыр/жыныс коды 1-6 диапазонынан тыс болса қабылданбайды', () {
      expect(Validators.isValidIin('030712700170'), isFalse); // код 7
    });
  });

  group('Аты-жөні валидаторы', () {
    test('кемінде екі сөзден тұратын есім қабылданады', () {
      expect(Validators.isValidFullName('Бектұр Нұртөре'), isTrue);
    });

    test('бір сөз қабылданбайды', () {
      expect(Validators.isValidFullName('Бектұр'), isFalse);
    });

    test('бір әріптік сөз қабылданбайды', () {
      expect(Validators.isValidFullName('А Бектұр'), isFalse);
    });
  });

  group('Құпиясөз ережелері', () {
    test('минимум ұзындық, цифр, бас әріп бөлек тексеріледі', () {
      expect(Validators.hasMinLength('1234567'), isFalse);
      expect(Validators.hasMinLength('12345678'), isTrue);
      expect(Validators.hasDigit('Abcdefgh'), isFalse);
      expect(Validators.hasDigit('Abcdefg1'), isTrue);
      expect(Validators.hasUppercase('abcdefg1'), isFalse);
      expect(Validators.hasUppercase('Аbcdefg1'), isTrue);
    });

    test('passwordScore 0..3 балл береді', () {
      expect(Validators.passwordScore(''), 0);
      expect(Validators.passwordScore('abc'), 0);
      expect(Validators.passwordScore('abcdefgh'), 1); // тек ұзындық
      expect(Validators.passwordScore('Abcde123'), 3); // бәрі бар
    });

    test('isStrongPassword тек 3 балл болғанда true', () {
      expect(Validators.isStrongPassword('Abcde123'), isTrue);
      expect(Validators.isStrongPassword('abcde123'), isFalse);
    });
  });

  group('QQ-ID және OTP', () {
    test('QQ-XXXXXXXXX форматы (кіші әріп те қабылданады)', () {
      expect(Validators.isValidQqId('QQ-ABC123XYZ'), isTrue);
      expect(Validators.isValidQqId('qq-abc123xyz'), isTrue);
      expect(Validators.isValidQqId('QQ-ABC123'), isFalse); // қысқа
      expect(Validators.isValidQqId('ABC123XYZ'), isFalse); // префикссіз
    });

    test('OTP — дәл 4 цифр', () {
      expect(Validators.isValidOtp('1234'), isTrue);
      expect(Validators.isValidOtp('123'), isFalse);
      expect(Validators.isValidOtp('12a4'), isFalse);
    });
  });
}
