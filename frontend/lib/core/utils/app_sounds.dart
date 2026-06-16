import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Ойын дыбыстары — баптаулардағы «Дыбыс» қосқышына бағынады.
/// SettingsNotifier жүктелгенде/өзгергенде [enabled] синхрондалады
/// (AppHaptics үлгісі).
///
/// Дыбыстар бір-бірін жиі баса алады (жауап → монета → level up), сондықтан
/// шағын плеер пулы қолданылады. Кез келген платформалық қате (мыс. Linux-та
/// аудио backend жоқ) демоны құлатпауы үшін жұтылады.
abstract final class AppSounds {
  static bool enabled = true;

  static const int _poolSize = 3;
  static final List<AudioPlayer> _pool = [];
  static int _next = 0;

  static void _play(String asset, {double volume = 1.0}) {
    if (!enabled) return;
    try {
      if (_pool.isEmpty) {
        for (var i = 0; i < _poolSize; i++) {
          _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
        }
      }
      final player = _pool[_next];
      _next = (_next + 1) % _poolSize;
      player
          .play(AssetSource('sounds/$asset'), volume: volume)
          .catchError((Object e) {
        debugPrint('AppSounds: $asset ойнатылмады — $e');
      });
    } catch (e) {
      debugPrint('AppSounds: $asset — $e');
    }
  }

  /// Батырма басу (жұмсақ шертпе).
  static void tap() => _play('tap.wav', volume: 0.6);

  /// Дұрыс жауап.
  static void correct() => _play('correct.wav');

  /// Қате жауап.
  static void wrong() => _play('wrong.wav', volume: 0.8);

  /// Монета/сатып алу/сыйлық.
  static void coin() => _play('coin.wav');

  /// Жаңа деңгей.
  static void levelUp() => _play('levelup.wav');

  /// Жеңіс (сессия/батл).
  static void win() => _play('win.wav');

  /// Жеңіліс / сәтсіз сессия.
  static void lose() => _play('lose.wav', volume: 0.8);
}
