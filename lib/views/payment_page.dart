import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/payment_viewmodel.dart';

class PaymentPage extends StatefulWidget {
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

  // 1. FUNCIÓN QUE LANZA EL SIMULADOR
  Future<void> _processPaymentAndRegister() async {
    if (selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona un monto para continuar.")),
      );
      return;
    }

    final String cleanAmount = selectedAmount!.replaceAll('\$', '').replaceAll(',', '.');
    final double amountValue = double.parse(cleanAmount);

    // Navegamos a nuestra pasarela propia
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => MockPaypalScreen(
          amount: amountValue,
          onPaymentComplete: (paypalEmail, paypalPass) {
            Navigator.pop(context); // Cerramos el simulador
            _ejecutarRegistroFirebase(); // Registramos en la BD
          },
        ),
      ),
    );
  }

  // 2. FUNCIÓN DE REGISTRO EN FIREBASE
  Future<void> _ejecutarRegistroFirebase() async {
    final vm = context.read<PaymentViewModel>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: unimetOrange),
      ),
    );

    final ok = await vm.registrarConMembresia(
      email: widget.email,
      password: widget.password,
      rol: widget.rol,
      montoDonado: selectedAmount!,
    );

    if (!mounted) return;
    Navigator.pop(context); 

    if (ok) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? "Error al registrar"), backgroundColor: Colors.red),
      );
    }
  }

  // 3. DIÁLOGO DE ÉXITO
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(
          "¡Donación de $selectedAmount exitosa!\n\nTu cuenta (${widget.email}) ha sido activada correctamente.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.of(context).pushNamedAndRemoveUntil('/edit_profile', (route) => false);
              },
              child: const Text("Completar mi perfil", style: TextStyle(fontWeight: FontWeight.bold, color: unimetOrange)),
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
      body: Stack(
        children: [
          // Fondo gradiente
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF081827), Color(0xFF14324A), Color(0xFF204F73)],
                ),
              ),
            ),
          ),
          // Capas decorativas
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _DotPatternPainter()))),
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BlobPainter()))),
          
          // Contenido Principal
          Center(
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
                    const Text("Tu aporte ayuda a la comunidad UNIMET. Realiza una donación para activar tu cuenta.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 30),
                    // Cuadrícula de montos
                    Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      alignment: WrapAlignment.center,
                      children: ["\$0,99", "\$1,99", "\$4,99", "\$9,99", "\$15,99", "\$19,99"].map((amount) {
                        final bool isSelected = selectedAmount == amount;
                        return GestureDetector(
                          onTap: () => setState(() => selectedAmount = amount),
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: isSelected ? unimetOrange : unimetBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Simulador seguro vía ", style: TextStyle(fontSize: 13, color: Colors.black54)),
                        Icon(Icons.paypal, color: Color(0xFF003087), size: 20),
                        Text(" PayPal", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003087))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 4. CLASE DEL SIMULADOR (DENTRO DEL MISMO ARCHIVO)
// ---------------------------------------------------------
class MockPaypalScreen extends StatefulWidget {
  final double amount;
  final Function(String email, String password) onPaymentComplete;

  const MockPaypalScreen({super.key, required this.amount, required this.onPaymentComplete});

  @override
  State<MockPaypalScreen> createState() => _MockPaypalScreenState();
}

class _MockPaypalScreenState extends State<MockPaypalScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handlePayment() async {
    String email = _emailController.text.trim();
    if (!email.endsWith('@gmail.com')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Solo correos @gmail.com"), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    widget.onPaymentComplete(email, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text("PayPal Simulation", style: TextStyle(color: Colors.black))),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text("Pagar \$${widget.amount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Correo Gmail")),
            const SizedBox(height: 15),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Contraseña")),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePayment,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0070BA)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Pagar Ahora", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 5. PAINTERS (DIBUJOS DE FONDO)
// ---------------------------------------------------------
class _BlobPainter extends CustomPainter {
  const _BlobPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.8), 150, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.02);
    for (double i = 0; i < size.width; i += 20) {
      for (double j = 0; j < size.height; j += 20) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}