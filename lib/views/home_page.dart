import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // Importante para las imágenes Base64
import 'material_detail_page.dart';
import 'package:bookloop_unimet/views/chat_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donation_screen.dart';
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
  @override
  Widget build(BuildContext context) {
    final homeVM = context.watch<HomeViewModel>();
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 900; // Detecta si es Web o Móvil

    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F2A3F), unimetBlue, Color(0xFF2C5E8C)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          const _BackgroundBlobs(),
          
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 200 : 20, vertical: 10),
                    child: _buildSearchBar(homeVM),
                  ),

                  // Filtro de categorías responsivo
                  _buildCategoryFilter(homeVM, isWide),
                  
                  const SizedBox(height: 15),

                  // SECCIÓN BLANCA (LIBROS) con margen adaptativo
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: isWide ? 200 : 15), 
                    constraints: BoxConstraints(
                      minHeight: size.height * 0.65, 
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
                          padding: EdgeInsets.only(left: isWide ? 40 : 20, bottom: 20),
                          child: const Text(
                            "Material Reciente", 
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                              color: unimetBlue,
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
                              padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 15, vertical: 10),
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 280,
                                childAspectRatio: 0.56,
                                crossAxisSpacing: isWide ? 28 : 15,
                                mainAxisSpacing: isWide ? 28 : 15,
                              ),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
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

  //MÉTODOS AUXILIARES 

  Widget _buildHeader(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Izquierda: Logo
          const Row(
            children: [
              Icon(Icons.menu_book, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                "BookLoop",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Derecha: Acciones en Wrap
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: unimetOrange, borderRadius: BorderRadius.circular(8)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pushNamed(context, '/publish'),
                ),
              ),
              _headerCircleBtn(Icons.home_outlined, () {}), // Ya estamos en home
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chats').where('users', arrayContains: currentUid).snapshots(),
                builder: (context, snapshot) {
                  bool hasActivity = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return Badge(
                    isLabelVisible: hasActivity,
                    backgroundColor: Colors.redAccent,
                    child: _headerCircleBtn(Icons.notifications_none_outlined, () {
                      setState(() {
                        _hasNewNotifications = false;
                      });
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListPage()));
                    }),
                  );
                },
              ),
              _headerCircleBtn(Icons.person_outline, () => Navigator.pushNamed(context, '/profile')),
              
              PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
              padding: EdgeInsets.zero,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              offset: const Offset(0, 45), // Desplaza el menú hacia abajo para no tapar el icono
              onSelected: (value) {
                if (value == 'donate') {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const DonationScreen())
                  );
                }
                if (value == 'logout') {
                  _handleLogout(context);
                }
              },
              itemBuilder: (context) => [
                // Opción de Donar
                const PopupMenuItem(
                  value: 'donate',
                  child: Row(
                    children: [
                      Icon(Icons.volunteer_activism, color: Color(0xFFF28B31)), // Naranja Unimet
                      SizedBox(width: 10),
                      Text(
                        'Realizar donación', 
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                ),
                // Opción de Cerrar Sesión
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Color(0xFF1B3A57)), // Azul Marino Unimet
                      SizedBox(width: 10),
                      Text(
                        'Cerrar sesión', 
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)
                      ),
                    ],
                  ),
                ),
              ],
            )
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCircleBtn(IconData icon, VoidCallback tap) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: IconButton(padding: EdgeInsets.zero, icon: Icon(icon, color: Colors.white, size: 18), onPressed: tap),
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

    const Color brownBtn = cardBrown;

    Widget buildChip(String cat, int i) {
      final isSelected = vm.selectedCategory == cat;
      final bool isTodo = cat == "TODO";
      final String label = isTodo ? "Todo" : cat;

      final chip = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5), // Menos separación entre botones
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => vm.setCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 38), // Altura reducida (antes 52)
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding más pequeño
              decoration: BoxDecoration(
                color: isSelected ? unimetOrange : brownBtn,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.18 : 0.12),
                    blurRadius: isSelected ? 8 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isTodo) ...[
                    const Icon(Icons.apps_rounded, size: 16, color: Colors.white), // Icono más pequeño
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13, // Letra más pequeña (antes 15)
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
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 20, // Línea separadora más pequeña
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
      margin: EdgeInsets.symmetric(horizontal: isWide ? 200 : 10),
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

  Widget _buildBookCard(String materialId, Map<String, dynamic> data) {
    // =============================
    // ESTADO DEL MATERIAL (RF-03)
    // Disponible / Reservado / En préstamo
    // Importante: el estado REAL puede venir de `chats`.
    // Si existe un chat activo/pending para este materialId,
    // esa info manda sobre `materials.status`.
    // =============================

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

      final Color color = isDisponible ? Colors.green : (isReservado ? Colors.amber : Colors.red);

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

    final String statusMaterialNorm = _normStatus((data['status'] ?? 'disponible').toString());
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
          // Portada y Chip de estado
          Expanded(
            flex: 8,
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
                              final m = (d.data() as Map<String, dynamic>?) ?? {};
                              final s = _normStatus((m['status'] ?? '').toString());

                              if (<String>{'rentado', 'devolucion_pendiente', 'en_prestamo'}.contains(s)) {
                                foundPrestamo = true;
                              }
                              if (<String>{'reservado', 'pendiente', 'esperando_confirmacion'}.contains(s)) {
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

          // Texto + chip 
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        titulo,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14, 
                          color: Colors.black87,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        autor.isEmpty ? '—' : autor,
                        maxLines: 1, 
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12, 
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // Chip de materia
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: double.infinity),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                      ),
                      child: Text(
                        materia.isEmpty ? '—' : materia,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
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