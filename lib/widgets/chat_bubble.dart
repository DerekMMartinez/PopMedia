import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final double width;
  final EdgeInsetsGeometry padding;
  final bool isEditing;
  final TextEditingController controller;
  final bool spoilers;
  final bool mine; 

  const ChatBubble({
    super.key,
    required this.message,
    required this.width,
    required this.controller,
    required this.spoilers,
    required this.mine,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 12, 12),
    this.isEditing = false,
  });

  @override
  State<ChatBubble> createState() => _ChatBubble();
}

class _ChatBubble extends State<ChatBubble>{ 
  bool _showSpoilers = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    
    return CustomPaint(
      painter: ChatBubblePainter(
        borderColor: widget.isEditing ? Colors.red : Colors.black,
        borderWidth: widget.isEditing ? 2 : 2,
      ),
      child: Container(
        width: widget.width,
        padding: widget.padding,
        child: widget.isEditing
    ? TextFormField(
        controller: widget.controller,
        onTap: () {context.read<TtsService>().speak("Editing Review Text");},
        maxLines: null,
        style: TextStyle(
          fontSize: 14,
          fontFamily: theme.fontFamily,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Enter your review here',
          hintStyle: TextStyle(color: Colors.grey, fontFamily: theme.fontFamily),
          isDense: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
        ),
      )
    : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with spoiler toggle button
          if (widget.spoilers && !widget.mine)
            Row(
              children: [
                const Spacer(), // pushes button to the right
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showSpoilers = !_showSpoilers;
                    });
                  },
                  child: Text(
                    _showSpoilers ? 'Hide Spoiler' : 'Show Spoiler',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 2), 
          Stack(
            children: [
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: theme.fontFamily,
                ),
              ),
              if (widget.spoilers && !_showSpoilers && !widget.mine)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class ChatBubblePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  ChatBubblePainter({
    this.fillColor = Colors.white,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path();

    path.moveTo(26, 0);

    path.lineTo(size.width - 16, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 16);

    path.lineTo(size.width, size.height - 16);
    path.quadraticBezierTo(
        size.width, size.height, size.width - 16, size.height);

    path.lineTo(26, size.height);
    path.quadraticBezierTo(10, size.height, 10, size.height - 16);

    path.lineTo(10, 40);
    path.lineTo(0, 30);
    path.lineTo(10, 20);

    path.lineTo(10, 16);
    path.quadraticBezierTo(10, 0, 26, 0);

    path.close();

    canvas.drawPath(path, fillPaint);

    if (borderWidth > 0) {
      canvas.drawPath(path, borderPaint);
    }

    canvas.drawShadow(path, Colors.black26, 3, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
