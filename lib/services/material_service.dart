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

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  String _docIdFromCategory(String value) {
    return _normalize(value).replaceAll('/', '_');
  }

  Future<void> ensureDefaultCategories() async {
    for (final category in defaultCategories) {
      final normalized = _normalize(category);
      final docRef =
          _firestore.collection('categories').doc(_docIdFromCategory(category));
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'name': category,
          'normalizedName': normalized,
          'isBase': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> addMaterial(Map<String, dynamic> data) async {
    try {
      await ensureDefaultCategories();

      final category = (data['category'] ?? '').toString().trim();
      if (category.isNotEmpty) {
        final normalized = _normalize(category);
        final existing = await _firestore
            .collection('categories')
            .where('normalizedName', isEqualTo: normalized)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await _firestore
              .collection('categories')
              .doc(_docIdFromCategory(category))
              .set({
            'name': category,
            'normalizedName': normalized,
            'isBase': defaultCategories
                .any((c) => _normalize(c) == normalized),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

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
      return categorias;
    });
  }
}

//  MaterialService es una clase que proporciona métodos para interactuar con la colección de materiales y categorías en Firestore. Incluye funcionalidades para agregar materiales, obtener materiales por categoría y obtener un stream de categorías, asegurando que las categorías predeterminadas estén siempre presentes en la base de datos.