import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  //Estilos base del desarrollo
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  //Navegación 
  void _goLogin(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));

  void _goRegister(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));

  //Acciones de sesión 
  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("👋 Sesión cerrada. ¡Vuelve pronto!"),
        backgroundColor: unimetOrange,
      ),
    );

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  //Diálogos informativos 
  void _showInfoDialog(BuildContext context, String titulo, String contenido) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final maxH = MediaQuery.of(dialogContext).size.height * 0.75;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            titulo,
            style: const TextStyle(
              color: StartPage.unimetBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: maxH,
            ),
            child: SingleChildScrollView(
              child: Text(
                contenido,
                style: const TextStyle(fontSize: 15, height: 1.45),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Entendido",
                style: TextStyle(
                  color: StartPage.unimetOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTerms(BuildContext context) {
  _showInfoDialog(
    context,
    'Términos y Condiciones',
    'Al usar BookLoop aceptas lo siguiente:\n\n'
    '1) Acceso y verificación\n'
    '• Solo se permite el uso de correos institucionales UNIMET.\n'
    '• La cuenta es personal e intransferible.\n\n'
    '2) Uso responsable de la plataforma\n'
    '• Mantén un trato respetuoso en chats y publicaciones.\n'
    '• Está prohibido publicar contenido ofensivo, fraudulento o engañoso.\n'
    '• BookLoop puede suspender cuentas ante evidencias de abuso.\n\n'
    '3) Préstamos y devoluciones\n'
    '• Al solicitar/aceptar un préstamo te comprometes a cumplir fecha, condiciones y lugar acordados.\n'
    '• El usuario que recibe el material es responsable de cuidarlo y devolverlo en el estado acordado.\n'
    '• En caso de pérdida o daño, ambas partes deben coordinar una solución (reposición o acuerdo).\n\n'
    '4) Seguridad y reportes\n'
    '• BookLoop puede limitar funciones (publicar/solicitar) si detecta patrones de incumplimiento.\n\n'
    '5) Privacidad y datos\n'
    '• Se almacenan datos mínimos para operar la plataforma (correo, datos personales y actividad de préstamos).\n'
    '• No se publican datos sensibles; tú controlas qué muestras en tu perfil.\n\n'
    '6) Alcance del servicio\n'
    '• BookLoop es una herramienta de coordinación; no garantiza la disponibilidad de material.\n'
    '• La UNIMET y el equipo de BookLoop no se responsabilizan por acuerdos fuera de la plataforma.\n',
  );
}

  @override
  Widget build(BuildContext context) {
    //MVVM: la vista observa el estado del AuthViewModel
    final authVM = context.watch<AuthViewModel>();
    final isLoggedIn = authVM.isLoggedIn;
    final email = authVM.email ?? "";

    return Scaffold(
      backgroundColor: unimetBlue,
      body: Stack(
        children: [
          //Fondo: gradiente principal
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

          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DotPatternPainter(),
              ),
            ),
          ),

          const Positioned.fill(child: _BackgroundBlobs()),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;

                return Column(
                  children: [
                    _TopBar(
                      onLogin: () => _goLogin(context),
                      onRegister: () => _goRegister(context),
                      onLogout: () => _handleLogout(context),
                      onTerms: () => _showTerms(context),
                      onShowInfo: (t, c) => _showInfoDialog(context, t, c),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              child: Column(
                                children: [
                                  if (isWide)
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const Expanded(child: _LeftHero()),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: _RightCard(
                                              isLoggedIn: isLoggedIn,
                                              email: email,
                                              onLogin: () => _goLogin(context),
                                              onRegister: () => _goRegister(context),
                                              onGoHome: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const HomePage()),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Column(
                                      children: [
                                        const _LeftHero(),
                                        const SizedBox(height: 18),
                                        _RightCard(
                                          isLoggedIn: isLoggedIn,
                                          email: email,
                                          onLogin: () => _goLogin(context),
                                          onRegister: () => _goRegister(context),
                                          onGoHome: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const HomePage()),
                                            );
                                          },
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 26),

                                  // Sección: cómo funciona
                                  const _SectionTitle(
                                    title: "Así funciona BookLoop",
                                    subtitle: "Un flujo simple para que el intercambio no se pierda en chats.",
                                  ),
                                  const SizedBox(height: 14),
                                  _HowItWorksRow(isWide: isWide),

                                  const SizedBox(height: 26),

                                  // Sección: por qué no usar grupos
                                  const _SectionTitle(
                                    title: "¿Por qué no seguir intercambiando por grupos?",
                                    subtitle: "Porque se pierde la información y nadie sabe qué sigue.",
                                  ),
                                  const SizedBox(height: 14),
                                  const _GroupsPainCard(),

                                  const SizedBox(height: 26),

                                  // Sección: diseñado para UNIMET
                                  const _SectionTitle(
                                    title: "Diseñado para la UNIMET desde el día 1",
                                    subtitle: "Orden, claridad y acceso institucional.",
                                  ),
                                  const SizedBox(height: 14),
                                  _PillsWrap(isWide: isWide),

                                  const SizedBox(height: 26),

                                  _FinalCTA(
                                    onLogin: () => _goLogin(context),
                                    onRegister: () => _goRegister(context),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    _Footer(onTerms: () => _showTerms(context)),
                  ],
                );
              },
            ),
          ),
        ],
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
    required this.onShowInfo,
  });

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isLoggedIn = authVM.isLoggedIn;
    final email = authVM.email ?? "";
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10, // Espacio vertical si los botones saltan a la línea de abajo
        children: [
          //LOGO Y TEXTO
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.menu_book, color: Colors.white, size: 26),
              SizedBox(width: 8),
              Text(
                'BookLoop',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          
          // 
          if (isWide) 
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavLink(
                  '¿Qué es?',
                  onTap: () => onShowInfo(
                    "¿Qué es BookLoop?",
                    "BookLoop es una plataforma exclusiva para la comunidad UNIMET donde estudiantes y docentes pueden "
                    "publicar, solicitar y coordinar intercambios de material académico con un flujo claro y trazable.",
                  ),
                ),
                _NavLink(
                  'Misión',
                  onTap: () => onShowInfo(
                    "Misión",
                    "Facilitar el acceso a material académico dentro de la UNIMET con una plataforma simple, confiable "
                    "y segura, promoviendo la reutilización organizada.",
                  ),
                ),
                _NavLink(
                  'Visión',
                  onTap: () => onShowInfo(
                    "Visión",
                    "Convertirnos en el punto de referencia dentro de la UNIMET para el intercambio académico, reduciendo "
                    "la dependencia de canales informales y la incertidumbre al conseguir material.",
                  ),
                ),
              ],
            ),

          // BOTONES DE SESIÓN
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isLoggedIn) ...[
                OutlinedButton(
                  onPressed: onRegister,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(horizontal: 12), // Botones más ajustados
                  ),
                  child: const Text('Crear cuenta', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StartPage.unimetOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ] else ...[
                Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  tooltip: 'Cerrar sesión',
                  onPressed: onLogout,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LeftHero extends StatelessWidget {
  const _LeftHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Más que libros.\nUnimetanos ayudando a\nunimetanos.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          SizedBox(height: 14),
          Text(
            "Intercambia libros, guías y material académico sin caos y con un proceso claro.",
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.3),
          ),
          SizedBox(height: 22),

          _BenefitItem(
            icon: Icons.verified_outlined,
            title: "Préstamos seguros",
            subtitle: "Acceso con correo UNIMET y miembros verificados.",
          ),
          SizedBox(height: 16),
          _BenefitItem(
            icon: Icons.search_rounded,
            title: "Acceso equitativo",
            subtitle: "Consigue material sin depender de terceros.",
          ),
          SizedBox(height: 16),
          _BenefitItem(
            icon: Icons.alt_route_rounded,
            title: "Trazabilidad",
            subtitle: "Del “lo necesito” al “ya lo entregué”.",
          ),

          SizedBox(height: 18),
          Divider(color: Colors.white24),
          SizedBox(height: 14),

          Text(
            "Hecho por estudiantes UNIMET",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            "Somos un equipo que se cansó de perder oportunidades por falta de material. "
            "BookLoop nace para ordenar el intercambio académico con una plataforma simple, bonita y confiable.",
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: StartPage.unimetOrange, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.25)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RightCard extends StatelessWidget {
  final bool isLoggedIn;
  final String email;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onGoHome;

  const _RightCard({
    required this.isLoggedIn,
    required this.email,
    required this.onLogin,
    required this.onRegister,
    required this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/bookloop_logo.png',
            height: 120,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.menu_book_rounded, size: 80, color: StartPage.unimetBlue),
          ),
          const SizedBox(height: 14),
          Text(
            !isLoggedIn ? 'Tu acceso comienza aquí' : '¡Bienvenido de nuevo!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: StartPage.unimetBlue),
          ),
          const SizedBox(height: 10),
          Text(
            !isLoggedIn
                ? 'Regístrate con correo institucional y activa tu cuenta.'
                : 'Ya tienes una sesión activa con $email.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 24),
          if (!isLoggedIn) ...[
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: StartPage.unimetOrange,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Iniciar sesión', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRegister,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: StartPage.unimetBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Crear cuenta',
                style: TextStyle(color: StartPage.unimetBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: onGoHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: StartPage.unimetOrange,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "🚀 Listo para explorar",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const Text(
            'Acceso exclusivo UNIMET.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  final bool isWide;
  const _HowItWorksRow({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final bool effectivelyWide = MediaQuery.of(context).size.width > 800;

    if (effectivelyWide) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _GlassCard(
              emoji: "📌",
              title: "Publica o busca",
              subtitle: "Encuentra guías, libros y material por carrera o materia.",
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _GlassCard(
              emoji: "🤝",
              title: "Solicita y coordina",
              subtitle: "Todo queda más claro: disponibilidad y pasos del intercambio.",
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _GlassCard(
              emoji: "✅",
              title: "Cierra y deja feedback",
              subtitle: "Un historial simple para fortalecer la comunidad.",
            ),
          ),
        ],
      );
    }

    // Diseño para CELULAR
    return Column(
      children: const [
        _GlassCard(
          emoji: "📌",
          title: "Publica o busca",
          subtitle: "Encuentra guías, libros y material por carrera o materia.",
        ),
        SizedBox(height: 16),
        _GlassCard(
          emoji: "🤝",
          title: "Solicita y coordina",
          subtitle: "Todo queda más claro: disponibilidad y pasos del intercambio.",
        ),
        SizedBox(height: 16),
        _GlassCard(
          emoji: "✅",
          title: "Cierra y deja feedback",
          subtitle: "Un historial simple para fortalecer la comunidad.",
        ),
      ],
    );
  }
}

class _GroupsPainCard extends StatelessWidget {
  const _GroupsPainCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "En WhatsApp todo se mezcla: mensajes, dudas, “sigue disponible”, y nadie sabe en qué quedó.",
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          SizedBox(height: 12),
          _Bullet(text: "Se pierde la información entre cientos de mensajes."),
          _Bullet(text: "No hay estados: solicitado, aceptado, entregado."),
          _Bullet(text: "No existe historial ni trazabilidad del intercambio."),
          SizedBox(height: 12),
          Text(
            "BookLoop lo ordena con publicaciones claras, filtros y un flujo que se entiende.",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PillsWrap extends StatelessWidget {
  final bool isWide;
  const _PillsWrap({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final items = const [
      _Pill(icon: Icons.school_outlined, text: "2 tipos de cuenta: Estudiante y Docente"),
      _Pill(icon: Icons.search_outlined, text: "Búsqueda por filtros: carrera, materia y tipo"),
      _Pill(icon: Icons.sync_alt_rounded, text: "Flujo con estados: solicitado, aceptado, entregado"),
      _Pill(icon: Icons.verified_user_outlined, text: "Acceso institucional: solo correos UNIMET"),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((w) {
        return SizedBox(
          width: isWide ? 360 : double.infinity,
          child: w,
        );
      }).toList(),
    );
  }
}

class _FinalCTA extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _FinalCTA({required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    // Detectamos si la pantalla es estrecha (celular)
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22), 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: isMobile 
        ? Column( // DISEÑO PARA CELULAR
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "¿Te sumas al piloto?",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                "Crea tu cuenta UNIMET y empieza a moverte con material que sí aparece y sí se entrega.",
                style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 15),
              ),
              const SizedBox(height: 24),
           
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StartPage.unimetOrange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Entrar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRegister,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Registro", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row( // DISEÑO PARA PC
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "¿Te sumas al piloto?",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Crea tu cuenta UNIMET y empieza a moverte con material que sí aparece y sí se entrega.",
                      style: TextStyle(color: Colors.white70, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              ElevatedButton(
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StartPage.unimetOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Iniciar sesión", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onRegister,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Crear cuenta", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _GlassCard({required this.emoji, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row( 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)), 
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: StartPage.unimetOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Colors.white70, fontSize: 18)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.25))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _Footer extends StatelessWidget {
  final VoidCallback onTerms;
  const _Footer({required this.onTerms});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Text('© BookLoop • UNIMET', style: TextStyle(color: Colors.white60, fontSize: 12)),
          const Spacer(),
          TextButton(
            onPressed: onTerms,
            child: const Text('Términos y condiciones', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BlobPainter(), child: const SizedBox.expand());
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintWhiteSoft = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);

    final paintWhiteSofter = Paint()
      ..color = Colors.white.withOpacity(0.045)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final paintOrangeSoft = Paint()
      ..color = StartPage.unimetOrange.withOpacity(0.045)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 56);

    final s = size.shortestSide;

    canvas.drawCircle(Offset(size.width * 0.20, size.height * 0.20), s * 0.26, paintWhiteSoft);

    canvas.drawCircle(Offset(size.width * 0.90, size.height * 0.42), s * 0.30, paintWhiteSofter);

    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.86), s * 0.22, paintOrangeSoft);

    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.88), s * 0.20, paintWhiteSoft);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
        // Fade hacia el centro para no competir con el contenido
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