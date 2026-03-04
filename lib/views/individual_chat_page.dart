import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class IndividualChatPage extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final Map<String, dynamic> materialData;

  const IndividualChatPage({
    super.key,
    required this.chatId,
    required this.materialData,
    required this.receiverName,
  });

  @override
  State<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // LÓGICA DE ROLES: ¿Soy el dueño del libro?
  bool get isOwner => widget.materialData['userId'] == currentUserId;

  void _sendTextMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(
        widget.chatId,
        currentUserId,
        _messageController.text.trim(),
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color unimetBlue = Color(0xFF1B3A57);
    const Color unimetOrange = Color(0xFFF28B31);

    final String libroTitulo = widget.materialData['title'] ?? 'Consultando libro...';
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: unimetBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, 
                 style: const TextStyle(fontSize: 16, color: Colors.white)),
            Text(libroTitulo, 
                 style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Cinta de estado con lógica dinámica
          _buildLoanStatusBar(unimetOrange),

          // 2. Área de mensajes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == currentUserId;
                    return _buildMessageBubble(msg['text'] ?? '', isMe);
                  },
                );
              },
            ),
          ),

          // 3. Barra de entrada
          _buildInputArea(unimetOrange),
        ],
      ),
    );
  }

  // WIDGET: Cinta de estado del préstamo (ACTUALIZADA)
  Widget _buildLoanStatusBar(Color accentColor) {
    // Definimos variables dinámicas según el rol
    final String buttonText = isOwner ? "Confirmar Entregado" : "Confirmar Recibido";
    final IconData buttonIcon = isOwner ? Icons.local_shipping : Icons.handshake;
    final Color buttonColor = isOwner ? Colors.green : accentColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Estado:", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.materialData['status']?.toUpperCase() ?? 'SOLICITADO',
                  style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // BOTÓN DINÁMICO
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // Mañana implementaremos la lógica de Firebase aquí
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Acción: $buttonText (Próximamente)")),
                );
              },
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Escribe un mensaje...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: accentColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendTextMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFD1E3F3) : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }
}