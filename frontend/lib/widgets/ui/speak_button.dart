import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/tts_service.dart';

/// «Дауыстап оқу» батырмасы — TTS қолжетімді болғанда ғана көрінеді
/// (капабилитиге байланысты; жоқ болса бос орын). Бір түрткі — оқу/тоқтату.
class SpeakButton extends StatefulWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.color,
    this.tooltip = 'Дауыстап оқу',
  });

  /// Оқылатын мәтін (сұрақ/сабақ). Әр build-та жаңарып отыруы мүмкін.
  final String text;
  final Color? color;
  final String tooltip;

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton> {
  final _tts = TtsService.instance;

  @override
  void initState() {
    super.initState();
    // Капабилитиді анықтау (бір рет, фонда). Дайын болса батырма пайда болады.
    _tts.ensureInit();
  }

  @override
  void dispose() {
    // Экраннан шыққанда оқуды тоқтатамыз.
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.eagleBlue;
    return ValueListenableBuilder<bool>(
      valueListenable: _tts.available,
      builder: (context, available, _) {
        if (!available) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: _tts.speaking,
          builder: (context, speaking, _) {
            return IconButton(
              tooltip: widget.tooltip,
              onPressed: () {
                if (speaking) {
                  _tts.stop();
                } else {
                  _tts.speak(widget.text);
                }
              },
              icon: Icon(
                speaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                color: color,
              ),
            );
          },
        );
      },
    );
  }
}
