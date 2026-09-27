import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/models/badge.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/widgets/alpha_masked_image.dart';
import 'package:pop_media/widgets/badge_earned_popup.dart';
import 'package:pop_media/widgets/badge_locked_popup.dart';
import 'package:provider/provider.dart';

class BadgeCard extends StatelessWidget {
  final Badge badge;
  final isEarned;

  const BadgeCard({
    super.key,
    required this.badge,
    required this.isEarned
  });

  @override
  Widget build(BuildContext context) {
    return Column(
    children: [ 
      Padding(
          padding: const EdgeInsets.all(2.5),
          child: GestureDetector(
            onTap: () {
              if(isEarned){
                context.read<TtsService>().speak("Badge Earned: ${badge.name}");
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => BadgeEarnedPopUp(
                    badge: badge,
                    confetti: false,
                  )
                );
              }
              else{
                context.read<TtsService>().speak("Badge Locked: ${badge.name}");
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => BadgeLockedPopUp(
                    badge: badge,
                  )
                );
              }
            },
            child: Opacity(
              opacity: isEarned ? 1.0 : 0.4,
              child: Card(
                color: Colors.transparent,
                elevation: 0,
                child: badge.imageUrl != null && badge.imageUrl!.startsWith('http')
                  ? AlphaMaskedImage(imageUrl: badge.imageUrl!, height: 150, width: 128)
                  : Image.asset(
                      badge.imageUrl!,
                      height: 150,
                      fit: BoxFit.contain,
                    )
              ),
            ),
          ),
        ),
        ]
    );
  }
}
