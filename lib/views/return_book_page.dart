import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

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

    await _chatService.registerReturnRequest(

      chatId: widget.chatId,
      materialId: widget.materialData['id'],
      senderId: currentUser,
      utilidad: utilidad,
      estadoFisico: estadoFisico,

    );

    if(!mounted) return;

    Navigator.pop(context,true);

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

              const Text("¿Qué tan útil te resultó este libro?"),

              Slider(
                value: utilidad.toDouble(),
                min:1,
                max:5,
                divisions:4,
                label: utilidad.toString(),
                onChanged:(value){
                  setState(() {
                    utilidad=value.toInt();
                  });
                },
              ),

              const SizedBox(height:20),

              const Text("¿Cuál es el estado físico del libro?"),

              Slider(
                value: estadoFisico.toDouble(),
                min:1,
                max:5,
                divisions:4,
                label: estadoFisico.toString(),
                onChanged:(value){
                  setState(() {
                    estadoFisico=value.toInt();
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