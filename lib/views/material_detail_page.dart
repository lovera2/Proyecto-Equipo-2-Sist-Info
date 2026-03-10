import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'individual_chat_page.dart';

class MaterialDetailPage extends StatelessWidget {
  final String materialId;
  final Map<String, dynamic> materialData;

  // Cuando es admin, la pantalla usa el theme naranja (como HomeAdmin)
  final bool isAdmin;

  const MaterialDetailPage({
    super.key,
    required this.materialId,
    required this.materialData,
    this.isAdmin = false,
  });

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);
  static const Color cardBrown = Color(0xFFD2A679);

  Future<Map<String, String>> _fetchOwnerProfile(String ownerUid) async {
    if (ownerUid.trim().isEmpty) return {'fullName': '', 'username': ''};

    try {
      final snap = await FirebaseFirestore.instance.collection('usuarios').doc(ownerUid).get();
      final data = snap.data();
      if (data == null) return {'fullName': '', 'username': ''};

      final nombre = (data['nombre'] ?? '').toString().trim();
      final apellido = (data['apellido'] ?? '').toString().trim();
      final email = (data['email'] ?? '').toString().trim();

      final fullName = ("$nombre $apellido").trim();
      final username = email.contains('@') ? email.split('@').first : '';

      return {
        'fullName': fullName,
        'username': username,
      };
    } catch (_) {
      return {'fullName': '', 'username': ''};
    }
  }

  Widget _buildImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholder();
    }

    if (imagePath.startsWith('data:image') || !imagePath.startsWith('http')) {
      try {
        final String cleanBase64 = imagePath.contains(',') ? imagePath.split(',')[1] : imagePath;
        return Image.memory(
          base64Decode(cleanBase64),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (_) {
        return _buildPlaceholder();
      }
    }

    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text("Sin imagen", style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  BoxDecoration _backgroundDecoration(bool effectiveIsAdmin) {
    if (effectiveIsAdmin) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF28B31),
            Color(0xFFF6A24B),
            Color(0xFFF9B862),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      );
    }

    return const BoxDecoration(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = (materialData['title'] ?? 'Sin título').toString();
    final String category = (materialData['category'] ?? 'N/A').toString();
    final User? user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? '';
    final String ownerUid = (materialData['userId'] ?? '').toString();
    final bool isOwner = currentUid.isNotEmpty && currentUid == ownerUid;

    // Datos del dueño (intentamos mostrar: "Nombre Apellido (@usuario)")
    final String ownerNameRaw = (materialData['ownerName'] ?? '').toString().trim();
    final String ownerUsernameRaw = (materialData['ownerUsername'] ?? '').toString().trim();
    final String ownerEmailRaw = (materialData['ownerEmail'] ?? '').toString().trim();

    final String ownerUserFromOwnerEmail = ownerEmailRaw.contains('@')
        ? ownerEmailRaw.split('@').first
        : ownerEmailRaw;

    final String emailRaw = (user?.email ?? '').toString().trim();
    final String usernameFromEmail = emailRaw.contains('@') ? emailRaw.split('@').first : emailRaw;

    final String displayNameFromAuth = (user?.displayName ?? '').toString().trim();

    final String ownerUsernameFallback = ownerUsernameRaw.isNotEmpty
        ? ownerUsernameRaw
        : (ownerUserFromOwnerEmail.isNotEmpty
            ? ownerUserFromOwnerEmail
            : (isOwner && usernameFromEmail.isNotEmpty ? usernameFromEmail : ''));

    final String ownerNameFallback = ownerNameRaw.isNotEmpty
        ? ownerNameRaw
        : (isOwner && displayNameFromAuth.isNotEmpty
            ? displayNameFromAuth
            : (isOwner && usernameFromEmail.isNotEmpty ? usernameFromEmail : ''));

    // Si no viene nombre/username en el material, intentamos buscarlo en /usuarios/{uid}
    final Future<Map<String, String>> ownerFuture = _fetchOwnerProfile(ownerUid);
    final String subject = (materialData['subject'] ?? 'N/A').toString();
    final String desc = (materialData['description'] ?? 'Sin descripción disponible.').toString();
    final String author = (materialData['author'] ?? 'N/A').toString();

    final email = (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase().trim();
    final bool effectiveIsAdmin = isAdmin || email.startsWith('admin');

    final String statusRaw = (materialData['status'] ?? 'disponible').toString().toLowerCase();
    final bool isAvailable = statusRaw == 'disponible';

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: _backgroundDecoration(effectiveIsAdmin)),
          const _BackgroundBlobs(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  isAdmin: effectiveIsAdmin,
                  onBack: () => Navigator.pop(context),
                  onHome: () {
                    final route = effectiveIsAdmin ? '/home_admin' : '/home_page';
                    Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
                  },
                  onPublish: () {
                    Navigator.pushNamed(context, '/publish');
                  },
                  onProfile: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  onNotifications: () {
                    // Si en tu app las notificaciones son ChatListPage, acá puedes cambiarlo.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Notificaciones en desarrollo.'),
                        backgroundColor: effectiveIsAdmin ? unimetBlue : unimetOrange,
                      ),
                    );
                  },
                  onMenuLogout: () {
                    // Logout se maneja desde el menú en tu header principal.
                    // Aquí solo lo dejamos como placeholder por si quieres conectarlo luego.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Cierre de sesión: integrar desde el menú global.'),
                        backgroundColor: effectiveIsAdmin ? unimetBlue : unimetOrange,
                      ),
                    );
                  },
                ),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth >= 860;

                            final cover = Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CoverCard(
                                  image: _buildImage(materialData['imageUrl']),
                                ),
                                const SizedBox(height: 10),
                                const _RatingRow(rating: 4.0),
                              ],
                            );

                            final details = FutureBuilder<Map<String, String>>(
                              future: ownerFuture,
                              builder: (context, snap) {
                                final fetchedFullName = (snap.data?['fullName'] ?? '').trim();
                                final fetchedUsername = (snap.data?['username'] ?? '').trim();

                                final String finalName = fetchedFullName.isNotEmpty ? fetchedFullName : ownerNameFallback;
                                final String finalUsername = fetchedUsername.isNotEmpty ? fetchedUsername : ownerUsernameFallback;

                                final String ownerDisplay = (finalName.isNotEmpty && finalUsername.isNotEmpty)
                                    ? (finalName.toLowerCase() == finalUsername.toLowerCase()
                                        ? '@$finalUsername'
                                        : '$finalName (@$finalUsername)')
                                    : (finalName.isNotEmpty
                                        ? finalName
                                        : (finalUsername.isNotEmpty ? '@$finalUsername' : 'No especificado'));

                                return _DetailsCard(
                                  title: title,
                                  category: category,
                                  ownerName: ownerDisplay,
                                  subject: subject,
                                  author: author,
                                  description: desc,
                                  isAvailable: isAvailable,
                                  isAdmin: effectiveIsAdmin,
                                  onEdit: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Editar material: pendiente de conectar.'),
                                        backgroundColor: effectiveIsAdmin ? unimetBlue : unimetOrange,
                                      ),
                                    );
                                  },
                                );
                              },
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isWide) ...[
                                      cover,
                                      const SizedBox(width: 22),
                                      Expanded(child: details),
                                    ] else ...[
                                      Expanded(child: details),
                                    ]
                                  ],
                                ),

                                if (!isWide) ...[
                                  const SizedBox(height: 16),
                                  cover,
                                ],

                                const SizedBox(height: 18),
                                Divider(color: Colors.black.withOpacity(0.08)),
                                const SizedBox(height: 14),

                                const SizedBox(height: 14),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (!isOwner && !effectiveIsAdmin)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isAvailable
                                              ? (effectiveIsAdmin ? unimetBlue : unimetOrange)
                                              : Colors.grey.shade500,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          elevation: 0,
                                        ),
                                        onPressed: () async {
                                          if (!isAvailable) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Este libro ahorita no está disponible para solicitar préstamo.'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                            return;
                                          }

                                          final chatService = ChatService();
                                          final User? user = FirebaseAuth.instance.currentUser;

                                          if (user == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Debes iniciar sesión para solicitar un libro')),
                                            );
                                            return;
                                          }

                                          final String currentUserId = user.uid;

                                          final String chatId = await chatService.getOrCreateChat(
                                            currentUserId,
                                            (materialData['userId'] ?? '').toString(),
                                            materialId,
                                          );

                                          final Map<String, dynamic> dataConId = Map.from(materialData);
                                          dataConId['id'] = materialId;
                                          dataConId['userId'] = (materialData['userId'] ?? '').toString();

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => IndividualChatPage(
                                                chatId: chatId,
                                                materialData: dataConId,
                                                receiverName: ownerNameFallback.isNotEmpty ? ownerNameFallback : 'Propietario',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        label: Text(
                                          isAvailable ? 'Solicitar préstamo' : ' Préstamo no disponible',
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 1),
                                    TextButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.favorite_border, color: Colors.grey),
                                      label: const Text('Añadir a favoritos', style: TextStyle(color: Colors.grey)),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
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

class _TopBar extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onPublish;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;
  final VoidCallback onMenuLogout;

  const _TopBar({
    required this.isAdmin,
    required this.onBack,
    required this.onHome,
    required this.onPublish,
    required this.onProfile,
    required this.onNotifications,
    required this.onMenuLogout,
  });

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: onBack,
              ),
              const SizedBox(width: 6),
              const Icon(Icons.menu_book, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(
                isAdmin ? 'BookLoop ADMIN' : 'BookLoop',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isAdmin ? unimetBlue : unimetOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: onPublish,
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: 'Publicar material',
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28),
                onPressed: onHome,
                tooltip: 'Inicio',
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                onPressed: onNotifications,
                tooltip: 'Notificaciones',
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                onPressed: onProfile,
                tooltip: 'Perfil',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (value) {
                  if (value == 'logout') onMenuLogout();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: unimetBlue),
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

class _CoverCard extends StatelessWidget {
  final Widget image;

  const _CoverCard({
    required this.image,
  });

  static const Color cardBrown = Color(0xFFD2A679);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBrown,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 0.72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: image,
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String title;
  final String category;
  final String ownerName;
  final String subject;
  final String author;
  final String description;
  final bool isAvailable;
  final bool isAdmin;
  final VoidCallback onEdit;

  const _DetailsCard({
    required this.title,
    required this.category,
    required this.ownerName,
    required this.subject,
    required this.author,
    required this.description,
    required this.isAvailable,
    required this.isAdmin,
    required this.onEdit,
  });

  static const Color unimetBlue = Color(0xFF1B3A57);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalles del material',
                style: const TextStyle(
                  color: unimetBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),

              _InfoLine(label: 'Título', value: title),
              _InfoLine(label: 'Autor', value: author),
              _InfoLine(label: 'Categoría', value: category),
              _InfoLine(label: 'Dueño', value: ownerName),
              _InfoLine(label: 'Asignatura', value: subject),
              _InfoLine(
                label: 'Disponibilidad',
                value: isAvailable ? 'Disponible' : 'No disponible',
                valueColor: isAvailable ? Colors.green : Colors.red,
              ),

              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: unimetBlue,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (isAdmin)
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: unimetBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  elevation: 0,
                ),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text(
                  'Editar',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.25),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: valueColor ?? Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;

  const _RatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    final int full = rating.floor().clamp(0, 5);
    final bool half = (rating - full) >= 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Calificación',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(width: 10),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Row(
          children: List.generate(5, (i) {
            if (i < full) {
              return const Icon(Icons.star, color: Colors.orange, size: 26);
            }
            if (i == full && half) {
              return const Icon(Icons.star_half, color: Colors.orange, size: 26);
            }
            return const Icon(Icons.star_border, color: Colors.orange, size: 26);
          }),
        ),
      ],
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
    canvas.drawCircle(Offset(size.width * 0.60, size.height * 0.15), 140, p1);

    final p2 = Paint()..color = Colors.white.withOpacity(0.035);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 50, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}