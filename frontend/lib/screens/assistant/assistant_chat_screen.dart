import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_haptics.dart';
import '../../models/chat_message.dart';
import '../../models/enums.dart';
import '../../providers/assistant_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/avatar/avatar_base.dart';

/// Серікпен (Бектұр/Назым) мәтіндік чат.
class AssistantChatScreen extends ConsumerStatefulWidget {
  const AssistantChatScreen({super.key});

  @override
  ConsumerState<AssistantChatScreen> createState() =>
      _AssistantChatScreenState();
}

class _AssistantChatScreenState extends ConsumerState<AssistantChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _send([String? preset]) {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    AppHaptics.tap();
    ref.read(assistantChatProvider.notifier).send(text);
    _controller.clear();
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final assistant =
        ref.watch(currentUserProvider)?.assistantType ?? AssistantType.bektur;
    final isNazym = assistant == AssistantType.nazym;
    final accent = isNazym ? AppColors.nazymRose : AppColors.eagleBlue;
    final accentGradient =
        isNazym ? AppColors.heroRose : AppColors.heroEagle;
    final chat = ref.watch(assistantChatProvider);

    // Жаңа хабарлама/typing өзгергенде төменге айналдыру.
    ref.listen(assistantChatProvider, (_, _) => _scrollToBottom());

    final showSuggestions = chat.messages.length <= 1 && !chat.isSending;
    final itemCount = chat.messages.length + (chat.isSending ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: accentGradient,
                shape: BoxShape.circle,
                boxShadow: AppColors.glow(accent, opacity: .35, blur: 12, y: 3),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: AvatarBase(assistant: assistant, size: 34),
              ),
            ),
            const SizedBox(width: AppSpacing.sp3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isNazym ? AppStrings.nazymName : AppStrings.bekturName,
                  style: AppTypography.h3.copyWith(fontSize: 17),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: chat.isSending ? accent : AppColors.successJade,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      chat.isSending
                          ? AppStrings.chatTyping
                          : AppStrings.chatOnline,
                      style: AppTypography.caption.copyWith(
                        color:
                            chat.isSending ? accent : AppColors.successJade,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sp4,
                AppSpacing.sp4,
                AppSpacing.sp4,
                AppSpacing.sp4,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (chat.isSending && index == chat.messages.length) {
                  return _TypingBubble(accent: accent);
                }
                return _MessageBubble(
                  message: chat.messages[index],
                  accent: accent,
                  accentGradient: accentGradient,
                );
              },
            ),
          ),
          if (showSuggestions) _Suggestions(accent: accent, onTap: _send),
          _InputBar(
            controller: _controller,
            focusNode: _inputFocus,
            accent: accent,
            accentGradient: accentGradient,
            enabled: !chat.isSending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

/// Бір хабарлама көпіршігі.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.accent,
    required this.accentGradient,
  });

  final ChatMessage message;
  final Color accent;
  final Gradient accentGradient;

  @override
  Widget build(BuildContext context) {
    final fromUser = message.fromUser;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.xl),
      topRight: const Radius.circular(AppRadius.xl),
      bottomLeft: Radius.circular(fromUser ? AppRadius.xl : AppRadius.sm),
      bottomRight: Radius.circular(fromUser ? AppRadius.sm : AppRadius.xl),
    );
    final fg = fromUser ? AppColors.white : AppColors.ink;

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4,
          vertical: AppSpacing.sp3,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: fromUser ? accentGradient : null,
          color: fromUser
              ? null
              : (message.isError ? AppColors.tintSunset : AppColors.surface),
          borderRadius: radius,
          border: fromUser ? null : Border.all(color: AppColors.border),
          boxShadow: fromUser
              ? AppColors.glow(accent, opacity: .28, blur: 14, y: 5)
              : AppColors.sh1,
        ),
        child: Text(
          message.text,
          style: AppTypography.body.copyWith(color: fg, fontSize: 15),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.12, curve: Curves.easeOut);
  }
}

/// «Жазып жатыр...» нүкте анимациясы.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sp3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp4,
          vertical: AppSpacing.sp4,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl),
            topRight: Radius.circular(AppRadius.xl),
            bottomLeft: Radius.circular(AppRadius.sm),
            bottomRight: Radius.circular(AppRadius.xl),
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.sh1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(delay: (i * 180).ms, duration: 500.ms)
                  .scaleXY(begin: 0.6, end: 1, duration: 500.ms),
            );
          }),
        ),
      ),
    );
  }
}

/// Бастапқы ұсыныс-чиптер.
class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.accent, required this.onTap});

  final Color accent;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      AppStrings.chatSuggest1,
      AppStrings.chatSuggest2,
      AppStrings.chatSuggest3,
      AppStrings.chatSuggest4,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sp4,
        0,
        AppSpacing.sp4,
        AppSpacing.sp2,
      ),
      child: Wrap(
        spacing: AppSpacing.sp2,
        runSpacing: AppSpacing.sp2,
        children: [
          for (final item in items)
            GestureDetector(
              onTap: () => onTap(item),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp4,
                  vertical: AppSpacing.sp3,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .08),
                  borderRadius: AppRadius.rFull,
                  border: Border.all(color: accent.withValues(alpha: .5)),
                ),
                child: Text(
                  item,
                  style: AppTypography.bodySmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Төмендегі енгізу жолы.
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.accent,
    required this.accentGradient,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Color accent;
  final Gradient accentGradient;
  final bool enabled;
  final ValueChanged<String?> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sp4,
        AppSpacing.sp3,
        AppSpacing.sp3,
        AppSpacing.sp3 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(null),
              style: AppTypography.body.copyWith(fontSize: 15),
              decoration: InputDecoration(
                counterText: '',
                hintText: AppStrings.chatHint,
                hintStyle: AppTypography.body
                    .copyWith(color: AppColors.muted, fontSize: 15),
                filled: true,
                fillColor: AppColors.tintBlue,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp4,
                  vertical: AppSpacing.sp3,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.rXl,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.rXl,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.rXl,
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sp2),
          GestureDetector(
            onTap: enabled ? () => onSend(null) : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: enabled ? accentGradient : null,
                color: enabled ? null : AppColors.muted,
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? AppColors.glow(accent, opacity: .4, blur: 14, y: 5)
                    : null,
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
