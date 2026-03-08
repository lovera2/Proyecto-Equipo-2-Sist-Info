import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/material_service.dart';

class HomeViewModel extends ChangeNotifier {
  final MaterialService _materialService;

  // Estado: Categoría seleccionada (Por defecto "TODO")
  String _selectedCategory = "TODO";
  String get selectedCategory => _selectedCategory;

  // Estado: Búsqueda 
  String _searchQuery = "";

  HomeViewModel(this._materialService);

  //Acción: Cambiar categoría (FACES, INGENIERÍA, etc.)
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners(); // Esto recarga la pantalla
  }

  //Acción: Actualizar texto de búsqueda
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  //Conexión directa a la base de datos
  String get searchQuery => _searchQuery;

  Stream<List<QueryDocumentSnapshot>> get filteredMaterialsStream {
    return _materialService.getMaterials(_selectedCategory).map((snapshot) {
      final query = _searchQuery.toLowerCase().trim();

      // Da la lista completa si no hay texto en la búsqueda
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
