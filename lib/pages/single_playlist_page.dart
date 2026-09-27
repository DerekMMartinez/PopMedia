import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/models/playlist.dart';
import 'package:pop_media/pages/create_playlist_page.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/generic_media_grid.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/widgets/manage_collaborators_popup.dart';
import 'package:pop_media/widgets/manage_media_popup.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:pop_media/widgets/media_filter.dart';
import 'package:pop_media/widgets/media_section.dart';
import 'package:pop_media/widgets/text_popup.dart';
import 'package:pop_media/widgets/user_card.dart';
import 'package:provider/provider.dart';

class SinglePlaylistPage extends StatefulWidget {
  final Playlist playlist;
  const SinglePlaylistPage({super.key, required this.playlist});

  @override
  State<SinglePlaylistPage> createState() => _SinglePlaylistPageState();
}


class _SinglePlaylistPageState extends State<SinglePlaylistPage> {
  String? imageUrl;
  Uint8List? _coverImageBytes;
  String? _coverImageName;
  bool _deleteCoverPhoto = false;
  bool _isEditing = false;
  bool _isSearching = false;
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();
  late Future<List<Media>> mediaFuture;
  List<Media> _allMedia = [];
  List<Media> _filteredMedia = [];
  String mediaFilter = 'All';
  late Future<List<Map<String, dynamic>>> _futureCollaborators;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String editedName;
  late String editedDescription;
  bool _canChange = false;
  Privacy _privacy = Privacy.public;

  @override
  void initState() {
    super.initState();
    _loadMedia('a');
    imageUrl = widget.playlist.imageUrl;
    _controller.addListener(_filterMedia);
    _futureCollaborators = DataService.getCollaborators(widget.playlist.pid, true, widget.playlist.uid);
    _nameController = TextEditingController(text: widget.playlist.name);
    _descriptionController = TextEditingController(text: widget.playlist.description);
    editedName = widget.playlist.name;
    editedDescription = widget.playlist.description;
    _privacy = widget.playlist.public ? Privacy.public : Privacy.private;
    _checkCanChange();
  }

  void _loadMedia(String type) async {
    setState(() {
      _isLoading = true;
    });

    final media = await DataService.getPlaylistMedia(widget.playlist.pid, type);

    if (!mounted) return;

    setState(() {
      _allMedia = media;
      _isLoading = false;
    });

    _filterMedia();
  }

  void _checkCanChange() async {
    setState(() {
      _isLoading = true;
    });

    final collaborators = await _futureCollaborators;

    if (!mounted) return;

    bool canChange = collaborators.any(
      (user) => user["uid"] == UserSession.uid,
    );

    setState(() {
      _canChange = canChange;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_filterMedia);
    _controller.dispose();
    super.dispose();
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      mediaFilter = newFilter;
    });

    _filterMedia();
  }

  void _filterMedia() {
    final query = _controller.text.toLowerCase();

    setState(() {
      _filteredMedia = _allMedia.where((m) {
        final matchesFilter = mediaFilter == 'All' ||
            (mediaFilter == 'Books' && m.id.startsWith('b')) ||
            (mediaFilter == 'Movies' && m.id.startsWith('m')) ||
            (mediaFilter == 'TV Shows' && m.id.startsWith('t'));

        final matchesSearch =
            query.isEmpty || m.name.toLowerCase().contains(query);

        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  void _manageCollaboratorsPopUp() async{
    if(!mounted) return;
    final didUpdate = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ManageCollaboratorsPopup(
        pid: widget.playlist.pid,
      ),
    );

    if (didUpdate == true) {
      setState(() {
        _futureCollaborators = DataService.getCollaborators(widget.playlist.pid, true, widget.playlist.uid);
      });
    }
  }

  void _manageMediaPopUp() async{
  if (!mounted) return;

  final didUpdate = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ManageMediaPopup(
      pid: widget.playlist.pid,
      allMedia: _allMedia
    ),
  );

  if (didUpdate == true) {
    _loadMedia(mediaFilter[0].toLowerCase());
  }
  
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Are you sure you want to delete this playlist?",
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx); 
                    },
                    child: const ComicTitle(title: "Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      final success = await DataService.deletePlaylist(
                        widget.playlist.pid
                      );

                      // Close the bottom sheet FIRST
                      Navigator.pop(ctx);

                      if (success) {
                        Navigator.pushReplacementNamed(context, '/homePage');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to delete playlist. Please try again later.'),
                          ),
                        );
                      }
                    },
                    child: const ComicTitle(title: "Delete"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
      final theme = context.watch<ThemeController>().currentTheme;
      return MainScaffold(
      currentIndex: null,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SizedBox.expand(
        child: Stack (
            children: [
            Positioned.fill(
              child: theme.mainBackgroundImage != null
                  ? Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        theme.subBackgroundImageThree,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      color: theme.mainBackgroundColor,
                    ),
            ),
        SingleChildScrollView(
          child: Stack(
        children: [
        Padding(  
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Center(
                      child: _isEditing
                      ? GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isDismissible: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  child: const ComicTitle(title: "Change Photo"),
                                  onPressed: () async {
                                    Navigator.pop(context);

                                    try {
                                      final result = await FilePicker.platform.pickFiles(
                                        type: FileType.image,
                                        withData: true,
                                      );

                                      if (result == null || result.files.single.bytes == null) return;

                                      final file = result.files.single;
                                      setState(() {
                                        _coverImageBytes = file.bytes!;
                                        _coverImageName = file.name;
                                        _deleteCoverPhoto = false;
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Cover photo updated locally. Press save checkmark to finalize.',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint("Upload failed: $e");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Upload failed: $e')),
                                      );
                                    }
                                  },
                                ),
                                TextButton(
                                  child: const ComicTitle(title: "Delete Photo", color: Colors.red),
                                  onPressed: () {
                                    Navigator.pop(context);

                                    setState(() {
                                      _deleteCoverPhoto = true;
                                      _coverImageBytes = null;
                                      _coverImageName = null;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Cover photo will be replaced with this default on save.'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                        child: _deleteCoverPhoto
                            ? Image.network(
                                "https://d21jyc5i6ygo3u.cloudfront.net/playlist_default.PNG",
                                width: 110,
                                height: 165,
                                fit: BoxFit.cover,
                              )
                            : (_coverImageBytes != null
                                ? Image.memory(
                                    _coverImageBytes!,
                                    width: 110,
                                    height: 156,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                        imageUrl ?? "https://d21jyc5i6ygo3u.cloudfront.net/playlist_default.PNG",
                                        width: 110,
                                        height: 165,
                                        fit: BoxFit.cover,
                                      )
                                    ),
                    )
                    : Image.network(
                        imageUrl ?? "https://d21jyc5i6ygo3u.cloudfront.net/playlist_default.PNG",
                        width: 120,
                        height: 180,
                        fit: BoxFit.cover,
                    )
                  )
                ),
                if(_isEditing)
                    Text('Tap to Edit', style: TextStyle(fontSize: 12, color: theme.primaryColor),)
                  ]
                ),
             const SizedBox(width: 16),
                Expanded(
                  child: Container(
                  height: 180,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor, width: 2)
                  ),
                  child: Column( 
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      Expanded(
                        child: _isEditing
                            ? SizedBox(
                              height: 35,
                                child: TextField(
                                  controller: _nameController,
                                  style: TextStyle(
                                    fontFamily: theme.fontFamily,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'i.e. Watchlist',
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red, width: 2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.red, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 8,
                                    ),
                                  ),
                                )
                              )
                            : Text(
                                editedName,
                                style: TextStyle(
                                  fontFamily: theme.fontFamily,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      if (_canChange)
                      IconButton(
                        icon: Icon(_isEditing ? Icons.check : Icons.edit),
                        color: Colors.black,
                        style: IconButton.styleFrom(
                          backgroundColor: _isEditing ? const Color.fromARGB(255, 136, 236, 139) : Colors.white,
                        ),
                        tooltip: _isEditing ? 'Save' : 'Edit',
                        onPressed: () async {
                          setState(() {
                            _isEditing = !_isEditing;
                          });

                          if (!_isEditing) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              bool hasError = false;

                              if (_nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "The name field cannot be blank.",
                                          ),
                                        ),
                                      );
                                hasError = true;
                              }

                              if (_nameController.text.trim().length > 20) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "The name cannot be longer than 20 characters",
                                          ),
                                        ),
                                      );
                                hasError = true;
                              }

                              if (hasError) {
                                _isEditing = !_isEditing;
                                return;
                              };

                              editedName = _nameController.text;
                              editedDescription = _descriptionController.text;

                              String? finalImageUrl = imageUrl;

                              if (_deleteCoverPhoto) {
                                finalImageUrl = "https://d21jyc5i6ygo3u.cloudfront.net/playlist_default.PNG";
                              }

                              else if (_coverImageBytes != null && _coverImageName != null) {
                                String contentType = 'image/jpeg';

                                if (_coverImageName!.endsWith('.png')) contentType = 'image/png';
                                if (_coverImageName!.endsWith('.webp')) contentType = 'image/webp';

                                finalImageUrl = await DataService.uploadProfilePicture(
                                  fileName: _coverImageName!,
                                  bytes: _coverImageBytes!,
                                  guessedContentType: contentType,
                                  pictureType: "cover",
                                );
                              }
                              setState(() {
                                imageUrl = finalImageUrl!;
                                _coverImageBytes = null;
                                _coverImageName = null;
                                _deleteCoverPhoto = false;
                              });

                              await DataService.updatePlaylist(
                                widget.playlist.pid, 
                                widget.playlist.uid, 
                                editedName, 
                                editedDescription, 
                                imageUrl!,
                                _privacy == Privacy.public,
                              );

                            } catch (e) {
                              debugPrint("Save failed: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error editing playlist attributes")),
                              );
                            } finally {
                              Navigator.pop(context);
                            }
                          }
                        },
                      ),
                      if (widget.playlist.uid == UserSession.uid && _isEditing)
                      IconButton(
                        onPressed:  () {
                          _showDeleteConfirmation(context);
                        },
                        icon: const Icon(Icons.delete),
                        color: Colors.black,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                        )
                      ),
                      ]),
                      SizedBox(height: 2),
                      if (_isEditing)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red, width:2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _privacy = _privacy == Privacy.public
                                        ? Privacy.private
                                        : Privacy.public;
                                  });
                                  
                                  try {
                                    final message = _privacy == Privacy.public
                                        ? "Privacy changed to public"
                                        : "Privacy changed to private";

                                    context.read<TtsService>().speak(message);
                                  } catch (e) {
                                    debugPrint("TTS failed: $e");
                                  }
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(opacity: animation, child: child),
                                  child: Icon(
                                    _privacy == Privacy.public
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    key: ValueKey(_privacy),
                                    size: 30,
                                  ),
                                ),
                              )
                            )
                          ],
                        ),
                        SizedBox(height: 4),
                      _isEditing
                      ? SizedBox(
                        height: 75,
                        child: TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            style: TextStyle(
                              fontFamily: theme.fontFamily,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write your description here...',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              )
                            ),
                          ))
                        :TextPopUp(text: editedDescription, maxLines:5, type: "Playlist", playlist: widget.playlist),
                    ],
                  ),
                ),
                ),
              ],
            ),          
            SizedBox(height: 8),
            MediaSection<Map<String, dynamic>>(
              title: 'Collaborators',
              count: false,
              onNavigate: null,
              onNavigateUpload: _canChange ? () {
                _manageCollaboratorsPopUp();
              } : null,
              sectionHeight: 160,
              postReview: false,
              friendSection: false,
              playlistCollaborator: _canChange,
              borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorThree,
              future: _futureCollaborators,
              backgroundImage: theme.name != 'Noir' ? theme.subBackgroundImageOne : theme.subBackgroundImageTwo,
              itemBuilder: (context, userMap) {
                final uid = userMap['uid'];
                final profilePicUrl = userMap['profile_pic_url'];

                if(uid == null || uid is !String){
                  return const SizedBox.shrink();
                }

                return UserCard(
                  uid: uid,
                  profilePicUrl: profilePicUrl,
                );
              },
            ),
            SizedBox(height: 15),
            ConstrainedBox(
            constraints: BoxConstraints( minWidth: screenWidth, minHeight: 300),
              child: Container(
                padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor, width: 2,),
                    color: theme.mainBackgroundColor,
                    image: theme.mainBackgroundImage != null
                        ? DecorationImage(
                            image: AssetImage(theme.subBackgroundImageTwo),
                            fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.white.withOpacity(theme.imageOpactity),
                              BlendMode.lighten,
                            ),
                          )
                        : null,
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  ComicTitle(title: 'Playlist Media', size: 25),
                  Spacer(),
                    if (_canChange)
                    TextButton(
                          onPressed: () {
                            _manageMediaPopUp();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: theme.accentColorTwo, width: 4),
                            ),
                          ),
                          child: Text(
                            screenWidth < 500 ? "Manage" : "Manage Media",
                            style: TextStyle(
                              fontFamily: theme.fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                  ],),
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
                              hintText: 'Search Media in Playlist by Title',
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
                                    _isSearching = false;
                                    _controller.clear();
                                  });
                                },
                              ),
                            ),
                          )
                        : Row(
                            key: const ValueKey('filtersRow'),
                            children: [
                                MediaFilter(
                                  selectedType: mediaFilter,
                                  onChanged: _onFilterChanged,
                                ),
                              Spacer(),
                              IconButton(
                                icon: const Icon(Icons.search),
                                color: theme.primaryColor,
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
                  else if (_filteredMedia.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No media found')),
                    )
                  else
                  Align(
                    alignment: Alignment.topLeft,
                    key: ValueKey('${mediaFilter}_${_filteredMedia.length}'),
                    child: GridListBuilder<Media>(
                      items: _filteredMedia,
                      cardHeight: 225,
                      itemBuilder: (context, media) => MediaCard(
                        media: media,
                        type: MediaCardType.overview,
                        hideName: false
                      ),
                    ))
                ],
                ),
              ),
            ),
          ],
        ),
        ),]
        ),
        ),]
      ),))
    );
  }
}