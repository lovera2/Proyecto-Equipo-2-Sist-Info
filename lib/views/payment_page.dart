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

    final vm = context.read<PaymentViewModel>();

    if (vm.isLoading) return;

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
      final msg = vm.errorMessage ?? "❌ Error de conexión";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
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
                Navigator.pop(dialogContext); // cerrar el dialog
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/edit_profile',
                  (route) => false,
                );
              },
              child: const Text(
                "Completar mi perfil",
                style: TextStyle(fontWeight: FontWeight.bold, color: unimetOrange),
              ),
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
          // Fondo con gradiente (igual estilo StartPage)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.45, 1.0],
                  colors: [
                    Color(0xFF081827),
                    Color(0xFF14324A),
                    Color(0xFF204F73),
                  ],
                ),
              ),
            ),
          ),

          // Glow sutil
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.1,
                    colors: [
                      Color(0x332D5E8B),
                      Color(0x00000000),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pattern sutil
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotPatternPainter(),
              ),
            ),
          ),

          // Blobs suaves
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BlobPainter(),
              ),
            ),
          ),

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
                    const Text(
                      "¿Te gusta BookLoop?",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: unimetBlue),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Tu aporte nos ayuda a cubrir los costos de los servidores y a seguir mejorando la herramienta para toda la comunidad UNIMET. Por favor, realiza una donación a fin de poder utilizar el servicio.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
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
                            child: Center(
                              child: Text(
                                amount,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
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
                      child: const Text(
                        "Realizar Donación",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("El pago se descontará de tu cuenta de ", style: TextStyle(fontSize: 13, color: Colors.black54)),
                        Icon(Icons.paypal, color: Color(0xFF003087), size: 20),
                        Text(" PayPal", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003087), fontSize: 14)),
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

class _BlobPainter extends CustomPainter {
  const _BlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paintWhiteSoft = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);

    final paintWhiteSofter = Paint()
      ..color = Colors.white.withOpacity(0.045)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final paintOrangeSoft = Paint()
      ..color = _PaymentPageState.unimetOrange.withOpacity(0.045)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 56);

    final s = size.shortestSide;

    canvas.drawCircle(Offset(size.width * 0.20, size.height * 0.20), s * 0.26, paintWhiteSoft);
    canvas.drawCircle(Offset(size.width * 0.90, size.height * 0.42), s * 0.30, paintWhiteSofter);
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.86), s * 0.22, paintOrangeSoft);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.88), s * 0.20, paintWhiteSoft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.035);

    final stepX = (size.width / 26).clamp(18.0, 44.0);
    final stepY = (size.height / 18).clamp(18.0, 52.0);
    final r = (size.shortestSide / 520).clamp(1.2, 2.0);

    double y = 0;
    int row = 0;
    while (y <= size.height) {
      final xOffset = (row.isEven ? stepX * 0.15 : stepX * 0.55);
      double x = xOffset;
      while (x <= size.width) {
        final dx = (x - size.width * 0.55).abs() / (size.width * 0.55);
        final dy = (y - size.height * 0.35).abs() / (size.height * 0.55);
        final fade = (1.0 - (dx * 0.55 + dy * 0.45)).clamp(0.15, 1.0);

        dotPaint.color = Colors.white.withOpacity(0.028 * fade);
        canvas.drawCircle(Offset(x, y), r, dotPaint);

        x += stepX;
      }
      y += stepY;
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
