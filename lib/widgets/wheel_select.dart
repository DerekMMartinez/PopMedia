import 'dart:async';
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:pop_media/colors.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/models/theme.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:provider/provider.dart';

class WheelSelect extends StatefulWidget {
  final List<Media> media;

  const WheelSelect({super.key, required this.media});

  @override
  _WheelSelectState createState() => _WheelSelectState();
}

class _WheelSelectState extends State<WheelSelect> {  
  @override
  Widget build(BuildContext context) {
      final theme = context.watch<ThemeController>().currentTheme;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            context.read<TtsService>().speak("Opened Wheel Select");
            _showWheelPopup(context, theme);
          },
          child: Image.asset(
            theme.wheelIcon,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )),
          Text('Spin Select', style: TextStyle(fontSize: 11, color: theme.primaryColor),)
      ]);
    }

    void _showWheelPopup(BuildContext context, theme) {
      // Create a fresh stream controller for this dialog
      final StreamController<int> selected = StreamController<int>();
      int? currentIndex;
      final shuffledMedia = getWheelItems(widget.media);

      // Schedule first spin after dialog builds
      Future.delayed(Duration.zero, () {
        final initialIndex = DateTime.now().millisecondsSinceEpoch % shuffledMedia.length;
        currentIndex = initialIndex;
        selected.add(initialIndex);
      });

      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: theme.mainBackgroundColor,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                border: Border.all(color: theme.primaryColor, width: 2),
                image: theme.mainBackgroundImage != null
                    ? DecorationImage(
                        image: AssetImage(theme.mainBackgroundImage!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.white.withOpacity(theme.imageOpactity),
                          BlendMode.lighten,
                        ),
                      )
                    : null,
              ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  child: Text(
                    "SPIN SELECTION",
                    style: TextStyle(
                      fontFamily: 'Swanky',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: theme.primaryColor
                    ),
                  ),
                ),

                Expanded(
                  child: FortuneWheel(
                    selected: selected.stream,
                    items: [
                      for (var media in shuffledMedia)
                        FortuneItem(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              media.image,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.2),
                                    Colors.black.withOpacity(0.6),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  media.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onAnimationEnd: () {
                      if (currentIndex != null) {
                        _showResultDialog(context, shuffledMedia[currentIndex!], theme);
                      }
                    },
                  ),
                ),
                TextButton(
                  child: ComicTitle(title: "Spin!"),
                  onPressed: () {
                    context.read<TtsService>().speak("Spinning Again!");
                    final randomIndex = DateTime.now().millisecondsSinceEpoch % shuffledMedia.length;
                    currentIndex = randomIndex;
                    selected.add(randomIndex);
                  },
                ),
              ],
            ),
          ),
        ),
      ).then((_) {
        selected.close();
      });
  }


void _showResultDialog(BuildContext context, Media media, Theme theme) {
  final controller = ConfettiController(duration: const Duration(seconds: 2));
  controller.play();
  context.read<TtsService>().speak("Spin Select Resulted in ${media.name}");
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => 
    
    Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.8, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: 275,
              padding: const EdgeInsets.all(16),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 30),

                  const Text(
                    "YOU GOT!",
                    style: TextStyle(
                      fontFamily: 'Swanky',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    media.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: theme.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  MediaCard(media: media, type: MediaCardType.overview, hideName: false),
                  Text("Click to Learn More", style: TextStyle(color: Colors.grey)),

                  const SizedBox(height: 16),


                  TextButton(
                    child: ComicTitle(title: "Close"),
                    onPressed: () {
                      context.read<TtsService>().stop();
                      context.read<TtsService>().speak("Closed Spin Selection ${media.name}");
                      controller.dispose();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

          ConfettiWidget(
            confettiController: controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.teamBlue,
              AppColors.teamGold,
              AppColors.teamPink
            ],
          ),
        ],
      ),
    ),
    ),
  );
  }
}


List<Media> getWheelItems(List<Media> fullList) {
  fullList.shuffle();
  return fullList.take(6).toList();
}