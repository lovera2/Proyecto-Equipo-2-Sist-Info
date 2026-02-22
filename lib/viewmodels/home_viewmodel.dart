import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthService _authService;
  String _searchQuery = "";

  HomeViewModel(this._authService);

  String get searchQuery => _searchQuery;

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}