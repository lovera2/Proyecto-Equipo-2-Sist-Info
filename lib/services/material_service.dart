import 'package:cloud_firestore/cloud_firestore.dart';

// Esta clase es el puente directo con la base de datos de Firebase se encarga de mandar los datos.
class MaterialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Función para subir los datos del libro o guía a la colección 'materials'.
  // Recibe un mapa (JSON) con toda la info que recolectamos en la vista.
  Future<void> uploadMaterial(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('materials').add(data);
    } catch (e) {
      // Si algo sale mal con Firebase, avisamos para que el ViewModel se entere.
      throw Exception("Error al subir material: $e");
    }
  }
}