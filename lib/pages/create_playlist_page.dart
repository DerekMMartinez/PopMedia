import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pop_media/models/playlist.dart';
import 'package:pop_media/pages/single_playlist_page.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:provider/provider.dart';

class CreatePlaylistPage extends StatefulWidget {
  const CreatePlaylistPage({super.key});
  @override
  State<CreatePlaylistPage> createState() => _CreatePlaylistState();
}

enum Privacy { public, private }

class _CreatePlaylistState extends State<CreatePlaylistPage> {
  Privacy _privacy = Privacy.public;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _nameError;
  String? imageUrl = "https://d21jyc5i6ygo3u.cloudfront.net/playlist_default.PNG";
  Uint8List? _coverImageBytes;
  String? _coverImageName;
  bool _deleteCoverPhoto = false;
  Playlist? playlist;

@override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    return MainScaffold(
      currentIndex: null,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SizedBox.expand(
        child: Stack (
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(
                    theme.subBackgroundImageFour,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 12),
          child: Stack(
        children: [
        Padding(  
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              'Create New Playlist',
              style: TextStyle(
                fontFamily: theme.fontFamily,
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,),
            ),),
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center, // centers children vertically
              children: [
              Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isDismissible: true, // tap outside to dismiss
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Change Photo Button
                                TextButton(
                                  child: const ComicTitle(title: "Change Photo"),
                                  onPressed: () async {
                                    Navigator.pop(context); // close bottom sheet first

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
                                            'Cover photo updated locally. Press "Create Playlist" to finalize.',
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
                                // Delete Photo Button
                                TextButton(
                                  child: const ComicTitle(title: "Delete Photo", color: Colors.red),
                                  onPressed: () {
                                    Navigator.pop(context); // close bottom sheet

                                    setState(() {
                                      _deleteCoverPhoto = true;
                                      _coverImageBytes = null;
                                      _coverImageName = null;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('This default photo will be used when you click Create Playlist.'),
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
                                width: 120,
                                height: 180,
                                fit: BoxFit.cover,
                              )
                            : (_coverImageBytes != null
                                ? Image.memory(
                                    _coverImageBytes!,
                                    width: 120,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  )
                                : (imageUrl != null && imageUrl!.isNotEmpty)
                                    ? Image.network(
                                        imageUrl!,
                                        width: 120,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                      "https://d21jyc5i6ygo3u.cloudfront.net/playlist_default.PNG",
                                      width: 120,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    )),
                    ),
                  )
                ),
                    Text('Tap to Edit', style: TextStyle(fontSize: 12, color: theme.primaryColor),)
                  ],
                ),
                const SizedBox(width: 16), // space between image and fields
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // makes column only as tall as its children
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name: ',
                        style: TextStyle(fontFamily: theme.fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: theme.primaryColor),
                      ),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'i.e. Watchlist',
                          border: OutlineInputBorder(),
                          errorText: _nameError,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Description: ',
              style: TextStyle(fontFamily: theme.fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: theme.primaryColor),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 275,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _descriptionController,
                      expands: true,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Write your description here...',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Radio<Privacy>(
                      value: Privacy.private,
                      groupValue: _privacy,
                      onChanged: (value) {
                        setState(() {
                          _privacy = value!;
                        });
                      },
                    ),
                    Text("Private",
                    style: TextStyle(fontFamily: theme.fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: theme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Radio<Privacy>(
                      value: Privacy.public,
                      groupValue: _privacy,
                      onChanged: (value) {
                        setState(() {
                          _privacy = value!;
                        });
                      },
                    ),
                    Text("Public",
                    style: TextStyle(fontFamily: theme.fontFamily, fontSize: 16, fontWeight: FontWeight.w500, color: theme.primaryColor),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 8),

            Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      bool hasError = false;

                      // Reset errors first
                      setState(() {
                        _nameError = null;
                      });

                      if (_nameController.text.trim().isEmpty) {
                        setState(() {
                          _nameError = "The name field cannot be blank.";
                        });
                        hasError = true;
                      }

                      if (_nameController.text.trim().length > 20) {
                        setState(() {
                          _nameError = "The name cannot be longer than 20 characters";
                        });
                        hasError = true;
                      }

                      if (hasError) return;
                      
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        String? finalImageUrl = imageUrl;

                        // DELETE case
                        if (_deleteCoverPhoto) {
                          finalImageUrl = "https://d21jyc5i6ygo3u.cloudfront.net/playlist_default.PNG";
                        }

                        // UPLOAD case
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


                        int pid = await DataService.postPlaylist(
                          uid: UserSession.uid!,
                          name: _nameController.text,
                          description: _descriptionController.text,
                          cover_pic_url: finalImageUrl!,
                          public: _privacy == Privacy.public
                        );

                        if(pid == -1) 
                          throw Exception("Failed to create Playlist");

                        if(pid != -1) 
                          playlist = Playlist.fromJson({
                            'pid': pid,
                            'uid': UserSession.uid,
                            'name': _nameController.text.trim(), 
                            'description': _descriptionController.text.trim(),
                            'image_url': finalImageUrl,
                            'public': _privacy == Privacy.public
                          });


                      } catch (e) {
                        debugPrint("Create Playlist failed: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to create playlist. Please try again later.')),
                        );
                      }

                      if (playlist == null) {
                        Navigator.pop(context); // close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to create playlist. Please try again later.')),
                        );
                        return;
                      }

                      else{
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SinglePlaylistPage(playlist: playlist!),
                          ),
                          (route) => false,
                        );
                      }

                    },
                    child: const ComicTitle(title: "Create Playlist"),
                  ),
                ],
              ),
            ),
          ],
        ),
        )
        ]
      ),
        )])))
    );
  }
}