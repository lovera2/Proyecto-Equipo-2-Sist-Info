import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentPage extends StatefulWidget {
  // Recibimos los datos desde RegisterPage
  final String email;
  final String password;
  final String rol;

  const PaymentPage({
    super.key,
    required this.email,
    required this.password,
    required this.rol,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);
  
  String? selectedAmount; 

  // --- EL MOMENTO DE LA VERDAD: REGISTRO REAL EN FIREBASE ---
  Future<void> _processPaymentAndRegister() async {
    if (selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona un monto para continuar."))
      );
      return;
    }

    // 1. Mostrar el indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: unimetOrange),
      ),
    );

    try {
      // 2. Simulamos el retraso de red de 2 segundos
      await Future.delayed(const Duration(seconds: 2));

      // 3. CREACIÓN DEL USUARIO EN FIREBASE AUTH
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: widget.email, 
            password: widget.password
          );

      // 4. GUARDADO DE PERFIL EN CLOUD FIRESTORE
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
        'email': widget.email,
        'rol': widget.rol,
        'monto_donado': selectedAmount,
        'fecha_registro': FieldValue.serverTimestamp(),
        'status': 'activo',
      });

      // 5. Quitar el loading y mostrar éxito
      if (!mounted) return;
      Navigator.pop(context); // Quita el CircularProgress
      _showSuccessDialog();

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Quita el CircularProgress
      
      String errorMsg = "Ocurrió un error en el registro";
      if (e.code == 'email-already-in-use') errorMsg = "⚠️ Este correo ya está en uso.";
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error de conexión"), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(
          "¡Donación de $selectedAmount exitosa!\n\nTu cuenta (${widget.email}) ha sido activada correctamente en BookLoop.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.of(context).popUntil((route) => route.isFirst); // Regresa al inicio
              },
              child: const Text("Empezar a usar BookLoop", style: TextStyle(fontWeight: FontWeight.bold, color: unimetOrange)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: unimetBlue,
      appBar: AppBar(
        title: const Text("Membresía & Donaciones", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("¿Te gusta BookLoop?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: unimetBlue)),
                const SizedBox(height: 15),
                const Text(
                  "Tu aporte nos ayuda a cubrir los costos de los servidores y a seguir mejorando la herramienta para toda la comunidad UNIMET.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 30),
                
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: ["\$0,99", "\$1,99", "\$4,99", "\$9,99", "\$15,99", "\$19,99"].map((amount) {
                    bool isSelected = selectedAmount == amount;
                    return GestureDetector(
                      onTap: () => setState(() => selectedAmount = amount),
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: isSelected ? unimetOrange : unimetBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _processPaymentAndRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unimetOrange,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Realizar Donación", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("El pago se descontará de tu cuenta de ", style: TextStyle(fontSize: 13, color: Colors.black54)),
                    Icon(Icons.paypal, color: Color(0xFF003087), size: 20),
                    Text(" PayPal", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003087), fontSize: 14)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}