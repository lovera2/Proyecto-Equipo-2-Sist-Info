import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Iniciar o recuperar un chat existente
  Future<String> getOrCreateChat(String currentUserId, String ownerId, String materialId) async {
    final query = await _firestore
        .collection('chats')
        .where('materialId', isEqualTo: materialId)
        .where('participants', arrayContains: currentUserId)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    DocumentReference docRef = await _firestore.collection('chats').add({
      'participants': [currentUserId, ownerId],
      'materialId': materialId,
      'status': 'solicitado', 
      'lastMessage': 'Solicitud de préstamo enviada',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // 2. Enviar mensaje
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // 3. Cambiar estado del libro y del préstamo
  Future<void> updateLoanStatus(String chatId, String materialId, String newStatus) async {
    await _firestore.collection('chats').doc(chatId).update({'status': newStatus});
    
    await _firestore.collection('materials').doc(materialId).update({
      'status': newStatus == 'en_prestamo' ? 'no disponible' : 'disponible'
    });
  }

  // 4. Establecer límite de días
  Future<void> setLoanDuration(String chatId, int days) async {
    await _firestore.collection('chats').doc(chatId).update({
      'loanDurationDays': days,
      'loanStartDate': FieldValue.serverTimestamp(),
    });
  }
} 