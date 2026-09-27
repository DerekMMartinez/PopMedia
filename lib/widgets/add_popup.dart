import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/playlist.dart';
import 'package:pop_media/pages/create_playlist_page.dart';
import 'package:pop_media/pages/upload_page.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/widgets/ajax_search.dart';
import 'package:pop_media/widgets/comic_title.dart';

class AddPopup extends StatefulWidget {
  final Media media;

  const AddPopup({super.key, required this.media});

  @override
  State<AddPopup> createState() => _AddState();
}

class _AddState extends State<AddPopup> {
  Map<String, dynamic>? _selectedPlaylist;
  String _errorMessage = "";
  List<Playlist> _allPlaylists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await DataService.getPlaylists(UserSession.uid!, false);
    setState(() {
      _allPlaylists = playlists;
    });
  }

  List<Playlist> _filterPlaylistsFromList(String query) {
    if (query.isEmpty) return _allPlaylists;

    return _allPlaylists.where((playlist) {
      final name = playlist.name.toLowerCase();

      return name.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ComicTitle(title: 'Add'),
              SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if(!UserSession.userReviews!.any((media) => media.media.id == widget.media.id))
                  TextButton(
                    onPressed: () {
                      Map<String, dynamic> mediaMap = {
                        'media_id': widget.media.id,
                        'title': widget.media.name,
                        'description': widget.media.description,
                        'creator': widget.media.creator,
                        'image': widget.media.image,
                        'release_date': widget.media.date,
                        'overall_rating': widget.media.rate,
                        'genres': widget.media.genre,
                      };
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => UploadPage(preselectedMedia: mediaMap)),
                      );
                    },
                    child: const ComicTitle(title: "Add Review", size: 16)),
                  TextButton(
                    onPressed: () async {
                      await _loadPlaylists();
                      showDialog(
                        context: context,
                        builder: (context) => _addToPlaylistBuild(),
                      );
                    }, 
                    child: const ComicTitle(title: "Add to Playlist", size: 16)),
                ]
              ),
              SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                }, 
                child: const ComicTitle(title: "Close", size: 16)
              ), 
            ]
          )
        ),
      ),
    );
  }

  Widget _addToPlaylistBuild() {
    final TextEditingController _nameController = TextEditingController();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Center(
                        child: const ComicTitle(title: 'Add Media to Playlist'),
                      ),
                    ]
                  ),
                  SizedBox(height: 14),

                  // --- Title Ajax Search  ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ComicTitle(title: 'Playlist: *', size: 14),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.grey.shade200.withOpacity(0.9),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: AjaxSearchField(
                            controller: _nameController,
                            hintText: "Name of the Playlist",
                            onSearch: (query) async {
                              try {
                                final playlistList =
                                    _filterPlaylistsFromList(query);
                                final normalized = playlistList.map((item) {
                                  final playlist = item.toJson();
                                  return playlist;
                                }).toList();

                                return normalized;
                              } catch (e) {
                                print("Error fetching users: $e");
                                return [];
                              }
                            },
                            displayStringForOption: (Map<String, dynamic> playlist) =>
                                playlist['name']?.toString() ?? '',
                            onSelected: (Map<String, dynamic> playlist) {
                              setDialogState(() {
                                _selectedPlaylist = playlist;
                                _nameController.text =
                                    playlist['name']?.toString() ?? '';
                                _errorMessage = "";
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // --- Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if (_selectedPlaylist == null) {
                            setDialogState(() {
                              _errorMessage = "Please select a playlist.";
                            });
                            return;
                          }

                          try {
                            final success =
                                await DataService.addMediaToPlaylist(
                              _selectedPlaylist!['pid'],
                              widget.media.id
                            );

                            setDialogState(() {
                              _errorMessage = success
                                  ? "Successfully added. Please select another playlist or close."
                                  : "Failed to add media to playlist.";
                            });

                          } catch (e) {
                            setDialogState(() {
                              _errorMessage = "Error adding media to playlist.";
                            });
                          }
                        },
                        child:
                            const ComicTitle(title: "Add", size: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: const ComicTitle(title: "Close", size: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CreatePlaylistPage()),
                        );
                      },
                      child: const ComicTitle(title: "Create New Playlist", size: 16),
                    ),
                  ), 

                  // --- Error message display ---
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorMessage,
                        style: _errorMessage.contains("Success") 
                          ? TextStyle(color: Colors.black) 
                          : const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
