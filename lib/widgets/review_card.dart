import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/review.dart';
import 'package:pop_media/pages/profile_page.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_controller.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/static_star_rating.dart';
import 'package:pop_media/widgets/chat_bubble.dart';
import 'package:pop_media/pages/single_review_page.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:provider/provider.dart';

class ReviewCard extends StatefulWidget {
  final Media media;
  final Review review;
  final int maxLines;

  const ReviewCard({
    super.key,
    required this.media,
    required this.review,
    this.maxLines = 6,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _showSpoilers = false;


  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    
    String username = widget.review.username.length > 20
    ? '${widget.review.username.substring(0, 20)}...'
    : widget.review.username;
    return CustomPaint(
      painter: ChatBubblePainter(
        borderColor: Colors.black,
        borderWidth: 1.5,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () {
                    if(widget.review.username != widget.review.uid){ //Not from the APIS
                      context.read<TtsService>().speak("Opening ${widget.review.username}'s Profile");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(userId: widget.review.uid, adminAccess: false),
                        ),
                      );
                    }
                    else{
                      context.read<TtsService>().speak("Imported Review");
                      showDialog(
                      context: context,
                      barrierDismissible: true, 
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: Colors.transparent,
                          contentPadding: EdgeInsets.zero,
                          content: Container(
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
                          padding: const EdgeInsets.all(16), 
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Imported Review',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: TextStyle(color: theme.primaryColor),
                                  children: [
                                    if (widget.media.id.startsWith('b')) ...[
                                      const TextSpan(
                                        text: 'This review is imported from \n Google Plays API',
                                      ),
                                    ] else ...[
                                      const TextSpan(
                                        text: 'This review is imported from \n The TMDB API',
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(
                                  'Close',
                                  style: TextStyle(color: theme.primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      },
                    );
                  }
                },
                child: Text(
                  username,
                  style: TextStyle(
                    fontFamily: theme.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ),
                Consumer<TTSController>(
                  builder: (context, ttsController, _) {
                    if (!ttsController.ttsEnabled) return SizedBox.shrink();
                    return IconButton(
                      icon: Icon(Icons.volume_up),
                      onPressed: () {
                        context.read<TtsService>().speak("${widget.review.username}'s Review: ${widget.review.rating}");
                        if(!widget.review.spoilers || _showSpoilers){
                          context.read<TtsService>().speak("${widget.review.review}");
                        }
                        else{
                          context.read<TtsService>().speak("Mark show spoiler to hear review");
                        }
                      },
                    );
                  },
                ),
                Spacer(),
                staticStarRating(widget.review.rating),
                Spacer(),
                if (widget.review.spoilers && (widget.review.uid != UserSession.uid))
                  TextButton(
                    onPressed: () {
                      setState(() {
                        context.read<TtsService>().speak("Show spoiler ${!_showSpoilers}");
                        _showSpoilers = !_showSpoilers;
                      });
                    },
                    child: Text(
                      _showSpoilers ? 'Hide Spoiler' : 'Show Spoiler',
                      style: TextStyle(color: Colors.black, fontFamily: theme.fontFamily),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.review.review != null && widget.review.review!.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Text(
                          widget.review.review!,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: theme.fontFamily,
                          ),
                          maxLines: widget.maxLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.review.spoilers && !_showSpoilers && (widget.review.uid != UserSession.uid))
                          Positioned.fill(
                            child: ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  color: Colors.black.withOpacity(0.1),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      context.read<TtsService>().speak("Opening ${widget.review.username}'s Review");
                      widget.review.uid == UserSession.uid
                        ? Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SingleReviewsPage(
                              media: widget.media,
                              review: widget.review,
                              type: MediaCardType.myReview,
                            ),
                          ),
                          (route) => false,
                        )
                        : Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleReviewsPage(
                            media: widget.media,
                            review: widget.review,
                            type: MediaCardType.friendReview,
                          ),
                        ),
                      );
                    },
                  ),
                ]
              )
            ]
          )
        )
      );
    }
  }