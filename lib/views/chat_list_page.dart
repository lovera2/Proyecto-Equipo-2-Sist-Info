import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'individual_chat_page.dart';
import 'donation_screen.dart';
import 'admin_dashboard_page.dart';
import 'admin_user_management_page.dart';
import 'admin_material_management_page.dart';
import '../viewmodels/admin_user_management_viewmodel.dart';
import '../viewmodels/admin_material_viewmodel.dart';
import '../services/admin_material_service.dart';

class ChatListPage extends StatelessWidget {
  final bool isAdmin;

  const ChatListPage({super.key, this.isAdmin = false});

  void _goHome(BuildContext context) {
    final email =
        (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase().trim();
    final route = email.startsWith('admin') ? '/home_admin' : '/home_page';
    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const _AdminDashboardShellFromChat(),
        ),
      );
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
      return;
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
    }
  }

  // aqui se obtiene el nombre del otro usuario y título del libro para guardarlo
  // cuando el chat no trae esos campos ya desde antes
  Future<Map<String, String>> _resolveExtras({
    required String otherUserId,
    required String materialId,
  }) async {
    String otherName = '';
    String bookTitle = '';
    String avatarEmoji = '';

    try {
      if (otherUserId.isNotEmpty) {
        final userSnap = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(otherUserId)
            .get();

        final u = userSnap.data() ?? {};
        final nombre = (u['nombre'] ?? '').toString().trim();
        final apellido = (u['apellido'] ?? '').toString().trim();
        final usuario = (u['usuario'] ?? '').toString().trim();
        avatarEmoji = (u['avatarEmoji'] ?? '').toString().trim();

        // Formato: Nombre Apellido (@usuario)
        final full = ('$nombre $apellido').trim();
        if (full.isNotEmpty && usuario.isNotEmpty) {
          otherName = '$full (@$usuario)';
        } else if (full.isNotEmpty) {
          otherName = full;
        } else if (usuario.isNotEmpty) {
          otherName = '@$usuario';
        }
      }
    } catch (_) {
    }

    try {
      if (materialId.isNotEmpty) {
        final matSnap = await FirebaseFirestore.instance
            .collection('materials')
            .doc(materialId)
            .get();

        final m = matSnap.data() ?? {};
        bookTitle = (m['title'] ?? '').toString().trim();
      }
    } catch (_) {
      // i hay un error se hace fallback por si acaso
    }

    return {
      'otherName': otherName,
      'bookTitle': bookTitle,
      'avatarEmoji': avatarEmoji,
    };
  }

  void _showTermsDialog(BuildContext context) {
    const Color unimetBlue = Color(0xFF1B3A57);
    const Color unimetOrange = Color(0xFFF28B31);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final h = MediaQuery.of(dialogContext).size.height;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Términos y Condiciones',
            style: TextStyle(color: unimetBlue, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 520,
            height: h * 0.62,
            child: const SingleChildScrollView(
              child: Text(
                'Al usar BookLoop aceptas lo siguiente:\n\n'
                '1) Acceso y verificación\n'
                '• Solo se permite el uso de correos institucionales UNIMET (docente y estudiante).\n'
                '• La cuenta es personal e intransferible.\n\n'
                '2) Uso responsable\n'
                '• Mantén un trato respetuoso en publicaciones y mensajes.\n'
                '• Está prohibido publicar contenido ofensivo, engañoso o spam.\n'
                '• BookLoop puede limitar o suspender cuentas ante evidencias de abuso.\n\n'
                '3) Préstamos y devoluciones\n'
                '• Al solicitar/aceptar un préstamo te comprometes a cumplir fecha, condiciones y lugar acordados.\n'
                '• Quien recibe el material es responsable de cuidarlo y devolverlo en el estado acordado.\n'
                '• En caso de pérdida o daño, las partes deben coordinar una solución (reposición o acuerdo).\n\n'
                '4) Seguridad y reportes\n'
                '• BookLoop puede limitar funciones (publicar/solicitar) si detecta patrones de incumplimiento.\n\n'
                '5) Privacidad y datos\n'
                '• Se almacenan datos mínimos para operar la plataforma.\n'
                '• No se publican datos sensibles.\n\n'
                '6) Alcance del servicio\n'
                '• BookLoop es una herramienta de coordinación; no garantiza la disponibilidad de material.\n'
                '• La UNIMET y el equipo de BookLoop no se responsabilizan por acuerdos fuera de la plataforma.\n',
                style: TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido', style: TextStyle(color: unimetOrange)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    const Color unimetBlue = Color(0xFF1B3A57);
    const Color unimetOrange = Color(0xFFF28B31);

    Future<void> handleLogout() async {
      await context.read<AuthViewModel>().logout();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: unimetOrange,
          content: Text('👋 Sesión cerrada. ¡Vuelve pronto!', style: TextStyle(color: Colors.white)),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }

    final String email = (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase().trim();
    final bool isAdmin = email.startsWith('admin');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo y título
          const Row(
            children: [
              Icon(Icons.menu_book, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'BookLoop',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Acciones con WRAP para que no se desborde
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Publicar (naranja)
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: unimetOrange, borderRadius: BorderRadius.circular(8)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pushNamed(context, '/publish'),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
              
              // Inicio
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.home_outlined, color: Colors.white, size: 18),
                  onPressed: () => _goHome(context),
                ),
              ),

              // Notificaciones / Mensajes (ya estás aquí)
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: unimetBlue,
                        content: Text('📩 Ya estás en Mensajes.', style: TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),

              // Perfil
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.person_outline, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                ),
              ),

              // Admin Menu (Si es admin)
              if (isAdmin)
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.settings_suggest, color: Colors.white, size: 18),
                    onPressed: () => _mostrarMenuAdmin(context),
                  ),
                ),

              // Menú (cerrar sesión)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (value) async {
                  if (value == 'donate') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationScreen()));
                  } else if (value == 'logout') {
                    await handleLogout();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'donate', child: Row(children: [Icon(Icons.volunteer_activism, color: Color(0xFFF28B31)), SizedBox(width: 10), Text('Realizar donación')])),
                  const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Color(0xFF1B3A57)), SizedBox(width: 10), Text('Cerrar sesión')])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Detectamos el ancho de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 800; 

    // si no hay usuario autenticado, no hacemos consultas
    if (currentUserId.trim().isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión para ver tus mensajes.')),
      );
    }

    const Color unimetBlue = Color(0xFF1B3A57);
    const Color unimetOrange = Color(0xFFF28B31);
    final email =
        (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase().trim();
    final bool effectiveIsAdmin = email.startsWith('admin');

    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: effectiveIsAdmin ? Alignment.topCenter : Alignment.topLeft,
                end: effectiveIsAdmin ? Alignment.bottomCenter : Alignment.bottomRight,
                colors: effectiveIsAdmin
                    ? const [
                        Color(0xFFF28B31),
                        Color(0xFFD67628),
                      ]
                    : const [
                        Color(0xFF0F2A3F),
                        unimetBlue,
                        Color(0xFF2C5E8C),
                      ],
                stops: effectiveIsAdmin ? null : const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          _BackgroundBlobs(isAdmin: effectiveIsAdmin),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    // MAGIA RESPONSIVA: 200 en PC, 15 en Celular
                    margin: EdgeInsets.fromLTRB(isWide ? 200 : 15, 0, isWide ? 200 : 15, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        Padding(
                          // Ajustamos el padding del título también
                          padding: EdgeInsets.only(left: isWide ? 40 : 20, bottom: 14),
                          child: const Text(
                            'Mis Mensajes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: unimetBlue,
                            ),
                          ),
                        ),

                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('chats')
                                .where('participants', arrayContains: currentUserId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Center(child: Text('Error al cargar mensajes'));
                              }
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: unimetOrange));
                              }

                              final rawDocs = snapshot.data?.docs ?? [];
                              
                              // 1. FILTRADO DE SEGURIDAD Y LIMPIEZA
                              final seenKeys = <String>{};
                              final List<QueryDocumentSnapshot> chats = [];

                              for (var doc in rawDocs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final List participants = data['participants'] ?? [];
                                
                                if (!participants.contains(currentUserId)) continue;

                                final String mId = (data['materialId'] ?? '').toString();
                                final String chatKey = "${mId}_${participants.join('_')}";

                                if (seenKeys.contains(chatKey)) continue;
                                
                                seenKeys.add(chatKey);
                                chats.add(doc);
                              }

                              // 2. ORDENADO POR FECHA (El más reciente arriba)
                              chats.sort((a, b) {
                                final dataA = a.data() as Map<String, dynamic>;
                                final dataB = b.data() as Map<String, dynamic>;
                                final tsA = (dataA['lastMessageAt'] ?? dataA['createdAt'] ?? Timestamp.now()) as Timestamp;
                                final tsB = (dataB['lastMessageAt'] ?? dataB['createdAt'] ?? Timestamp.now()) as Timestamp;
                                return tsB.compareTo(tsA);
                              });

                              if (chats.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'Aún no tienes conversaciones.\nCuando solicites un préstamo, verás el chat aquí.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 15.5, color: Colors.black54, height: 1.4),
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: chats.length,
                                padding: const EdgeInsets.only(top: 6, bottom: 18),
                                itemBuilder: (context, index) {
                                  final chatDoc = chats[index];
                                  final chatData = chatDoc.data() as Map<String, dynamic>;
                                  final String materialId = (chatData['materialId'] ?? '').toString();
                                  
                                  // Identificar al otro usuario
                                  final List participants = chatData['participants'] ?? [];
                                  final String otherUserId = participants.firstWhere(
                                    (p) => p != currentUserId, 
                                    orElse: () => ''
                                  );

                                  return FutureBuilder<Map<String, String>>(
                                    future: _resolveExtras(otherUserId: otherUserId, materialId: materialId),
                                    builder: (context, extraSnap) {
                                      final extra = extraSnap.data ?? {'otherName': 'Usuario', 'bookTitle': 'Libro', 'avatarEmoji': ''};
                                      
                                      final bool isOwner = chatData['ownerId'] == currentUserId;
                                      final String displayName = extra['otherName'] ?? 'Usuario';
                                      final String bookTitle = extra['bookTitle'] ?? 'Consultar detalles';

                                      return Card(
                                        // Ajustamos el margen de la tarjeta
                                        margin: EdgeInsets.symmetric(horizontal: isWide ? 18 : 12, vertical: 8),
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                          leading: CircleAvatar(
                                            radius: 26,
                                            backgroundColor: unimetOrange,
                                            child: Text(
                                              extra['avatarEmoji']?.isNotEmpty == true ? extra['avatarEmoji']! : '📖',
                                              style: const TextStyle(fontSize: 22),
                                            ),
                                          ),
                                          title: Text(
                                            isOwner ? "$displayName pidió tu libro" : "Pediste un libro a $displayName",
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: unimetBlue, fontSize: 16),
                                          ),
                                          subtitle: Text(
                                            "Libro: $bookTitle",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                                          ),
                                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: unimetBlue),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => IndividualChatPage(
                                                  chatId: chatDoc.id,
                                                  receiverName: displayName,
                                                  materialData: {...chatData, 'id': materialId},
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
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
  final bool isAdmin;
  const _BackgroundBlobs({this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BlobPainter(isAdmin: isAdmin),
      child: const SizedBox.expand(),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final bool isAdmin;
  _BlobPainter({this.isAdmin = false});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withOpacity(isAdmin ? 0.05 : 0.06);
    final p2 = Paint()..color = Colors.white.withOpacity(isAdmin ? 0.03 : 0.035);

    if (isAdmin) {
      canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.18), 170, p1);
      canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.72), 220, p1);
      canvas.drawCircle(Offset(size.width * 0.52, size.height * 0.10), 130, p2);
    } else {
      canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.30), 180, p1);
      canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.70), 220, p1);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 50, p2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdminDashboardShellFromChat extends StatelessWidget {
  const _AdminDashboardShellFromChat();

  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  Widget build(BuildContext context) {
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
          const _BackgroundBlobs(isAdmin: true),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AdminDashboardView(
                    onBack: () => Navigator.pop(context),
                    onOpenMenu: () async {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}