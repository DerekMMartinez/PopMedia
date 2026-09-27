import 'package:flutter/material.dart';
import 'package:pop_media/pages/single_playlist_page.dart';
import 'package:pop_media/models/playlist.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';


class PlaylistCard extends StatelessWidget {
  final Playlist playlist;

  const PlaylistCard({
    super.key,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context) {
  final theme = context.watch<ThemeController>().currentTheme;
    return Column(
    children: [ 
      Padding(
          padding: const EdgeInsets.all(2.5),
          child: GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SinglePlaylistPage(playlist: playlist)),
                (route) => false, 
              );
            },
            child: Card(
                shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            margin: EdgeInsets.zero,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: 130,  
              child: AspectRatio(
                aspectRatio: 2 / 3,   // same 2:3 poster ratio
                child: Image.network( playlist.imageUrl, fit: BoxFit.cover, cacheWidth: 300),
              ),
            ),
            ),
          ),
        ),
          Column(
            children: [
              Text(
                playlist.name,
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ]
          )
        ]
    );
  }
}
