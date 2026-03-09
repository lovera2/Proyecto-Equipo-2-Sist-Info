import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'package:bookloop_unimet/views/chat_list_page.dart';


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
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Términos y Condiciones",
            style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold),
          ),
          content: const SingleChildScrollView(
            child: Text(
              "Al usar BookLoop UNIMET, aceptas el intercambio responsable de material académico...",
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar", style: TextStyle(color: unimetOrange)),
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

                Expanded(
                  child: _showDashboard 
                    ? _buildDashboardView() // Función que crearemos abajo
                    : Center( // Tu vista original
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
                    setState(() => _showDashboard = true);
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
                        Text('Gestión de Perfiles'),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatListPage()),
                  );
                },
                tooltip: 'Mis chats y notificaciones',
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                onPressed: () {},
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
          hintText: "Buscar por título, autor o carrera...",
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: unimetOrange),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
Widget _buildDashboardView() {
  return Column(
    children: [
      // Botón para regresar
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _showDashboard = false),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text("Regresar", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildMetricCard("Usuarios Registrados", "150", Icons.people, Colors.blue),
              const SizedBox(height: 15),
              _buildMetricCard("Intercambios Totales", "45", Icons.swap_horiz, Colors.orange),
              const SizedBox(height: 15),
              _buildMetricCard("Libros Activos", "320", Icons.book, Colors.green),
              const SizedBox(height: 20),
              // Aquí podrías agregar tus gráficos
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24)
                ),
                child: const Center(
                  child: Text("Gráfico de Categorías", style: TextStyle(color: Colors.white60)),
                ),
              )
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: unimetBlue)),
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
    // Usamos blanco con muy baja opacidad para el efecto de fondo
    final paint = Paint()..color = Colors.white.withOpacity(0.05);
    
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.1), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.5), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.9), 120, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}