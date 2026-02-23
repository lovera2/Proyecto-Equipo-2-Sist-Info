import 'package:flutter/foundation.dart';

class RegisterViewModel extends ChangeNotifier {
  //Validaciones de registro
  String? errorMessage;

  bool validarCorreoUnimet(String email) {
    final e=email.trim().toLowerCase();
    return e.endsWith('@unimet.edu.ve') || e.endsWith('@correo.unimet.edu.ve');
  }

  bool validarPassword(String password) {
    return password.trim().length >= 6;
  }

  // Retorna true si está todo bien, y deja el mensaje en errorMessage si falla
  bool validarFormulario({required String email, required String password}) {
    errorMessage=null;

    if(email.trim().isEmpty || password.trim().isEmpty){
      errorMessage="❌ Por favor, llena todos los campos";
      return false;
    }

    if(!validarCorreoUnimet(email)){
      errorMessage="❌ Error: Usa tu correo institucional UNIMET";
      return false;
    }

    if(!validarPassword(password)){
      errorMessage="❌ La clave debe tener al menos 6 caracteres";
      return false;
    }

    return true;
  }
}
