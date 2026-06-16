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

  bool get isActive =>
      DateTime.now().isAfter(startsAt) && DateTime.now().isBefore(endsAt);

  Tournament copyWith({bool? joined, int? participants}) => Tournament(
        id: id,
        title: title,
        description: description,
        prizePool: prizePool,
        startsAt: startsAt,
        endsAt: endsAt,
        participants: participants ?? this.participants,
        joined: joined ?? this.joined,
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
      );
}
