import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pop_media/session/user_session.dart';
import '../auth/auth_service.dart';
import 'package:pop_media/service/data_service.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});
  @override
  State<CreateAccountPage> createState() => _CreateAccountState();
}


class _CreateAccountState extends State<CreateAccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _auth = AuthService();
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  String _errorMessage = "";
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _usernameError;
  String? _nameError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF72B8D9),
        centerTitle: true,
          title: Image.asset(
            'assets/logo/popLogo.png',
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
                    'assets/backgrounds/popArt/verticalBackground.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Align(
              alignment: Alignment.center,
              child: const Text(
                'Create Account',
                style: TextStyle(
                  fontFamily: 'ComicSans',
                  fontSize: 20, 
                  fontWeight: FontWeight.bold),
              ),),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Email: ',
                    style: TextStyle(fontFamily: 'ComicSans', fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(width: 42),

                  Expanded(
                    child: TextField(
                      key: const Key('create_email'),
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'example@gmail.com',
                        border: OutlineInputBorder(),
                        errorText: _emailError,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Password: ',
                    style: TextStyle(fontFamily: 'ComicSans', fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextField(
                      key: const Key('create_password'),
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: 'password',
                        border: OutlineInputBorder(),
                        errorText: _passwordError,
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
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Confirm\nPassword: ',
                    style: TextStyle(fontFamily: 'ComicSans', fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextField(
                      key: const Key('confirm_password'),
                      controller: _confirmController,
                      decoration: InputDecoration(
                        hintText: 'confirm password',
                        border: OutlineInputBorder(),
                        errorText: _confirmError,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _confirmVisible = !_confirmVisible; // toggle
                            });
                          },
                          child: Icon(
                            _confirmVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      obscureText: !_confirmVisible,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Username: ',
                    style: TextStyle(fontFamily: 'ComicSans', fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: TextField(
                      key: const Key('create_username'),
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'janedoe123',
                        border: OutlineInputBorder(),
                        errorText: _usernameError,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Name: ',
                    style: TextStyle(fontFamily: 'ComicSans', fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(width: 39),

                  Expanded(
                    child: TextField(
                      key: const Key('create_name'),
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Jane Doe',
                        border: OutlineInputBorder(),
                        errorText: _nameError,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Bio: ',
                style: TextStyle(fontFamily: 'ComicSans', fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 260,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('create_bio'),
                        controller: _bioController,
                        expands: true,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Write your bio here...',
                          border: OutlineInputBorder(),
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
                    TextButton(
                      key: const Key('create_submit'),
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
                      onPressed: () async {
                        bool hasError = false;

                        setState(() {
                          _emailError = null;
                          _passwordError = null;
                          _confirmError = null;
                          _usernameError = null;
                          _nameError = null;
                          _errorMessage = "";

                          if (_emailController.text.trim().isEmpty) {
                            _emailError = "The email field cannot be blank.";
                            hasError = true;
                          }
                          if (_passwordController.text.trim().isEmpty) {
                            _passwordError = "The password field cannot be blank.";
                            hasError = true;
                          }
                          if (_usernameController.text.trim().isEmpty) {
                            _usernameError = "The username field cannot be blank.";
                            hasError = true;
                          }
                          if (_usernameController.text.trim().contains(" ")) {
                            _usernameError = "The username cannot have any spaces";
                            hasError = true;
                          }
                          if (_usernameController.text.trim().length > 20) {
                            _usernameError = "The username cannot be longer than 20 characters";
                            hasError = true;
                          }
                          if (_nameController.text.trim().isEmpty) {
                            _nameError = "The name field cannot be blank.";
                            hasError = true;
                          }
                          if (_nameController.text.trim().length > 20) {
                            _nameError = "The name cannot be longer than 20 characters";
                            hasError = true;
                          }
                          if(_passwordController.text.trim().compareTo(_confirmController.text.trim()) != 0){
                            _passwordError = "Passwords do not match.";
                            _confirmError = "Passwords do not match.";
                            hasError = true;
                          }
                        });

                        if (!hasError) {
                          bool taken = await DataService.checkUsernameTaken(
                            username: _usernameController.text.trim(),
                            email: _emailController.text.trim(),
                          );

                          if (taken) {
                            setState(() {
                              _usernameError = "Username already taken.";
                            });
                            hasError = true;
                          }
                        }

                        if(hasError) return;

                        try {
                          UserCredential result =
                            await _auth.register(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );

                          String uid = result.user!.uid;
                          await DataService.postUser(
                            uid: uid,
                            username: _usernameController.text,
                            email: _emailController.text,
                            name: _nameController.text,
                            bio: _bioController.text,
                            profile_pic_url: "https://d21jyc5i6ygo3u.cloudfront.net/defaultProfilePic.png"
                          );

                          await DataService.postBadgeEarned(bid: 1, uid: uid, earned_at: DateTime.now());

                          UserSession.setUserId(uid);

                          setState(() => _errorMessage = "Account Created!");
                          Navigator.pushReplacementNamed(context, '/homePage', arguments:{'showWelcomeBadge': true});
                        } on FirebaseAuthException catch (e) {
                          if(e.message != null && e.message!.contains("email"))
                            setState(() => _emailError = e.message!);
                          else if(e.message != null && (e.message!.contains("password") || e.message!.contains("Password")))
                            setState(() => _passwordError = e.message!);
                          else
                            setState(() => _errorMessage = e.message ?? "Unknown error");
                        } catch (e) {
                          setState(() => _errorMessage = e.toString());
                        }
                      },
                      child: const Text("Create Account", style: TextStyle(
                        fontFamily: 'ComicSans',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),),
                    ),
                    SizedBox(height: 4),
                    TextButton(
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
                      onPressed: () async {
                        Navigator.pushReplacementNamed(context, '/loginPage');
                      },
                      child: const Text("Login Page", style: TextStyle(
                        fontFamily: 'ComicSans',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),),
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
        )]
        ),
      ),)
    );
  }
}