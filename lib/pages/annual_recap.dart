import 'dart:async';

import 'package:flutter/material.dart' hide Theme;
import 'package:pop_media/colors.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/badge_card.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/line_chart.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:pop_media/widgets/podium.dart';
import 'package:pop_media/widgets/recap_overlay.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';

class _AnimateOnFirstVisible extends StatefulWidget {
  final String visibilityId;
  final Widget Function(bool hasBeenVisible) builder;

  const _AnimateOnFirstVisible({
    required this.visibilityId,
    required this.builder,
  });

  @override
  State<_AnimateOnFirstVisible> createState() => _AnimateOnFirstVisibleState();
}

class _AnimateOnFirstVisibleState extends State<_AnimateOnFirstVisible> {
  bool _hasBeenVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.visibilityId),
      onVisibilityChanged: (info) {
        if (!_hasBeenVisible && info.visibleFraction > 0.05) {
          setState(() {
            _hasBeenVisible = true;
          });
        }
      },
      child: widget.builder(_hasBeenVisible),
    );
  }
}


// ignore: must_be_immutable
class AnnualRecap extends StatefulWidget {
  String year;

  AnnualRecap({super.key, required this.year});

  @override
  State<AnnualRecap> createState() => _AnnualRecapState();
}

class _AnnualRecapState extends State<AnnualRecap>{

  Map<String, dynamic>? _recapData;
  String? _loadError;
  bool showRecap = false;
  bool _isRecapOverlayReady = false;

  Future<Map<String, dynamic>> _loadRecapForSelectedYear() async {
    return DataService.getAnnualRecapForUser(
      uid: UserSession.uid!,
      year: widget.year,
    );
  }

  Widget getInfoBox(
    theme_border_color, 
    theme_background_color, 
    theme_background_image,
    theme_font_family, 
    String display_text){
    final normalizedText = display_text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme_border_color, width: 2,),
        color: theme_background_color,
        image: theme_background_image != null
            ? DecorationImage(
                image: AssetImage(theme_background_image!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Center (
        child:Text(
          normalizedText,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            // Use a stable readable face for paragraph text to avoid custom-font kerning artifacts.
            fontFamily: 'Simple',
            fontFamilyFallback: theme_font_family is String ? [theme_font_family] : null,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  String combineText(String prefix, String value, String suffix){
    final parts = [prefix.trim(), value.trim(), suffix.trim()]
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  String toTitleCase(String input) {
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

  String getInfoTextFromRecap(
    Map<String, dynamic> recap_data, {
    required String dataKey,
    required String prefix,
    String suffix = '',
    String fallbackValue = '0',
  }) {
    try {
      final recap = recap_data;
      final value = recap[dataKey];
      final displayValue = value == null ? fallbackValue : value.toString();
      return combineText(prefix, displayValue, suffix);
    } catch (_) {
      return 'Could not load recap info.';
    }
  }

  String getTopInfoTextFromRecap({
    required Map<String, dynamic> recapData,
    required String top3DataKey,
    String prefix = '',
    String infix = ' ',
    String suffix = '',
  }) {
    try {
      final recap = recapData;
      final topThree = recap[top3DataKey] as List<dynamic>? ?? const <dynamic>[];

      if (topThree.isEmpty) {
        return 'No data found.';
      }


      final firstEntry = topThree.first;
      if (firstEntry is! List || firstEntry.length <= 1) {
        return 'No data found.';
      }

      final name = toTitleCase(firstEntry[0].toString());
      final score = firstEntry[1].toString();

      if (name.isEmpty || name == 'N/A') {
        return 'No data found.';
      }

      return combineText(prefix, '$name, $infix $score', suffix);
    } catch (_) {
      return 'Could not load recap info.';
    }
  }
  
  Widget getMonthlyDataChart(
    String title,
    Color lineColor,
    Map<String, dynamic> recap_data,
    String data_key, {
    Duration startDelay = Duration.zero,
  }){
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2,),
              gradient: LinearGradient(
                colors: [Color.lerp(lineColor, Colors.white, 0.3)!, lineColor, Color.lerp(lineColor, Colors.black, 0.3)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ComicTitle(title: title),
              SizedBox(height: 15),
              SizedBox(
                child: Builder(
                  builder: (context) {
                    final monthlyDataRaw =
                        recap_data[data_key] as List<dynamic>? ??
                            const <dynamic>[];

                    final monthlyData = monthlyDataRaw
                        .map((value) => (value as num).toDouble())
                        .toList();

                    return _AnimateOnFirstVisible(
                      visibilityId: 'chart_$data_key',
                      builder: (hasBeenVisible) => LineChartWidget(
                        monthlyData: monthlyData,
                        startDelay: startDelay,
                        shouldAnimate: hasBeenVisible,
                        lineColor: Colors.black,
                      ),
                    );
                  },
                ),
              ),
            ]
          ),
        ),
        ),
      ],
    );
  }

  Widget getTopThreePodium(
    String title,
    Map<String, dynamic> recap_data,
    String top_3_key,
    String photo_key,
    List<String> stat_texts, {
    Duration startDelay = Duration.zero,
  }){
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 218, 216, 216),
              border: Border.all(color: Colors.black, width: 2,),
            ),
          
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ComicTitle(title: title),
              SizedBox(height: 45),
              SizedBox(
                child: Builder(
                  builder: (context) {
                    final topThreeRaw = recap_data[top_3_key] as List<dynamic>? ?? const <dynamic>[];
                    final peoplePictures = recap_data[photo_key] as Map<String, dynamic>? ?? const <String, dynamic>{};
                    const fallbackImage = 'assets/profile/profilePic.jpg';

                    String getNameAt(int index) {
                      if (index >= topThreeRaw.length) return 'N/A';
                      final entry = topThreeRaw[index];
                      if (entry is List && entry.isNotEmpty && entry.first is String) {
                        return toTitleCase(entry.first as String);
                      }
                      return 'N/A';
                    }

                    String getStatAt(int index) {
                      final customText = index < stat_texts.length ? stat_texts[index] : '';

                      String formatScore(num score) {
                        final scoreDouble = score.toDouble();
                        if (scoreDouble % 1 == 0) {
                          return scoreDouble.toInt().toString();
                        }

                        return scoreDouble
                            .toStringAsFixed(2)
                            .replaceFirst(RegExp(r'0+$'), '')
                            .replaceFirst(RegExp(r'\.$'), '');
                      }

                      String singularizeFirstWord(String label) {
                        final trimmed = label.trim();
                        if (trimmed.isEmpty) {
                          return trimmed;
                        }

                        final parts = trimmed.split(RegExp(r'\s+'));
                        var first = parts.first;
                        final lower = first.toLowerCase();

                        const irregularSingulars = {
                          'movies': 'movie',
                          'shows': 'show',
                          'series': 'series',
                          'species': 'species',
                        };

                        String applyOriginalCasing(String original, String updated) {
                          if (original.isEmpty || updated.isEmpty) {
                            return updated;
                          }

                          final isCapitalized =
                              original[0] == original[0].toUpperCase();
                          if (!isCapitalized) {
                            return updated;
                          }

                          return '${updated[0].toUpperCase()}${updated.substring(1)}';
                        }

                        if (irregularSingulars.containsKey(lower)) {
                          first = applyOriginalCasing(first, irregularSingulars[lower]!);
                        } else if (lower.endsWith('ies') && first.length > 3) {
                          first = '${first.substring(0, first.length - 3)}y';
                        } else if (lower.endsWith('s') && !lower.endsWith('ss') && first.length > 1) {
                          first = first.substring(0, first.length - 1);
                        }

                        parts[0] = first;
                        return parts.join(' ');
                      }

                      if (index >= topThreeRaw.length) {
                        return customText;
                      }

                      final entry = topThreeRaw[index];
                      if (entry is List && entry.length > 1 && entry[1] is num) {
                        final score = (entry[1] as num);
                        final scoreText = formatScore(score);
                        final isSingular = (score.toDouble() - 1.0).abs() < 0.000001;
                        final label = customText.isEmpty
                            ? ''
                            : (isSingular ? singularizeFirstWord(customText) : customText);

                        return label.isEmpty ? scoreText : '$scoreText $label';
                      }

                      return customText;
                    }

                    String getImageFor(String name) {
                      if (name == 'N/A') return fallbackImage;
                      final image = peoplePictures[name.toLowerCase()];
                      if (image is String && image.isNotEmpty && image != 'N/A') {
                        return image;
                      }
                      return fallbackImage;
                    }

                    final firstName = getNameAt(0);
                    final secondName = getNameAt(1);
                    final thirdName = getNameAt(2);
                    final firstStat = getStatAt(0);
                    final secondStat = getStatAt(1);
                    final thirdStat = getStatAt(2);

                    return _AnimateOnFirstVisible(
                      visibilityId: 'podium_$top_3_key',
                      builder: (hasBeenVisible) => PodiumWidget(
                        imageFirst: getImageFor(firstName),
                        textFirst: firstName,
                        statFirst: firstStat,
                        imageSecond: getImageFor(secondName),
                        textSecond: secondName,
                        statSecond: secondStat,
                        imageThird: getImageFor(thirdName),
                        textThird: thirdName,
                        statThird: thirdStat,
                        startDelay: startDelay,
                        shouldAnimate: hasBeenVisible,
                      ),
                    );
                  },
                ),
              ),
            ]
          ),
        ),
        ),
      ],
    );
  }

  Widget getTopThreeInfoBoxFB(
    theme_border_color,
    theme_background_color,
    theme_background_image,
    theme_font_family, 
    Map<String, dynamic> recap_data, 
    String top_3_key, 
    prefix, 
    infix, 
    suffix,
    ) {
    return _AnimateOnFirstVisible(
      visibilityId: 'info_top_$top_3_key',
      builder: (hasBeenVisible) => AnimatedOpacity(
        opacity: hasBeenVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Text(
                    getTopInfoTextFromRecap(
                      recapData: recap_data,
                      top3DataKey: top_3_key,
                      prefix: prefix,
                      infix: infix,
                      suffix: suffix,
                    ),
                  ),
      ),
    );
  }

Widget getStringInfoBoxFB(
    theme_border_color,
    theme_background_color,
    theme_background_image,
    theme_font_family, 
    Map<String, dynamic> recap_data, 
    String data_key, 
    prefix, 
    suffix
    ) {
    return _AnimateOnFirstVisible(
      visibilityId: 'info_value_$data_key',
      builder: (hasBeenVisible) => AnimatedOpacity(
        opacity: hasBeenVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Text(
                    getInfoTextFromRecap(
                      recap_data,
                      dataKey: data_key,
                      prefix: prefix,
                      suffix: suffix,
                    ),
                    
                    ),
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final data = await _loadRecapForSelectedYear();

      if (!mounted) return;

      setState(() {
        _recapData = data;
        _loadError = null;
        showRecap = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadError = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    showRecap = true;
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    final hasRecapData = _recapData != null;
    final Map<String, dynamic> recapData = _recapData ?? {};
    final showRecapContent = _isRecapOverlayReady;
    Duration nextAnimDelay() => Duration.zero;
    
    return Scaffold(
      backgroundColor: theme.mainBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.topBarColor,
        foregroundColor: theme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/profilePage',
                (route) => false,
              );
            }
          },
        ),
        title: Image.asset(
          theme.logo,
          height: 60,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: theme.mainBackgroundImage != null
                ? Opacity(
                    opacity: theme.imageOpactity,
                    child: Image.asset(
                      theme.mainBackgroundImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    color: theme.mainBackgroundColor,
                  ),
          ),
          // Content on top of the background
          if (!hasRecapData && _loadError == null)
            const Center(child: CircularProgressIndicator())
          else if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load recap. $_loadError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else if (showRecapContent)
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 5, right:5, left: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ComicTitle(title: "${widget.year} Recap"),
                      Spacer(),
                      ElevatedButton( 
                        onPressed: () {setState(() {
                              showRecap = true;
                              _isRecapOverlayReady = false;
                            });},
                        style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                      side: BorderSide(color: Colors.black, width: 2),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    elevation: 0,
                                  ),
                                  
                        child: ComicTitle(title: 'Replay Overview >', size: 14),
                      ),
                    ],
                  ),
                   SizedBox(height: 10),

                  //-------INTRO-------------//
                  // getTopThreeWidget(theme, _recap_data, ''),
                  Text(
                      'WELCOME to your ${widget.year} RECAP!',
                      textAlign: TextAlign.center,
                        style: TextStyle(
                                fontFamily: 'Swanky',
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                                letterSpacing: 1.2,
                              ),
                    ),
                  SizedBox(height: 10),
                  // ================== STATS BY TYPE ======================//
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:[
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: AppColors.teamPink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              recapData['movie_total_watched'].toString(),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "movies",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ]
                        )
                      ),
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: widget.year == '2024' ? AppColors.teamTeal: AppColors.teamGold,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              recapData['tv_total_watched'].toString(),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "seasons",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ]
                        )
                      ),
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          color: widget.year == '2024' ? AppColors.teamGreen : AppColors.teamBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              recapData['total_books_read'].toString(),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "books",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ]
                        )
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // ================== MOVIE STATS ======================//
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.teamPink,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/movie.png',
                              width: 60,
                              height: 60,
                            ),
                            const SizedBox(width: 5),
                            ComicTitle(title: "Your Movie Data", size: 30),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ComicTitle(title: "Top Movies"),
                        SizedBox( 
                          height: 230,
                          child: recapData['favorite_movies'].length == 0 ? Center(child: Text("No Movies Reviewed This Year", textAlign: TextAlign.center,)) : 
                          ListView.builder( 
                            scrollDirection: Axis.horizontal, 
                            itemCount: recapData['favorite_movies'].length, 
                            itemBuilder: (context, index) { 
                              final review = recapData['favorite_movies'][index][0]; 
                              final media = recapData['favorite_movies'][index][1]; 
                            return Padding( 
                              padding: const EdgeInsets.only(right: 12), 
                              child: MediaCard( 
                                media: media, 
                                review: review, 
                                type: MediaCardType.myReview, 
                                hideName: true, ), 
                            ); }, ), ),],),),
                        const SizedBox(height: 10),
                        // Number of movies watched chart
                        getMonthlyDataChart(
                          'Movies By Month',
                          AppColors.teamPink,
                          recapData,
                          "movie_per_month",
                          startDelay: nextAnimDelay(),
                        ),
                        const SizedBox(height: 10),
                        // Top three liked movie actors podium
                        getTopThreePodium(
                          "Top Movie Actors",
                          recapData,
                          'movie_top_3_weighted_actors',
                          'movie_people_pictures',
                          ['Stars', 'Stars', 'Stars'],
                          startDelay: nextAnimDelay(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  //======================== TV STATS ======================//
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.year == '2024' ? AppColors.teamTeal: AppColors.teamGold,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[
                      Image.asset(
                          'assets/icons/tv.png',
                          width: 60,
                          height: 60,
                        ),
                      SizedBox(width: 5),
                      ComicTitle(title: "Your TV Data", size: 30),
                    ]
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  ComicTitle(title: "Top TV"),
                  SizedBox( 
                    height: 230, 
                    child: recapData['favorite_tv'].length == 0 ? Center(child: Text("No TV Shows Reviewed This Year", textAlign: TextAlign.center,)) : 
                    ListView.builder( 
                      scrollDirection: Axis.horizontal, 
                      itemCount: recapData['favorite_tv'].length, 
                      itemBuilder: (context, index) { 
                        final review = recapData['favorite_tv'][index][0]; 
                        final media = recapData['favorite_tv'][index][1]; 
                      return Padding( 
                        padding: const EdgeInsets.only(right: 12), 
                        child: MediaCard( 
                          media: media, 
                          review: review, 
                          type: MediaCardType.myReview, 
                          hideName: true, ), 
                      ); }, ), ),],),),
                  SizedBox(height: 10),
                  // Number of TV shows watched chart
                  getMonthlyDataChart(
                    'Seasons By Month',
                    widget.year == '2024' ? AppColors.teamTeal: AppColors.teamGold,
                    recapData,
                    "tv_per_month",
                    startDelay: nextAnimDelay(),
                  ),                                     
                  SizedBox(height: 10),
                  // top three liked tv actors podium
                  getTopThreePodium(
                    'Top TV Actors',
                    recapData,
                    'tv_top_3_weighted_actors', 
                    'tv_people_pictures', 
                    ['Stars', 'Stars', 'Stars'],
                    startDelay: nextAnimDelay(),
                  ),  ])),                
                  SizedBox(height: 20),

                  //-------BOOKS STATS-------------//
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.year == '2024' ? AppColors.teamGreen : AppColors.teamBlue,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[
                      Image.asset(
                          'assets/icons/book.png',
                          width: 60,
                          height: 60,
                        ),
                      SizedBox(width: 5),
                      ComicTitle(title: "Your Book Data", size: 30),
                    ]
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.year == '2024' ? AppColors.teamGreen : AppColors.teamBlue,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  ComicTitle(title: "Top Books"),
                  SizedBox( 
                    height: 230,
                    child: recapData['favorite_books'].length == 0 ? Center(child: Text("No Books Reviewed This Year", textAlign: TextAlign.center,)) : 
                    ListView.builder( 
                      scrollDirection: Axis.horizontal, 
                      itemCount: recapData['favorite_books'].length, 
                      itemBuilder: (context, index) { 
                        final review = recapData['favorite_books'][index][0]; 
                        final media = recapData['favorite_books'][index][1]; 
                      return Padding( 
                        padding: const EdgeInsets.only(right: 12), 
                        child: MediaCard( 
                          media: media, 
                          review: review, 
                          type: MediaCardType.myReview, 
                          hideName: true, ), 
                      ); }, ), ),],),),
                  SizedBox(height: 10),
                  // Number of books read chart
                  getMonthlyDataChart(
                    'Books By Month',
                    widget.year == '2024' ? AppColors.teamGreen : AppColors.teamBlue,
                    recapData,
                    "books_read_per_month",
                    startDelay: nextAnimDelay(),
                  ),
                  
                  SizedBox(height: 10),
                  // top three liked authors podium
                  getTopThreePodium(
                    'Top Authors',
                    recapData,
                    'top_3_weighted_authors',
                    'book_people_pictures',
                    ['Stars', 'Stars', 'Stars'],
                    startDelay: nextAnimDelay(),
                  ),])),
                  SizedBox(height: 20),

                  // ================== GENRE STATS ======================//
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ComicTitle(title: "Favorite Genres"),
                      const SizedBox(height: 4),

                      for (int i = 0; i < recapData['top_5_genres'].length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            "${i + 1}. ${recapData['top_5_genres'][i]}",
                            style: TextStyle(
                              fontFamily: theme.fontFamily,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),

                  // ======================== BADGES EARNED STATS ======================//
                  if((recapData['badges_earned'] as List).length != 0)...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    ComicTitle(title: "Badges Earned This Year"),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: (recapData['badges_earned'] as List).length,
                              itemBuilder: (context, index) {
                                final badge =
                                (recapData['badges_earned'] as List)[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: BadgeCard(
                                    badge: badge,
                                    isEarned: true,
                                  ),
                                );
                              },
                            ),
                    ),])),],
                  SizedBox(height: 20),

                  // ================== MILESTONE STATS ======================//
                  Row(
                    children:[
                      Spacer(),
                      Container(
                        height: 125,
                        width: 125,
                        decoration: BoxDecoration(
                          color: AppColors.teamPink,
                          shape: BoxShape.rectangle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              recapData['total_watchtime'].toString(),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "hours\nwatched",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ]
                        )
                      ),
                      SizedBox(width: 20),
                      Container(
                        height: 125,
                        width: 125,
                        decoration: BoxDecoration(
                          color: widget.year == '2024' ? AppColors.teamGreen : AppColors.teamBlue,
                          shape: BoxShape.rectangle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              recapData['total_pages_read'].toString(),
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "pages\nread",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ]
                        )
                      ),
                      Spacer(),
                    ],
                  ),
                  SizedBox(height: 20),
                  // ======================== Additional STATS ======================//
                  
                  ComicTitle(title: "And More...", size: 30),
                  SizedBox(height: 10),
                  // top three liked directors podium
                  getTopThreePodium( 
                    'Top Movie Directors',
                    recapData,
                    'movie_top_3_weighted_directors', 
                    'movie_people_pictures', 
                    ['Stars', 'Stars', 'Stars'],
                    startDelay: nextAnimDelay(),
                  ),

                  SizedBox(height: 10),

                   getTopThreePodium( 
                    'Your Top Movie Composers',
                    recapData,
                    'movie_top_3_weighted_composers',
                    'movie_people_pictures',
                    ['Stars', 'Stars', 'Stars'],
                    startDelay: nextAnimDelay(),
                  ),
                  
                  SizedBox(height: 10),
                  // top three viewed cinematographers podium
                  getTopThreePodium(
                    'Top Movie Cinematographers',
                    recapData,
                    'movie_top_3_weighted_cinematographers',
                    'movie_people_pictures',
                    ['Stars', 'Stars', 'Stars'],
                    startDelay: nextAnimDelay(),
                  ),

            
                  SizedBox(height: 10),
                  // top three viewed stunt coordinators podium
                  getTopThreePodium(
                    'Top Stunt Coordinators',
                    recapData,
                    'movie_top_3_weighted_stunt_coordinators',
                    'movie_people_pictures',
                    ['Stars', 'Stars', 'Stars'],
                    startDelay: nextAnimDelay(),
                  ),
                  SizedBox(height: 10),
                  
                  // top three viewed casting directors podium
                  getTopThreePodium(
                    'Top Casting Directors',
                    recapData,
                    'movie_top_3_weighted_castors',
                    'movie_people_pictures',
                    ['Stars', 'Stars', 'Stars'],
                    startDelay: nextAnimDelay(),
                  ),
                  SizedBox(height: 10),
                  
                  // top three viewed costumer designers podium
                  getTopThreePodium(
                    'Top Costumer Designers',
                    recapData,
                    'movie_top_3_weighted_costumer_designers',
                    'movie_people_pictures',
                    ['Stars', 'Stars', 'Stars'],
                    startDelay: nextAnimDelay(),
                  ),
                   SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (showRecap)
            RecapOverlay(
              year: widget.year,
              gradientColor: widget.year == '2024' ? AppColors.teamGreen : AppColors.teamBlue,
              recapData: recapData,
              onWelcomeRendered: () {
                if (mounted) {
                  setState(() {
                    _isRecapOverlayReady = true;
                  });
                }
              },
              onClose: () {
                setState(() {
                  showRecap = false;
                  _isRecapOverlayReady = true; // Show recap content after closing overlay
                });
              },
            ),
          if (showRecap && !_isRecapOverlayReady)
            Positioned.fill(
              child: Container(
                color: theme.mainBackgroundColor,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}