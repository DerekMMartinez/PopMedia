import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pop_media/session/user_session.dart';
import 'login_page.dart';
import 'home_page.dart';

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("AuthGate build: checking auth state...");
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          UserSession.uid = snapshot.data!.uid;
          return HomePage();
        }
        return LoginPage();
     },
    );
  }
}