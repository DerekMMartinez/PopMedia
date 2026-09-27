import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class MediaBadgeLockedPopUp extends StatelessWidget {
  final Media media;
  final MediaCardType type;
  final String username;

  const MediaBadgeLockedPopUp({super.key, required this.media, required this.username, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(4, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ComicTitle(title: 'Media Badge Locked'),
            const SizedBox(height: 5),
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.4,
                  child: Image.network(media.image, height: 125),
                ),
                Icon(
                  Icons.lock, size:60, color: Colors.black
                )
              ],
            ),
            const SizedBox(height: 12),
            if(type == MediaCardType.myReview)...[
              Text(
                "Earn By:\n 1. Click The Use Photo Button\n2. Upload Poster/Cover Photo Of ${media.name}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ]
            else...[
              Text(
                "${username} has not earned the badge for ${media.name}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
            const SizedBox(height: 5),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const ComicTitle(title: "Close", size: 12),
            ),
              Text(
                "**This feature is not avaliable on select mobile devices download the app or visit web on computer to resolve",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
          ],
      )
    )));
  }
}