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
            Text(widget.receiverName, style: const TextStyle(fontSize: 16, color: Colors.white)),
            Text(libroTitulo, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildLoanStatusBar(unimetOrange),
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
          _buildInputArea(unimetOrange),
        ],
      ),
    );
  }

  Widget _buildLoanStatusBar(Color accentColor) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

        final chatData = snapshot.data!.data() as Map<String, dynamic>;
        final String currentStatus = chatData['status'] ?? 'disponible';
        
        
        // buscama en materialData
        final String idDesdeMaterial = widget.materialData['userId'] ?? '';
        // busca en el documento del chat directamente
        final String idDesdeChat = chatData['ownerId'] ?? ''; 
        // Fallback: El segundo participante 
        final List participants = chatData['participants'] ?? [];
        final String idAlternativo = (participants.length > 1) ? participants[1] : '';

        // Consolida quién es el dueño real
        final String ownerIdFinal = idDesdeMaterial.isNotEmpty 
            ? idDesdeMaterial 
            : (idDesdeChat.isNotEmpty ? idDesdeChat : idAlternativo);
        
        final bool imTheOwner = (currentUserId == ownerIdFinal);

        // DEBUG para verificar en consola (estaba dando muchos problemas pero ya se resolvio, se puede remover si ustedes no lo ven necesario pero dejenlo just in case)
        print("DEBUG: Mi ID: $currentUserId | Dueño Detectado: $ownerIdFinal | ¿Soy dueño?: $imTheOwner");

        String buttonText = "";
        IconData buttonIcon = Icons.info_outline;
        Color buttonColor = Colors.grey;
        VoidCallback? action;

        if (imTheOwner) {
          if (currentStatus == 'disponible' || currentStatus == 'solicitado') {
            buttonText = "Confirmar Entrega";
            buttonIcon = Icons.local_shipping;
            buttonColor = Colors.green;
            action = () => _chatService.updateLoanStatus(widget.chatId, widget.materialData['id'] ?? '', 'esperando_confirmacion');
          } else {
            buttonText = "Esperando confirmación...";
            buttonIcon = Icons.hourglass_bottom;
            buttonColor = Colors.grey;
            action = null;
          }
        } else {
          if (currentStatus == 'esperando_confirmacion') {
            buttonText = "Confirmar Recibido";
            buttonIcon = Icons.handshake;
            buttonColor = accentColor;
            action = () => _chatService.updateLoanStatus(widget.chatId, widget.materialData['id'] ?? '', 'rentado');
          } else if (currentStatus == 'rentado') {
            buttonText = "Libro Recibido";
            buttonIcon = Icons.check_circle;
            buttonColor = Colors.blue;
            action = null;
          } else {
            buttonText = "Esperando entrega...";
            buttonIcon = Icons.schedule;
            buttonColor = Colors.grey;
            action = null;
          }
        }

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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Text(currentStatus.toUpperCase(), 
                      style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
                  onPressed: action,
                  icon: Icon(buttonIcon, size: 18),
                  label: Text(buttonText),
                ),
              ),
            ],
          ),
        );
      },
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