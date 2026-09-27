import 'package:flutter/material.dart' hide Theme;
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:provider/provider.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/models/theme.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final theme = context.watch<ThemeController>().currentTheme;
    final currentTheme = controller.currentTheme;

    return PopupMenuButton<Theme>(
      initialValue: currentTheme,
      onSelected: (theme) {
        context.read<TtsService>().speak("Changing Theme to ${theme.name}");
        context.read<ThemeController>().setTheme(theme);
      },
      itemBuilder: (context) => allThemes.map((theme) {
        return PopupMenuItem<Theme>(
          value: theme,
          child: Row(
            children: [
              const SizedBox(width: 8),

              Text(
                theme.name[0].toUpperCase() + theme.name.substring(1),
              ),
            ],
          ),
        );
      }).toList(),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ComicTitle(
            title: currentTheme.name,
            size: 15,
          ),
          Icon(Icons.arrow_drop_down, color: theme.primaryColor),
        ],
      ),
    );
  }
}