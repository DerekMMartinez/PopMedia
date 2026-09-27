
import 'package:flutter/material.dart';
import 'package:pop_media/colors.dart';
import 'dart:math' as Math;
import 'dart:async';

import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';

class RecapOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onWelcomeRendered;
  final String year;
  final Color gradientColor;
  final Map<String, dynamic>? recapData;
  
  const RecapOverlay({
    super.key,
    required this.onClose,
    this.onWelcomeRendered,
    required this.year,
    required this.gradientColor,
    this.recapData,
  });

  @override
  State<RecapOverlay> createState() => _RecapOverlayState();
}

class _RecapOverlayState extends State<RecapOverlay> {
  
  int currentSlide = 0;
  Timer? _autoPlayTimer;

  List<_RecapSlideData> get _slides {
    final slides = <_RecapSlideData>[
      _RecapSlideData.welcome(
        text: "Welcome\nto your\n${widget.year}\nPOP\nRewind",
      ),
    ];

    

    final recap = widget.recapData;
    if (recap == null) {
      return slides;
    }

    final topMovieActors = _readTopThree(recap, 'movie_top_3_actors');
    if (topMovieActors.isNotEmpty) {
      final topName = _toTitleCase(topMovieActors.first['name']!);
      slides.add(
        _RecapSlideData.stats(
          heading: 'Your Most Viewed\nMovie Actors',
          subHeading:
              'Top pick: $topName',
          imageUrl: _imageFor(
            recap,
            pictureKey: 'movie_people_pictures',
            personName: topMovieActors.first['name']!,
          ),
        ),
      );
    }

    final topTvActors = _readTopThree(recap, 'tv_top_3_actors');
    if (topTvActors.isNotEmpty) {
      final topName = _toTitleCase(topTvActors.first['name']!);
      slides.add(
        _RecapSlideData.stats(
          heading: 'Your Most Viewed\nTV Actors',
          subHeading:
              'Top pick: $topName',
          imageUrl: _imageFor(
            recap,
            pictureKey: 'tv_people_pictures',
            personName: topTvActors.first['name']!,
          ),
        ),
      );
    }

    final topAuthors = _readTopThree(recap, 'top_3_authors');
    if (topAuthors.isNotEmpty) {
      final topName = _toTitleCase(topAuthors.first['name']!);
      slides.add(
        _RecapSlideData.stats(
          heading: 'Your Most Viewed\nAuthors',
          subHeading:
              'Top pick: $topName',
          imageUrl: _imageFor(
            recap,
            pictureKey: 'book_people_pictures',
            personName: topAuthors.first['name']!,
          ),
        ),
      );
    }

    return slides;
  }

  int get totalSlides => _slides.length;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
  _scheduleNextSlide();
  }

void _scheduleNextSlide() {
  _autoPlayTimer?.cancel();

  final isWelcome = currentSlide == 0;

  final duration = isWelcome
      ? const Duration(seconds: 7)   // 👈 welcome screen
      : const Duration(seconds: 5);  // 👈 other slides

  _autoPlayTimer = Timer(duration, () {
    if (!mounted) return;

    setState(() {
      if (currentSlide < totalSlides - 1) {
        currentSlide++;
      } else {
        currentSlide = 0; // 🔁 loop back to start
      }
    });

    _scheduleNextSlide(); // 🔁 keep looping
  });
}

  void nextSlide() {
    if (currentSlide < totalSlides - 1) {
      setState(() => currentSlide++);
    }
  }

  void prevSlide() {
    if (currentSlide > 0) {
      setState(() => currentSlide--);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTapDown: (details) {
      //   final width = MediaQuery.of(context).size.width;

      //   if (details.globalPosition.dx < width / 2) {
      //     prevSlide();
      //   } else {
      //     nextSlide();
      //   }
      // },
      onTapDown: (details) {
        final width = MediaQuery.of(context).size.width;

        if (details.globalPosition.dx < width / 2) {
          prevSlide();
        } else {
          nextSlide();
        }

        _scheduleNextSlide(); // 👈 reset autoplay timing after user interaction
      },
      onLongPressStart: (_) {
        _autoPlayTimer?.cancel();
      },
      onLongPressEnd: (_) {
        _scheduleNextSlide();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.teamPink, widget.gradientColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.95, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildSlide(currentSlide),
            ),

            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(totalSlides, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= currentSlide
                            ? Colors.white
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(int index) {
    final slides = _slides;
    if (index < 0 || index >= slides.length) {
      return const SizedBox.shrink();
    }

    final slide = slides[index];
    if (slide.type == _RecapSlideType.welcome) {
      return Center(
        key: ValueKey(index),
        child: WelcomeSlide(
          text: slide.text,
          accentColor: widget.gradientColor,
          onRendered: widget.onWelcomeRendered,
        ),
      );
    }

    return Center(
      key: ValueKey(index),
      child: StatsSlide(
        heading: slide.heading,
        subHeading: slide.subHeading,
        imageUrl: slide.imageUrl,
      ),
    );
  }

  List<Map<String, String>> _readTopThree(Map<String, dynamic> recap, String key) {
    final raw = recap[key] as List<dynamic>? ?? const <dynamic>[];
    final output = <Map<String, String>>[];

    for (final entry in raw.take(3)) {
      if (entry is List && entry.length > 1) {
        final name = entry[0].toString().trim();
        final score = entry[1].toString().trim();
        if (name.isNotEmpty) {
          output.add({'name': name, 'score': score});
        }
      }
    }

    return output;
  }

  String _imageFor(
    Map<String, dynamic> recap, {
    required String pictureKey,
    required String personName,
  }) {
    const fallback = 'assets/profile/profilePic.jpg';
    final map = recap[pictureKey] as Map<String, dynamic>?;
    if (map == null) {
      return fallback;
    }

    final exact = map[personName];
    if (exact is String && exact.trim().isNotEmpty) {
      return exact;
    }

    final lower = personName.toLowerCase();
    for (final item in map.entries) {
      if (item.key.toLowerCase() == lower && item.value is String) {
        final value = item.value as String;
        if (value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    return fallback;
  }

  String _toTitleCase(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return input;
    }

    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) {
            return word;
          }
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }
}

enum _RecapSlideType { welcome, stats }

class _RecapSlideData {
  final _RecapSlideType type;
  final String text;
  final String heading;
  final String subHeading;
  final String imageUrl;

  const _RecapSlideData._({
    required this.type,
    required this.text,
    required this.heading,
    required this.subHeading,
    required this.imageUrl,
  });

  const _RecapSlideData.welcome({required String text})
      : this._(
          type: _RecapSlideType.welcome,
          text: text,
          heading: '',
          subHeading: '',
          imageUrl: '',
        );

  const _RecapSlideData.stats({
    required String heading,
    required String subHeading,
    required String imageUrl,
  }) : this._(
          type: _RecapSlideType.stats,
          text: '',
          heading: heading,
          subHeading: subHeading,
          imageUrl: imageUrl,
        );
}

class WelcomeSlide extends StatefulWidget {
  final String text;
  final Color accentColor;
  final VoidCallback? onRendered;

  const WelcomeSlide({
    super.key,
    required this.text,
    required this.accentColor,
    this.onRendered,
  });

  @override
  State<WelcomeSlide> createState() => _WelcomeSlideState();
}


class _WelcomeSlideState extends State<WelcomeSlide>
    with TickerProviderStateMixin {
  bool _useEnhancedTextStyle = false;
  late final AnimationController _motionController;
  bool _hasTriggeredRendered = false;
  
  late final AnimationController _bgController;

  

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // onRendered callback (safe)
      if (!_hasTriggeredRendered) {
        _hasTriggeredRendered = true;

        Future.microtask(() {
          if (mounted) {
            widget.onRendered?.call();
          }
        });
      }

      // Phase 1: text style
      Future.delayed(const Duration(milliseconds: 160), () {
        if (!mounted) return;
        setState(() {
          _useEnhancedTextStyle = true;
        });
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isVisible = ModalRoute.of(context)?.isCurrent ?? true;

    if (isVisible) {
      _bgController.repeat();
    } else {
      _bgController.stop();
    }
  }


  @override
  void dispose() {
    _motionController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _bgController,
          builder: (context, child) {
  final elapsed = _bgController.lastElapsedDuration?.inMilliseconds ?? 0;
  final t = elapsed / 9000;

  final waveA = Math.sin(t * 2 * Math.pi);
  final waveB = Math.cos(t * 2 * Math.pi * 0.8);

  final pinkBlend = Color.lerp(
    AppColors.teamPink,
    widget.accentColor,
    (waveA + 1) / 2,
  )!;

  final accentBlend = Color.lerp(
    AppColors.teamPink,
    AppColors.teamPink,
    (waveB + 1) / 2,
  )!;

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(
          -1 + waveA * 0.2,
          -1 + waveB * 0.2,
        ),
        end: Alignment(
          1 - waveB * 0.2,
          1 - waveA * 0.2,
        ),
        
        colors: [
          const Color(0xFF06050F),
          pinkBlend.withValues(alpha: 0.55),
          accentBlend.withValues(alpha: 0.50),
          const Color(0xFF130B28),
        ],
        stops: const [0.0, 0.32, 0.68, 1.0],
      ),
    ),
  );
}

        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, 0.0),
                  radius: 1.0,
                  colors: [
                    const Color(0xFF04030B).withValues(alpha: 0.35), // dark center
                    widget.accentColor.withValues(alpha: 0.55),     // glowing ring
                    Colors.transparent,  
                  ],
                  stops: const [0.1, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: FloatingText(
              text: widget.text,
              useEnhancedStyle: _useEnhancedTextStyle,
            ),
          ),
        ),
      ],
    );
  }
}

class FloatingText extends StatelessWidget {
  final String text;
  final bool useEnhancedStyle;

  const FloatingText({
    super.key,
    required this.text,
    this.useEnhancedStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 60,
      fontFamily: 'Swanky',
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 1.2,
      height: 1.05,
      shadows: useEnhancedStyle
          ? const [
              Shadow(
                blurRadius: 12,
                color: AppColors.teamGold,
                offset: Offset(0, 0),
              ),
              Shadow(
                blurRadius: 24,
                color: Color(0x66FFFFFF),
                offset: Offset(0, 0),
              ),
            ]
          : const [],
    );

    return Text(
      text,
      textAlign: TextAlign.center,
      style: textStyle,
    );
  }
}

// ignore: must_be_immutable
class StatsSlide extends StatefulWidget {
  String heading;
  String subHeading;
  String imageUrl;
  
  StatsSlide({super.key, required this.heading, required this.subHeading, required this.imageUrl});

  @override
  State<StatsSlide> createState() => _StatsSlideState();
}

class _StatsSlideState extends State<StatsSlide>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _buildAnimation(double start, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _animatedItem(Animation<double> animation, Widget child) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value;

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 40), // slide up
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    final anim1 = _buildAnimation(0.0, 0.4);
    final anim2 = _buildAnimation(0.6, 0.9);
    final anim3 = _buildAnimation(0.9, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        _animatedItem(
          anim1,
          Text(
            widget.heading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontFamily: theme.fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 30),

        _animatedItem(
          anim2,
          Text(
            widget.subHeading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontFamily: theme.fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 30),

        _animatedItem(
          anim3,
          ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Container(
              height: 120,
              width: 120,
              color: Colors.white24,
              child: Center(
                child: Image.network(
                  widget.imageUrl,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/profile/profilePic.jpg',
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          )   
        ),
      ],
    );
  }
}