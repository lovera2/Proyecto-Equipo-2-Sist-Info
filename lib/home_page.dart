import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Colores
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: unimetBlue,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 1000;

          return Stack(
            children: [
              // Fondo circulos
              Positioned.fill(child: _BackgroundBlobs()),

              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      onLogin: () => _goLogin(context),
                      onRegister: () => _goRegister(context),
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
                                      Expanded(child: _LeftHero()),
                                      const SizedBox(width: 24),
                                      Expanded(child: _RightCard(
                                        onLogin: () => _goLogin(context),
                                        onRegister: () => _goRegister(context),
                                      )),
                                    ],
                                  )
                                : ListView(
                                    children: [
                                      _LeftHero(),
                                      const SizedBox(height: 18),
                                      _RightCard(
                                        onLogin: () => _goLogin(context),
                                        onRegister: () => _goRegister(context),
                                      ),
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

  void _goLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _goRegister(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Términos y condiciones (TBD)'),
        content: const Text(
          'TBD: Documento corto con reglas de uso, conducta y privacidad.\n\n'
          'Sugerencia mínima:\n'
          '• Solo correos institucionales UNIMET.\n'
          '• Conducta respetuosa en chats.\n'
          '• Cumplimiento de entrega/devolución.\n'
          '• Protección de datos según lineamientos UNIMET.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onTerms;

  const _TopBar({
    required this.onLogin,
    required this.onRegister,
    required this.onTerms,
  });

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Ícono/Logo pequeño
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.menu_book, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Text(
            'BookLoop',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const Spacer(),

          if (isWide) ...[
            _NavLink('¿Qué es?', onTap: () => _snack(context, 'Sección: ¿Qué es BookLoop?')),
            _NavLink('Misión', onTap: () => _snack(context, 'Sección: Misión')),
            _NavLink('Visión', onTap: () => _snack(context, 'Sección: Visión')),
            _NavLink('Términos', onTap: onTerms),
            const SizedBox(width: 12),
          ],

          OutlinedButton(
            onPressed: onRegister,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            child: const Text('Crear cuenta'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: unimetOrange,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _NavLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _NavLink(this.text, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _LeftHero extends StatelessWidget {
  const _LeftHero();

  static const Color unimetBlue = Color(0xFF1B3A57);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Más que\nlibros',
            style: TextStyle(
              color: Colors.white,
              fontSize: 54,
              height: 1.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'BookLoop es una plataforma exclusiva para la comunidad UNIMET '
            'que centraliza el préstamo de material académico físico.\n\n'
            'Permite publicar, buscar y coordinar préstamos con trazabilidad.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 18),
          Text('Misión', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text(
            'Proporcionar a la comunidad docente y estudiantil una plataforma centralizada, segura y exclusiva '
            'que facilite el préstamo y circulación de material académico.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          SizedBox(height: 14),
          Text('Visión', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text(
            'Ser la plataforma de referencia en la UNIMET para la reutilización organizada de material académico, '
            'reduciendo la dependencia de canales informales.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RightCard extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _RightCard({
    required this.onLogin,
    required this.onRegister,
  });

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/bookloop_logo.png',
            height: 150,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tu acceso comienza aquí',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: unimetBlue),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Regístrate con correo institucional y activa tu cuenta para acceder a las funciones completas.',
            style: TextStyle(color: Colors.black54, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          ElevatedButton(
            onPressed: onLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: unimetOrange,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRegister,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: const BorderSide(color: unimetBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Crear cuenta', style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Acceso exclusivo UNIMET.\nLa membresía se valida luego del registro.',
            style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onTerms;

  const _Footer({required this.onTerms});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      child: Row(
        children: [
          const Text(
            '© BookLoop • Proyecto académico UNIMET',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const Spacer(),
          TextButton(
            onPressed: onTerms,
            child: const Text('Términos y condiciones', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlobPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withOpacity(0.06);
    final p2 = Paint()..color = Colors.white.withOpacity(0.04);

    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.30), size.width * 0.22, p1);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.62), size.width * 0.28, p2);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.28), size.width * 0.22, p2);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.68), size.width * 0.30, p1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}