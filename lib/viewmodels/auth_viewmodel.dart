import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  //Desarrollo capa de estado y reglas de UI
  final AuthService _authService;

  AuthViewModel(this._authService);

  //Estado observable  
  bool isLoading = false;
  String? errorMessage;

  //Estado derivado 
  bool get isLoggedIn => _authService.currentUser != null;
  String? get email => _authService.currentUser?.email;

 //Mapeo de errores 
  String _mensajeAuthES(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
        return "❌ Correo o contraseña incorrectos.";
      case 'user-not-found':
        return "❌ No existe una cuenta con ese correo.";
      case 'invalid-email':
        return "❌ El correo no es válido.";
      case 'too-many-requests':
        return "⏳ Demasiados intentos. Intenta de nuevo en unos minutos.";
      case 'network-request-failed':
        return "🌐 Error de red. Revisa tu conexión e intenta de nuevo.";
      case 'user-disabled':
        return "⛔ Esta cuenta fue deshabilitada.";
      default:
        return "❌ No se pudo iniciar sesión. Intenta nuevamente.";
    }
  }

  //Acción: login 
  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = _mensajeAuthES(e.code);
      return false;
    } catch (_) {
      errorMessage = "❌ Ocurrió un error inesperado. Intenta nuevamente.";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  //Acción: logout
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}
