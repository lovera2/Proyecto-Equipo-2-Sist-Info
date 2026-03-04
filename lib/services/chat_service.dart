import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // metodo para obtener o crear un chat
  Future<String> getOrCreateChat(String uid1, String uid2, String materialId) async {
    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContains: uid1)
        .get();

    for (var doc in query.docs) {
      List participants = doc['participants'];
      if (participants.contains(uid2) && doc['materialId'] == materialId) {
        return doc.id;
      }
    }

    DocumentReference docRef = await _firestore.collection('chats').add({
      'participants': [uid1, uid2],
      'materialId': materialId,
      'status': 'disponible',
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  // metodo para enviar mensajes
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastUpdate': FieldValue.serverTimestamp(),
    });
  }
  Future<void> updateLoanStatus(String chatId, String materialId, String newStatus) async {
    if (materialId.isEmpty) {
      print("Error: El ID del material está vacío.");
      return;
    }

    try {
      // se actualiza el libro en la colección materials
      await _firestore.collection('materials').doc(materialId).update({
        'status': newStatus,
      });

      // se actualiza el estado dentro del chat
      await _firestore.collection('chats').doc(chatId).update({
        'status': newStatus,
        'lastUpdate': FieldValue.serverTimestamp(),
      });

      print("Firebase actualizado con éxito a: $newStatus");
    } catch (e) {
      print("Error en updateLoanStatus: $e");
      rethrow;
    }
  }
}