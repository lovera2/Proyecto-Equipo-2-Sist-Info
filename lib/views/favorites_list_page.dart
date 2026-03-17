import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import 'material_detail_page.dart';
import 'chat_list_page.dart'; 
import 'donation_screen.dart';

class FavoritesListPage extends StatelessWidget {
  const FavoritesListPage({super.key});

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);


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
        child: Icon(Icons.book, size: 30, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // Fondo azul degradado
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
            child: Column(
              children: [
                // top bar
                _TopBar(
                  currentUid: currentUid,
                  onBack: () => Navigator.pop(context),
                  onHome: () => Navigator.of(context).pushNamedAndRemoveUntil('/home_page', (route) => false),
                  onPublish: () => Navigator.pushNamed(context, '/publish'),
                  onProfile: () => Navigator.pushNamed(context, '/profile'),
                  onNotifications: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatListPage()));
                  },
                ),
                
                // Título de la sección
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  child: Row(
                    children: [
                      Text('Mis Favoritos', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F6F9), // Un gris super clarito como en los chats
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
                    ),
                    child: StreamBuilder<List<String>>(
                      stream: UserService().getUserFavoritesStream(currentUid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: unimetOrange));
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No tienes libros en favoritos todavía.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          );
                        }

                        final favoriteIds = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 20),
                          itemCount: favoriteIds.length,
                          itemBuilder: (context, index) {
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('materials').doc(favoriteIds[index]).get(),
                              builder: (context, bookSnap) {
                                if (!bookSnap.hasData || !bookSnap.data!.exists) return const SizedBox.shrink();

                                final data = bookSnap.data!.data() as Map<String, dynamic>;
                                final String id = bookSnap.data!.id;

                                // tarjeta del libro
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (context) => MaterialDetailPage(materialId: id, materialData: data),
                                        ));
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            // Imagen
                                            SizedBox(
                                              width: 65, height: 95,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: _buildImage(data['imageUrl']),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            
                                            // Textos
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(data['title'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: unimetBlue), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                  const SizedBox(height: 6),
                                                  Text(data['author'] ?? 'Autor desconocido', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(color: unimetOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                                    child: Text(data['category'] ?? 'General', style: const TextStyle(color: unimetOrange, fontWeight: FontWeight.bold, fontSize: 11)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Corazón
                                            IconButton(
                                              icon: const Icon(Icons.favorite, color: Colors.red, size: 28),
                                              onPressed: () async {
                                                //se guarfa el messenger y el título ANTES del await
                                                final messenger = ScaffoldMessenger.of(context);
                                                final String bookTitle = (data['title'] ?? 'este libro').toString();

                                                //se elimina de la base de datos
                                                await UserService().removeFavorite(uid: currentUid, bookId: id);

                                                //se muestra el mensaje de que se quitó
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text('Has quitado "$bookTitle" de tus favoritos 💔'),
                                                    backgroundColor: Colors.grey[700],
                                                    duration: const Duration(seconds: 2),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
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
  final VoidCallback onBack, onHome, onPublish, onProfile, onNotifications;
  final String currentUid;

  const _TopBar({
    required this.onBack, required this.onHome, required this.onPublish,
    required this.onProfile, required this.onNotifications, required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
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
              const Text('BookLoop', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF28B31), borderRadius: BorderRadius.circular(14)),
                child: IconButton(onPressed: onPublish, icon: const Icon(Icons.add, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              IconButton(icon: const Icon(Icons.home_outlined, color: Colors.white, size: 28), onPressed: onHome),
              
              // Badge de notificaciones
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('chats').where('users', arrayContains: currentUid).snapshots(),
                builder: (context, snapshot) {
                  bool hasActivity = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return Badge(
                    isLabelVisible: hasActivity,
                    backgroundColor: Colors.redAccent,
                    child: IconButton(icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28), onPressed: onNotifications),
                  );
                },
              ),
              
              IconButton(icon: const Icon(Icons.person_outline, color: Colors.white, size: 28), onPressed: onProfile),
              
              PopupMenuButton<String>(
                            
                            icon: const Icon(Icons.more_vert, color: Colors.white, size: 28), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            onSelected: (value) async {
                              if (value == 'donate') {
                                
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => const DonationScreen())
                                );
                              } else if (value == 'logout') {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                  
                                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); 
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              // donaciones
                              const PopupMenuItem(
                                value: 'donate',
                                child: Row(
                                  children: [
                                    Icon(Icons.volunteer_activism, color: Color(0xFFF28B31)), 
                                    SizedBox(width: 10),
                                    Text('Realizar donación'),
                                  ],
                                ),
                              ),
                              // cerrar sesion
                              const PopupMenuItem(
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
    final p1 = Paint()..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.30), 180, p1);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.70), 220, p1);
    canvas.drawCircle(Offset(size.width * 0.60, size.height * 0.15), 140, p1);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}