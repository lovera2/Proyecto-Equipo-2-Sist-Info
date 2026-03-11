import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'individual_chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

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
          content: Text(
            '👋 Sesión cerrada. ¡Vuelve pronto!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo y título (igual al Home)
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              const Text(
                'BookLoop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Acciones (igual al Home)
          Row(
            children: [
              // Publicar (naranja)
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

              // Inicio
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28),
                tooltip: 'Inicio',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home_page',
                  (route) => false,
                ),
              ),

              // Notificaciones / Mensajes (ya estás aquí)
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                tooltip: 'Mensajes',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: unimetBlue,
                      content: Text(
                        '📩 Ya estás en Mensajes.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),

              // Perfil
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                tooltip: 'Perfil',
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),

              // Menú (cerrar sesión)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                onSelected: (value) {
                  if (value == 'logout') handleLogout();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: unimetBlue),
                        SizedBox(width: 10),
                        Text('Cerrar Sesión'),
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

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // si no hay usuario autenticado, no hacemos consultas
    if (currentUserId.trim().isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión para ver tus mensajes.')),
      );
    }

    const Color unimetBlue = Color(0xFF1B3A57);
    const Color unimetOrange = Color(0xFFF28B31);

    return Scaffold(
      body: Stack(
        children: [
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
          const _BackgroundBlobs(),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(200, 0, 200, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        const Padding(
                          padding: EdgeInsets.only(left: 40, bottom: 14),
                          child: Text(
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
                            // Mantenemos la consulta, pero nos aseguramos de que el campo sea exacto
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
                                
                                // DOBLE BLINDAJE: Si yo no estoy en la lista de participantes, este chat no es para mí
                                if (!participants.contains(currentUserId)) continue;

                                final String mId = (data['materialId'] ?? '').toString();
                                // Generamos una llave única para evitar que el mismo libro/persona aparezca dos veces
                                // Si el chat es del mismo material y las mismas personas, es un duplicado
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
                                      
                                      // Lógica de visualización (Punto 3 adelantado para que se vea genial)
                                      final bool isOwner = chatData['ownerId'] == currentUserId;
                                      final String displayName = extra['otherName'] ?? 'Usuario';
                                      final String bookTitle = extra['bookTitle'] ?? 'Consultar detalles';

                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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