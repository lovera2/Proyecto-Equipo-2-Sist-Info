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
  Stream<QuerySnapshot> get materialsStream =>
      _materialService.getMaterials(_selectedCategory);
}
