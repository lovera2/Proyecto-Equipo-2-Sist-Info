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
      await ref.set({
        'participants': users,
        'materialId': m,
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

  //Confirmar devolución por el dueño
  Future<void> confirmBookReturn({

    required String chatId,
    required String materialId,
    required String confirmerId,

  }) async {

    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.update({

      'status': 'disponible',
      'lastUpdate': FieldValue.serverTimestamp(),

    });

    await _firestore.collection('materials').doc(materialId).update({

      'status': 'disponible'

    });

  }

}