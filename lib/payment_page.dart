import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);
  
  String? selectedAmount; // El usuario tiene plena libertad de aportar la cantidad que desee

  void _processPayment() {
    if (selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona un monto para continuar."))
      );
      return;
    }

    // Aqui se hace una simple simulacion de pago, no se hace uso de la API(aun) pero muestra el proceso en tiempo real 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: unimetOrange),
      ),
    );

    // Se hace una pequenna simulacion de un retraso de red de 2 segundos para hacer mas realista la transferencia
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Un indicador de que el pago fue exitoso y redirecciona al inicio de pantalla, 
      //cuando este lista la pagina principal de la vista de libros, etc, pues se ver eso
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          "¡Donación exitosa! Tu cuenta ha sido activada correctamente en BookLoop.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Se ierra el diálogo
                Navigator.of(context).popUntil((route) => route.isFirst); // la funcion que hace el regeso al inicio que se menciono antes
              },
              child: const Text("Empezar a usar BookLoop", style: TextStyle(fontWeight: FontWeight.bold)),
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
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
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
                
                // Colocamos las cantidades que nos parecieron logicas para opciones de pago libre
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: ["\$0,99", "\$1,99", "\$4,99", "\$9,99", "\$15,99", "\$19,99"].map((amount) {
                    bool isSelected = selectedAmount == amount;
                    return GestureDetector(
                      onTap: () => setState(() => selectedAmount = amount),
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: isSelected ? unimetOrange : unimetBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _processPayment,
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
                  children: [
                    const Text("El pago se descontará de tu cuenta de ", style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const Icon(Icons.paypal, color: Color(0xFF003087), size: 20),
                    const Text(" PayPal", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003087), fontSize: 14)),
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