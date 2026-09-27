import 'package:flutter/material.dart';
import 'package:pop_media/pages/profile_page.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class FollowersListPage extends StatelessWidget {
  final String userId; // Pass the current user's ID
  final bool searchForFollowers;
  const FollowersListPage({super.key, required this.userId, this.searchForFollowers=true});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    
    return Scaffold(
      backgroundColor: theme.mainBackgroundColor,
      appBar: AppBar(title: searchForFollowers ? Text('Followers', style: TextStyle(color: theme.primaryColor)) : Text('Following', style: TextStyle(color: theme.primaryColor)), 
        backgroundColor: theme.topBarColor,
        foregroundColor: theme.primaryColor,),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: searchForFollowers ? DataService.loadFollowers(userId) : DataService.loadFollowing(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            var e = snapshot.error;
            return Center(child: Text('Error loading followers:\n$e', style: TextStyle(color: theme.primaryColor)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No followers found', style: TextStyle(color: theme.primaryColor)));
          } else {
            final followers = snapshot.data!;
            return ListView.builder(
              itemCount: followers.length,
              itemBuilder: (context, index) {
                final user = followers[index]; // user is a Map<String, dynamic>
                return ListTile(
                  leading: GestureDetector( 
                    onTap: (){
                      context.read<TtsService>().speak("Opening ${user['name']}'s Profile");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfilePage(userId: user['uid'], adminAccess: false),
                      ));
                    },
                    child: CircleAvatar(
                    backgroundImage: (user['profile_pic_url'] != null && user['profile_pic_url'] != 'temp')
                      ? NetworkImage(user['profile_pic_url'])
                      : AssetImage('assets/profile/profilePic.jpg') as ImageProvider,
                    ),
                  ),
                  title: GestureDetector(
                    onTap: (){
                      context.read<TtsService>().speak("Opening ${user['name']}'s Profile");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfilePage(userId: user['uid'], adminAccess: false),
                      ));
                    },
                    child: Text(user['username'] ?? '', style: TextStyle(fontFamily: theme.fontFamily, fontSize: 15, fontWeight: FontWeight.bold, color: theme.primaryColor,)),
                  ),
                  subtitle: Text(user['name'] ?? '', style: TextStyle(color: theme.primaryColor)),
                  trailing: TextButton(
                    onPressed: (){
                      context.read<TtsService>().speak("Opening ${user['name']}'s Profile");
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: user['uid'], adminAccess: false)));
                    },
                    child: ComicTitle(title: 'View account >', size: 12),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}