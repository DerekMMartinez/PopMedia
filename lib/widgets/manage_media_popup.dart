import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/models/book.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/movie.dart';
import 'package:pop_media/models/television.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/widgets/ajax_search.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/media_buttons.dart';

class ManageMediaPopup extends StatefulWidget {
  final int pid;
  final List<Media> allMedia;
  const ManageMediaPopup({super.key, required this.pid, required this.allMedia});

  @override
  State<ManageMediaPopup> createState() => _ManageMediaPopupState();
}

class _ManageMediaPopupState extends State<ManageMediaPopup> {
  RadioType _selectedType = RadioType.movie;
  bool mediaAdded = false;
  String mediaFilter = 'All';
  String mediaChar = 'a';
  late List<Media> _allMedia;

  @override
  void initState() {
    super.initState();
    _allMedia = List.from(widget.allMedia);
  }
 
    List<Map<String, dynamic>> _loadFilteredMedia(
        String query,
        String mediaChar,
    ) {
      final q = query.toLowerCase();

      return _allMedia.where((m) {
            final idMatch = mediaChar == 'a' ||
                (m.id.isNotEmpty &&
                m.id[0].toLowerCase() == mediaChar.toLowerCase());

            final titleMatch =
                q.isEmpty || m.name.toLowerCase().contains(q);

            return idMatch && titleMatch;
          })
          .map((m) => {
                'media_id': m.id,
                'title': m.name,
                'image': m.image,
                'type': m.id.isNotEmpty ? m.id[0] : '',
              })
          .toList();
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ComicTitle(title: 'Manage Media'),
              SizedBox(height: 14),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _addBuild(),
                      );
                    }, 
                    child: const ComicTitle(title: "Add", size: 16)),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _deleteBuild(),
                      );
                    }, 
                    child: const ComicTitle(title: "Delete", size: 16)),
                ]
              ),
              SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, mediaAdded);
                }, 
                child: const ComicTitle(title: "Close", size: 16)
              ),
            ]
          )
        ),
      ),
    );
  }

  Widget _addBuild() {
    final TextEditingController titleController = TextEditingController();
    Map<String, dynamic>? selectedMedia;
    RadioType selectedType = _selectedType;
    String errorMessage = "";

    return StatefulBuilder(
      builder: (context, setDialogState) {
        final isMobile = MediaQuery.of(context).size.width < 500;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
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
                  const ComicTitle(title: 'Add Media'),
                  const SizedBox(height: 14),
                  // Media Type Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ComicTitle(title: 'Type:', size: 14),
                      if (isMobile)
                        Flexible(
                          child: MediaTypeRadio(
                            value: selectedType,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedType = value;
                                selectedMedia = null;
                                titleController.clear();
                              });
                            },
                          ),
                        )
                      else
                        MediaTypeRadio(
                          value: selectedType,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value;
                              selectedMedia = null;
                              titleController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search Field
                  Row(
                    children: [
                      ComicTitle(title: 'Title:', size: 14),
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
                            controller: titleController,
                            hintText: "Media Title",
                            onSearch: (query) async {
                              try {
                                final mediaList =
                                    await DataService.loadMedia(query, selectedType);
                                return mediaList.map((item) {
                                  final map = Map<String, dynamic>.from(item);
                                  map['image'] = map['image']?.toString() ??
                                      'assets/media_imgs/placeholder_poster.png';
                                  return map;
                                }).toList();
                              } catch (e) {
                                print("Error fetching media: $e");
                                return [];
                              }
                            },
                            displayStringForOption: (Map<String, dynamic> media) =>
                                media['title']?.toString() ?? '',
                            onSelected: (Map<String, dynamic> media) {
                              setDialogState(() {
                                selectedMedia = media;
                                titleController.text = media['title']?.toString() ?? '';
                                errorMessage = "";
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if (selectedMedia == null) {
                            setDialogState(() {
                              errorMessage = "Please select a media item.";
                            });
                            return;
                          }

                          try {
                            final success = await DataService.addMediaToPlaylist(
                                widget.pid, selectedMedia!['media_id']);
                            if (success) {
                              mediaAdded = true;

                              setState(() {
                                var charType = selectedMedia!['media_id'][0];
                                if(charType == 'm')
                                  _allMedia.add(Movie.fromJson(selectedMedia!));
                                if(charType == 't')
                                  _allMedia.add(Television.fromJson(selectedMedia!));
                                if(charType == 'b')
                                  _allMedia.add(Book.fromJson(selectedMedia!));
                              });

                              setDialogState(() {
                                errorMessage =
                                    "Successfully added. Please select another title or close.";
                              });
                            } else {
                              setDialogState(() {
                                errorMessage = "Failed to add media.";
                              });
                            }
                          } catch (e) {
                            setDialogState(() {
                              errorMessage = "Error adding media.";
                            });
                          }
                        },
                        child: const ComicTitle(title: "Add", size: 16),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, mediaAdded);
                          Navigator.pop(context, mediaAdded);
                        },
                        child: const ComicTitle(title: "Close", size: 16),
                      ),
                    ],
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        errorMessage,
                        style: errorMessage.contains("Success") 
                          ? TextStyle(color: Colors.black) 
                          : const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _deleteBuild() {
    final TextEditingController titleController = TextEditingController();
    Map<String, dynamic>? selectedMedia;
    String errorMessage = "";
    String mediaCharLocal = mediaChar;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
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
                  const ComicTitle(title: 'Delete Media'),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ComicTitle(title: 'Title:', size: 14),
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
                            controller: titleController,
                            hintText: "Media Title",
                            onSearch: (query) async {
                              try {
                                final mediaList = _loadFilteredMedia(query, mediaCharLocal);
                                return mediaList.map((item) {
                                  final map = Map<String, dynamic>.from(item);
                                  map['image'] = map['image']?.toString() ??
                                      'assets/media_imgs/placeholder_poster.png';
                                  return map;
                                }).toList();
                              } catch (e) {
                                print("Error fetching media: $e");
                                return [];
                              }
                            },
                            displayStringForOption: (Map<String, dynamic> media) =>
                                media['title']?.toString() ?? '',
                            onSelected: (Map<String, dynamic> media) {
                              setDialogState(() {
                                selectedMedia = media;
                                titleController.text = media['title']?.toString() ?? '';
                                errorMessage = "";
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if (selectedMedia == null) {
                            setDialogState(() {
                              errorMessage = "Please select a media item.";
                            });
                            return;
                          }

                          try {
                            final success = await DataService.deleteMediaFromPlaylist(
                                widget.pid, selectedMedia!['media_id']);
                            if (success) {
                              mediaAdded = true;
                              
                                setState(() {
                                  _allMedia.removeWhere(
                                    (m) => m.id == selectedMedia!['media_id'],
                                  );
                                });
                                
                              setDialogState(() {
                                errorMessage =
                                    "Successfully deleted. Please select another title or close.";
                              });
                            } else {
                              setDialogState(() {
                                errorMessage = "Failed to delete media.";
                              });
                            }
                          } catch (e) {
                            print("deleteMedia error: $e");
                            setDialogState(() {
                              errorMessage = "Error deleting media.";
                            });
                          }
                        },
                        child: const ComicTitle(title: "Delete", size: 16),
                      ),
                      TextButton(
                        onPressed: () { 
                          Navigator.pop(context, mediaAdded);
                          Navigator.pop(context, mediaAdded);
                        },
                        child: const ComicTitle(title: "Close", size: 16),
                      ),
                    ],
                  ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        errorMessage,
                        style: errorMessage.contains("Success") 
                          ? TextStyle(color: Colors.black) 
                          : const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}