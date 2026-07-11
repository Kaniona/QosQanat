import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../data/curriculum.dart';
import '../models/chat_message.dart';
import '../models/enums.dart';
import '../services/assistant_service.dart';
import 'auth_provider.dart';
import 'mastery_provider.dart';

/// Серікпен чаттың күйі.
class AssistantChatState {
  const AssistantChatState({
    this.messages = const [],
    this.isSending = false,
  });

  final List<ChatMessage> messages;

  /// Серік жауабын дайындап жатыр (typing индикаторы).
  final bool isSending;

  bool get isEmpty => messages.isEmpty;

  AssistantChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
  }) =>
      AssistantChatState(
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
      );
}

class AssistantChatNotifier extends StateNotifier<AssistantChatState> {
  AssistantChatNotifier(this._ref) : super(const AssistantChatState()) {
    _greet();
  }

  final Ref _ref;
  final AssistantService _service = AssistantService();

  /// Чат ашылғанда серіктің алғашқы сәлемі.
  void _greet() {
    final name = _ref.read(currentUserProvider)?.firstName ?? '';
    state = state.copyWith(
      messages: [ChatMessage.assistant(AppStrings.chatGreeting(name))],
    );
  }

  /// Оқушының хабарламасын жіберіп, серіктің жауабын алады.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final user = _ref.read(currentUserProvider);
    final assistant = user?.assistantType ?? AssistantType.bektur;

    // Оқушы хабарламасын қосып, typing күйіне көшу.
    final withUser = [...state.messages, ChatMessage.user(trimmed)];
    state = state.copyWith(messages: withUser, isSending: true);

    // Бейімделу контексті — коуч офлайн режимде нақты әлсіз тұсты атайды.
    final mastery = _ref.read(masteryProvider);
    final weak = mastery.weakest;
    final weakTopic = weak == null
        ? null
        : Curriculum.nodeById('${weak.skillId}_n0')?.moduleTitle;

    try {
      final answer = await _service.reply(
        assistant: assistant,
        studentId: user?.qosqanatId ?? '',
        studentName: user?.firstName ?? '',
        grade: user?.grade ?? 7,
        history: withUser,
        prompt: trimmed,
        weakTopic: weakTopic,
        dueCount: mastery.dueCount,
      );
      state = state.copyWith(
        messages: [...state.messages, ChatMessage.assistant(answer)],
        isSending: false,
      );
    } catch (_) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage.assistant(AppStrings.chatError, isError: true),
        ],
        isSending: false,
      );
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

final assistantChatProvider =
    StateNotifierProvider<AssistantChatNotifier, AssistantChatState>(
  (ref) => AssistantChatNotifier(ref),
);
