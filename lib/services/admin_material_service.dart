import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMaterialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> obtenerMateriales() async {
    final snap = await _firestore.collection('materials').get();
    return snap.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<void> actualizarMaterial(String id, Map<String, dynamic> data) async {
    await _firestore.collection('materials').doc(id).update(data);
  }

  // Aquí se elimina el libro SÓLO si está disponible
  Future<void> eliminarMaterial(String id, String status) async {
    if (status.toLowerCase() != 'disponible') {
      throw Exception("Solo se pueden eliminar libros en estado 'disponible'.");
    }
    await _firestore.collection('materials').doc(id).delete();
  }
}