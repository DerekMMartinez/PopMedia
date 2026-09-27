import 'package:flutter/material.dart';
import 'package:pop_media/pages/overview_page.dart';
import 'package:pop_media/pages/single_review_page.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/review.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/static_star_rating.dart';
import 'package:provider/provider.dart';


class MediaCard extends StatelessWidget {
  final Media media;
  final MediaCardType type;
  final Review? review;
  final bool hideName;

  const MediaCard({
    super.key,
    required this.media,
    required this.type,
    this.review,
    required this.hideName
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
              (review?.review != null && (type == MediaCardType.myReview || type == MediaCardType.friendReview))
                  ? { if (type == MediaCardType.friendReview) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SingleReviewsPage(media: media, review: review!, type: type)),
                    ),
                    context.read<TtsService>().speak("Opening ${review!.username}'s Review of ${media.name}")
                  }
                    else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SingleReviewsPage(
                            media: media,
                            review: review!,
                            type: type,
                          ),
                        ),
                        (route) => false, 
                      ),
                      context.read<TtsService>().speak("Opening ${review!.username}'s Review of ${media.name}")
                    }
                  }
                  : {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OverviewPage(media: media)),
                    ),
                    context.read<TtsService>().speak("Opening Overivew of ${media.name}")
                  };
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
                child: Image.network( media.image, fit: BoxFit.cover, cacheWidth: 300),
              ),
            ),
            ),
          ),
        ),
        if(type == MediaCardType.myReview || hideName) ...[
          staticStarRating(review!.rating, size:18)],
        if(type == MediaCardType.friendReview && !hideName) ...[
          Column(
            children: [
              Text(
                review!.username,
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              staticStarRating(review!.rating, size:18)
            ]
          )
        ]
      ],
    );
  }
}
