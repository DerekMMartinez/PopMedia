import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register
  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() {
    return _auth.signOut();
  }
  // Request password reset
  Future<String> requestPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return 'true';
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is not valid.';
        default:
          return 'An unexpected error occurred. Please try again.';
      }
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
