import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;

  Future<String?> signIn(String email, String password) async {
    try {
      print('Attempting sign-in for: $email');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException sign-in error: [${e.code}] ${e.message}');
      return '[${e.code}] ${e.message}';
    } catch (e) {
      print('Generic sign-in error: $e');
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
