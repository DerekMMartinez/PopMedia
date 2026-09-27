import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/auth/auth_service.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class ForgotPasswordPopup extends StatefulWidget {
  const ForgotPasswordPopup({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPopup> createState() => _ForgotPasswordPopupState();
}

class _ForgotPasswordPopupState extends State<ForgotPasswordPopup> {
  final _emailController = TextEditingController();
  final _auth = AuthService();
  String _errorMessage = "";
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              offset: const Offset(4, 6),
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final theme = context.watch<ThemeController>().currentTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ComicTitle(title: 'Reset Password'),
        const SizedBox(height: 5),
        Text(
          'Enter your email to reset your password:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: theme.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          style: const TextStyle(fontSize: 14),
          onTap: () {context.read<TtsService>().speak("Entering Email for Password Reset");},
          decoration: const InputDecoration(
            labelText: "Email",
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 18,
            ),
          ),
        ),
        const SizedBox(height: 5),
        TextButton(
          onPressed: _handleReset,
          child: const ComicTitle(title: "Send reset email", size: 12),
        ),
        TextButton(
          onPressed: () => {
            context.read<TtsService>().speak("Closed Password Reset"),
            Navigator.pop(context),
          },
          child: const ComicTitle(title: "Close", size: 12),
        ),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ComicTitle(title: 'Success!'),
        const SizedBox(height: 16),
        const Text(
          'If an account exists for that email, a reset link has been sent!\n\n'
          'Please check your spam folder if you do not see it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const ComicTitle(title: "Close", size: 12),
        ),
      ],
    );
  }

  Future<void> _handleReset() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        context.read<TtsService>().speak("Error Sending Password Reset, ${_errorMessage}");
        _errorMessage = 'Must input an email';
      });
      return;
    }

    var result =
        await _auth.requestPasswordReset(_emailController.text.trim());

    if (result == 'true') {
      context.read<TtsService>().speak("Password Reset Sent, Check Junk Mail");
      setState(() {
        _sent = true;
      });
    } else {
      setState(() {
        context.read<TtsService>().speak("Error Sending Password Reset, ${_errorMessage}");
        _errorMessage = result;
      });
    }
  }
}