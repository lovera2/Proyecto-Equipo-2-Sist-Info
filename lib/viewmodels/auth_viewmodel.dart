import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel(this._authService);

  bool isLoading=false;
  String? errorMessage;

  bool get isLoggedIn => _authService.currentUser != null;
  String? get email => _authService.currentUser?.email;

  Future<bool> login(String email,String password) async {
    isLoading=true;
    errorMessage=null;
    notifyListeners();

    try{
      await _authService.login(email,password);
      return true;
    }catch(e){
      errorMessage=e.toString();
      return false;
    }finally{
      isLoading=false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}