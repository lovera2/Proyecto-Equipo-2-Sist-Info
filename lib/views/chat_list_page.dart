import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'individual_chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Mensajes", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B3A57),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Buscamos chats donde aparezca mi ID en la lista de participantes
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar mensajes"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text("Aún no tienes conversaciones."),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            padding: const EdgeInsets.only(top: 10),
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              
              // Intentamos obtener el nombre guardado, si no, mostramos un genérico
              final String otherUserName = chatData['otherUserName'] ?? 'Chat de Material';
              // Opcional: Si tienes el título del libro guardado en el chat
              final String bookTitle = chatData['bookTitle'] ?? 'Consultar detalles';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFF28B31), // Naranja Unimet para contraste
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    otherUserName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3A57),
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      "Libro: $bookTitle",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Color(0xFF1B3A57),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IndividualChatPage(
                          chatId: chatDoc.id,
                          receiverName: otherUserName,
                          materialData: chatData,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}