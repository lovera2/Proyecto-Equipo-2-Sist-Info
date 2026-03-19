import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_material_service.dart';

class AdminMaterialViewModel extends ChangeNotifier {
  final AdminMaterialService _service;
  AdminMaterialViewModel(this._service);

  List<Map<String, dynamic>> _todosLosMateriales = [];
  List<Map<String, dynamic>> _materialesFiltrados = [];
  List<String> _categorias = [];
  Map<String, dynamic>? _materialSeleccionado;
  bool _isLoading = false;

  List<Map<String, dynamic>> get materiales => _materialesFiltrados;
  List<String> get categorias => _categorias;
  Map<String, dynamic>? get materialSeleccionado => _materialSeleccionado;
  bool get isLoading => _isLoading;

  bool esCategoriaBase(String categoria) {
    return _service.esCategoriaBase(categoria);
  }

  Future<void> actualizarMaterial(
    String id,
    Map<String, dynamic> newData,
  ) async {
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
      _materialesFiltrados = List.from(_todosLosMateriales);
      _categorias = await _service.obtenerCategorias();
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
      _materialesFiltrados = List.from(_todosLosMateriales);
    } else {
      final texto = query.toLowerCase();
      _materialesFiltrados = _todosLosMateriales.where((m) {
        final titulo = m['title']?.toString().toLowerCase() ?? '';
        final autor = m['author']?.toString().toLowerCase() ?? '';
        final categoria = m['category']?.toString().toLowerCase() ?? '';
        return titulo.contains(texto) ||
            autor.contains(texto) ||
            categoria.contains(texto);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> agregarCategoria(String nombre) async {
    await _service.crearCategoria(nombre);
    _categorias = await _service.obtenerCategorias();
    notifyListeners();
  }

  Future<void> renombrarCategoria(
    String nombreActual,
    String nuevoNombre,
  ) async {
    await _service.renombrarCategoria(nombreActual, nuevoNombre);
    await cargarMateriales();
  }

  Future<void> eliminarCategoria(String nombre) async {
    await _service.eliminarCategoria(nombre);
    await cargarMateriales();
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