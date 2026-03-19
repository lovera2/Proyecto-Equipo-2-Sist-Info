import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMaterialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> categoriasBase = [
    'Faces',
    'Ingeniería',
    'Humanidades',
    'Derecho',
    'Otros',
  ];

  String _normalizarTexto(String valor) {
    return valor.trim().toLowerCase();
  }

  String _buildCategoryDocId(String categoryName) {
    return _normalizarTexto(categoryName).replaceAll('/', '_');
  }

  bool esCategoriaBase(String nombreCategoria) {
    final normalizada = _normalizarTexto(nombreCategoria);
    return categoriasBase.any((c) => _normalizarTexto(c) == normalizada);
  }

  Future<List<Map<String, dynamic>>> obtenerMateriales() async {
    final snap = await _firestore.collection('materials').get();
    return snap.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }

  Future<void> actualizarMaterial(String id, Map<String, dynamic> data) async {
    await _firestore.collection('materials').doc(id).update(data);
  }

  Future<void> eliminarMaterial(String id, String status) async {
    if (_normalizarTexto(status) != 'disponible') {
      throw Exception("Solo se pueden eliminar libros en estado 'disponible'.");
    }
    await _firestore.collection('materials').doc(id).delete();
  }

  Future<void> asegurarCategoriasBase() async {
    for (final categoria in categoriasBase) {
      final docRef =
          _firestore.collection('categories').doc(_buildCategoryDocId(categoria));
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'name': categoria,
          'normalizedName': _normalizarTexto(categoria),
          'isBase': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> sincronizarCategoriasDesdeMateriales() async {
    final materialsSnapshot = await _firestore.collection('materials').get();

    for (final materialDoc in materialsSnapshot.docs) {
      final data = materialDoc.data();
      final categoria = (data['category'] ?? '').toString().trim();

      if (categoria.isEmpty) continue;

      final normalizada = _normalizarTexto(categoria);
      final existing = await _firestore
          .collection('categories')
          .where('normalizedName', isEqualTo: normalizada)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await _firestore
            .collection('categories')
            .doc(_buildCategoryDocId(categoria))
            .set({
          'name': categoria,
          'normalizedName': normalizada,
          'isBase': esCategoriaBase(categoria),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<List<String>> obtenerCategorias() async {
    await asegurarCategoriasBase();
    await sincronizarCategoriasDesdeMateriales();

    final snapshot = await _firestore.collection('categories').get();

    final categorias = snapshot.docs
        .map((doc) => (doc.data()['name'] ?? '').toString().trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    categorias.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return categorias;
  }

  Future<void> crearCategoria(String nombre) async {
    final limpio = nombre.trim();
    final normalizado = _normalizarTexto(limpio);

    if (limpio.isEmpty) {
      throw Exception('El nombre de la categoría no puede estar vacío.');
    }

    final snapshot = await _firestore.collection('categories').get();

    final yaExiste = snapshot.docs.any((doc) {
      final data = doc.data();
      final nombreExistente = (data['name'] ?? '').toString();
      final normalizadoExistente =
          (data['normalizedName'] ?? '').toString();

      if (normalizadoExistente.trim().isNotEmpty) {
        return _normalizarTexto(normalizadoExistente) == normalizado;
      }

      return _normalizarTexto(nombreExistente) == normalizado;
    });

    if (yaExiste) {
      throw Exception('Esa categoría ya existe.');
    }

    await _firestore
        .collection('categories')
        .doc(_buildCategoryDocId(limpio))
        .set({
      'name': limpio,
      'normalizedName': normalizado,
      'isBase': esCategoriaBase(limpio),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> renombrarCategoria(
    String nombreActual,
    String nuevoNombre,
  ) async {
    final actualLimpio = nombreActual.trim();
    final nuevoLimpio = nuevoNombre.trim();
    final actualNormalizado = _normalizarTexto(actualLimpio);
    final nuevoNormalizado = _normalizarTexto(nuevoLimpio);

    if (actualLimpio.isEmpty || nuevoLimpio.isEmpty) {
      throw Exception('Los nombres de la categoría no pueden estar vacíos.');
    }

    if (esCategoriaBase(actualLimpio)) {
      throw Exception('Las categorías base no pueden renombrarse.');
    }

    if (actualNormalizado == nuevoNormalizado) {
      throw Exception('Debes ingresar un nombre diferente.');
    }

    final existing = await _firestore
        .collection('categories')
        .where('normalizedName', isEqualTo: nuevoNormalizado)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Ya existe una categoría con ese nombre.');
    }

    final batch = _firestore.batch();

    final oldCategoryRef = _firestore
        .collection('categories')
        .doc(_buildCategoryDocId(actualLimpio));

    final newCategoryRef = _firestore
        .collection('categories')
        .doc(_buildCategoryDocId(nuevoLimpio));

    batch.set(newCategoryRef, {
      'name': nuevoLimpio,
      'normalizedName': nuevoNormalizado,
      'isBase': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final materialsSnapshot = await _firestore.collection('materials').get();

    for (final materialDoc in materialsSnapshot.docs) {
      final data = materialDoc.data();
      final categoriaMaterial =
          _normalizarTexto((data['category'] ?? '').toString());

      if (categoriaMaterial == actualNormalizado) {
        batch.update(materialDoc.reference, {
          'category': nuevoLimpio,
          'normalizedCategory': nuevoNormalizado,
        });
      }
    }

    batch.delete(oldCategoryRef);

    await batch.commit();
  }

  Future<void> eliminarCategoria(String nombreCategoria) async {
    final categoriaLimpia = nombreCategoria.trim();
    final categoriaNormalizada = _normalizarTexto(categoriaLimpia);

    if (esCategoriaBase(categoriaLimpia)) {
      throw Exception('Las categorías base no pueden eliminarse.');
    }

    final materialsSnapshot = await _firestore.collection('materials').get();

    final materialesDeCategoria = materialsSnapshot.docs.where((doc) {
      final data = doc.data();
      final categoriaMaterial =
          _normalizarTexto((data['category'] ?? '').toString());
      return categoriaMaterial == categoriaNormalizada;
    }).toList();

    final materialesNoDisponibles = materialesDeCategoria.where((doc) {
      final data = doc.data();
      final status = _normalizarTexto((data['status'] ?? '').toString());
      return status != 'disponible';
    }).toList();

    if (materialesNoDisponibles.isNotEmpty) {
      throw Exception(
        'No se puede eliminar la categoría porque tiene libros prestados, reservados o no disponibles.',
      );
    }

    final batch = _firestore.batch();

    for (final materialDoc in materialesDeCategoria) {
      batch.delete(materialDoc.reference);
    }

    final categoriaDoc = _firestore
        .collection('categories')
        .doc(_buildCategoryDocId(categoriaLimpia));

    batch.delete(categoriaDoc);

    await batch.commit();
  }
}

//  AdminMaterialService es una clase que proporciona métodos para administrar materiales y categorías en la base de datos de Firestore. Incluye funcionalidades para obtener, actualizar y eliminar materiales, así como para gestionar categorías, asegurando la integridad de los datos y aplicando reglas específicas para categorías base y materiales en diferentes estados.