import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'package:bookloop_unimet/views/chat_list_page.dart';
import 'admin_dashboard_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; 


class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);
  static const Color cardBrown = Color(0xFFD2A679);
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
                    ? AdminDashboardView(onBack: () => setState(() => _showDashboard = false))
                    : _buildCatalogView(homeVM, MediaQuery.of(context).size.height), 
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


Widget _buildDashboardView() {
  return Column(
    children: [
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

  Widget _buildImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        color: cardBrown,
        child: const Center(
          child: Icon(Icons.menu_book, color: Colors.white, size: 50),
        ),
      );
    }
    
    try {
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } catch (e) {
      debugPrint("Error decodificando imagen: $e");
      return Container(
        color: cardBrown,
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 50),
        ),
      );
    }
  }

  Widget _buildSearchBar(HomeViewModel homeVM) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: TextField(
        onChanged: (value) => homeVM.updateSearchQuery(value),
        decoration: const InputDecoration(
          hintText: "Buscar libros, guías...",
          border: InputBorder.none,
          icon: Icon(Icons.search, color: unimetBlue),
        ),
      ),
    );
  }

  Widget _buildCatalogView(HomeViewModel homeVM, double screenHeight) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCategoryFilter(homeVM),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 200), 
            constraints: BoxConstraints(minHeight: screenHeight * 0.7),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 40, top: 30, bottom: 20),
                  child: Text("Catálogo de Libros", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: unimetBlue)),
                ),
                _buildBooksGrid(homeVM),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildCategoryFilter(HomeViewModel vm) {
    final categories = ["TODO", "FACES", "Ingeniería", "Humanidades", "Derecho"];

    const Color brownBtn = cardBrown;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...categories.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              final isSelected = vm.selectedCategory == cat;

              final bool isTodo = cat == "TODO";
              final String label = isTodo ? "Todo" : cat;

              final chip = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => vm.setCategory(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? unimetOrange : brownBtn,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.black.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isSelected ? 0.18 : 0.12),
                          blurRadius: isSelected ? 10 : 8,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isTodo) ...[
                          const Icon(Icons.apps_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              final bool addSeparator = i == 0;

              return Row(
                children: [
                  chip,
                  if (addSeparator)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 30,
                      width: 1.2,
                      color: Colors.white.withOpacity(0.35),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksGrid(HomeViewModel homeVM) {
    return StreamBuilder(
      stream: homeVM.filteredMaterialsStream, 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint("Error en el Stream: ${snapshot.error}");
          return const Center(child: Text("Ocurrió un error al cargar el catálogo."));
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(child: Text("No hay libros disponibles."));
        }

        final docs = snapshot.data as List; 

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 40, right: 40, bottom: 40),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.60,
            crossAxisSpacing: 40,
            mainAxisSpacing: 40,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildBookCard(data); 
          },
        );
      },
    );
  }

  Widget _buildBookCard(Map<String, dynamic> data) {
    final String status = (data['status'] ?? 'disponible').toString().toLowerCase();
    final bool isAvailable = status == 'disponible';

    final String titulo = (data['title'] ?? '').toString();
    final String autor = (data['author'] ?? '').toString();
    final String materia = (data['subject'] ?? '').toString();

    return Container(
      decoration: BoxDecoration(
        color: cardBrown,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Portada + badge estado
          Expanded(
            flex: 9,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(data['imageUrl']),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          isAvailable ? "Disponible" : "No disponible",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Texto
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    titulo,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Colors.black87,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    autor.isEmpty ? "—" : autor,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        child: Text(
                          materia.isEmpty ? "—" : materia,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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