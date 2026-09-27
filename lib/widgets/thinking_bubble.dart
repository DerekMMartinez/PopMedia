import 'package:flutter/material.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';

class ThinkingBubble extends StatelessWidget {
  final String initialText;
  final TextEditingController controller;

  const ThinkingBubble({
    super.key,
    required this.initialText,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Optional: max width for larger screens
    final bubbleWidth = screenWidth * 0.95 > 400 ? 400.0 : screenWidth * 0.95;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: bubbleWidth,
        minHeight: 250,
      ),
      child: AspectRatio(
        aspectRatio: 1.5, // adjust to match your bubble image ratio
        child: Stack(
          children: [
            // Background cloud image
            Image.asset(
              'assets/backgrounds/thought_bubble.png',
              width: bubbleWidth,
              fit: BoxFit.cover,
            ),
            // Scrollable text inside the bubble
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(44, 50, 44, 58),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: TextFormField(
                      maxLines: null,
                      onTap: () {context.read<TtsService>().speak("Editing Review");},
                      controller: controller,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: theme.fontFamily,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: initialText, // <-- this stays as hint text
                        hintStyle: TextStyle(
                          fontSize: 16,
                          fontFamily: theme.fontFamily,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}