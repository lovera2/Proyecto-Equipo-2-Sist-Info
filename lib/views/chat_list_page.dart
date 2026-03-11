import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'individual_chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  // Intenta obtener nombre del otro usuario y título del material
  // cuando el chat no trae esos campos guardados.
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
      // Si falla, lo dejamos vacío para usar fallback.
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
      // Si falla, fallback.
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.menu_book, color: Colors.white, size: 30),
              const SizedBox(width: 12),
              const Text(
                'BookLoop',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF28B31), borderRadius: BorderRadius.circular(14)),
                child: IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/publish'),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Publicar material',
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28),
                tooltip: 'Ir al Inicio',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home_page', (route) => false),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                tooltip: 'Perfil',
                onPressed: () => Navigator.pushNamed(context, '/profile'),
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

    // Si no hay usuario autenticado, no disparamos consultas.
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
          // Fondo (igual estilo Home)
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

                // Sección blanca (contenedor principal)
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

                              final rawChats = snapshot.data?.docs ?? [];

                              // Evita listas infladas por duplicados o documentos "basura".
                              final seen = <String>{};
                              final chats = <QueryDocumentSnapshot<Object?>>[];

                              for (final d in rawChats) {
                                final data = d.data() as Map<String, dynamic>;

                                final status = (data['status'] ?? '').toString().toLowerCase().trim();

                                final hasLastMessage = (data['lastMessage'] ?? '').toString().trim().isNotEmpty ||
                                    (data['lastMessageText'] ?? '').toString().trim().isNotEmpty;

                                final hasLastMessageAt = data['lastMessageAt'] != null;
                                final hasUpdatedAt = data['updatedAt'] != null;
                                final hasLastUpdate = data['lastUpdate'] != null || data['lastUpdatedAt'] != null;
                                final hasCreatedAt = data['createdAt'] != null;

                                final allowPending = status == 'pendiente';

                                // Si no hay señales mínimas y no está pendiente, lo ignoramos.
                                if (!allowPending &&
                                    !hasLastMessage &&
                                    !hasLastMessageAt &&
                                    !hasUpdatedAt &&
                                    !hasLastUpdate &&
                                    !hasCreatedAt) {
                                  continue;
                                }

                                final String materialId = (data['materialId'] ?? data['id'] ?? '').toString().trim();
                                final List participants = (data['participants'] ?? const []).toList();

                                String otherUserId = '';
                                for (final p in participants) {
                                  final pid = p.toString().trim();
                                  if (pid.isNotEmpty && pid != currentUserId) {
                                    otherUserId = pid;
                                    break;
                                  }
                                }

                                final key = materialId.isNotEmpty && otherUserId.isNotEmpty
                                    ? '$materialId|$otherUserId'
                                    : d.id;

                                if (seen.contains(key)) continue;
                                seen.add(key);
                                chats.add(d);
                              }

                              // Orden visual: más reciente primero.
                              chats.sort((a, b) {
                                final da = a.data() as Map<String, dynamic>;
                                final db = b.data() as Map<String, dynamic>;

                                DateTime ta = DateTime.fromMillisecondsSinceEpoch(0);
                                DateTime tb = DateTime.fromMillisecondsSinceEpoch(0);

                                final la = da['lastMessageAt'];
                                final lb = db['lastMessageAt'];

                                if (la is Timestamp) ta = la.toDate();
                                if (lb is Timestamp) tb = lb.toDate();

                                if (ta.millisecondsSinceEpoch == 0) {
                                  final ua = da['updatedAt'] ?? da['lastUpdate'] ?? da['lastUpdatedAt'] ?? da['createdAt'];
                                  if (ua is Timestamp) ta = ua.toDate();
                                }
                                if (tb.millisecondsSinceEpoch == 0) {
                                  final ub = db['updatedAt'] ?? db['lastUpdate'] ?? db['lastUpdatedAt'] ?? db['createdAt'];
                                  if (ub is Timestamp) tb = ub.toDate();
                                }

                                return tb.compareTo(ta);
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

                                  final String materialId = (chatData['materialId'] ?? '').toString().trim();

                                  final List participants = (chatData['participants'] ?? const []).toList();
                                  String otherUserId = '';
                                  for (final p in participants) {
                                    final pid = p.toString().trim();
                                    if (pid.isNotEmpty && pid != currentUserId) {
                                      otherUserId = pid;
                                      break;
                                    }
                                  }

                                  final String otherUserNameStored = (chatData['otherUserName'] ?? '').toString().trim();
                                  final String bookTitleStored = (chatData['bookTitle'] ?? '').toString().trim();

                                  return FutureBuilder<Map<String, String>>(
                                    future: _resolveExtras(otherUserId: otherUserId, materialId: materialId),
                                    builder: (context, extraSnap) {
                                      final extra = extraSnap.data ?? const {'otherName': '', 'bookTitle': '', 'avatarEmoji': ''};

                                      final String otherUserName = otherUserNameStored.isNotEmpty
                                          ? otherUserNameStored
                                          : (extra['otherName'] ?? '').trim();

                                      final String bookTitle = bookTitleStored.isNotEmpty
                                          ? bookTitleStored
                                          : (extra['bookTitle'] ?? '').trim();

                                      final String materialTitleFallback =
                                          (chatData['materialTitle'] ?? chatData['title'] ?? '').toString().trim();

                                      final String avatarEmoji = (extra['avatarEmoji'] ?? '').trim();

                                      final String bookTitleToShow = bookTitle.isNotEmpty
                                          ? bookTitle
                                          : (materialTitleFallback.isNotEmpty ? materialTitleFallback : 'Consultar detalles');

                                      final String titleToShow = otherUserName.isNotEmpty
                                          ? otherUserName
                                          : (otherUserId.isNotEmpty ? 'Usuario: $otherUserId' : 'Chat de material');

                                      return Card(
                                        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                        elevation: 3,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                          leading: CircleAvatar(
                                            radius: 26,
                                            backgroundColor: unimetOrange,
                                            child: avatarEmoji.isNotEmpty
                                                ? Text(
                                                    avatarEmoji,
                                                    style: const TextStyle(fontSize: 22),
                                                  )
                                                : const Icon(Icons.person, color: Colors.white, size: 22),
                                          ),
                                          title: Text(
                                            titleToShow,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: unimetBlue,
                                              fontSize: 16.5,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Libro:',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  bookTitleToShow,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 18,
                                            color: unimetBlue,
                                          ),
                                          onTap: () {
                                            final Map<String, dynamic> materialInfo = Map.from(chatData);
                                            materialInfo['id'] = materialId;

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => IndividualChatPage(
                                                  chatId: chatDoc.id,
                                                  receiverName: titleToShow,
                                                  materialData: materialInfo,
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