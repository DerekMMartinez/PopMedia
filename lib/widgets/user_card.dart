import 'package:flutter/material.dart';
import 'package:pop_media/pages/profile_page.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';

class UserCard extends StatelessWidget {
  final String uid;
  final String profilePicUrl;

  const UserCard({
    super.key,
    required this.uid,
    required this.profilePicUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;

    return FutureBuilder<String>(
      future: DataService.getUsername(uid: uid),
      builder: (context, snapshot) {
        final username = snapshot.data ?? 'Unknown user';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(2.5),
              child: GestureDetector(
                onTap: () {
                  context.read<TtsService>().speak("Opening $username's Profile");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        userId: uid,
                        adminAccess: false,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Image.network(
                    profilePicUrl,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              username,
              style: TextStyle(
                fontFamily: theme.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }
}