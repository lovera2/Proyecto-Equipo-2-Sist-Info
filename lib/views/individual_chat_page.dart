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
    
        centerTitle: false, 
        elevation: 0,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .snapshots(),
          builder: (context, chatSnap) {
            String resolvedTitle = libroTituloLocal;
            String materialIdFromChat = '';

            if (chatSnap.hasData && chatSnap.data != null && chatSnap.data!.exists) {
              final data = chatSnap.data!.data() as Map<String, dynamic>;
              final String titleFromChat = (data['materialTitle'] ?? data['bookTitle'] ?? '').toString().trim();
              materialIdFromChat = (data['materialId'] ?? '').toString().trim();
              if (resolvedTitle.isEmpty) resolvedTitle = titleFromChat;
            }

            
            if (resolvedTitle.isEmpty && materialIdFromChat.isNotEmpty) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('materials').doc(materialIdFromChat).get(),
                builder: (context, matSnap) {
                  String fetchedTitle = 'Libro';
                  if (matSnap.hasData && matSnap.data?.exists == true) {
                    final md = matSnap.data!.data() as Map<String, dynamic>;
                    fetchedTitle = (md['title'] ?? 'Libro').toString().trim();
                  }
                  return _buildCenteredHeader(widget.receiverName, fetchedTitle);
                },
              );
            }

            return _buildCenteredHeader(
              widget.receiverName, 
              resolvedTitle.isNotEmpty ? resolvedTitle : 'Libro'
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
      
      // modificaciones de la logica, para asegurar que ahora los botones sirvan otra vez
      final String ownerIdFromChat = chatData['ownerId'] ?? '';
      final List participants = chatData['participants'] ?? [];
      
      final String ownerIdFinal = ownerIdFromChat.isNotEmpty 
          ? ownerIdFromChat 
          : (participants.isNotEmpty ? participants[0] : '');

      final bool imTheOwner = (currentUserId == ownerIdFinal);

      String buttonText = "";
      IconData buttonIcon = Icons.info_outline;
      Color buttonColor = Colors.grey;
      VoidCallback? action;

      // Botón secundario (ej: rechazar solicitud)
      String secondaryText = "";
      IconData secondaryIcon = Icons.close;
      Color secondaryColor = Colors.red;
      VoidCallback? secondaryAction;

      Future<void> _confirmReject() async {
        final bool? ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: const Text("Rechazar solicitud"),
              content: const Text(
                "¿Seguro que quieres rechazar este pedido?\n\n"
                "El libro volverá a estar disponible y la otra persona podrá solicitarlo nuevamente.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.close),
                  label: const Text("Rechazar"),
                ),
              ],
            );
          },
        );

        if (ok != true) return;

        final String materialId = (chatData['materialId'] ?? '').toString().trim();

        // 1) Cambiamos el estado del chat a rechazado
        await _chatService.updateLoanStatus(
          widget.chatId,
          materialId,
          'rechazado',
        );

        // 2) Dejamos un mensaje en el chat para que quede constancia
        _chatService.sendMessage(
          widget.chatId,
          currentUserId,
          "❌ Solicitud rechazada por el dueño.\n\n"
          "Por ahora el libro no será prestado. Puedes intentar solicitarlo más adelante si vuelve a estar disponible.",
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Solicitud rechazada")),
          );
        }
        if (context.mounted) {
          Navigator.pop(context);
        }
      }

      if (imTheOwner) {
        if (currentStatus == 'devolucion_pendiente') {
          buttonText = "Confirmar Devolución";
          buttonIcon = Icons.assignment_return;
          buttonColor = Colors.green;
          action = () async {
            // Mostramos un indicador de carga opcional
            await _chatService.confirmBookReturn(
              chatId: widget.chatId,
              materialId: chatData['materialId'] ?? '',
              confirmerId: currentUserId,
            );
            if (context.mounted) {
              Navigator.pop(context);
            }
          };
        } else if (currentStatus == 'solicitado' || currentStatus == 'pendiente') {
          buttonText = "Confirmar Entrega";
          buttonIcon = Icons.local_shipping;
          buttonColor = Colors.green;
          action = () => _chatService.updateLoanStatus(
            widget.chatId,
            chatData['materialId'] ?? '',
            'esperando_confirmacion',
          );

          // Permitir rechazar la solicitud mientras está en trámite
          secondaryText = "Rechazar pedido";
          secondaryIcon = Icons.close;
          secondaryColor = Colors.red;
          secondaryAction = _confirmReject;
        } else if (currentStatus == 'rechazado') {
          buttonText = "Solicitud rechazada";
          buttonIcon = Icons.block;
          buttonColor = Colors.blueGrey;
          action = null;
        } else if (currentStatus == 'disponible') {
          buttonText = "Sin solicitud activa";
          buttonIcon = Icons.info_outline;
          buttonColor = Colors.blueGrey;
          action = null;
        }
        else {
          buttonText = "Libro en préstamo";
          buttonIcon = Icons.hourglass_bottom;
          buttonColor = Colors.blueGrey;
          action = null;
        }
      } else {
        // Logica para los que solicitan el libro
        if (currentStatus == 'rechazado') {
          buttonText = "Solicitud rechazada";
          buttonIcon = Icons.block;
          buttonColor = Colors.blueGrey;
          action = null;
        } else if (currentStatus == 'esperando_confirmacion') {
          buttonText = "Confirmar Recibido";
          buttonIcon = Icons.handshake;
          buttonColor = accentColor;
          action = () => _chatService.updateLoanStatus(
            widget.chatId,
            chatData['materialId'] ?? '',
            'rentado',
          );
        } else if (currentStatus == 'rentado') {
          buttonText = "Registrar Devolución";
          buttonIcon = Icons.assignment_return;
          buttonColor = Colors.orange;
          action = _openReturnPage;
        } else {
          buttonText = "Esperando respuesta...";
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
                  // Chip de estado con color mejorado para 'rechazado'
                  // Insert status-aware color logic:
                  // final bool isRejected = currentStatus.toLowerCase() == 'rechazado';
                  // final Color chipColor = isRejected ? Colors.red : accentColor;
                  // ...Container...
                  // Inserted here:
                  // Determine chip color based on status
                  // (must be right before Container)
                  ...[
                    (() {
                      final bool isRejected = currentStatus.toLowerCase() == 'rechazado';
                      final Color chipColor = isRejected ? Colors.red : accentColor;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: chipColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentStatus.toUpperCase(),
                          style: TextStyle(
                            color: chipColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    })(),
                  ],
                ],
              ),

              const SizedBox(height: 10),

              if (secondaryAction == null) ...[
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
              ] else ...[
                Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: secondaryAction,
                        icon: Icon(secondaryIcon, size: 18),
                        label: Text(secondaryText),
                      ),
                    ),
                  ],
                ),
              ],

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
  
Widget _buildCenteredHeader(String name, String book) {
    return Container(
      width: double.infinity,
      // 48 es el ancho estándar del botón de retroceso en Flutter
      margin: const EdgeInsets.only(right: 48), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            "Libro: $book",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}