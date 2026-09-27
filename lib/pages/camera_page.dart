import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/session/user_session.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
    required this.media,
    required this.callback,
    required this.stillUploading,
    this.popCountAfterConfirm = 2,
  });

  final CameraDescription camera;
  final Media media;
  final void Function(bool result) callback;
  final bool stillUploading;
  final int popCountAfterConfirm;
  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize().timeout(
      const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Camera unavailable',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _cameraErrorMessage(snapshot.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: _isTakingPicture
            ? null
            : () async {
                // Take the Picture in a try / catch block. If anything goes wrong,
                // catch the error.
                try {
                  setState(() {
                    _isTakingPicture = true;
                  });

                  // Ensure that the camera is initialized.
                  await _initializeControllerFuture;

                  // Attempt to take a picture and get the file `image`
                  // where it was saved.
                  final image = await _controller.takePicture();

                  if (!context.mounted) return;

                  final imageBytes = await File(image.path).readAsBytes();

                  // If the picture was taken, display it on a new screen.
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => DisplayPictureScreen(
                        // Pass the automatically generated path to
                        // the DisplayPictureScreen widget.
                        imagePath: image.path,
                        imageBase64: base64Encode(imageBytes),
                        media: widget.media,
                        callback: widget.callback,
                        stillUploading: widget.stillUploading,
                        popCountAfterConfirm: widget.popCountAfterConfirm,
                      ),
                    ),
                  );
                } catch (e) {
                  // If an error occurs, log the error to the console.
                  print(e);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_cameraErrorMessage(e))),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isTakingPicture = false;
                    });
                  }
                }
              },
        child: _isTakingPicture
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.camera_alt),
      ),
    );
  }

  String _cameraErrorMessage(Object? error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
        case 'CameraAccessDeniedWithoutPrompt':
        case 'CameraAccessRestricted':
          return 'Camera permission is required. Please allow camera access in Settings and try again.';
        default:
          return error.description ??
              'The camera could not be started. Please try again.';
      }
    }

    return 'The camera could not be started. Please try again.';
  }
}

//-----------------------------------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------
// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final String imageBase64;
  final Media media;
  final void Function(bool result) callback;
  final bool stillUploading;
  final int popCountAfterConfirm;

  const DisplayPictureScreen({
    super.key,
    required this.imagePath,
    required this.imageBase64,
    required this.media,
    required this.callback,
    required this.stillUploading,
    this.popCountAfterConfirm = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm?')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
      persistentFooterButtons: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        //figure out how to make this async and disable the button while it's processing
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            //show loading screen/info popup
            DataService.verifyImageMatch(
              imageBase64,
              media,
              UserSession.uid!,
              callback,
              stillUploading,
            );
            for (var i = 0; i < popCountAfterConfirm; i++) {
              if (!Navigator.of(context).canPop()) break;
              Navigator.of(context).pop();
            }
            messenger?.showSnackBar(
              SnackBar(
                content: Text(
                  "Photo submitted for badge verification! This may take a moment.",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
