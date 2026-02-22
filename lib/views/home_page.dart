import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);


  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("👋 Sesión cerrada. ¡Vuelve pronto!"),
        backgroundColor: unimetBlue,
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
                colors: [unimetBlue, Color(0xFF2C5E8C)],
              ),
            ),
          ),
          
          const _BackgroundBlobs(),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                
                // Se creó la "search bar" para optimizar el diseño, no es funcional
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books_outlined, 
                             size: 80, 
                             color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 10),
                        const Text(
                          "Explora el catálogo pronto...",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
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
                "BookLoop",
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
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                onPressed: () {},
              ),
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
          const Text('© BookLoop • UNIMET', 
            style: TextStyle(color: Colors.white60, fontSize: 12)),
          const Spacer(),
          TextButton(
            onPressed: onTerms,
            child: const Text('Términos y condiciones', 
              style: TextStyle(color: Colors.white70, fontSize: 12)),
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
    final p1 = Paint()..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 100, p1);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.5), 150, p1);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.8), 120, p1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}