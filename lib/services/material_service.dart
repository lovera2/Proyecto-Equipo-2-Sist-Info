import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> defaultCategories = [
    'Faces',
    'Ingeniería',
    'Humanidades',
    'Derecho',
    'Otros',
  ];

  Future<void> ensureDefaultCategories() async {
    final batch = _firestore.batch();

    for (final category in defaultCategories) {
      final normalized = category.trim().toLowerCase();
      final docId = normalized.replaceAll('/', '_');
      final docRef = _firestore.collection('categories').doc(docId);
      final doc = await docRef.get();

      if (!doc.exists) {
        batch.set(docRef, {
          'name': category,
          'normalizedName': normalized,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  Future<void> addMaterial(Map<String, dynamic> data) async {
    try {
      await ensureDefaultCategories();
      await _firestore.collection('materials').add(data);
    } catch (e) {
      print("Error guardando: $e");
      throw Exception("Error al guardar material: $e");
    }
  }

  Stream<QuerySnapshot> getMaterials(String category) {
    if (category == "TODO") {
      return _firestore
          .collection('materials')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return _firestore
          .collection('materials')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Stream<List<String>> getCategoriesStream() async* {
    await ensureDefaultCategories();

    yield* _firestore.collection('categories').snapshots().map((snapshot) {
      final categorias = snapshot.docs
          .map((doc) => (doc.data()['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      categorias.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (categorias.isEmpty) {
        return defaultCategories;
      }

      if (!categorias.any((c) => c.trim().toLowerCase() == 'otros')) {
        categorias.add('Otros');
        categorias.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }

      return categorias;
    });
  }
}