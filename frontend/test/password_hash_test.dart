import 'package:flutter_test/flutter_test.dart';
import 'package:qosqanat/core/utils/password_hash.dart';

void main() {
  group('PasswordHash', () {
    test('детерминистік — бірдей кіріс бірдей хэш береді', () {
      expect(
        PasswordHash.make('user-1', 'Qupia123'),
        PasswordHash.make('user-1', 'Qupia123'),
      );
    });

    test('SHA-256 — 64 таңбалы hex', () {
      final hash = PasswordHash.make('user-1', 'Qupia123');
      expect(hash.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });

    test('per-user salt — бірдей құпиясөз әр қолданушыда басқа хэш', () {
      expect(
        PasswordHash.make('user-1', 'Qupia123'),
        isNot(PasswordHash.make('user-2', 'Qupia123')),
      );
    });

    test('verify дұрыс құпиясөзге true, қатеге false', () {
      final hash = PasswordHash.make('user-1', 'Qupia123');
      expect(PasswordHash.verify('user-1', 'Qupia123', hash), isTrue);
      expect(PasswordHash.verify('user-1', 'qupia123', hash), isFalse);
      expect(PasswordHash.verify('user-2', 'Qupia123', hash), isFalse);
    });
  });
}
