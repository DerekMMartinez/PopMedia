import 'package:flutter/material.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/playlist.dart';
import 'package:pop_media/models/review.dart';
import 'package:pop_media/models/user.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';

class TextPopUp extends StatelessWidget {
  final String text;
  final String type;
  final int maxLines;
  final Media? media;
  final User? user;
  final Review? review;
  final Playlist? playlist;


  const TextPopUp({
    super.key,
    required this.text, 
    required this.type,
    required this.maxLines,
    this.media,
    this.user,
    this.review,
    this.playlist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    Widget? dialogTitle;

    if(type == "Overview"){
      dialogTitle = Text("${media!.name} Overview");
    }
    else if(type == "Profile"){
      dialogTitle = Text(user!.name + "Bio");
    }
    else if(type == "Seasons"){
      dialogTitle = Text(review!.username + "'s" + " Overall Review");
    }
    else if(type == "Genre"){
      dialogTitle = Text("${media!.name} Genres");
    }
    else if(type == "Playlist"){
      dialogTitle = Text("${playlist!.name} Description");
    }
    

    
    return LayoutBuilder(
      builder:
        (context, constraints) {
          final textSpan = TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: theme.fontFamily,
              fontSize: 14,
            ),
          );

          final textPainter =
              TextPainter(
            text: textSpan,
            maxLines: maxLines,
            textDirection:
                TextDirection.ltr,
          )..layout(
                  maxWidth:
                      constraints.maxWidth);

          final isOverflowing =
              textPainter
                  .didExceedMaxLines;

          return Stack(
            children: [
              Text(
                text,
                textAlign: type == "Genre" ? TextAlign.center : null,
                maxLines: maxLines,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: type == "Profile" ? theme.primaryColor : Colors.black,
                  fontFamily: theme.fontFamily,
                  fontSize: 14,
                ),
              ),
              if (isOverflowing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child:
                      GestureDetector(
                    onTap: () {
                      context.read<TtsService>().speak("${dialogTitle}, ${text}");
                      showDialog(
                        context:
                            context,
                        builder: (context) =>
                          AlertDialog(
                            title:dialogTitle,    
                            content:
                              SingleChildScrollView(
                                child: Text(text),
                              ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => {
                                    context.read<TtsService>().stop(),
                                    Navigator.of(context).pop(),
                                },
                              child:
                                  const Text(
                                      'Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding:
                          const EdgeInsets
                              .only(
                                  left: 4),
                      color:
                          theme.mainBackgroundColor,
                      child:
                        Icon(
                          Icons.arrow_drop_down,
                          color:theme.accentColor,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
  }
}