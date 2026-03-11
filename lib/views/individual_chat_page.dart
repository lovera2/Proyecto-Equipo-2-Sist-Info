import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/chat_service.dart';
import 'return_book_page.dart';

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

  //Abrir pantalla de devolución
  void _openReturnPage() async {

    final result = await Navigator.push(

      context,

      MaterialPageRoute(
        builder: (_) => ReturnBookPage(
          chatId: widget.chatId,
          materialData: widget.materialData,
        ),
      ),

    );

    if(result == true && mounted){

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text("Devolución registrada"),
        ),

      );

    }

  }

  @override
  Widget build(BuildContext context) {

    const Color unimetBlue = Color(0xFF1B3A57);
    const Color unimetOrange = Color(0xFFF28B31);

    final String libroTituloLocal = (widget.materialData['title'] ??
            widget.materialData['materialTitle'] ??
            widget.materialData['bookTitle'] ??
            widget.materialData['nombreLibro'] ??
            '')
        .toString()
        .trim();

    return Scaffold(

      appBar: AppBar(

        backgroundColor: unimetBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,

        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .snapshots(),
          builder: (context, chatSnap) {
            // 1) Preferimos lo que venga ya en memoria (MaterialDetail -> Chat)
            final String titleFromLocal = libroTituloLocal;

            // 2) Si no viene en memoria, intentamos leerlo del documento del chat
            String titleFromChat = '';
            String materialIdFromChat = '';

            if (chatSnap.hasData && chatSnap.data != null && chatSnap.data!.exists) {
              final data = chatSnap.data!.data() as Map<String, dynamic>;
              titleFromChat = (data['materialTitle'] ?? data['bookTitle'] ?? '').toString().trim();
              materialIdFromChat = (data['materialId'] ?? '').toString().trim();
            }

            final String resolvedTitle =
                (titleFromLocal.isNotEmpty ? titleFromLocal : titleFromChat);

            // 3) Si aún no tenemos título, consultamos la colección materials usando materialId
            if (resolvedTitle.isEmpty && materialIdFromChat.isNotEmpty) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('materials')
                    .doc(materialIdFromChat)
                    .get(),
                builder: (context, matSnap) {
                  String fetchedTitle = '';
                  if (matSnap.hasData && matSnap.data != null && matSnap.data!.exists) {
                    final md = matSnap.data!.data() as Map<String, dynamic>;
                    fetchedTitle = (md['title'] ?? '').toString().trim();
                  }

                  final String finalTitle =
                      fetchedTitle.isNotEmpty ? fetchedTitle : 'Libro';

                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.receiverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Libro: $finalTitle",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            return SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.receiverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Libro: ${resolvedTitle.isNotEmpty ? resolvedTitle : 'Libro'}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
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

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(

                  reverse: true,
                  itemCount: messages.length,

                  itemBuilder: (context, index) {

                    final msg =
                        messages[index].data() as Map<String, dynamic>;

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

      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .snapshots(),

      builder: (context, snapshot) {

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final chatData = snapshot.data!.data() as Map<String, dynamic>;
        final String currentStatus = chatData['status'] ?? 'disponible';

        final String idDesdeMaterial = widget.materialData['userId'] ?? '';
        final String idDesdeChat = chatData['ownerId'] ?? '';

        final List participants = chatData['participants'] ?? [];

        final String idAlternativo =
            (participants.length > 1) ? participants[1] : '';

        final String ownerIdFinal = idDesdeMaterial.isNotEmpty
            ? idDesdeMaterial
            : (idDesdeChat.isNotEmpty ? idDesdeChat : idAlternativo);

        final bool imTheOwner = (currentUserId == ownerIdFinal);

        String buttonText = "";
        IconData buttonIcon = Icons.info_outline;
        Color buttonColor = Colors.grey;
        VoidCallback? action;

        //Dueño del libro
        if (imTheOwner) {

          if(currentStatus == 'devolucion_pendiente'){

            buttonText = "Confirmar Devolución";
            buttonIcon = Icons.assignment_return;
            buttonColor = Colors.green;

            action = () => _chatService.confirmBookReturn(
              chatId: widget.chatId,
              materialId: widget.materialData['id'] ?? '',
              confirmerId: currentUserId,
            );

          }

          else if (currentStatus == 'disponible' || currentStatus == 'solicitado') {

            buttonText = "Confirmar Entrega";
            buttonIcon = Icons.local_shipping;
            buttonColor = Colors.green;

            action = () => _chatService.updateLoanStatus(
              widget.chatId,
              widget.materialData['id'] ?? '',
              'esperando_confirmacion',
            );

          }

          else {

            buttonText = "Esperando acción...";
            buttonIcon = Icons.hourglass_bottom;
            buttonColor = Colors.grey;
            action = null;

          }

        }

        //Usuario que pidió el libro
        else {

          if (currentStatus == 'esperando_confirmacion') {

            buttonText = "Confirmar Recibido";
            buttonIcon = Icons.handshake;
            buttonColor = accentColor;

            action = () => _chatService.updateLoanStatus(
              widget.chatId,
              widget.materialData['id'] ?? '',
              'rentado',
            );

          }

          else if (currentStatus == 'rentado') {

            buttonText = "Registrar Devolución";
            buttonIcon = Icons.assignment_return;
            buttonColor = Colors.orange;

            action = _openReturnPage;

          }

          else {

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

                  const Text(
                    "Estado:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  Container(

                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),

                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: Text(
                      currentStatus.toUpperCase(),
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),

                filled: true,
                fillColor: Colors.grey[200],

                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20),

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

        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),

        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),

        decoration: BoxDecoration(

          color: isMe
              ? const Color(0xFFD1E3F3)
              : Colors.grey[300],

          borderRadius: BorderRadius.only(

            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),

            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),

          ),
        ),

        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}