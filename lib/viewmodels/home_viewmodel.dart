import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeViewModel extends ChangeNotifier {
  //Estado de Home y reglas de UI
  final AuthService _authService;

  //Estado observable
  String _searchQuery = "";

  HomeViewModel(this._authService);

  String get searchQuery => _searchQuery;

  //Acción: desarrollo/ejecución de cambios
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  //Acción: logout
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}
