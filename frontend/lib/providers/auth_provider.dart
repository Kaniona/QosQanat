import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/password_hash.dart';
import '../core/utils/validators.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../services/demo_seeder.dart';
import '../services/local_storage_service.dart';
import '../services/mock_data_service.dart';

enum AuthStatus { idle, loading, authenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.idle,
    this.user,
    this.errorMessage,
    this.pendingOtp,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  /// Offline режімдегі имитацияланған SMS коды.
  final String? pendingOtp;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? pendingOtp,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingOtp: pendingOtp ?? this.pendingOtp,
    );
  }
}

/// Кіру / тіркелу / сеанс — бәрі локальді Hive арқылы.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage) : super(const AuthState());

  final LocalStorageService _storage;

  /// Splash-та шақырылады: сақталған сеансты қалпына келтіру.
  Future<void> restoreSession() async {
    try {
      final id = _storage.currentUserId;
      if (id == null) return;
      final user = _storage.getUser(id);
      if (user != null) {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  /// Offline кіру: телефон форматы + құпиясөз хэшін салыстыру.
  /// Хэші жоқ ескі аккаунт алғашқы кіруде осы құпиясөзбен бекітіледі.
  Future<bool> login(String phone, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!Validators.isValidPhone(phone)) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Телефон нөмірі толық емес',
        );
        return false;
      }
      if (password.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Құпиясөзді енгіз',
        );
        return false;
      }
      var user = _storage.findUserByPhone(phone);
      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Бұл нөмірмен аккаунт табылмады',
        );
        return false;
      }
      final hash = user.passwordHash;
      if (hash == null) {
        // Миграция: ескі аккаунтқа құпиясөз осы кіруде бекітіледі.
        user = user.copyWith(
          passwordHash: PasswordHash.make(user.id, password),
        );
        await _storage.saveUser(user);
      } else if (!PasswordHash.verify(user.id, password, hash)) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Телефон немесе құпиясөз қате',
        );
        return false;
      }
      await _storage.setCurrentUserId(user.id);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Кіру кезінде қате: $e',
      );
      return false;
    }
  }

  /// Жаңа қолданушы тіркеу: QQ-ID генерациялау + құпиясөз хэші +
  /// Hive-ға сақтау + кіру.
  Future<bool> register({
    required String fullName,
    required String phone,
    required String iin,
    required String password,
    required String city,
    required String school,
    required int grade,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (_storage.findUserByPhone(phone) != null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Бұл нөмір тіркеліп қойған',
        );
        return false;
      }
      final id = MockDataService.generateUserId();
      final user = User(
        id: id,
        qosqanatId: MockDataService.generateQqId(),
        fullName: fullName.trim(),
        phone: phone,
        iin: iin,
        passwordHash: PasswordHash.make(id, password),
        city: city,
        school: school.trim(),
        grade: grade,
        lastLoginDate: DateTime.now(),
        currentStreak: 1,
        createdAt: DateTime.now(),
      );
      await _storage.saveUser(user);
      await _storage.setCurrentUserId(user.id);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Тіркелу кезінде қате: $e',
      );
      return false;
    }
  }

  /// Презентация/көрме режимі: бір түрткімен дайын демо-аккаунтқа кіру
  /// (телефон/құпиясөз теруді қажет етпейді). Аккаунт тұқымдалмаса — false.
  Future<bool> loginAsDemo() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      var user = _storage.getUser(DemoSeeder.demoUserId);
      if (user == null) {
        // Сирек жағдай (тұқым жоғалса) — қайта тұқымдап көреміз.
        await DemoSeeder.instance.reset();
        user = _storage.getUser(DemoSeeder.demoUserId);
      }
      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Демо аккаунт дайын емес',
        );
        return false;
      }
      await _storage.setCurrentUserId(user.id);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Демоға кіру қатесі: $e',
      );
      return false;
    }
  }

  /// Демо прогресін қалпына келтіріп, ағымдағы күйді жаңарту (стенд reset).
  Future<void> resetDemo() async {
    await DemoSeeder.instance.reset();
    refreshUser();
  }

  /// Серік таңдау (тіркелуден кейін) + 100 монета сыйлық.
  Future<void> chooseAssistant(AssistantType type) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(
      assistantType: type,
      assistantChangedAt: DateTime.now(),
      coins: user.coins + 100,
    );
    await _storage.saveUser(updated);
    state = state.copyWith(user: updated);
  }

  /// Құпиясөзді қалпына келтіру (offline имитация): mock 4 таңбалы код.
  Future<String?> requestPasswordReset(String phone) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!Validators.isValidPhone(phone)) return null;
      if (_storage.findUserByPhone(phone) == null) return null;
      // Offline режім: кодты детерминистік генерациялаймыз.
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final code =
          ((digits.hashCode.abs() % 9000) + 1000).toString();
      state = state.copyWith(pendingOtp: code);
      return code;
    } catch (_) {
      return null;
    }
  }

  bool verifyOtp(String code) => code == state.pendingOtp;

  /// Жаңа құпиясөздің хэшін сақтап, аккаунтты нақты жаңартады.
  Future<bool> resetPassword(String phone, String newPassword) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!Validators.isStrongPassword(newPassword)) return false;
    try {
      final user = _storage.findUserByPhone(phone);
      if (user == null) return false;
      await _storage.saveUser(user.copyWith(
        passwordHash: PasswordHash.make(user.id, newPassword),
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Сыртқы провайдерлер (game, shop, task) жаңартқан қолданушыны
  /// қайта оқу — HUD пен профиль синхронда болады.
  void refreshUser() {
    final id = state.user?.id;
    if (id == null) return;
    final fresh = _storage.getUser(id);
    if (fresh != null) {
      state = state.copyWith(user: fresh);
    }
  }

  /// Профиль өрістерін жаңарту (сурет, аты, серік т.б.).
  Future<void> updateUser(User updated) async {
    await _storage.saveUser(updated);
    state = state.copyWith(user: updated);
  }

  Future<void> logout() async {
    await _storage.setCurrentUserId(null);
    state = const AuthState();
  }
}

final storageProvider = Provider<LocalStorageService>(
  (ref) => LocalStorageService.instance,
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(storageProvider)),
);

/// Ағымдағы қолданушы (null = кірмеген).
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authProvider).user,
);
