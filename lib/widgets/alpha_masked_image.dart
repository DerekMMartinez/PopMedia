import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class AlphaMaskedImage extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;

  const AlphaMaskedImage({
    super.key,
    required this.imageUrl,
    this.width = 50,
    this.height = 70,
  });

  @override
  State<AlphaMaskedImage> createState() => _AlphaMaskedImageState();
}

class _AlphaMaskedImageState extends State<AlphaMaskedImage> {
  ui.Image? _maskImage;

  @override
  void initState() {
    super.initState();
    _loadMask();
  }

  Future<void> _loadMask() async {
    final data = await rootBundle.load('assets/badges/pinkBadge.png');
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() => _maskImage = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;

    if (_maskImage == null) {
      return SizedBox(width: width, height: height);
    }

    return SizedBox(
      width: width,
      height: height,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (Rect bounds) {
          return ImageShader(
            _maskImage!,
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity().scaled(
              bounds.width / _maskImage!.width,
              bounds.height / _maskImage!.height,
            ).storage,
          );
        },
        child: Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}