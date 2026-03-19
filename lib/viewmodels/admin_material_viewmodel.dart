import 'package:flutter/material.dart';
import '../services/admin_material_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMaterialViewModel extends ChangeNotifier {
  final AdminMaterialService _service;
  AdminMaterialViewModel(this._service);

  List<Map<String, dynamic>> _todosLosMateriales = [];
  List<Map<String, dynamic>> _materialesFiltrados = [];
  Map<String, dynamic>? _materialSeleccionado;
  bool _isLoading = false;

  List<Map<String, dynamic>> get materiales => _materialesFiltrados;
  Map<String, dynamic>? get materialSeleccionado => _materialSeleccionado;
  bool get isLoading => _isLoading;

  Future<void> actualizarMaterial(String id, Map<String, dynamic> newData) async {
      try {
        await FirebaseFirestore.instance
            .collection('materials')
            .doc(id)
            .update(newData);
            
        await cargarMateriales(); 
      } catch (e) {
        throw Exception("Fallo de conexión con la base de datos: $e");
      }
    }

  Future<void> cargarMateriales() async {
    _isLoading = true;
    notifyListeners();
    try {
      _todosLosMateriales = await _service.obtenerMateriales();
      _materialesFiltrados = _todosLosMateriales;
    } catch (e) {
      debugPrint("Error: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  void seleccionarMaterial(Map<String, dynamic> material) {
    _materialSeleccionado = material;
    notifyListeners();
  }

  void filtrarMateriales(String query) {
    if (query.isEmpty) {
      _materialesFiltrados = _todosLosMateriales;
    } else {
      _materialesFiltrados = _todosLosMateriales.where((m) {
        final titulo = m['title']?.toString().toLowerCase() ?? '';
        return titulo.contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  Future<bool> eliminarSeleccionado() async {
    if (_materialSeleccionado == null) return false;
    try {
      await _service.eliminarMaterial(
        _materialSeleccionado!['id'],
        _materialSeleccionado!['status'] ?? '',
      );
      await cargarMateriales();
      _materialSeleccionado = null;
      return true;
    } catch (e) {
      rethrow;
    }
  }
}