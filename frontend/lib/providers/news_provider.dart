import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/news.dart';
import 'auth_provider.dart';

/// Жаңалықтар таспасы — offline режімде seed-тен оқылады
/// (болашақта админ жариялайтын арна).
final newsProvider = Provider<List<News>>((ref) {
  try {
    return ref.watch(storageProvider).getAllNews();
  } catch (_) {
    return const [];
  }
});
