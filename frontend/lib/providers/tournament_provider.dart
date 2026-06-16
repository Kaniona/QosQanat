import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tournament.dart';
import '../services/local_storage_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';

/// Турнирлер (offline mock). Қатысу күйі Hive-та сақталады.
class TournamentNotifier extends StateNotifier<List<Tournament>> {
  TournamentNotifier(this._ref, this._storage) : super(const []) {
    _load();
  }

  final Ref _ref;
  final LocalStorageService _storage;

  void _load() {
    try {
      final list = _storage.getAllTournaments()
        ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
      state = list;
    } catch (_) {
      state = const [];
    }
  }

  Future<void> join(String tournamentId) async {
    final index = state.indexWhere((t) => t.id == tournamentId);
    if (index == -1 || state[index].joined) return;
    final updated = state[index].copyWith(
      joined: true,
      participants: state[index].participants + 1,
    );
    await _storage.saveTournament(updated);
    state = [...state]..[index] = updated;
    await _ref.read(achievementProvider.notifier).unlock('ach_tournament');
  }
}

final tournamentProvider =
    StateNotifierProvider<TournamentNotifier, List<Tournament>>(
  (ref) => TournamentNotifier(ref, ref.watch(storageProvider)),
);
