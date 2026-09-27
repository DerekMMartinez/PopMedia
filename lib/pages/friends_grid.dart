import 'package:flutter/material.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/widgets/generic_media_grid.dart';
import 'package:pop_media/widgets/user_card.dart';
import 'package:pop_media/models/user.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class FriendsGrid extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> friends;
  final String? username;

  const FriendsGrid({super.key, required this.friends, this.username});

  @override
  State<FriendsGrid> createState() => _FriendsGridState();
}

class _FriendsGridState extends State<FriendsGrid>{
  bool _isSearching = false;
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();
  late Future<List<User>> friendsList;
  List<Map<String, dynamic>> _allFriends = [];
  List<Map<String, dynamic>> _filteredFriends = [];

  late final String activeUid;

@override
void initState() {
  super.initState();
  _controller.addListener(_filterFriends);

  _isLoading = true;

  widget.friends.then((friendMaps) {
    setState(() {
      _allFriends = friendMaps;
      _filteredFriends = _allFriends;
      _isLoading = false;
    });
  }).catchError((error) {
    setState(() {
      _allFriends = [];
      _filteredFriends = [];
      _isLoading = false;
    });
    print("Error loading friends: $error");
  });
}

@override
void dispose() {
  _controller.removeListener(_filterFriends);
  _controller.dispose();
  super.dispose();
}

void _filterFriends() {
  final query = _controller.text.toLowerCase();

  setState(() {
    if (query.isEmpty) {
      _filteredFriends = _allFriends;
    } else {
      context.read<TtsService>().speak("Filtering Friends by ${query}");
      _filteredFriends = _allFriends.where((item) {
        final username = (item['username'] ?? '').toLowerCase();
        final name = (item['name'] ?? '').toLowerCase();
        return username.contains(query) || name.contains(query);
      }).toList();
    }
  });
}


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
              theme.subBackgroundImageOne,
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
                    border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorTwo, width: 2,),
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
                  ComicTitle(title: widget.username == null ? 'My Friends' : "${widget.username}'s Friends", size: 25),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSearching
                        ? TextField(
                            key: const ValueKey('searchField'),
                            controller: _controller,
                            autofocus: true,
                            style: TextStyle(color: theme.primaryColor),
                            decoration: InputDecoration(
                              hintText: 'Search Friends',
                              hintStyle: TextStyle(color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.primaryColor) 
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.accentColor) 
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.close, color: theme.primaryColor),
                                onPressed: () {
                                  setState(() {
                                    _controller.clear();
                                    _isSearching = false;
                                    context.read<TtsService>().speak("Clearing Search Filter");
                                  });
                                },
                              ),
                            ),
                          )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                                icon: Icon(Icons.search, color: theme.primaryColor),
                                color: Colors.black,
                                onPressed: () {
                                  setState(() {
                                    _isSearching = true;
                                  });
                                },
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                  else if (_filteredFriends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No friends found', 
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontFamily: theme.fontFamily)
                          )),
                    )
                  else
                  Align(
                    alignment: Alignment.topLeft,
                    key: ValueKey('${_filteredFriends.length}'),
                    child: GridListBuilder<Map<String, dynamic>>(
                      items: _filteredFriends,
                      cardHeight: 150,
                      itemBuilder: (context, userMap) => UserCard(
                        uid: userMap['uid'],
                        profilePicUrl: userMap['profile_pic_url'],
                      ),
                    )
                  )
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