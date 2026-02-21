import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  ProfileViewModel(this._authService,this._userService);

  bool isLoading=false;
  String? errorMessage;

  String? nombre;
  String? email;

  Future<void> cargarPerfil() async {
    isLoading=true;
    errorMessage=null;
    notifyListeners();

    try{
      final user=_authService.currentUser;

      if(user==null){
        nombre=null;
        email=null;
        errorMessage="No hay sesión activa.";
        return;
      }

      // Default desde Auth
      email=user.email;

      final data=await _userService.getUserProfile(user.uid);

      if(data==null){
        nombre=null;
        return;
      }

      final n=data['nombre'];
      if(n is String && n.trim().isNotEmpty){
        nombre=n.trim();
      }else{
        nombre=null;
      }

      final e=data['email'];
      if(e is String && e.trim().isNotEmpty){
        email=e.trim();
      }
    }catch(e){
      errorMessage="Error cargando perfil";
    }finally{
      isLoading=false;
      notifyListeners();
    }
  }
}