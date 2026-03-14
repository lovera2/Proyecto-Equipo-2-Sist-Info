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

  Future<void> _processPaymentAndRegister() async {
    if (selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona un monto para continuar.")),
      );
      return;
    }

    final String cleanAmount = selectedAmount!.replaceAll('\$', '').replaceAll(',', '.');
    final double amountValue = double.parse(cleanAmount);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => MockPaypalScreen(
          amount: amountValue,
          onPaymentComplete: (paypalEmail, paypalPass) {
            Navigator.pop(context); 
            _ejecutarRegistroFirebase(selectedAmount!); 
          },
        ),
      ),
    );
  }

  // modificacion para la existencia de cuentas gratuitas
  void _showFreeAccountWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Atención: Cuenta Gratuita", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            "Al elegir la opción gratuita tienes acceso a todas las funciones pero solo podrás realizar 10 donaciones y préstamos en total.\n\n¿Deseas continuar con tu elección?\n\n(¡Siempre puedes ir a tu perfil para realizar una pequeña donación y tener acceso a préstamos y donaciones ilimitadas!)",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Volver", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
              onPressed: () {
                Navigator.pop(context); 
                _ejecutarRegistroFirebase("\$0,00"); 
              },
              child: const Text("Aceptar y Continuar", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _ejecutarRegistroFirebase(String monto) async {
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
      montoDonado: monto,
    );

    if (!mounted) return;
    Navigator.pop(context); 

    if (ok) {
      _showSuccessDialog(monto);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? "Error al registrar"), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog(String monto) {
    bool esGratis = monto == "\$0,00";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          esGratis ? Icons.info_outline : Icons.check_circle, 
          color: esGratis ? Colors.blue : Colors.green, 
          size: 60
        ),
        content: Text(
          esGratis 
            ? "¡Cuenta creada!\n\nHas iniciado con el plan gratuito (10 intercambios disponibles)."
            : "¡Donación de $monto exitosa!\n\nTu cuenta (${widget.email}) ha sido activada con beneficios ilimitados.",
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
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _DotPatternPainter()))),
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _BlobPainter()))),
          
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
                    
                    const SizedBox(height: 15),

                    // NUEVO BOTÓN aqui se incluyo la opcion dsictutida con franklin para el boton de no pagar nada
                    OutlinedButton(
                      onPressed: _showFreeAccountWarning,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300, width: 2),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                        "Continuar sin donar (\$0,00)", 
                        style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)
                      ),
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

// simulador de paypalS
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