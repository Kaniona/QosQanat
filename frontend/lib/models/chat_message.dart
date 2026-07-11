/// Серікпен чаттағы бір хабарлама.
///
/// Чат тарихы әзірге тек жадыда (offline-first); серверге сақталмайды.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    required this.createdAt,
    this.isError = false,
  });

  /// Оқушы жіберген хабарлама фабрикасы.
  factory ChatMessage.user(String text) => ChatMessage(
        text: text,
        fromUser: true,
        createdAt: DateTime.now(),
      );

  /// Серіктің жауабы фабрикасы.
  factory ChatMessage.assistant(String text, {bool isError = false}) =>
      ChatMessage(
        text: text,
        fromUser: false,
        createdAt: DateTime.now(),
        isError: isError,
      );

  final String text;

  /// true — оқушы жазды, false — серік жауап берді.
  final bool fromUser;
  final DateTime createdAt;

  /// Жауап қате күйінде келді (мыс. желі/прокси қатесі).
  final bool isError;
}
