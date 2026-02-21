import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importante para el Logout
import 'login_page.dart';
import 'register_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  // --- LÓGICA DE CERRAR SESIÓN ---
  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("👋 Sesión cerrada. ¡Vuelve pronto!"),
        backgroundColor: unimetBlue,
      ),
    );
    // Forzamos el refresco de la página
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  // --- DIÁLOGOS INFORMATIVOS ---
  void _showInfoDialog(BuildContext context, String titulo, String contenido) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(titulo, style: const TextStyle(color: unimetBlue, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450, // Ajusta este valor a tu gusto (400-500 suele ser ideal)
            child: Text(
              contenido, 
              style: const TextStyle(fontSize: 16, height: 1.5), 
              textAlign: TextAlign.justify,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido", style: TextStyle(color: unimetOrange, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showTerms(BuildContext context) {
    _showInfoDialog(context, 'Términos y Condiciones', '• Solo correos institucionales UNIMET.\n• Conducta respetuosa en chats.\n• Cumplimiento estricto de fechas de devolución.\n• Protección de datos según lineamientos de la universidad.');
  }

  void _goLogin(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  void _goRegister(BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: unimetBlue,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 1000;
          return Stack(
            children: [
              Positioned.fill(child: _BackgroundBlobs()),
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      onLogin: () => _goLogin(context),
                      onRegister: () => _goRegister(context),
                      onLogout: () => _handleLogout(context), // Pasamos la función
                      onShowInfo: (tit, cont) => _showInfoDialog(context, tit, cont),
                      onTerms: () => _showTerms(context),
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            child: isWide
                                ? Row(
                                    children: [
                                      const Expanded(child: _LeftHero()),
                                      const SizedBox(width: 24),
                                      Expanded(child: _RightCard(onLogin: () => _goLogin(context), onRegister: () => _goRegister(context))),
                                    ],
                                  )
                                : ListView(
                                    children: [
                                      const _LeftHero(),
                                      const SizedBox(height: 18),
                                      _RightCard(onLogin: () => _goLogin(context), onRegister: () => _goRegister(context)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                    _Footer(onTerms: () => _showTerms(context)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onLogout;
  final VoidCallback onTerms;
  final Function(String, String) onShowInfo;

  const _TopBar({
    required this.onLogin, 
    required this.onRegister, 
    required this.onLogout,
    required this.onTerms, 
    required this.onShowInfo
  });

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;
    // Chequeamos si hay un usuario para mostrar u ocultar botones
    final User? user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: Colors.white, size: 30),
          const SizedBox(width: 12),
          const Text('BookLoop', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (isWide) ...[
            _NavLink('¿Qué es?', onTap: () => onShowInfo("¿Qué es BookLoop?", "Es una plataforma exclusiva para la comunidad UNIMET de préstamo y circulación de material académico. Nuestra plataforma busca conectar a estudiantes y profesores dentro de un entorno seguro, facilitando el acceso equitativo a recursos edicativos mediante la reutilización organizada.")),
            _NavLink('Misión', onTap: () => onShowInfo("Nuestra Misión", "Proporcionar a la comunidad docente y estudiantil de la Universidad Metropolitana una plataforma centralizada, segura y exclusiva, que facilite el préstamo y circulación de material académico, fomentando la reutilización de recursos y el acceso equitativo a las herramientas de aprendizaje.")),
            _NavLink('Visión', onTap:  () => onShowInfo("Nuestra Visión", "Ser la plataforma de referencia para la comunidad de la Universidad Metropolitana en la reutilización organizada de material académico, reduciendo la dependencia de canales informales y la incertidumbre al momento de conseguir recursos.")),
            const SizedBox(width: 12),
          ],
          
          if (user == null) ...[
            OutlinedButton(
              onPressed: onRegister,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54)),
              child: const Text('Crear cuenta', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF28B31)),
              child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white)),
            ),
          ] else ...[
            // SI HAY USUARIO, MOSTRAMOS LOGOUT
            Text(user.email ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              tooltip: 'Cerrar Sesión',
              onPressed: onLogout,
            ),
          ],
        ],
      ),
    );
  }
}

// --- EL RESTO DE TUS COMPONENTES SE MANTIENEN IGUAL ---

class _LeftHero extends StatelessWidget {
  const _LeftHero();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Center(
            child: Text(
              'Más que libros', 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white, 
                fontSize: 48,
                fontWeight: FontWeight.w900, 
              )
            ),
          ),
          SizedBox(height: 24),
          Text(
            'La red oficial de intercambio académico de la UNIMET.', 
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)
          ),
          SizedBox(height: 32),
          
          _BenefitItem(icon: Icons.check_circle_outline, title: 'Préstamos Seguros', subtitle: 'Gestiona tus libros con miembros verificados.'),
          SizedBox(height: 20),
          _BenefitItem(icon: Icons.history_edu, title: 'Acceso Equitativo', subtitle: 'Encuentra material sin depender de terceros.'),
          SizedBox(height: 20),
          _BenefitItem(icon: Icons.volunteer_activism, title: 'Cultura Responsable', subtitle: 'Fomenta la reutilización entre unimetanos.'),
        ],
      ),
    );
  }
}

//Esta clase fue creada con ayuda de Gemini, funciona para mantener los textos alineados a la izquierda, a excepción del título. 

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _BenefitItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFF28B31), size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RightCard extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  const _RightCard({required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(22), 
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/bookloop_logo.png', height: 120, errorBuilder: (context, error, stackTrace) => const Icon(Icons.menu_book, size: 80, color: Color(0xFF1B3A57))),
          const SizedBox(height: 14),
          Text(user == null ? 'Tu acceso comienza aquí' : '¡Bienvenido de nuevo!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1B3A57))),
          const SizedBox(height: 10),
          Text(user == null ? 'Regístrate con correo institucional y activa tu cuenta.' : 'Ya tienes una sesión activa con ${user.email}.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, height: 1.4)),
          const SizedBox(height: 24),
          if (user == null) ...[
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF28B31), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRegister,
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), side: const BorderSide(color: Color(0xFF1B3A57)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Crear cuenta', style: TextStyle(color: Color(0xFF1B3A57), fontWeight: FontWeight.bold)),
            ),
          ] else
            const Text("🚀 Listo para explorar libros", style: TextStyle(color: Color(0xFF1B3A57), fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Divider(),
          const Text('Acceso exclusivo UNIMET.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4)),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _NavLink(this.text, {required this.onTap});
  @override
  Widget build(BuildContext context) => TextButton(onPressed: onTap, child: Text(text, style: const TextStyle(color: Colors.white70)));
}

class _Footer extends StatelessWidget {
  final VoidCallback onTerms;
  const _Footer({required this.onTerms});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Row(children: [const Text('© BookLoop • UNIMET', style: TextStyle(color: Colors.white60, fontSize: 12)), const Spacer(), TextButton(onPressed: onTerms, child: const Text('Términos y condiciones', style: TextStyle(color: Colors.white70, fontSize: 12)))]));
}

class _BackgroundBlobs extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _BlobPainter(), child: const SizedBox.expand());
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.3), 180, p1);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.7), 220, p1);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}