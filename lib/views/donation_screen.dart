import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

import '../viewmodels/payment_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'payment_page.dart';
import 'chat_list_page.dart'; 

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  final List<double> donationAmounts = [0.99, 1.99, 4.99, 9.99, 15.99, 19.99];
  double? selectedAmount = 9.99;

  void _processDonation() {
    if (selectedAmount == null) return;
    final email = context.read<ProfileViewModel>().email ?? "";

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MockPaypalScreen(
          amount: selectedAmount!,
          onPaymentComplete: (payEmail, payPass) async {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator(color: unimetOrange)),
            );

            final ok = await context.read<PaymentViewModel>().sumarDonacionExtra(
                  userEmail: email,
                  montoNuevoString: selectedAmount.toString(),
                );
            
            if (!mounted) return;
            Navigator.pop(context); // Cierra diálogo carga

            if (ok) {
              Navigator.pop(context); // Cierra PayPal
              Navigator.pop(context); // Cierra Donaciones
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("¡Donación de \$${selectedAmount!.toStringAsFixed(2)} exitosa! Gracias por tu apoyo 🧡"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<ProfileViewModel>().cargarPerfil();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Error al procesar la donación."),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: unimetBlue,
      body: Stack(
        children: [
          
          Positioned.fill(
            child: CustomPaint(
              painter: _HeaderDiagonalPainter(),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center, 
                            children: const [
                              Icon(Icons.menu_book, color: Colors.white, size: 28),
                              SizedBox(width: 10), 
                              Text(
                                "BookLoop",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: unimetOrange,
                              borderRadius: BorderRadius.circular(14), 
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: () => Navigator.pushNamed(context, '/publish'),
                              tooltip: 'Publicar material',
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28),
                            onPressed: () {
                              final email = context.read<ProfileViewModel>().email?.toLowerCase() ?? '';
                              final route = email.startsWith('admin') ? '/home_admin' : '/home_page';
                              Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
                            },
                            tooltip: 'Inicio',
                          ),
                          const SizedBox(width: 10),
                          // CAMPANA
                          IconButton(
                            icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
                            }, 
                            tooltip: 'Notificaciones',
                          ),
                          const SizedBox(width: 5),
                          // PERFIL
                          IconButton(
                            icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context), 
                            tooltip: 'Perfil',
                          ),
                         
                          PopupMenuButton<String>(
                            
                            icon: const Icon(Icons.more_vert, color: Colors.white, size: 28), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            onSelected: (value) async {
                              if (value == 'donate') {
                                
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => const DonationScreen())
                                );
                              } else if (value == 'logout') {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                  
                                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); 
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              // donaciones
                              const PopupMenuItem(
                                value: 'donate',
                                child: Row(
                                  children: [
                                    Icon(Icons.volunteer_activism, color: Color(0xFFF28B31)), 
                                    SizedBox(width: 10),
                                    Text('Realizar donación'),
                                  ],
                                ),
                              ),
                              // cerrar sesion
                              const PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Color(0xFF1B3A57)), 
                                    SizedBox(width: 10),
                                    Text('Cerrar sesión'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                //Recuadro blanco
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 850), 
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15), 
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            
                            // Título y flecha
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: unimetBlue, size: 26),
                                  onPressed: () => Navigator.pop(context),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Donaciones",
                                  style: TextStyle(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold, 
                                    color: unimetBlue, 
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Texto descriptivo
                            const Text(
                              "¿Te gusta BookLoop? Si te hemos ayudado a encontrar ese libro o guía que necesitabas, puedes realizar una donación voluntaria. Tu aporte, por pequeño que sea, nos ayuda a cubrir los costos de los servidores y a seguir mejorando la herramienta para todos.",
                              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 45),

                            
                            Wrap(
                              spacing: 25,
                              runSpacing: 25,
                              alignment: WrapAlignment.center,
                              children: donationAmounts.map((amount) {
                                final isSelected = selectedAmount == amount;
                                return InkWell(
                                  onTap: () => setState(() => selectedAmount = amount),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 150, 
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFFCAE5E) : const Color(0xFF2C5E8C),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "\$${amount.toStringAsFixed(2).replaceAll('.', ',')}",
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.normal),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 50),

                            // Botón principal de pago
                            SizedBox(
                              width: 300,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: selectedAmount != null ? _processDonation : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: unimetOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  "Realizar Donación",
                                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.normal),
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Footer PayPal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("El pago se descontará de tu cuenta de ", style: TextStyle(fontSize: 14, color: Colors.black87)),
                                Icon(Icons.paypal, color: Colors.blue[800], size: 20),
                                Text(" PayPal", style: TextStyle(fontSize: 15, color: Colors.blue[800], fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pintor para replicar la franja oscura diagonal del fondo
class _HeaderDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0F2A3F); 
    final path = Path();
    path.moveTo(0, size.height * 0.15); // 
    path.lineTo(size.width, size.height * 0.05); 
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}