import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pop_media/models/user.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

class EditAccountAccountPage extends StatefulWidget {
  final String? uid;
  const EditAccountAccountPage({super.key, required this.uid});

  @override
  State<EditAccountAccountPage> createState() => _EditAccountAccountState();
}


class _EditAccountAccountState extends State<EditAccountAccountPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  String? imageUrl;
  String _errorMessage = "";
  late Future<User> _userFuture;
  String? _usernameError;
  String? _nameError;
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  bool _deleteProfilePhoto = false;

  @override
  void initState() {
    super.initState();
      _userFuture = DataService.getUser(widget.uid!);
      _userFuture.then((user) {
        imageUrl = user.imageUrl;
        setState(() {
          _emailController.text = user.email;
          _usernameController.text = user.username;
          _nameController.text = user.name;
          _bioController.text = user.bio;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.topBarColor,
        centerTitle: true,   
          title: Image.asset(
            theme.logo,
            height: 60,   
            fit: BoxFit.contain,
          ), ),
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
              'Edit Account',
              style: TextStyle(
                fontFamily: theme.fontFamily,
                fontSize: 20, 
                fontWeight: FontWeight.bold),
            ),),
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Email: ',
                  style: TextStyle(fontFamily: theme.fontFamily, fontSize: 16, fontWeight: FontWeight.w500),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: Text(
                    _emailController.text,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                            context.read<TtsService>().speak("Opening Edit Profile Photo");
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
                                        context.read<TtsService>().speak("Opening Camera Roll");
                                        Navigator.pop(context);

                                        try {
                                          final result = await FilePicker.platform.pickFiles(
                                            type: FileType.image,
                                            withData: true,
                                          );

                                          if (result == null || result.files.single.bytes == null) return;

                                          final file = result.files.single;
                                          setState(() {
                                            _profileImageBytes = file.bytes!;
                                            _profileImageName = file.name;
                                            _deleteProfilePhoto = false;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Profile photo updated locally. Press "Save Changes" to finalize.',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          debugPrint("Upload failed: $e");
                                          context.read<TtsService>().speak("Image Upload Failed");
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
                                        context.read<TtsService>().speak("Profile Photo Deleted");
                                        Navigator.pop(context); // close bottom sheet

                                        setState(() {
                                          _deleteProfilePhoto = true;
                                          _profileImageBytes = null;
                                          _profileImageName = null;
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Profile photo will be removed on save.'),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRSuperellipse(
                            borderRadius: BorderRadius.circular(50),
                            child: _deleteProfilePhoto
                                ? Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.photo_camera, size: 80, color: Colors.black),
                                  )
                                : (_profileImageBytes != null
                                    ? Image.memory(
                                        _profileImageBytes!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : (imageUrl != null && imageUrl!.isNotEmpty)
                                        ? Image.network(
                                            imageUrl!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.photo_camera, size: 80, color: Colors.black),
                                          )),
                          ),
                        ),
                      )
                    ),
                    Text('Tap to Edit', style: TextStyle(fontSize: 12),)
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _usernameController,
                        onTapOutside: (event) {context.read<TtsService>().speak("Username changed to ${_usernameController.text}");},
                        decoration: InputDecoration(
                          hintText: 'username',
                          border: OutlineInputBorder(),
                          errorText: _usernameError,
                          filled: true,
                          fillColor: Colors.white,
                        )
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        onTapOutside: (event) {context.read<TtsService>().speak("Name changed to ${_nameController.text}");},
                        decoration: InputDecoration(
                          hintText: 'name',
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
              'Bio: ',
              style: TextStyle(fontFamily: theme.fontFamily, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 275,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bioController,
                      onTapOutside: (event) {context.read<TtsService>().speak("Bio changed to ${_bioController.text}");},
                      expands: true,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Write your bio here...',
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
                        _usernameError = null;
                        _nameError = null;
                        _errorMessage = "";
                      });

                      if (_usernameController.text.trim().isEmpty) {
                        setState(() {
                          _usernameError = "The username field cannot be blank.";
                          context.read<TtsService>().speak("${_usernameError}");
                        });
                        hasError = true;
                      }

                      if (_usernameController.text.trim().contains(" ")) {
                        setState(() {
                          _usernameError = "The username cannot have any spaces";
                          context.read<TtsService>().speak("${_usernameError}");
                        });
                        hasError = true;
                      }

                      if (_usernameController.text.trim().length > 20) {
                        setState(() {
                          _usernameError = "The username cannot be longer than 20 characters";
                          context.read<TtsService>().speak("${_usernameError}");
                        });
                        hasError = true;
                      }

                      if (_nameController.text.trim().isEmpty) {
                        setState(() {
                          _nameError = "The name field cannot be blank.";
                          context.read<TtsService>().speak("${_nameError}");
                        });
                        hasError = true;
                      }

                      if (_nameController.text.trim().length > 20) {
                        setState(() {
                          _nameError = "The name cannot be longer than 20 characters";
                          context.read<TtsService>().speak("${_nameError}");
                        });
                        hasError = true;
                      }

                      if (!hasError) {
                        bool taken = await DataService.checkUsernameTaken(
                          username: _usernameController.text.trim(),
                          email: _emailController.text.trim(),
                        );

                        if (taken) {
                          setState(() {
                            _usernameError = "Username already taken.";
                            context.read<TtsService>().speak("${_usernameError}");
                          });
                          hasError = true;
                        }
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
                        if (_deleteProfilePhoto) {
                          await DataService.deleteUserPhoto(widget.uid!);
                          finalImageUrl = "https://d21jyc5i6ygo3u.cloudfront.net/defaultProfilePic.png";
                        }

                        // UPLOAD case
                        else if (_profileImageBytes != null && _profileImageName != null) {
                          String contentType = 'image/jpeg';

                          if (_profileImageName!.endsWith('.png')) contentType = 'image/png';
                          if (_profileImageName!.endsWith('.webp')) contentType = 'image/webp';

                          finalImageUrl = await DataService.uploadProfilePicture(
                            fileName: _profileImageName!,
                            bytes: _profileImageBytes!,
                            guessedContentType: contentType,
                          );
                        }

                        // Update user
                        await DataService.postUser(
                          uid: widget.uid!,
                          username: _usernameController.text,
                          email: _emailController.text,
                          name: _nameController.text,
                          bio: _bioController.text,
                          profile_pic_url: finalImageUrl!,
                        );

                        UserSession.updateUsername(_usernameController.text);

                        //Update cache
                        UserSession.currentUser = UserSession.currentUser!.copyWith(
                          imageUrl: finalImageUrl,
                        );

                      } catch (e) {
                        
                        debugPrint("Save failed: $e");
                      }
                      context.read<TtsService>().speak("Changes Saved");

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/profilePage',
                        (route) => false,
                      );
                    },
                    child: const ComicTitle(title: "Save Changes", size: 30),
                  ),

                  if (_errorMessage.isNotEmpty)
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    )
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