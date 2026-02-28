import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Recibe el mapa de datos (que ya trae la foto en texto Base64) y lo guarda.
  Future<void> addMaterial(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('materials').add(data);
    } catch (e) {
      print("Error guardando: $e");
      throw Exception("Error al guardar material: $e");
    }
  }

  // Función para leer los materiales
  Stream<QuerySnapshot> getMaterials(String category) {
    if (category == "TODO") {
       return _firestore.collection('materials').orderBy('createdAt', descending: true).snapshots();
    } else {
       return _firestore.collection('materials')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }
}