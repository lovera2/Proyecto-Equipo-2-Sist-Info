import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Cambiamos a la ruta completa del proyecto para que no haya pérdida
import '../services/chat_service.dart';
import 'individual_chat_page.dart';

class MaterialDetailPage extends StatelessWidget {
  final String materialId;
  final Map<String, dynamic> materialData;

  const MaterialDetailPage({
    super.key,
    required this.materialId,
    required this.materialData,
  });

  // Aqui se coloca una logica hibrida, de esta manera da igual como se coloque la imagen
  //siempre habra una via de escape para que pueda ser annadida
  Widget _buildImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholder();
    }

    // Caso 1: Es Base64 (Empieza con 'data:image' o es una cadena larga sin http)
    if (imagePath.startsWith('data:image') || !imagePath.startsWith('http')) {
      try {
        final String cleanBase64 = imagePath.contains(',') 
            ? imagePath.split(',')[1] 
            : imagePath;

        return Image.memory(
          base64Decode(cleanBase64),
          width: 140,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }

    // Caso 2: Es una URL de internet normal
    return Image.network(
      imagePath,
      width: 140,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  // Cuadro gris de respaldo
  Widget _buildPlaceholder() {
    return Container(
      width: 140,
      height: 200,
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text("Sin imagen", style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color unimetBlue = Color(0xFF1B3A57);
    const Color unimetOrange = Color(0xFFF28B31);

    return Scaffold(
      backgroundColor: unimetBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Detalles del Material", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: _buildImage(materialData['imageUrl']), // Llamada a la lógica híbrida
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoText("Título", materialData['title']),
                          _buildInfoText("Categoría", materialData['category']),
                          _buildInfoText("Dueño", materialData['ownerName'] ?? 'No especificado'),
                          _buildInfoText("Asignatura", materialData['subject'] ?? 'N/A'),
                          _buildInfoText("Disponibilidad", "Disponible", color: Colors.green),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  materialData['description'] ?? "Sin descripción disponible.",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(5, (index) => Icon(
                      index < 4 ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    )),
                    const SizedBox(width: 10),
                    const Text("4.0", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: unimetOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () async {
                        final chatService = ChatService();
                        
                        // OBTENER EL USUARIO REAL DE FIREBASE
                        final User? user = FirebaseAuth.instance.currentUser;

                        if (user == null) {
                          // Si por alguna razón no hay sesión, avisamos al usuario
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Debes iniciar sesión para solicitar un libro")),
                          );
                          return;
                        }
                        String currentUserId = user.uid; // Este es el ID único y real del usuario
                        
                        String chatId = await chatService.getOrCreateChat(
                          currentUserId,
                          materialData['userId'] ?? '', // ID del dueño
                          materialId,
                        );

                        // Navegar a la pantalla de chat (la crearemos en el siguiente paso)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // ... dentro del Navigator.push ...
                            builder: (context) => IndividualChatPage(
                              chatId: chatId,
                              materialData: materialData, // Corregido
                              receiverName: materialData['ownerName'] ?? 'Propietario', // Corregido
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Solicitar préstamo"),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.favorite_border, color: Colors.grey),
                      label: const Text("Favoritos", style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoText(String label, String? value, {Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? 'N/A', style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}