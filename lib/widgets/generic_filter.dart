import 'package:flutter/material.dart';
import 'package:pop_media/widgets/comic_title.dart';

class GenericFilter extends StatelessWidget{
  final String selectedType;
  final ValueChanged<String> onChanged;
  final bool userShown;

  const GenericFilter(
    {
      super.key,
      required this.selectedType,
      required this.onChanged,
      this.userShown = false,
    });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selectedType,
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'All', child: Text('All')),
        if(userShown) 
          const PopupMenuItem(value: 'Users', child: Text('Users')),
        if(userShown)
          const PopupMenuItem(value: 'Playlists', child: Text('Playlists')),
        const PopupMenuItem(value: 'Books', child: Text('Books')),
        const PopupMenuItem(value: 'Movies', child: Text('Movies')),
        const PopupMenuItem(value: 'TV Shows', child: Text('TV Shows')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ComicTitle(title: selectedType, size: 15),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}