import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnBookPage extends StatefulWidget {

  final String chatId;
  final Map<String, dynamic> materialData;

  const ReturnBookPage({
    super.key,
    required this.chatId,
    required this.materialData,
  });

  @override
  State<ReturnBookPage> createState() => _ReturnBookPageState();

}

class _ReturnBookPageState extends State<ReturnBookPage> {

  static const Color unimetBlue = Color(0xFF1B3A57);
  static const Color unimetOrange = Color(0xFFF28B31);

  int utilidad = 5;
  int estadoFisico = 4;

  final ChatService _chatService = ChatService();

  Future<void> registrarDevolucion() async {
  final String currentUser = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String materialId = widget.materialData['id'];

  try {
    // se registra la devolución en el chat
    await _chatService.registerReturnRequest(chatId: widget.chatId,
          materialId: materialId,
          senderId: currentUser,
          utilidad: utilidad,
          estadoFisico: estadoFisico,);

    // se descuenta uno de los free exchanges
    final docRef = FirebaseFirestore.instance.collection('materials').doc(materialId);
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(currentUser);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final userSnap = await transaction.get(userRef);

      if (!snapshot.exists || !userSnap.exists) return;

      double currentRating = (snapshot.data()?['rating'] ?? 0.0).toDouble();
      int numRatings = snapshot.data()?['numRatings'] ?? 0;
      double newRating = ((currentRating * numRatings) + utilidad) / (numRatings + 1);

      // logica para los free exchanges nuevos 
      int currentExchanges = userSnap.data()?['free_exchanges'] ?? 0;
      
      // solo se va restar exchanges si es mayor a 0 (si es -1 es premium y por lo que no se resta, tienen exchanges ilimitados)
      if (currentExchanges > 0) {
        transaction.update(userRef, {'free_exchanges': currentExchanges - 1});
      }

      // se actualiza el libro
      transaction.update(docRef, {
        'rating': newRating,
        'numRatings': numRatings + 1,
        'status': 'disponible',
      });
    });

    if (!mounted) return;
    Navigator.pop(context, true);

  } catch (e) {
    print("Error al registrar: $e");
  }
}

  @override
  Widget build(BuildContext context) {

    final String titulo = widget.materialData['title'] ?? 'Libro';

    final String autor = widget.materialData['author'] ?? 'Autor';

    return Scaffold(

      backgroundColor: const Color(0xFF355987),

      body: Center(

        child: Container(

          width: 700,

          padding: const EdgeInsets.all(30),

          decoration: BoxDecoration(

            color: Colors.white,
            borderRadius: BorderRadius.circular(20),

          ),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              const Text(
                "Registrar Devolución",
                style: TextStyle(fontSize: 32),
              ),

              const SizedBox(height:20),

              const Icon(Icons.menu_book,size:120),

              const SizedBox(height:10),

              Text(
                titulo,
                style: const TextStyle(fontSize:26),
              ),

              Text(
                "Autor: $autor",
                style: const TextStyle(fontSize:16),
              ),

              const SizedBox(height:30),

              const Text("¿Qué tan útil te resultó este libro?", style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 10),
RatingBar.builder(
  initialRating: utilidad.toDouble(),
  minRating: 1,
  direction: Axis.horizontal,
  allowHalfRating: true,
  itemCount: 5,
  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
  onRatingUpdate: (rating) {
    setState(() {
      utilidad = rating.toInt(); 
    });
  },
),

const SizedBox(height: 30),

const Text("¿Cuál es el estado físico del libro?", style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 10),
RatingBar.builder(
  initialRating: estadoFisico.toDouble(),
  minRating: 1,
  direction: Axis.horizontal,
  allowHalfRating: true,
  itemCount: 5,
  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
  itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
  onRatingUpdate: (rating) {
    setState(() {
      estadoFisico = rating.toInt();
    });
  },
),

              const SizedBox(height:30),

              ElevatedButton(

                onPressed: registrarDevolucion,

                style: ElevatedButton.styleFrom(
                  backgroundColor: unimetOrange,
                  padding: const EdgeInsets.symmetric(horizontal:40,vertical:15),
                ),

                child: const Text(
                  "Registrar Devolución",
                  style: TextStyle(fontSize:18),
                ),

              )

            ],

          ),

        ),

      ),

    );

  }

}