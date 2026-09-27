import 'package:flutter/material.dart';

class PodiumWidget extends StatefulWidget {
  final String imageFirst;
  final String textFirst;
  final String statFirst;
  final String imageSecond;
  final String textSecond;
  final String statSecond;
  final String imageThird;
  final String textThird;
  final String statThird;
  final Duration startDelay;
  final bool shouldAnimate;

  const PodiumWidget({
    super.key,
    required this.imageFirst,
    required this.textFirst,
    required this.statFirst,
    required this.imageSecond,
    required this.textSecond,
    required this.statSecond,
    required this.imageThird,
    required this.textThird,
    required this.statThird,
    this.startDelay = Duration.zero,
    this.shouldAnimate = true,
  });

   @override
  _PodiumWidgetState createState() => _PodiumWidgetState();
}

class _PodiumWidgetState extends State<PodiumWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _barFactor;
  bool _hasStarted = false;

  void _startAnimationIfNeeded() {
    if (_hasStarted || !widget.shouldAnimate) {
      return;
    }

    _hasStarted = true;
    if (widget.startDelay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.startDelay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _barFactor = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );
    _startAnimationIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PodiumWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shouldAnimate && widget.shouldAnimate) {
      _startAnimationIfNeeded();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPodiumImage(String imagePath, double imageSize) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        height: imageSize,
        width: imageSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/profile/profilePic.jpg',
          height: imageSize,
          width: imageSize,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      imagePath,
      height: imageSize,
      width: imageSize,
      fit: BoxFit.cover,
    );
  }

  Widget _buildPodium(
    double height,
    Gradient gradient,
    String imagePath,
    String personName,
    String statText,
    double heightFactor,
    double podiumWidth,
    double imageSize,
    double statFontSize,
    double nameFontSize,
  ) {
    return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Transform.translate(
              offset: Offset(0, (1 - heightFactor) * height),
              child: Column(
                children: [
                  SizedBox(
                    width: podiumWidth,
                    child: Text(
                      statText,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Simple',
                        fontFamilyFallback: const ['Zen'],
                          fontSize: statFontSize,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  ClipRSuperellipse(
                    borderRadius: BorderRadius.circular(50),
                    child: _buildPodiumImage(imagePath, imageSize),
                  ),
                  SizedBox(
                    width: podiumWidth,
                    child: SizedBox(
                      height: nameFontSize * 1.4,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          personName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontFamily: 'Simple',
                            fontFamilyFallback: const ['Zen'],
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: podiumWidth,
              height: height,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: podiumWidth,
                  height: height * heightFactor,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: gradient,
                    ),
                  ),
                ),
              ),
            ),

          ],
        );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _hasStarted ? 1.0 : 0.0,
      child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          const regularGap = 6.0;
          final availableWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final gap = availableWidth < 340 ? 4.0 : regularGap;
          final computedWidth = (availableWidth - (gap * 2)) / 3;
          final podiumWidth = computedWidth.clamp(84.0, 125.0);
          final imageSize = (podiumWidth - 24).clamp(60.0, 100.0);
          final statFontSize = (podiumWidth * 0.11).clamp(10.0, 12.0);
          final nameFontSize = (podiumWidth * 0.118).clamp(11.0, 13.0);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPodium(
                40,
                const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 236, 234, 234),
                    Color.fromARGB(255, 101, 98, 98),
                  ],
                ),
                widget.imageSecond,
                widget.textSecond,
                widget.statSecond,
                _barFactor.value,
                podiumWidth,
                imageSize,
                statFontSize,
                nameFontSize,
              ),
              SizedBox(width: gap),
              _buildPodium(
                65,
                const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 248, 225, 132),
                    Color.fromARGB(255, 129, 103, 0),
                  ],
                ),
                widget.imageFirst,
                widget.textFirst,
                widget.statFirst,
                _barFactor.value,
                podiumWidth,
                imageSize,
                statFontSize,
                nameFontSize,
              ),
              SizedBox(width: gap),
              _buildPodium(
                30,
                const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 231, 104, 58),
                    Color.fromARGB(255, 82, 49, 38),
                  ],
                ),
                widget.imageThird,
                widget.textThird,
                widget.statThird,
                _barFactor.value,
                podiumWidth,
                imageSize,
                statFontSize,
                nameFontSize,
              )
            ],
          );
        },
      ),
    ));
  }
}