import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Importante para las imágenes Base64
import 'material_detail_page.dart';
import 'package:bookloop_unimet/views/chat_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Colores de la UNIMET
  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);
  static const Color cardBrown = Color(0xFFD2A679);
  bool _hasNewNotifications = true;
  Future<void> _handleLogout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: unimetOrange,
        content: Text(
          "👋 Sesión cerrada. ¡Vuelve pronto!",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );

    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
    // Calculamos la altura de la pantalla para el ajuste visual
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo 
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2A3F),
                  unimetBlue,
                  Color(0xFF2C5E8C),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Blobs de fondo (decoración)
          const _BackgroundBlobs(),
          
          // Contenido Principal con Scroll
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context),
                  
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

                  // SECCIÓN BLANCA (LIBROS)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 200), 
                    constraints: BoxConstraints(
                      minHeight: screenHeight * 0.65, 
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        
                        Padding(
                          padding: const EdgeInsets.only(left: 40, bottom: 20),
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
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 280,
                                childAspectRatio: 0.56,
                                crossAxisSpacing: 28,
                                mainAxisSpacing: 28,
                              ),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                // Usamos InkWell dentro de un Material para mejor respuesta visual
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      print("¡Clic detectado en el libro: ${data['title']}!");
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

  //MÉTODOS AUXILIARES 

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo y Título
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              const Text(
                "BookLoop",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Botones de acción
          Row(
            children: [
              // para publicar 
              Container(
                decoration: BoxDecoration(
                  color: unimetOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/publish'),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Publicar material',
                ),
              ),
              const SizedBox(width: 10),
              
              // aparicion de un punto rojo en notificaciones 
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                    onPressed: () {
                      setState(() {
                        _hasNewNotifications = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ChatListPage()),
                      );
                    },
                    tooltip: 'Mis chats y notificaciones',
                  ),
                  if (_hasNewNotifications)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: unimetBlue, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 5),

              // Botón Perfil
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
              
              // Menú de opciones 
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                onSelected: (value) {
                  if (value == 'logout') _handleLogout(context);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: unimetBlue),
                        SizedBox(width: 10),
                        Text("Cerrar Sesión")
                      ]
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

  bool _isMultilineText(String text, TextStyle style, double maxWidth, {int maxLines = 2}) {
    if (text.trim().isEmpty) return false;

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    // Si se renderiza en más de una línea, lo tratamos como multiline
    return painter.computeLineMetrics().length > 1;
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
          // Portada (rectangular, tipo libro)
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen ocupa todo el espacio disponible sin forzar aspectRatio extra.
                    _buildImage(data['imageUrl']),

                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                          isAvailable ? 'Disponible' : 'No disponible',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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

          // Texto + chip (sin overflows)
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                children: [
                  // Bloque de título y autor ocupa el espacio disponible y mantiene el chip abajo.
                  Expanded(
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
                        const SizedBox(height: 8),
                        Text(
                          autor.isEmpty ? '—' : autor,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Chip de materia siempre alineado abajo
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: Text(
                        materia.isEmpty ? '—' : materia,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.1,
                        ),
                      ),
                    ),
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
    const String defaultCover = 'https://img.freepik.com/vector-gratis/cubierta-libro-azul-vector-top-view_1017-31355.jpg';

    if (url == null || url.isEmpty) {
      return Image.network(
        defaultCover,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }

    final bool isBase64 = !url.startsWith('http') && !url.startsWith('blob') && !url.startsWith('data:image');

    if (isBase64) {
      try {
        return Image.memory(
          base64Decode(url),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Image.network(
            defaultCover,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        );
      } catch (_) {
        return Image.network(
          defaultCover,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        );
      }
    }

    if (url.startsWith('data:image')) {
      try {
        final clean = url.contains(',') ? url.split(',')[1] : url;
        return Image.memory(
          base64Decode(clean),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Image.network(
            defaultCover,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        );
      } catch (_) {
        return Image.network(
          defaultCover,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        );
      }
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => Image.network(
        defaultCover,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
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
    final p1 = Paint()..color = Colors.white.withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.30), 180, p1);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.70), 220, p1);

    final p2 = Paint()..color = Colors.white.withOpacity(0.035);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 50, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}