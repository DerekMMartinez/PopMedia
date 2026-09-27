import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/widgets/generic_media_grid.dart';
import 'package:pop_media/widgets/badge_card.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class MyBadgesPage extends StatefulWidget {
  final String uid;
  final String? username;

  const MyBadgesPage({super.key, required this.uid, this.username});

  @override
  State<MyBadgesPage> createState() => _MyBadgesPage();
}

Future<List<Map<String, dynamic>>> _loadBadges(String uid) async {
  return UserSession.getBadges(UserSession.uid!);
}

class _MyBadgesPage extends State<MyBadgesPage>{
@override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final theme = context.watch<ThemeController>().currentTheme;


  return MainScaffold(
    currentIndex: null,
    body: Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.4,
            child: Image.asset(
              theme.subBackgroundImageThree,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Scrollable content
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints( minHeight: screenHeight,),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                    border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorThree, width: 2,),
                    color: theme.mainBackgroundColor,
                    image: theme.mainBackgroundImage != null
                        ? DecorationImage(
                            image: AssetImage(theme.mainBackgroundImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ComicTitle(title: widget.username == null ? 'My Badges' : "${widget.username}'s Badges", size: 25),
                  const SizedBox(height: 10),
                    GridListBuilder<dynamic>(
                      future: widget.uid == UserSession.uid
                          ? _loadBadges(widget.uid)
                          : DataService.getBadgesEarned(widget.uid),
                      cardHeight: 170,
                      itemBuilder: widget.uid == UserSession.uid
                          ? (context, item) {
                              return BadgeCard(
                                badge: item['badge'],
                                isEarned: item['isEarned'],
                              );
                            }
                          : (context, badge) {
                              return BadgeCard(
                                badge: badge,
                                isEarned: true,
                              );
                            },
                    ),
                ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}