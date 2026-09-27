import 'package:flutter/material.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class MediaFilter extends StatelessWidget{
  final String selectedType;
  final ValueChanged<String> onChanged;

  const MediaFilter(
    {
      super.key,
      required this.selectedType,
      required this.onChanged,
    });
    
      static get context => null;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;

    return PopupMenuButton<String>(
      initialValue: selectedType,
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(key: Key('filter_all'),  value: 'All', child: Text('All')),
        PopupMenuItem(key: Key('filter_books'), value: 'Books', child: Text('Books')),
        PopupMenuItem(key: Key('filter_movies'), value: 'Movies', child: Text('Movies')),
        PopupMenuItem(key: Key('filter_tv'), value: 'TV Shows', child: Text('TV Shows')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ComicTitle(title: selectedType, size: 15),
          Icon(Icons.arrow_drop_down, color: theme.primaryColor),
        ],
      ),
    );
  }
}