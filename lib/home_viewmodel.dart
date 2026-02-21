import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Root cause of UI lag is often blocking the main thread. 
  // We use async/await to keep the UI responsive.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners(); // View will show a loading state if needed

    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error during logout: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}