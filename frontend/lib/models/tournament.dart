/// Турнир моделі (offline режімде mock деректермен).
class Tournament {
  const Tournament({
    required this.id,
    required this.title,
    required this.description,
    required this.prizePool,
    required this.startsAt,
    required this.endsAt,
    this.participants = 0,
    this.joined = false,
    this.played = false,
    this.rank = 0,
    this.bestScore = 0,
  });

  final String id;
  final String title;
  final String description;

  /// Жүлде қоры, теңге.
  final int prizePool;
  final DateTime startsAt;
  final DateTime endsAt;
  final int participants;
  final bool joined;

  /// Оқушы турнир раундын ойнап шықты ма.
  final bool played;

  /// Соңғы орны (1-ден басталады; 0 — әлі ойналмаған).
  final int rank;

  /// Үздік нәтиже (дұрыс жауап саны).
  final int bestScore;

  bool get isActive =>
      DateTime.now().isAfter(startsAt) && DateTime.now().isBefore(endsAt);

  Tournament copyWith({
    bool? joined,
    int? participants,
    bool? played,
    int? rank,
    int? bestScore,
  }) =>
      Tournament(
        id: id,
        title: title,
        description: description,
        prizePool: prizePool,
        startsAt: startsAt,
        endsAt: endsAt,
        participants: participants ?? this.participants,
        joined: joined ?? this.joined,
        played: played ?? this.played,
        rank: rank ?? this.rank,
        bestScore: bestScore ?? this.bestScore,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'prize_pool': prizePool,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'participants': participants,
        'joined': joined,
        'played': played,
        'rank': rank,
        'best_score': bestScore,
      };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        prizePool: json['prize_pool'] as int? ?? 0,
        startsAt: DateTime.tryParse(json['starts_at'] as String? ?? '') ??
            DateTime.now(),
        endsAt: DateTime.tryParse(json['ends_at'] as String? ?? '') ??
            DateTime.now(),
        participants: json['participants'] as int? ?? 0,
        joined: json['joined'] as bool? ?? false,
        played: json['played'] as bool? ?? false,
        rank: json['rank'] as int? ?? 0,
        bestScore: json['best_score'] as int? ?? 0,
      );
}

/// Турнир кестесінің бір жолы (оқушы немесе mock қарсылас).
class TournamentEntrant {
  const TournamentEntrant(this.name, this.score, {this.isMe = false});
  final String name;
  final int score;
  final bool isMe;
}
