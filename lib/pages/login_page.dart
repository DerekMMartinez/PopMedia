import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/widgets/forgot_password_popup.dart';
import '../auth/auth_service.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  String _errorMessage = "";
  bool _passwordVisible = false;

  void _showForgotPassword() async{
    if(!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ForgotPasswordPopup()
    );
  }

  bool get _isDesktop {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('login_page'),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF72B8D9),
        centerTitle: true,
        title: Image.asset(
          'assets/logo/popLogo.png',
          height: 60,
          fit: BoxFit.contain,
        ),
      ),
      body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/backgrounds/login_screen.png',
            fit: !_isDesktop ? BoxFit.fill : BoxFit.contain,
          ),
        ),

        SafeArea(
  child: LayoutBuilder(
    builder: (context, constraints) {
      return Stack(
        children: [
          /// LOGIN FORM
          Positioned(
            top: constraints.maxHeight * 0.45, 
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 260,
                child: _buildLoginForm(),
              ),
            ),
          ),

          /// DISCLAIMER
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: const Text(
              "This product uses the TMDB API but is not endorsed or certified by TMDB",
              style: TextStyle(fontSize: 8),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    },
  ),
)
      ],
    ), 
  );
  }

  Widget _buildLoginForm(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          key: const Key('email_field'),
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            labelText: "Email",
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 18,
            ),
          ),
        ),
        TextField(
          controller: _passwordController,
          key: const Key('pass_field'),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: "Password",
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              vertical: 6,
              horizontal: 18,
            ),
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _passwordVisible = !_passwordVisible; // toggle
                });
              },
              child: Icon(
                _passwordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
            ),
          ),
          obscureText: !_passwordVisible,
        ),
        SizedBox(height: 2),
        Center(
        child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
                side: BorderSide(
                  color: Colors.black,
                  width: 2.0,
                ),
              ),
            ),
            key: const Key('login_button'),
            onPressed: () async {
              if (_emailController.text.trim().isEmpty) {
                setState(() =>
                    _errorMessage = "The email field cannot be blank.");
                return;
              }
              if (_passwordController.text.trim().isEmpty) {
                setState(() =>
                    _errorMessage = "The password field cannot be blank.");
                return;
              }
              try {
                final credential = await _auth.signIn(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                );

                if (!mounted) return;

                String uid = credential.user!.uid;
                final user = await DataService.checkUser(uid: uid);

                if (user == false) {
                  throw Exception('User cannot be found');
                }

                UserSession.setUserId(uid);

                final isAdmin = await DataService.checkAdmin(uid: uid);
                
                if(isAdmin){
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/adminDash',
                    (route) => false,
                  );
                }
                else{
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/homePage',
                    (route) => false,
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                setState(() {
                  _errorMessage = 'Email or password is incorrect';
                });
                print(e.message);
              } catch (e) {
                if (!mounted) return;
                setState(() {
                  _errorMessage = "Something went wrong.";
                });
              }
            },
            child: Text("Sign In", style: TextStyle(
              fontFamily: 'ComicSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),),
          ),
        ),
        SizedBox(height: 2),
        Center(
        child: TextButton(
          style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
                side: BorderSide(
                  color: Colors.black,
                  width: 2.0,
                ),
              ),
            ),
          key: const Key('login_create_account_button'),
          onPressed: () async {
            Navigator.pushNamed(context, '/createAccountPage');
          },
          child: Text("Create Account", style: TextStyle(
              fontFamily: 'ComicSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),),
        ),
        ),
        TextButton(
          onPressed: () async {
            _showForgotPassword();
          },
          child: Text("Forgot Password", style: TextStyle(
              fontFamily: 'ComicSans',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),),
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
      ]
    );
  }
}
