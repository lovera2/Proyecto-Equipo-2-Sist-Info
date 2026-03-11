import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Crear o recuperar chat entre 2 usuarios para un material
  Future<String> getOrCreateChat(
    String userAId,
    String userBId,
    String materialId,
  ) async {
    final a = userAId.trim();
    final b = userBId.trim();
    final m = materialId.trim();

    if (a.isEmpty || b.isEmpty || m.isEmpty) {
      throw Exception('Ids inválidos para crear chat');
    }

    // key determinística: mismos usuarios + mismo material => mismo chat
    final users = [a, b]..sort();
    final chatId = '${users[0]}_${users[1]}_$m';

    final ref = _firestore.collection('chats').doc(chatId);
    final snap = await ref.get();

    if (!snap.exists) {
      // Buscamos el material para saber quién es el dueño original
      String ownerId = '';
      try {
        final matDoc = await _firestore.collection('materials').doc(m).get();
        if (matDoc.exists) {
          final data = matDoc.data() as Map<String, dynamic>;
          // Dependiendo de cómo lo llames en Firebase, buscamos userId u ownerId
          ownerId = (data['userId'] ?? data['ownerId'] ?? '').toString();
        }
      } catch (e) {
        // Si hay error, continuamos
      }

      await ref.set({
        'participants': users,
        'materialId': m,
        'ownerId': ownerId, // <--- AQUÍ GUARDAMOS EL DUEÑO
        'status': 'pendiente',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  //Enviar mensaje
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  //Actualizar estado del préstamo
  Future<void> updateLoanStatus(
      String chatId,
      String materialId,
      String newStatus,
      ) async {
    await _firestore.collection('chats').doc(chatId).update({
      'status': newStatus,
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    if (materialId.isNotEmpty) {
      await _firestore.collection('materials').doc(materialId).update({
        'status': newStatus,
      });
    }
  }

  //Registrar solicitud de devolución
  Future<void> registerReturnRequest({
    required String chatId,
    required String materialId,
    required String senderId,
    required int utilidad,
    required int estadoFisico,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.update({
      'status': 'devolucion_pendiente',
      'returnData': {
        'utilidad': utilidad,
        'estadoFisico': estadoFisico,
        'senderId': senderId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    });

    await _firestore.collection('materials').doc(materialId).update({
      'status': 'devolucion_pendiente'
    });
  }

  // nueva funcion optimizada por segunda vez, con esto el chat se elimina pero no de la base de datos, asi se puede acceder a ella para el dashboard
  Future<void> confirmBookReturn({
    required String chatId,
    required String materialId,
    required String confirmerId,
  }) async {
    try {
      // extraemos los datos antes de borrarlo para el historial
      final chatSnap = await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatSnap.data() as Map<String, dynamic>;

      // creamos un registro histórico en una nueva colección
      await _firestore.collection('completed_loans').add({
        'chatId': chatId,
        'materialId': materialId,
        'ownerId': chatData['ownerId'],
        'borrowerId': chatData['participants'].firstWhere((id) => id != chatData['ownerId']),
        'materialTitle': chatData['materialTitle'] ?? 'Libro',
        'completedAt': FieldValue.serverTimestamp(),
        'rating': chatData['returnData'] // guardamos la utilidad y estado físico que puso el usuario que son caracteristicas diferenciadoras
      });

      if (materialId.isNotEmpty) {
        await _firestore.collection('materials').doc(materialId).update({
          'status': 'disponible'
        });
      }

      // Limpiar mensajes y borrar chat
      final messagesSnapshot = await _firestore.collection('chats').doc(chatId).collection('messages').get();
      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('chats').doc(chatId).delete();

    } catch (e) {
      print("Error al archivar y cerrar chat: $e");
      rethrow;
    }
  }
  
}