import 'package:flutter/material.dart';
import 'package:pop_media/colors.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';

class StarRatingWidget extends StatefulWidget {
  final int starCount;
  final double initialRating;
  final Color? color;
  final double? starSize;
  final Function(double)? onRatingChanged;

  const StarRatingWidget({
    super.key,
    this.starCount = 5,
    this.initialRating = 0.0,
    this.color,
    this.starSize,
    this.onRatingChanged,
  });

  @override
  State<StarRatingWidget> createState() => _StarRatingWidgetState();
}

class _StarRatingWidgetState extends State<StarRatingWidget> {
  late double rating;

  @override
  void initState() {
    super.initState();
    rating = widget.initialRating;
  }

  double _calculateRatingFromTap(int index, TapDownDetails details, double starSize) {
    final tapX = details.localPosition.dx;

    // If tapped on the left half → .5 rating
    if (tapX < starSize / 2) {
      return index + 0.5;
    } else {
      return index + 1.0;
    }
  }

  Widget buildStar(int index) {
  final theme = context.watch<ThemeController>().currentTheme;
  final double starSize = widget.starSize ?? 50.0;

  Widget foreground;
  if (index + 1 <= rating) {
    // full star
    foreground = Icon(
      Icons.star,
      size: starSize * 0.9,
      color: widget.color ?? AppColors.teamGold,
    );
  } else if (index + 0.5 <= rating) {
    // half star
    foreground = Icon(
      Icons.star_half,
      size: starSize * 0.9,
      color: widget.color ?? AppColors.teamGold,
    );
  } else {
    foreground = const SizedBox.shrink();
  }


    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        double newRating = _calculateRatingFromTap(index, details, starSize);

        setState(() {
          rating = newRating;
        });

        if (widget.onRatingChanged != null) {
          widget.onRatingChanged!(newRating);
        }
      },
      child: SizedBox(
        width: starSize,
        height: starSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.star_outline,
              size: starSize,
              color: theme.primaryColor,
            ),
            foreground,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.starCount, buildStar),
    );
  }
}
