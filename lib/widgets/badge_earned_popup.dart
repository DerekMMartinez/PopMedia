import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/colors.dart';
import 'package:pop_media/models/badge.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:pop_media/widgets/alpha_masked_image.dart';

class BadgeEarnedPopUp extends StatefulWidget {
  final Badge badge;
  final bool confetti;

  const BadgeEarnedPopUp({super.key, required this.badge, required this.confetti});

   @override
  _BadgeEarnedPopUp createState() => _BadgeEarnedPopUp();
}

class _BadgeEarnedPopUp extends State<BadgeEarnedPopUp> {  
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;

    return Dialog(
      key: const Key('badge_earned'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 400,
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
                  ComicTitle(title: 'Badge Earned:'),
                  const SizedBox(height: 5),
                  Text(
                    widget.badge.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: theme.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  widget.badge.imageUrl != null && widget.badge.imageUrl!.startsWith('http')
                  ? AlphaMaskedImage(imageUrl: widget.badge.imageUrl!, width: 128, height: 150)
                  : Image.asset(
                      widget.badge.imageUrl!,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    widget.badge.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: theme.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextButton(
                    key: const Key('close_badge_earned'),
                    onPressed: () => Navigator.pop(context),
                    child: const ComicTitle(title: "Close", size: 12),
                  ),
                ],
              ),
            ),
          ),
          if(widget.confetti) ...[
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.teamBlue,
                AppColors.teamGold,
                AppColors.teamPink
              ],
            ),
          ]
        ],
      ),
    );
  }
}