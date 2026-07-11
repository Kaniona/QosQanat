/// Секундты «м:сс» пішіміне келтіру (сынақ таймері мен ұзақтық белгілері).
String mmss(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
