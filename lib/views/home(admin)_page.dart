import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/admin_user_management_viewmodel.dart';
import 'admin_dashboard_page.dart';
import 'admin_user_management_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'material_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';
import 'admin_material_management_page.dart';
import '../viewmodels/admin_material_viewmodel.dart';
import '../services/admin_material_service.dart';


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

  Future<void> _refrescarCategorias() async {
    await context.read<HomeViewModel>().cargarCategorias();
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
    final double screenHeight = MediaQuery.of(context).size.height;

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
            child: _showDashboard
                ? Column(
                    children: [
                      Expanded(
                        child: AdminDashboardView(
                          onBack: () => setState(() => _showDashboard = false),
                          onOpenMenu: () async {
                          },
                        ),
                      ),
                      _Footer(onTerms: () => _showTermsDialog(context)),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        _AdminTopHeader(
                          onBack: () {},
                          onOpenDashboard: () => setState(() => _showDashboard = true),
                          onRefreshCategorias: _refrescarCategorias,
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            children: [
                              _buildSearchBar(homeVM), 
                              const SizedBox(height: 25), 
                            ],
                          ),
                        ),

                        _buildCategoryFilter(homeVM),
                        const SizedBox(height: 15),

                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 200),
                          constraints: BoxConstraints(minHeight: screenHeight * 0.65),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              const Padding(
                                padding: EdgeInsets.only(left: 40, bottom: 20),
                                child: Text(
                                  "Material Reciente", 
                                  style: TextStyle(
                                    fontSize: 22, 
                                    fontWeight: FontWeight.bold, 
                                    color: unimetBlue
                                  ),
                                ),
                              ),

                        StreamBuilder<List<QueryDocumentSnapshot>>(
                          stream: homeVM.filteredMaterialsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(50.0),
                                child: Center(child: CircularProgressIndicator(color: unimetOrange)),
                              );
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(50.0),
                                child: _buildEmptyState(),
                              );
                            }

                            final docs = snapshot.data!;

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
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MaterialDetailPage(
                                            materialId: doc.id,
                                            materialData: data,
                                          ),
                                        ),
                                      );
                                    },
                                    child: _buildBookCard(doc.id, data),
                                  ),
                                );
                              },
                            );
                          },
                       ), 
                      ],
                    ),
                  ),
                  
                  _Footer(onTerms: () => _showTermsDialog(context)),
                ],
              ),
            ),
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
          hintText: "Buscar por título, autor o facultad",
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: unimetOrange),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(HomeViewModel vm) {
    final categories = ["TODO", ...vm.categorias];

    final categoriasSinDuplicados = <String>[];
    final categoriasNormalizadas = <String>{};

    for (final categoria in categories) {
      final normalizada = categoria
          .trim()
          .toLowerCase()
          .replaceAll('á', 'a')
          .replaceAll('é', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ú', 'u')
          .replaceAll('ñ', 'n');

      if (!categoriasNormalizadas.contains(normalizada)) {
        categoriasNormalizadas.add(normalizada);
        categoriasSinDuplicados.add(categoria);
      }
    }

    const Color brownBtn = cardBrown;

    Widget buildChip(String cat, int i) {
      final isSelected = vm.selectedCategory == cat;
      final bool isTodo = cat == "TODO";
      final String label = isTodo ? "Todo" : cat;

      final chip = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => vm.setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected ? unimetBlue : brownBtn,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      isSelected ? 0.18 : 0.12,
                    ),
                    blurRadius: isSelected ? 10 : 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isTodo) ...[
                    const Icon(
                      Icons.apps_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final bool addSeparator = i == 0;

      return Row(
        mainAxisSize: MainAxisSize.min,
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
    }

    final chips = categoriasSinDuplicados
        .asMap()
        .entries
        .map((entry) => buildChip(entry.value, entry.key))
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 200),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            thumbVisibility: categoriasSinDuplicados.length > 6,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: chips,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

Widget _buildBookCard(String materialId, Map<String, dynamic> data) {
  String _normStatus(String raw) {
    final s = raw.toLowerCase().trim();
    return s
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  ({String label, Color color}) _mapStatus(String statusNorm) {
    final bool isDisponible = statusNorm == 'disponible';

    final bool isReservado = <String>{
      'reservado',
      'pendiente',
      'esperando_confirmacion',
      'solicitado',
    }.contains(statusNorm);

    final bool isPrestamo = <String>{
      'rentado',
      'devolucion_pendiente',
      'en_prestamo',
    }.contains(statusNorm);

    final String label = isDisponible
        ? 'Disponible'
        : (isReservado
            ? 'Reservado'
            : (isPrestamo ? 'En préstamo' : 'No disponible'));

    final Color color =
        isDisponible ? Colors.green : (isReservado ? Colors.amber : Colors.red);

    return (label: label, color: color);
  }

  Widget _statusChip(String effectiveStatusNorm) {
    final mapped = _mapStatus(effectiveStatusNorm);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: mapped.color,
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
        mapped.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  final String statusMaterialNorm =
      _normStatus((data['status'] ?? 'disponible').toString());

  final String title = (data['title'] ?? 'Sin título').toString();
  final String author = (data['author'] ?? 'Autor desconocido').toString();
  final String materia = (data['subject'] ?? '').toString();

  final dynamic rawImage = data['imageUrl'];
  final String? imageBase64 = rawImage is String ? rawImage : null;

  Widget imageWidget =
      const Center(child: Icon(Icons.book, size: 50, color: Colors.grey));

  try {
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      final cleanBase64 =
          imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;

      imageWidget = Image.memory(
        base64Decode(cleanBase64),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
        ),
      );
    }
  } catch (e) {
    imageWidget = const Center(
      child: Icon(Icons.error_outline, size: 50, color: Colors.red),
    );
  }

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
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageWidget,
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .where('materialId', isEqualTo: materialId)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snap) {
                        String effective = statusMaterialNorm;

                        if (snap.hasData && snap.data!.docs.isNotEmpty) {
                          bool foundPrestamo = false;
                          bool foundReservado = false;

                          for (final d in snap.data!.docs) {
                            final m =
                                (d.data() as Map<String, dynamic>?) ?? {};
                            final s = _normStatus(
                              (m['status'] ?? '').toString(),
                            );

                            if (<String>{
                              'rentado',
                              'devolucion_pendiente',
                              'en_prestamo',
                            }.contains(s)) {
                              foundPrestamo = true;
                            }

                            if (<String>{
                              'reservado',
                              'pendiente',
                              'esperando_confirmacion',
                              'solicitado',
                            }.contains(s)) {
                              foundReservado = true;
                            }
                          }

                          if (foundPrestamo) {
                            effective = 'rentado';
                          } else if (foundReservado) {
                            effective = 'reservado';
                          }
                        }

                        return _statusChip(effective);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
                if (materia.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    materia,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "No hay libros en esta categoría", 
            style: TextStyle(color: Colors.grey[500], fontSize: 16)
          ),
        ],
      ),
    );
  }

}

class _AdminTopHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onOpenDashboard;
  final Future<void> Function() onRefreshCategorias;

  const _AdminTopHeader({
    required this.onBack,
    required this.onOpenDashboard,
    required this.onRefreshCategorias,
  });

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _mostrarMenuAdmin(BuildContext context) async {
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
              Icon(Icons.dashboard, color: Color(0xFF1B3A57), size: 20),
              SizedBox(width: 12),
              Text('Dashboard'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'perfiles',
          child: Row(
            children: [
              Icon(Icons.people, color: Color(0xFF1B3A57), size: 20),
              SizedBox(width: 12),
              Text('Gestión de Usuarios'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'materiales',
          child: Row(
            children: [
              Icon(Icons.book, color: Color(0xFF1B3A57), size: 20),
              SizedBox(width: 12),
              Text('Gestión de Material'),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'dashboard') {
      onOpenDashboard();
      return;
    } else if (value == 'perfiles') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AdminUserManagementViewModel(),
            child: const AdminUserManagementPage(),
          ),
        ),
      );
      if (context.mounted) {
        await onRefreshCategorias();
      }
    } else if (value == 'materiales') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AdminMaterialViewModel(AdminMaterialService()),
            child: const AdminMaterialManagementPage(),
          ),
        ),
      );
      if (context.mounted) {
        await onRefreshCategorias();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'BookLoop ADMIN',
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
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/publish'),
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
                tooltip: 'Publicar material',
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChatListPage()),
                  );
                },
                tooltip: 'Mis chats y notificaciones',
              ),
              const SizedBox(width: 5),
              IconButton(
                icon: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                tooltip: 'Mi perfil',
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings_suggest,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => _mostrarMenuAdmin(context),
                tooltip: 'Mostrar menú',
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 28,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    _handleLogout(context);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
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
    final paint = Paint()..color = Colors.white.withOpacity(0.05);
    
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.1), 100, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.5), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.9), 120, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}