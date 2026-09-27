import 'package:flutter/material.dart';
import 'package:pop_media/colors.dart';

class Theme{
  final String name;
  final String logo;
  final String fontFamily;
  final String? mainBackgroundImage;
  final Color? mainBackgroundColor;
  final Color primaryColor;
  final Color accentColor;
  final Color accentColorTwo;
  final Color accentColorThree;
  final String subBackgroundImageOne;
  final String subBackgroundImageTwo;
  final String subBackgroundImageThree;
  final String subBackgroundImageFour;
  final String vibeBackgroundImage;
  final String? privacyImage;
  final double imageOpactity;
  final Color topBarColor;
  final Color appBarColor;
  final Color appItemSelected;
  final Color appItemUnselected;
  final Color plusItemColor;
  final List<Color> gradientColors;
  final String wheelIcon;


Theme({
  required this.name,
  required this.logo,
  required this.fontFamily,
  this.mainBackgroundImage,
  this.mainBackgroundColor,
  required this.primaryColor,
  required this.accentColor,
  required this.accentColorTwo,
  required this.accentColorThree,
  required this.subBackgroundImageOne,
  required this.subBackgroundImageTwo,
  required this.subBackgroundImageThree,
  required this.subBackgroundImageFour,
  required this.vibeBackgroundImage,
  this.privacyImage,
  required this.imageOpactity,
  required this.topBarColor,
  required this.appBarColor,
  required this.appItemSelected,
  required this.appItemUnselected,
  required this.plusItemColor,
  required this.gradientColors,
  required this.wheelIcon
  });
}

final PopArt = Theme(
  name: 'PopArt',
  logo: 'assets/logo/popLogo.png',
  fontFamily: 'ComicSans',
  mainBackgroundImage: 'assets/backgrounds/popArt/g&w_background_vertical.jpg',
  mainBackgroundColor : Colors.white,
  primaryColor: Colors.black,
  accentColor: Colors.blue,
  accentColorTwo: Colors.amber,
  accentColorThree: Colors.red,
  subBackgroundImageOne: 'assets/backgrounds/popArt/red_background.jpg',
  subBackgroundImageTwo: 'assets/backgrounds/popArt/blue_background.jpg',
  subBackgroundImageThree: 'assets/backgrounds/popArt/yellow_background.jpg',
  subBackgroundImageFour: 'assets/backgrounds/popArt/verticalBackground.png',
  vibeBackgroundImage: 'assets/backgrounds/popArt/vibey_background.png',
  imageOpactity: 0.75,
  topBarColor: const Color(0xFF72B8D9),
  appBarColor: Colors.white,
  appItemSelected: Colors.blue, 
  appItemUnselected: Colors.grey,
  plusItemColor: Colors.white,
  gradientColors: [AppColors.teamBlue, AppColors.teamPink, AppColors.teamGold],
  wheelIcon: 'assets/wheels/popArt_wheel.png'
);

final Noir = Theme(
  name: 'Noir',
  logo: 'assets/logo/logo_bw.png',
  fontFamily: 'Noir',
  mainBackgroundImage: null,
  mainBackgroundColor: Color(0xFF121212),
  primaryColor: Colors.white,
  accentColor: Colors.red,
    accentColorTwo: Colors.red,
  accentColorThree: Colors.red,
  subBackgroundImageOne: 'assets/backgrounds/noir/noir_pop.jpg',
  subBackgroundImageTwo: 'assets/backgrounds/noir/noir_fog.jpg',
  subBackgroundImageThree: 'assets/backgrounds/noir/noir_spiral.jpg',
  subBackgroundImageFour: 'assets/backgrounds/noir/noir_city.png',
  vibeBackgroundImage: 'assets/backgrounds/noir/noir_vibes.jpg',
  privacyImage: 'assets/backgrounds/noir/noir_detective.jpg',
  imageOpactity: 0.6,
  topBarColor: const Color.fromARGB(255, 70, 69, 69),
  appBarColor: const Color.fromARGB(255, 70, 69, 69), 
  appItemSelected: Colors.white, 
  appItemUnselected: Colors.black,
  plusItemColor: Colors.black,
  gradientColors: [Colors.black, Colors.grey, Colors.white],
  wheelIcon: 'assets/wheels/noir_wheel.png'
);

final Simple = Theme(
  name: 'Simple',
  logo: 'assets/logo/popLogo.png',
  fontFamily: 'Simple',
  mainBackgroundImage: null,
  mainBackgroundColor : Colors.white,
  primaryColor: Colors.black,
  accentColor: AppColors.teamBlue,
  accentColorTwo: AppColors.teamPink,
  accentColorThree: AppColors.teamGold,
  subBackgroundImageOne: 'assets/backgrounds/simple/simple_background.jpg',
  subBackgroundImageTwo: 'assets/backgrounds/simple/simple_background.jpg',
  subBackgroundImageThree: 'assets/backgrounds/simple/simple_background.jpg',
  subBackgroundImageFour: 'assets/backgrounds/simple/simple_background.jpg',
  vibeBackgroundImage: 'assets/backgrounds/simple/simple_vibes.png',
  imageOpactity: 0.8,
  topBarColor: const Color(0xFF72B8D9),
  appBarColor: Colors.white,
  appItemSelected: Colors.blue, 
  appItemUnselected: Colors.grey,
  plusItemColor: Colors.white,
  gradientColors: [AppColors.teamBlue, AppColors.teamPink, AppColors.teamGold],
  wheelIcon: 'assets/wheels/simple_wheel.png'
);

final WaterColor = Theme(
  name: 'WaterColor',
  logo: 'assets/logo/watercolor_logo.png',
  fontFamily: 'Zen',
  mainBackgroundImage: 'assets/backgrounds/waterColor/watercolor_grey.jpg',
  mainBackgroundColor : Colors.white,
  primaryColor: Colors.black,
  accentColor: Colors.blue,
  accentColorTwo: Colors.amber,
  accentColorThree: Colors.red,
  subBackgroundImageOne: 'assets/backgrounds/waterColor/watercolor_red.jpg',
  subBackgroundImageTwo: 'assets/backgrounds/waterColor/watercolor_blue.jpg',
  subBackgroundImageThree: 'assets/backgrounds/waterColor/watercolor_yellow.jpg',
  subBackgroundImageFour: 'assets/backgrounds/waterColor/watercolor_mix.jpg',
  vibeBackgroundImage: 'assets/backgrounds/waterColor/book_store.png',
  imageOpactity: 0.4,
  topBarColor: const Color(0xFF72B8D9),
  appBarColor: Colors.white,
  appItemSelected: Colors.blue, 
  appItemUnselected: Colors.grey,
  plusItemColor: Colors.white,
  gradientColors: [AppColors.teamBlue, AppColors.teamPink, AppColors.teamGold],
  wheelIcon: 'assets/wheels/paint_wheel.png'
);

final allThemes = [PopArt, Noir, Simple, WaterColor];

ThemeData toThemeData(Theme theme) {
  return ThemeData();
}