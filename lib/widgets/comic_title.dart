import 'package:flutter/material.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';

class ComicTitle extends StatelessWidget {
  final String title;
  final double? size;
  final Color? color;

  const ComicTitle({
    super.key,
    required this.title,
    this.size,
    this.color
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // space inside the box
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor, width: 2,),
        color: theme.mainBackgroundColor,
        image: theme.mainBackgroundImage != null
            ? DecorationImage(
                image: AssetImage(theme.mainBackgroundImage!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: theme.fontFamily,
          fontSize: size ?? 20,
          fontWeight: FontWeight.bold,
          color: color ?? theme.primaryColor,
        ),
      ),
    );
  }
}