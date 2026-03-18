import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/admin_user_management_viewmodel.dart';
import 'admin_dashboard_page.dart';
import 'admin_user_management_page.dart';


class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);
  bool _showDashboard = false;

  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("👋 Sesión cerrada. ¡Vuelve pronto!"),
        backgroundColor: unimetOrange,
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final h = MediaQuery.of(dialogContext).size.height;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Términos y Condiciones",
            style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 520,
            height: h * 0.62,
            child: const SingleChildScrollView(
              child: Text(
                "Al usar BookLoop aceptas lo siguiente:\n\n"
                "1) Acceso y verificación\n"
                "• Solo se permite el uso de correos institucionales UNIMET (docente y estudiante).\n"
                "• La cuenta es personal e intransferible.\n\n"
                "2) Uso responsable\n"
                "• Mantén un trato respetuoso en publicaciones y mensajes.\n"
                "• Está prohibido publicar contenido ofensivo, engañoso o spam.\n"
                "• BookLoop puede limitar o suspender cuentas ante evidencias de abuso.\n\n"
                "3) Préstamos y devoluciones\n"
                "• Al solicitar/aceptar un préstamo te comprometes a cumplir fecha, condiciones y lugar acordados.\n"
                "• Quien recibe el material es responsable de cuidarlo y devolverlo en el estado acordado.\n"
                "• En caso de pérdida o daño, las partes deben coordinar una solución (reposición o acuerdo).\n\n"
                "4) Seguridad y reportes\n"
                "• BookLoop puede limitar funciones (publicar/solicitar) si detecta patrones de incumplimiento.\n\n"
                "5) Privacidad y datos\n"
                "• Se almacenan datos mínimos para operar la plataforma.\n"
                "• No se publican datos sensibles.\n\n"
                "6) Alcance del servicio\n"
                "• BookLoop es una herramienta de coordinación; no garantiza la disponibilidad de material.\n"
                "• La UNIMET y el equipo de BookLoop no se responsabilizan por acuerdos fuera de la plataforma.\n",
                style: TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Entendido", style: TextStyle(color: unimetOrange)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [unimetOrange, Color(0xFFD67628)], 
              ),
            ),
          ),
          
          const _BackgroundBlobs(),

          SafeArea(
            child: Column(
              children: [
                if (!_showDashboard) ...[
                  _buildHeader(context),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildSearchBar(homeVM),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],

                Expanded(
                  child: _showDashboard 
                    ? AdminDashboardView(
                        onBack: () => setState(() => _showDashboard = false),
                        onOpenMenu: () async {
                          final value = await showMenu<String>(
                            context: context,
                            position: const RelativeRect.fromLTRB(1000, 90, 20, 0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            items: const [
                              PopupMenuItem(
                                value: 'dashboard',
                                child: Row(
                                  children: [
                                    Icon(Icons.dashboard, color: unimetBlue, size: 20),
                                    SizedBox(width: 12),
                                    Text('Dashboard'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'perfiles',
                                child: Row(
                                  children: [
                                    Icon(Icons.people, color: unimetBlue, size: 20),
                                    SizedBox(width: 12),
                                    Text('Gestión de Usuarios'),
                                  ],
                                ),
                              ),
                            ],
                          );

                          if (!context.mounted || value == null) return;

                          if (value == 'dashboard') {
                            if (_showDashboard) {
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text('Ya estás en Dashboard.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                            } else {
                              setState(() => _showDashboard = true);
                            }
                            return;
                          }

                          if (value == 'perfiles') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider(
                                  create: (_) => AdminUserManagementViewModel(),
                                  child: const AdminUserManagementPage(),
                                ),
                              ),
                            );
                          }
                        },
                      )
                    : Center( 
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 100,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Panel de Administración',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '(en desarrollo)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                ),

                _Footer(onTerms: () => _showTermsDialog(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              const Text(
                "BookLoop ADMIN",
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 22, 
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          Row(
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings_suggest, color: Colors.white),
                onSelected: (value) {
                  if (value == 'dashboard') {
                    if (_showDashboard) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Ya estás en Dashboard.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                    } else {
                      setState(() => _showDashboard = true);
                    }
                    return;
                  }

                  if (value == 'perfiles') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider(
                          create: (_) => AdminUserManagementViewModel(),
                          child: const AdminUserManagementPage(),
                        ),
                      ),
                    );
                    return;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'dashboard',
                    child: Row(
                      children: [
                        Icon(Icons.dashboard, color: unimetBlue, size: 20),
                        SizedBox(width: 12),
                        Text('Dashboard'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'perfiles',
                    child: Row(
                      children: [
                        Icon(Icons.people, color: unimetBlue, size: 20),
                        SizedBox(width: 12),
                        Text('Gestión de Usuarios'),
                      ],
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: unimetBlue),
                        SizedBox(width: 10),
                        Text("Cerrar Sesión"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildAdminMenuItem(IconData icon, String text) {
    return PopupMenuItem(
      value: text.toLowerCase(),
      child: Row(
        children: [
          Icon(icon, color: unimetBlue, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildSearchBar(HomeViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) => vm.updateSearchQuery(value),
        style: const TextStyle(color: unimetBlue),
        decoration: const InputDecoration(
          hintText: "Buscar por título, autor o facultad",
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: unimetOrange),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Text(
            '© BookLoop • UNIMET', 
            style: TextStyle(color: Colors.white60, fontSize: 12)
          ),
          const Spacer(),
          TextButton(
            onPressed: onTerms,
            child: const Text(
              'Términos y condiciones', 
              style: TextStyle(color: Colors.white70, fontSize: 12)
            ),
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
    return CustomPaint(
      painter: _BlobPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05);
    
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.1), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.5), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.9), 120, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}