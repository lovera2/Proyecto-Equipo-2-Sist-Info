import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'publish_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'material_detail_page.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);
  static const Color cardBrown = Color(0xFFD2A679);

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

  void _showTermsDialog(BuildContext context) {
    const contenido =
        "Al usar BookLoop aceptas lo siguiente:\n\n"
        "1) Acceso y verificación\n"
        "• Solo se permite el uso de correos institucionales UNIMET.\n"
        "• La cuenta es personal e intransferible.\n\n"
        "2) Uso responsable de la plataforma\n"
        "• Mantén un trato respetuoso en chats y publicaciones.\n"
        "• Está prohibido publicar contenido ofensivo, fraudulento o engañoso.\n"
        "• BookLoop puede suspender cuentas ante evidencias de abuso.\n\n"
        "3) Préstamos y devoluciones\n"
        "• Al solicitar/aceptar un préstamo te comprometes a cumplir fecha, condiciones y lugar acordados.\n"
        "• El usuario que recibe el material es responsable de cuidarlo y devolverlo en el estado acordado.\n"
        "• En caso de pérdida o daño, ambas partes deben coordinar una solución (reposición o acuerdo).\n\n"
        "4) Seguridad y reportes\n"
        "• BookLoop puede limitar funciones (publicar/solicitar) si detecta patrones de incumplimiento.\n\n"
        "5) Privacidad y datos\n"
        "• Se almacenan datos mínimos para operar la plataforma (correo, datos personales y actividad de préstamos).\n"
        "• No se publican datos sensibles; tú controlas qué muestras en tu perfil.\n\n"
        "6) Alcance del servicio\n"
        "• BookLoop es una herramienta de coordinación; no garantiza la disponibilidad de material.\n"
        "• La UNIMET y el equipo de BookLoop no se responsabilizan por acuerdos fuera de la plataforma.\n";

    showDialog(
      context: context,
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.72;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Términos y Condiciones",
            style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520, maxHeight: maxH),
            child: SingleChildScrollView(
              child: const Text(
                contenido,
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Entendido", style: TextStyle(color: unimetOrange, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  void _showDevSnack(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🛠️ $feature en desarrollo"),
        backgroundColor: unimetBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSearchDevSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: unimetBlue,
        content: Text(
          "🔎 Búsqueda en desarrollo. El catálogo estará disponible pronto.",
          style: TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF28B31), // Unimet Orange
                  Color(0xFFF6A24B), // naranja medio (menos marrón)
                  Color(0xFFF9B862), // naranja claro pero NO blanquecino
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          const _BackgroundBlobs(),
          // Overlay sutil para mejorar contraste del header
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildSearchBar(context, homeVM),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),

                  _buildCategoryFilter(homeVM),
                  const SizedBox(height: 14),

                  // SECCIÓN BLANCA (CATÁLOGO)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 200),
                    constraints: BoxConstraints(
                      // Mantiene el panel blanco completo aunque no haya libros
                      minHeight: screenHeight * 0.62,
                    ),
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
                        const SizedBox(height: 26),
                        Padding(
                          padding: const EdgeInsets.only(left: 40, bottom: 18),
                          child: Text(
                            "Material Reciente",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: unimetBlue,
                            ),
                          ),
                        ),

                        StreamBuilder<QuerySnapshot>(
                          stream: homeVM.materialsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(50.0),
                                child: Center(
                                  child: CircularProgressIndicator(color: unimetBlue),
                                ),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return SizedBox(
                                height: screenHeight * 0.42,
                                child: Padding(
                                  padding: const EdgeInsets.all(50.0),
                                  child: _buildEmptyState(),
                                ),
                              );
                            }

                            final docs = snapshot.data!.docs;

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
                                    child: _buildBookCard(data),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: unimetBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PublishPage(isUserAdmin: true),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Crear / Publicar',
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings_suggest, color: Colors.white, size: 28),
                tooltip: "Funciones Admin",
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (value) {
                  // Pendiente: acciones admin (desarrollo en el proximo hito)
                  if (value.isEmpty) return;
                  final label = value[0].toUpperCase() + value.substring(1);
                  _showDevSnack(context, label);
                },
                itemBuilder: (context) => [
                  _buildAdminMenuItem(Icons.dashboard, "Dashboard"),
                  _buildAdminMenuItem(Icons.people, "Gestión de Perfiles"),
                  _buildAdminMenuItem(Icons.auto_stories, "Gestión de Material"),
                  _buildAdminMenuItem(Icons.filter_list, "Gestión de Filtros"),
                ],
              ),

              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
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
      value: text,
      child: Row(
        children: [
          Icon(icon, color: unimetBlue, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, HomeViewModel vm) {
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
        onTap: () => _showSearchDevSnack(context),
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

  Widget _buildCategoryFilter(HomeViewModel vm) {
    // UI label vs valor real (para que el filtro coincida con lo guardado en Firestore)
    // En PublishPage se guarda la categoría como: Faces, Ingeniería, Humanidades, Derecho.
    final items = <Map<String, String>>[
      {'label': 'Todo', 'value': 'TODO'},
      {'label': 'FACES', 'value': 'Faces'},
      {'label': 'Ingeniería', 'value': 'Ingeniería'},
      {'label': 'Humanidades', 'value': 'Humanidades'},
      {'label': 'Derecho', 'value': 'Derecho'},
    ];

    const Color brownBtn = Color(0xFFD2A679);

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items.map((item) {
            final label = item['label']!;
            final value = item['value']!;

            final isSelected = vm.selectedCategory == value;
            final isTodo = value == 'TODO';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => vm.setCategory(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      constraints: const BoxConstraints(minHeight: 52),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
                            color: Colors.black.withOpacity(isSelected ? 0.18 : 0.12),
                            blurRadius: isSelected ? 10 : 8,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: isTodo
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.apps_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text(
                                  'Todo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                  // separador visual después de "Todo" para dejar claro que no es una facultad
                  if (isTodo)
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Container(
                        width: 2,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "No hay libros en esta categoría",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
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

  Widget _buildImage(String? url) {
    const String defaultCover =
        'https://img.freepik.com/vector-gratis/cubierta-libro-azul-vector-top-view_1017-31355.jpg';

    if (url == null || url.isEmpty) {
      return Image.network(defaultCover, fit: BoxFit.cover);
    }

    final isBase64 = !url.startsWith('http') && !url.startsWith('blob');

    if (isBase64) {
      try {
        return Image.memory(
          base64Decode(url),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Image.network(defaultCover, fit: BoxFit.cover),
        );
      } catch (_) {
        return Image.network(defaultCover, fit: BoxFit.cover);
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Image.network(defaultCover, fit: BoxFit.cover),
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
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const Spacer(),
          TextButton(
            onPressed: onTerms,
            child: const Text(
              'Términos y condiciones',
              style: TextStyle(color: Colors.white70, fontSize: 12),
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
    // círculos grandes y suaves
    final soft = Paint()..color = Colors.white.withOpacity(0.035);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.22), 180, soft);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.58), 240, soft);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.12), 140, soft);

    // puntitos tipo “ruido” muy sutil
    final dots = Paint()..color = Colors.white.withOpacity(0.025);
    const step = 42.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        // variación simple sin random (determinístico)
        final r = ((x + y) % 3 == 0) ? 1.2 : 0.8;
        canvas.drawCircle(Offset(x + 10, y + 14), r, dots);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
