import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';

class PaymentViewModel extends ChangeNotifier {
  //Manejo de estado y flujo de registro con membresía
  final AuthService _authService;
  final UserService _userService;

  PaymentViewModel(this._authService,this._userService);

  //Estado observable
  bool isLoading=false;
  String? errorMessage;

  //Validación del dominio UNIMET
  bool _correoUnimetValido(String email){
    final e=email.toLowerCase().trim();
    return e.endsWith('@unimet.edu.ve') || e.endsWith('@correo.unimet.edu.ve');
  }

  //Acción: registro usuario y creación del perfil en Firestore 
  Future<bool> registrarConMembresia({
    required String email,
    required String password,
    required String rol,
    required String montoDonado,
  }) async {
    isLoading=true;
    errorMessage=null;
    notifyListeners();

    try{
      if(!_correoUnimetValido(email)){
        errorMessage='Debes usar correo institucional UNIMET.';
        return false;
      }

      // Simula el retraso
      await Future.delayed(const Duration(seconds: 2));

      final cred=await _authService.register(email,password);
      final uid=cred.user!.uid;

      await _userService.createUserProfile(
        uid: uid,
        data: {
          'email': email,
          'rol': rol,
          'monto_donado': montoDonado,
          'fecha_registro': FieldValue.serverTimestamp(),
          'status': 'activo',
        },
      );

      return true;

    } on FirebaseAuthException catch(e){
      //Manejo de errores de Firebase
      if(e.code=='email-already-in-use'){
        errorMessage="⚠️ Este correo ya está en uso. Por favor, modifique la dirección de correo.";
      }else if(e.code=='weak-password'){
        errorMessage="❌ La clave es muy débil.";
      }else if(e.code=='invalid-email'){
        errorMessage="❌ El correo es inválido.";
      }else{
        errorMessage="Ocurrió un error en el registro";
      }
      return false;

    } catch(e){
      errorMessage="❌ Error de conexión";
      return false;

    } finally{
      isLoading=false;
      notifyListeners();
    }
  }
}
