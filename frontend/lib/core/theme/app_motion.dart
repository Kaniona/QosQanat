import 'package:flutter/material.dart';

import '../utils/app_haptics.dart';

/// «Eagle Wings» қозғалыс жүйесі — бүкіл қосымшаның бір ырғағы.
///
/// Премиум gamified апптар (Duolingo, Brawl Stars) сезімі негізінен
/// микро-қозғалыстан туады: басқанда серпімді «squish», табиғи серіппелі
/// қисықтар, бір ұзақтық/қисық тілі. Осы токендер сол тілді орнатады.
abstract final class AppMotion {
  // ---- Ұзақтықтар (150–360 ms — HIG/Material аралығы) ----
  static const Duration instant = Duration(milliseconds: 110);
  static const Duration fast = Duration(milliseconds: 170);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 340);
  static const Duration page = Duration(milliseconds: 320);

  // ---- Қисықтар ----
  /// Кіретін элементтер — баяу тоқтайтын, сенімді.
  static const Curve enter = Curves.easeOutCubic;

  /// Шығатын элементтер — тез басталатын (кірістен ~65% қысқа).
  static const Curve exit = Curves.easeInCubic;

  /// Серпімді «squish» қайту — clay/мармелад сезімі.
  static const Curve spring = Curves.easeOutBack;

  /// Бас тарту мүмкін, тегіс күй ауысуы.
  static const Curve standard = Curves.easeOutCubic;

  /// Жүйе «қозғалысты азайту» (reduce motion) қосулы ма?
  /// VoiceOver/Android батарея үнемдеу режимінде құрметтейміз.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Серпімді басылатын орауыш — кез келген баланы «тірі» етеді.
///
/// Басқанда [pressedScale] дейін серіппемен қысылады, жібергенде қайта
/// серпіледі; жеңіл haptic береді. «Қозғалысты азайту» режимінде масштаб
/// өшеді, бірақ түрту әрекеті сақталады (қолжетімділік).
///
/// Claymorphism тілінде ripple емес, осы «squish» — негізгі түрту белгісі.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.haptic = true,
    this.borderRadius,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Басылғандағы масштаб (0.92 — күшті clay squish, 0.97 — нәзік).
  final double pressedScale;
  final bool haptic;

  /// Семантика/пішін үшін (қажет болса).
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setDown(bool v) {
    if (!_enabled || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduced(context);
    final scale = (_down && _enabled && !reduce) ? widget.pressedScale : 1.0;

    Widget result = AnimatedScale(
      scale: scale,
      duration: _down ? AppMotion.instant : AppMotion.base,
      curve: _down ? AppMotion.standard : AppMotion.spring,
      child: widget.child,
    );

    if (!_enabled) {
      return widget.semanticLabel == null
          ? result
          : Semantics(label: widget.semanticLabel, child: result);
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setDown(true),
        onTapUp: (_) => _setDown(false),
        onTapCancel: () => _setDown(false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) AppHaptics.tap();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                if (widget.haptic) AppHaptics.select();
                widget.onLongPress!();
              },
        child: result,
      ),
    );
  }
}
