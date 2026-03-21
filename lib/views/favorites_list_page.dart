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

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0F2A3F),
      body: Column(
        children: [
          _TopBar(
            currentUid: currentUid,
            onBack: () => Navigator.pop(context),
            onHome: () => Navigator.of(context).pushNamedAndRemoveUntil('/home_page', (route) => false),
            onPublish: () => Navigator.pushNamed(context, '/publish'),
            onNotifications: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage())),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mis Favoritos',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6F9),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
              ),
              child: StreamBuilder<List<String>>(
                stream: UserService().getUserFavoritesStream(currentUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: unimetOrange));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No tienes favoritos todavía.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    );
                  }

                  final favoriteIds = snapshot.data!;

                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 20),
                    itemCount: favoriteIds.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      return _FavoriteHorizontalCard(
                        bookId: favoriteIds[index],
                        currentUid: currentUid,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack, onHome, onPublish, onNotifications;
  final String currentUid;

  const _TopBar({
    required this.onBack,
    required this.onHome,
    required this.onPublish,
    required this.onNotifications,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 8, right: 8, bottom: 8),
      color: const Color(0xFF0F2A3F),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.menu_book, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'BookLoop',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFF28B31), borderRadius: BorderRadius.circular(10)),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    onPressed: onPublish,
                  ),
                ),
                _circleBtn(Icons.home_outlined, onHome),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('chats').where('users', arrayContains: currentUid).snapshots(),
                  builder: (context, snapshot) {
                    bool hasActivity = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    return Badge(
                      isLabelVisible: hasActivity,
                      backgroundColor: Colors.redAccent,
                      child: _circleBtn(Icons.notifications_none_outlined, onNotifications),
                    );
                  },
                ),
                _moreMenu(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback tap) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: IconButton(padding: EdgeInsets.zero, icon: Icon(icon, color: Colors.white, size: 20), onPressed: tap),
    );
  }

  Widget _moreMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: (val) {
        if (val == 'donate') Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationScreen()));
        if (val == 'logout') {
          FirebaseAuth.instance.signOut().then((_) => Navigator.pushReplacementNamed(context, '/'));
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'donate', child: Text("Donar")),
        const PopupMenuItem(value: 'logout', child: Text("Cerrar sesión")),
      ],
    );
  }
}

class _FavoriteHorizontalCard extends StatelessWidget {
  final String bookId;
  final String currentUid;

  const _FavoriteHorizontalCard({required this.bookId, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('materials').doc(bookId).get(),
      builder: (context, bookSnap) {
        if (!bookSnap.hasData || !bookSnap.data!.exists) return const SizedBox.shrink();

        final data = bookSnap.data!.data() as Map<String, dynamic>;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => MaterialDetailPage(materialId: bookId, materialData: data),
                ));
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 75,
                      height: 105,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImage(data['imageUrl']),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'Sin título',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3A57)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['author'] ?? '—',
                            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF28B31).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data['category'] ?? 'General',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF28B31)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red, size: 28),
                      onPressed: () async {
                        await UserService().removeFavorite(uid: currentUid, bookId: bookId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Eliminado: ${data['title']}'), behavior: SnackBarBehavior.floating),
                          );
                        }
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
  }

  Widget _buildImage(String? url) {
    const def = 'https://img.freepik.com/vector-gratis/cubierta-libro-azul-vector-top-view_1017-31355.jpg';
    if (url == null || url.isEmpty) return Image.network(def, fit: BoxFit.cover);
    if (url.startsWith('data:image') || !url.startsWith('http')) {
      try {
        return Image.memory(base64Decode(url.contains(',') ? url.split(',')[1] : url), fit: BoxFit.cover);
      } catch (_) { return Image.network(def, fit: BoxFit.cover); }
    }
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.network(def, fit: BoxFit.cover));
  }
}