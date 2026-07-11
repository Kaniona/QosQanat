import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tournament.dart';
import '../services/local_storage_service.dart';
import 'achievement_provider.dart';
import 'auth_provider.dart';
import 'game_provider.dart';

/// Турнир ойналған соңғы нәтиже (нәтиже экранына беріледі).
class TournamentResult {
  const TournamentResult({
    required this.rank,
    required this.fieldSize,
    required this.score,
    required this.total,
    required this.coins,
    required this.akyl,
    required this.board,
  });

  final int rank;
  final int fieldSize;
  final int score;
  final int total;
  final int coins;
  final int akyl;
  final List<TournamentEntrant> board;

  bool get isPodium => rank <= 3;
}

const List<String> _mockNames = [
  'Айдос', 'Дана', 'Ерлан', 'Гүлназ', 'Нұрлан', 'Аружан', 'Бекзат', 'Әсем',
  'Тимур', 'Мадина', 'Санжар', 'Жанна', 'Олжас', 'Камила', 'Дамир', 'Ділназ',
  'Алмас', 'Ажар', 'Ринат', 'Сабина', 'Ермек', 'Зере', 'Қанат', 'Інжу',
];

/// Турнирлер (offline mock). Қатысу + ОЙНАУ күйі Hive-та сақталады.
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

  /// Детерминистік кесте (id-ден тұқымдалады) — оқушы + mock қарсыластар.
  List<TournamentEntrant> _board(Tournament t, int myScore, int total) {
    final r = Random(t.id.hashCode);
    const field = 23;
    final myName = _ref.read(currentUserProvider)?.firstName ?? 'Мен';
    final entrants = <TournamentEntrant>[
      for (var i = 0; i < field; i++)
        TournamentEntrant(
          _mockNames[(r.nextInt(_mockNames.length) + i) % _mockNames.length],
          // Қоңырау тәрізді: 3 кездейсоқтың ортасы (орта деңгей жиі).
          ((r.nextInt(total + 1) +
                      r.nextInt(total + 1) +
                      r.nextInt(total + 1)) /
                  3)
              .round(),
        ),
      TournamentEntrant(myName, myScore, isMe: true),
    ];
    entrants.sort((a, b) {
      if (a.score != b.score) return b.score.compareTo(a.score);
      // Тең болса — оқушы жоғары тұрады (көтермелеу).
      return a.isMe ? -1 : (b.isMe ? 1 : 0);
    });
    return entrants;
  }

  (int, int) _prizeFor(int rank) => switch (rank) {
        1 => (250, 60),
        2 || 3 => (140, 35),
        <= 10 => (70, 15),
        _ => (25, 0),
      };

  /// Турнир раундын ойнау нәтижесін есептеу: кесте, орын, марапат.
  Future<TournamentResult> play(
    String tournamentId, {
    required int correct,
    required int total,
  }) async {
    final index = state.indexWhere((t) => t.id == tournamentId);
    if (index == -1) {
      return TournamentResult(
          rank: 0, fieldSize: 0, score: correct, total: total,
          coins: 0, akyl: 0, board: const []);
    }
    final t = state[index];
    final board = _board(t, correct, total);
    final rank = board.indexWhere((e) => e.isMe) + 1;
    // Марапат тек АЛҒАШҚЫ ойында — қайта ойнау арқылы монета фармдауға жол
    // жоқ (қайта ойнағанда нәтиже мен кесте көрсетіле береді, сыйлық 0).
    final firstPlay = !t.played;
    final (coins, akyl) = firstPlay ? _prizeFor(rank) : (0, 0);

    final game = _ref.read(gameProvider.notifier);
    if (coins > 0) await game.addCoins(coins);
    if (akyl > 0) await game.addAkylPoints(akyl);

    final updated = t.copyWith(
      played: true,
      // Сақталатын орын — ең үздігі (қайта ойнау нашарлатпайды).
      rank: firstPlay || (rank < t.rank && rank > 0) ? rank : t.rank,
      bestScore: correct > t.bestScore ? correct : t.bestScore,
    );
    await _storage.saveTournament(updated);
    state = [...state]..[index] = updated;
    await _ref.read(achievementProvider.notifier).evaluate();

    return TournamentResult(
      rank: rank,
      fieldSize: board.length,
      score: correct,
      total: total,
      coins: coins,
      akyl: akyl,
      board: board,
    );
  }
}

final tournamentProvider =
    StateNotifierProvider<TournamentNotifier, List<Tournament>>(
  (ref) => TournamentNotifier(ref, ref.watch(storageProvider)),
);
