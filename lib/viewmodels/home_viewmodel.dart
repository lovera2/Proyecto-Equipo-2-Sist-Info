import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/material_service.dart';

class HomeViewModel extends ChangeNotifier {
  final MaterialService _materialService;

  String _selectedCategory = "TODO";
  String get selectedCategory => _selectedCategory;

  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  List<String> _categorias = [];
  List<String> get categorias => _categorias;

  HomeViewModel(this._materialService) {
    cargarCategorias();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  String _normalizarTexto(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  Future<void> cargarCategorias() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('categories').get();

    final nombres = snapshot.docs
        .map((doc) => (doc.data()['name'] ?? '').toString().trim())
        .where((nombre) => nombre.isNotEmpty)
        .toList();

    final categoriasNormalizadas = <String>{};
    final categoriasLimpias = <String>[];

    for (final nombre in nombres) {
      final normalizado = _normalizarTexto(nombre);
      if (!categoriasNormalizadas.contains(normalizado)) {
        categoriasNormalizadas.add(normalizado);
        categoriasLimpias.add(nombre);
      }
    }

    categoriasLimpias.sort(
      (a, b) => _normalizarTexto(a).compareTo(_normalizarTexto(b)),
    );

    _categorias = categoriasLimpias;
    notifyListeners();
  }

  Stream<List<QueryDocumentSnapshot>> get filteredMaterialsStream {
    return _materialService.getMaterials(_selectedCategory).map((snapshot) {
      final query = _searchQuery.toLowerCase().trim();

      if (query.isEmpty) {
        return snapshot.docs;
      }

      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] ?? '').toString().toLowerCase();
        final author = (data['author'] ?? '').toString().toLowerCase();
        final category = (data['category'] ?? '').toString().toLowerCase();

        return title.contains(query) ||
            author.contains(query) ||
            category.contains(query);
      }).toList();
    });
  }
}
