import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'individual_chat_page.dart';
import 'chat_list_page.dart'; 
import '../services/user_service.dart';

class MaterialDetailPage extends StatelessWidget {
  final String materialId;
  final Map<String, dynamic> materialData;
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

      return {
        'fullName': ("$nombre $apellido").trim(),
        'username': email.contains('@') ? email.split('@').first : '',
      };
    } catch (_) {
      return {'fullName': '', 'username': ''};
    }
  }

  Widget _buildImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return _buildPlaceholder();
    if (imagePath.startsWith('data:image') || !imagePath.startsWith('http')) {
      try {
        final String cleanBase64 = imagePath.contains(',') ? imagePath.split(',')[1] : imagePath;
        return Image.memory(base64Decode(cleanBase64), fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
      } catch (_) { return _buildPlaceholder(); }
    }
    return Image.network(imagePath, fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder());
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
          colors: [Color(0xFFF28B31), Color(0xFFF6A24B), Color(0xFFF9B862)],
          stops: [0.0, 0.55, 1.0],
        ),
      );
    }
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F2A3F), unimetBlue, Color(0xFF2C5E8C)],
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

    final String ownerNameRaw = (materialData['ownerName'] ?? '').toString().trim();
    final String ownerUsernameRaw = (materialData['ownerUsername'] ?? '').toString().trim();
    final String ownerEmailRaw = (materialData['ownerEmail'] ?? '').toString().trim();
    final String ownerUserFromOwnerEmail = ownerEmailRaw.contains('@') ? ownerEmailRaw.split('@').first : ownerEmailRaw;
    final String emailRaw = (user?.email ?? '').toString().trim();
    final String usernameFromEmail = emailRaw.contains('@') ? emailRaw.split('@').first : emailRaw;
    final String displayNameFromAuth = (user?.displayName ?? '').toString().trim();

    final String ownerUsernameFallback = ownerUsernameRaw.isNotEmpty ? ownerUsernameRaw 
        : (ownerUserFromOwnerEmail.isNotEmpty ? ownerUserFromOwnerEmail 
        : (isOwner && usernameFromEmail.isNotEmpty ? usernameFromEmail : ''));

    final String ownerNameFallback = ownerNameRaw.isNotEmpty ? ownerNameRaw 
        : (isOwner && displayNameFromAuth.isNotEmpty ? displayNameFromAuth 
        : (isOwner && usernameFromEmail.isNotEmpty ? usernameFromEmail : ''));

    final Future<Map<String, String>> ownerFuture = _fetchOwnerProfile(ownerUid);
    final String subject = (materialData['subject'] ?? 'N/A').toString();
    final String desc = (materialData['description'] ?? 'Sin descripción disponible.').toString();
    final String author = (materialData['author'] ?? 'N/A').toString();

    final email = (FirebaseAuth.instance.currentUser?.email ?? '').toLowerCase().trim();
    final bool effectiveIsAdmin = isAdmin || email.startsWith('admin');
    final bool isAvailable = (materialData['status'] ?? 'disponible').toString().toLowerCase() == 'disponible';

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
                  onPublish: () => Navigator.pushNamed(context, '/publish'),
                  onProfile: () => Navigator.pushNamed(context, '/profile'),
                  onNotifications: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListPage()));
                  },
                  onMenuLogout: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 10))],
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth >= 860;
                            final cover = Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CoverCard(image: _buildImage(materialData['imageUrl'])),
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
                                    ? (finalName.toLowerCase() == finalUsername.toLowerCase() ? '@$finalUsername' : '$finalName (@$finalUsername)')
                                    : (finalName.isNotEmpty ? finalName : (finalUsername.isNotEmpty ? '@$finalUsername' : 'No especificado'));

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
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editar material: Próximamente.')));
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
                                if (!isWide) ...[const SizedBox(height: 16), cover],
                                const SizedBox(height: 18),
                                Divider(color: Colors.black.withOpacity(0.08)),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (!isOwner && !effectiveIsAdmin)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isAvailable ? (effectiveIsAdmin ? unimetBlue : unimetOrange) : Colors.grey.shade500,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          elevation: 0,
                                        ),
                                        onPressed: isAvailable ? () async {
                                          if (user == null) return;
                                          final chatService = ChatService();
                                          final String chatId = await chatService.getOrCreateChat(currentUid, ownerUid, materialId);
                                          final Map<String, dynamic> dataConId = Map.from(materialData);
                                          dataConId['id'] = materialId;

                                          Navigator.push(context, MaterialPageRoute(
                                            builder: (context) => IndividualChatPage(
                                              chatId: chatId,
                                              materialData: dataConId,
                                              receiverName: ownerNameFallback.isNotEmpty ? ownerNameFallback : 'Propietario',
                                            ),
                                          ));
                                        } : null,
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        label: Text(isAvailable ? 'Solicitar préstamo' : 'Préstamo no disponible', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      )
                                    else
                                      const SizedBox(width: 1),
                                    
                                    StreamBuilder<bool>(
                                      // el ID del usuario actual y el ID del libro
                                      stream: currentUid.isNotEmpty 
                                          ? UserService().isFavoriteStream(uid: currentUid, bookId: materialId) 
                                          : Stream.value(false),
                                      builder: (context, snapshot) {
                                        final bool isFav = snapshot.data ?? false; // ¿Es favorito en la DB?
                                        
                                        return TextButton.icon(
                                          onPressed: () async {
                                            if (currentUid.isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Debes iniciar sesión para guardar favoritos')),
                                              );
                                              return;
                                            }

                                            final userService = UserService();
                                            // Guardamos el messenger y el título antes del await
                                            final messenger = ScaffoldMessenger.of(context);
                                            final String bookTitle = (materialData['title'] ?? 'este libro').toString();

                                            if (isFav) {
                                              // Si ya era favorito, lo quitamos
                                              await userService.removeFavorite(uid: currentUid, bookId: materialId);
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text('Has quitado "$bookTitle" de tus favoritos 💔'),
                                                  backgroundColor: Colors.grey[700],
                                                  duration: const Duration(seconds: 2),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            } else {
                                              // Si no era, lo añadimos
                                              await userService.addFavorite(uid: currentUid, bookId: materialId);
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text('Has agregado "$bookTitle" a tus favoritos ❤️'),
                                                  backgroundColor: const Color(0xFFF28B31), // Naranja Unimet
                                                  duration: const Duration(seconds: 2),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          },
                                          icon: Icon(
                                            isFav ? Icons.favorite : Icons.favorite_border,
                                            color: isFav ? Colors.red : Colors.grey,
                                            size: 26,
                                          ),
                                          label: Text(
                                            isFav ? 'En favoritos' : 'Añadir a favoritos',
                                            style: TextStyle(
                                              color: isFav ? Colors.red : Colors.grey, 
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        );
                                      },
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
  final VoidCallback onBack, onHome, onPublish, onProfile, onNotifications, onMenuLogout;

  const _TopBar({
    required this.isAdmin, required this.onBack, required this.onHome,
    required this.onPublish, required this.onProfile, required this.onNotifications, required this.onMenuLogout,
  });

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: onBack),
              const SizedBox(width: 6),
              const Icon(Icons.menu_book, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Text(isAdmin ? 'BookLoop ADMIN' : 'BookLoop', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: isAdmin ? const Color(0xFF1B3A57) : const Color(0xFFF28B31), borderRadius: BorderRadius.circular(14)),
                child: IconButton(onPressed: onPublish, icon: const Icon(Icons.add, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              IconButton(icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28), onPressed: onHome),
              
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('users', arrayContains: currentUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Lógica simple: si hay algún chat donde el usuario participe, mostramos el punto
                  bool hasActivity = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return Badge(
                    isLabelVisible: hasActivity,
                    backgroundColor: Colors.redAccent,
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
                      onPressed: onNotifications,
                    ),
                  );
                },
              ),
              
              IconButton(icon: const Icon(Icons.person_outline, color: Colors.white, size: 28), onPressed: onProfile),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (value) { if (value == 'logout') onMenuLogout(); },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Color(0xFF1B3A57)), SizedBox(width: 10), Text('Cerrar sesión')])),
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
  const _CoverCard({required this.image});
  static const Color cardBrown = Color(0xFFD2A679);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBrown,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 8))],
      ),
      child: AspectRatio(aspectRatio: 0.72, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: image)),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String title, category, ownerName, subject, author, description;
  final bool isAvailable, isAdmin;
  final VoidCallback onEdit;

  const _DetailsCard({
    required this.title, required this.category, required this.ownerName,
    required this.subject, required this.author, required this.description,
    required this.isAvailable, required this.isAdmin, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detalles del material', style: TextStyle(color: Color(0xFF1B3A57), fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              _InfoLine(label: 'Título', value: title),
              _InfoLine(label: 'Autor', value: author),
              _InfoLine(label: 'Categoría', value: category),
              _InfoLine(label: 'Dueño', value: ownerName),
              _InfoLine(label: 'Asignatura', value: subject),
              _InfoLine(label: 'Disponibilidad', value: isAvailable ? 'Disponible' : 'No disponible', valueColor: isAvailable ? Colors.green : Colors.red),
              const SizedBox(height: 14),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF6F7FB), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black.withOpacity(0.06))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1B3A57), fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(description, style: const TextStyle(fontSize: 14, height: 1.45, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isAdmin)
          Positioned(
            top: 0, right: 0,
            child: SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B3A57), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(horizontal: 14), elevation: 0),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _InfoLine({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.25),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(text: value, style: TextStyle(color: valueColor ?? Colors.black87)),
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
        const Text('Calificación', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87)),
        const SizedBox(width: 10),
        Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
        const SizedBox(width: 12),
        Row(children: List.generate(5, (i) {
          if (i < full) return const Icon(Icons.star, color: Colors.orange, size: 26);
          if (i == full && half) return const Icon(Icons.star_half, color: Colors.orange, size: 26);
          return const Icon(Icons.star_border, color: Colors.orange, size: 26);
        })),
      ],
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BlobPainter(), child: const SizedBox.expand());
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