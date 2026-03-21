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
import 'donation_screen.dart'; 


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
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // 1. DEFINIMOS SI ES PC O CELULAR
    final bool isWide = screenWidth > 850; 

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
                          onOpenMenu: () async {},
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
                          child: Center(
                            child: SizedBox(
                              width: isWide ? 600 : double.infinity,
                              child: _buildSearchBar(homeVM),
                            ),
                          ),
                        ),

                        // Llamamos al filtro y le pasamos isWide
                        _buildCategoryFilter(homeVM, isWide), 
                        const SizedBox(height: 15),

                        Container(
                          width: double.infinity,
                          // Margen dinámico para que no se ponga el texto en vertical
                          margin: EdgeInsets.symmetric(horizontal: isWide ? 200 : 15),
                          constraints: BoxConstraints(minHeight: screenHeight * 0.65),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              Padding(
                                padding: EdgeInsets.only(left: isWide ? 40 : 20, bottom: 20),
                                child: const Text(
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
                                    return const Center(child: Padding(
                                      padding: EdgeInsets.all(50.0),
                                      child: CircularProgressIndicator(color: unimetOrange),
                                    ));
                                  }
                                  
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return _buildEmptyState();
                                  }

                                  final docs = snapshot.data!;

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 15, vertical: 20),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isWide ? 4 : 2,
                                    childAspectRatio: isWide ? 0.65 : 0.58, 
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,  
                                  ),
                                    itemCount: docs.length,
                                    itemBuilder: (context, index) {
                                      final doc = docs[index];
                                      final data = doc.data() as Map<String, dynamic>;
                                      return InkWell(
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

  Widget _buildCategoryFilter(HomeViewModel vm, bool isWide) {
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

    final chips = categoriasSinDuplicados.asMap().entries.map((entry) {
      final String cat = entry.value;
      final int i = entry.key;
      final bool isSelected = vm.selectedCategory == cat;
      final String label = cat == "TODO" ? "Todo" : cat;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => vm.setCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? unimetBlue : cardBrown,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          if (i == 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              height: 30,
              width: 1.2,
              color: Colors.white.withOpacity(0.35),
            ),
        ],
      );
    }).toList();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isWide ? 200 : 15), 
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips, 
        ),
      ),
    );
  }

  Widget _buildBookCard(String materialId, Map<String, dynamic> data) {
    String _normStatus(String raw) => raw.toLowerCase().trim().replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ñ', 'n');

    ({String label, Color color}) _mapStatus(String statusNorm) {
      if (statusNorm == 'disponible') return (label: 'Disponible', color: const Color(0xFF4CAF50)); // El verde del usuario normal
      if (<String>{'reservado', 'pendiente', 'esperando_confirmacion', 'solicitado'}.contains(statusNorm)) return (label: 'Reservado', color: Colors.amber);
      return (label: 'En préstamo', color: Colors.red);
    }

    final String statusMaterialNorm = _normStatus((data['status'] ?? 'disponible').toString());
    final mappedStatus = _mapStatus(statusMaterialNorm);
    final String title = (data['title'] ?? 'Sin título').toString();
    final String author = (data['author'] ?? 'Autor desconocido').toString();
    final String materia = (data['subject'] ?? '').toString();
    final dynamic rawImage = data['imageUrl'];
    final String? imageBase64 = rawImage is String ? rawImage : null;

    Widget imageWidget = const Center(child: Icon(Icons.book, size: 40, color: Colors.grey));
    try {
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        final cleanBase64 = imageBase64.contains(',') ? imageBase64.split(',').last : imageBase64;
        imageWidget = Image.memory(base64Decode(cleanBase64), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      }
    } catch (e) {
      imageWidget = const Center(child: Icon(Icons.broken_image, color: Colors.grey));
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBrown.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBrown, width: 10.0), 
      ),
      child: Column(
        children: [
          // PARTE SUPERIOR: IMAGEN + CHIP SUPERPUESTO
          Expanded(
            flex: 11, // La imagen es ligeramente más grande que el texto
            child: Stack(
              clipBehavior: Clip.none, // Permite que el botón flote fuera del límite
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: imageWidget,
                  ),
                ),
                // Botón "Disponible" flotando en el medio
                Positioned(
                  bottom: -12,
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: mappedStatus.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        mappedStatus.label,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // PARTE INFERIOR: TEXTO Y MATERIA
          Expanded(
            flex: 9, 
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 15), // Espacio para que el botón no tape el texto
                  Text(
                    title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87, height: 1.1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    author,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54),
                  ),
                  
                  const Spacer(),
                  
                  // La "pastillita" de la materia (ej. "matematicas")
                  if (materia.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white, // Fondo blanco
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBrown, width: 1.5), // Borde marrón
                      ),
                      child: Text(
                        materia,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
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
      position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: const [
        PopupMenuItem(value: 'perfiles', child: Text('Gestión de Usuarios')),
        PopupMenuItem(value: 'materiales', child: Text('Gestión de Material')),
      ],
    );
    if (value == 'perfiles') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(create: (_) => AdminUserManagementViewModel(), child: const AdminUserManagementPage())));
    } else if (value == 'materiales') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider(create: (_) => AdminMaterialViewModel(AdminMaterialService()), child: const AdminMaterialManagementPage())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 750;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. PARTE IZQUIERDA: Logo y texto
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onBack, 
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(), // Quita el margen extra invisible
              ),
              const SizedBox(width: 4),
              const Icon(Icons.menu_book, color: Colors.white, size: 22),
              const SizedBox(width: 4),
              const Text('BookLoop', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (isWide) const Text(' ADMIN', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),

          
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown, 
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 8), 
                  _circleBtn(context, Icons.add, const Color(0xFF1B3A57), () => Navigator.pushNamed(context, '/publish')),
                  const SizedBox(width: 4),
                  _circleBtn(context, Icons.notifications_none, null, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage()))),
                  const SizedBox(width: 4),
                  _circleBtn(context, Icons.person_outline, null, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
                  const SizedBox(width: 4),
                  _circleBtn(context, Icons.settings_suggest, null, () => _mostrarMenuAdmin(context)),
                  const SizedBox(width: 4),
                  // 3. MENÚ DE LOS 3 PUNTITOS
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white), 
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    offset: const Offset(0, 45),
                    onSelected: (v) {
                      if (v == 'logout') _handleLogout(context);
                      if (v == 'donate') Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationScreen()));
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'donate',
                        child: Row(
                          children: [
                            Icon(Icons.volunteer_activism, color: Color(0xFFF28B31)), // Ícono de las manos con el corazón
                            SizedBox(width: 10),
                            Text('Realizar donación', style: TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Color(0xFF1B3A57)), // Ícono de salir azul marino
                            SizedBox(width: 10),
                            Text('Cerrar sesión', style: TextStyle(color: Colors.black87)),
                          ],
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

  // Mantenemos tu diseño original (cuadrados redondeados de 34x34)
  Widget _circleBtn(BuildContext context, IconData icon, Color? bg, VoidCallback onTap) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: bg ?? Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10), // Tu forma original intacta
      ),
      child: IconButton(padding: EdgeInsets.zero, icon: Icon(icon, color: Colors.white, size: 18), onPressed: onTap),
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