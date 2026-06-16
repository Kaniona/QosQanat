import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Құпиясөзді хэштеу — ашық мәтін ЕШҚАШАН сақталмайды.
/// Salt ретінде қолданушының id-і пайдаланылады (per-user, тұрақты),
/// сондықтан бірдей құпиясөздер әр қолданушыда әртүрлі хэш береді.
abstract final class PasswordHash {
  static String make(String userId, String password) =>
      sha256.convert(utf8.encode('qosqanat|$userId|$password')).toString();

  static bool verify(String userId, String password, String hash) =>
      make(userId, password) == hash;
}
