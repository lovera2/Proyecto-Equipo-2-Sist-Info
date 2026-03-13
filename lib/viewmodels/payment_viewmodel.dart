import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class PaymentViewModel extends ChangeNotifier {
  //Manejo de estado y flujo de registro con membresía
  final AuthService _authService;
  final UserService _userService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
Future<bool> sumarDonacionExtra({
  required String userEmail, 
  required String montoNuevoString,
  String? paypalEmailIngresado, 
}) async {
  try {
    // solo correos con dominio @gmail.com
    if (paypalEmailIngresado != null && !paypalEmailIngresado.endsWith('@gmail.com')) {
      print("Error: El correo de PayPal debe ser @gmail.com");
      return false; 
    }

    double montoASumar = double.tryParse(montoNuevoString) ?? 0.0;

    final userDoc = await _db.collection('usuarios')
        .where('email', isEqualTo: userEmail) 
        .get();

    if (userDoc.docs.isNotEmpty) {
      final docId = userDoc.docs.first.id;
      final datosActuales = userDoc.docs.first.data();
      
     String montoTexto = datosActuales['monto_donado']?.toString() ?? "0";
double montoActual = double.tryParse(montoTexto.replaceAll('\$', '').replaceAll(',', '.')) ?? 0.0;

double nuevoTotal = montoActual + montoASumar;

await _db.collection('usuarios').doc(docId).update({
  'monto_donado': "\$${nuevoTotal.toStringAsFixed(2).replaceAll('.', ',')}",
});
      return true;
    } else {
      print("No se encontró el usuario en Firebase");
      return false;
    }
  } catch (e) {
    print("Error en la donación: $e");
    return false;
  }
}
  
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

      // simulamos un circulito de carga para que se vea mas realista todo
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
