import 'package:flutter/foundation.dart';

import '../services/admin_user_management_service.dart';

class AdminUserManagementViewModel extends ChangeNotifier {
  final AdminUserManagementService _service = AdminUserManagementService();

  bool isLoading = false;
  bool isProcessing = false;
  String? errorMessage;

  String _busqueda = '';

  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> usuariosFiltrados = [];

  Map<String, dynamic>? usuarioSeleccionado;

  List<Map<String, dynamic>> get usuarios => List.unmodifiable(_usuarios);
  String get busqueda => _busqueda;

  Future<void> cargarUsuarios() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _usuarios = await _service.obtenerUsuarios();
      _aplicarFiltro();

      if (usuarioSeleccionado != null) {
        final uid = (usuarioSeleccionado!['uid'] ?? '').toString();
        try {
          usuarioSeleccionado = _usuarios.firstWhere(
            (u) => (u['uid'] ?? '').toString() == uid,
          );
        } catch (_) {
          usuarioSeleccionado = null;
        }
      }
    } catch (e) {
      errorMessage = 'No se pudieron cargar los usuarios: $e';
      _usuarios = [];
      usuariosFiltrados = [];
      usuarioSeleccionado = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setBusqueda(String texto) {
    _busqueda = texto.trim();
    _aplicarFiltro();
    notifyListeners();
  }

  void seleccionarUsuario(Map<String, dynamic> usuario) {
    usuarioSeleccionado = usuario;
    notifyListeners();
  }

  void limpiarSeleccion() {
    usuarioSeleccionado = null;
    notifyListeners();
  }

  Future<String?> suspenderUsuarioSeleccionado() async {
    if (usuarioSeleccionado == null) {
      return 'Debes seleccionar un usuario.';
    }

    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uid = (usuarioSeleccionado!['uid'] ?? '').toString();
      final mensaje = await _service.suspenderUsuario(uid);
      await cargarUsuarios();
      return mensaje;
    } catch (e) {
      errorMessage = 'No se pudo suspender la cuenta: $e';
      notifyListeners();
      return errorMessage;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<String?> reactivarUsuarioSeleccionado() async {
    if (usuarioSeleccionado == null) {
      return 'Debes seleccionar un usuario.';
    }

    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uid = (usuarioSeleccionado!['uid'] ?? '').toString();
      final mensaje = await _service.reactivarUsuario(uid);
      await cargarUsuarios();
      return mensaje;
    } catch (e) {
      errorMessage = 'No se pudo reactivar la cuenta: $e';
      notifyListeners();
      return errorMessage;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<String?> eliminarUsuarioSeleccionado() async {
    if (usuarioSeleccionado == null) {
      return 'Debes seleccionar un usuario.';
    }

    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uid = (usuarioSeleccionado!['uid'] ?? '').toString();
      final mensaje = await _service.eliminarUsuario(uid);
      usuarioSeleccionado = null;
      await cargarUsuarios();
      return mensaje;
    } catch (e) {
      errorMessage = 'No se pudo eliminar la cuenta: $e';
      notifyListeners();
      return errorMessage;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  Future<String?> editarUsuarioSeleccionado({
    required String nombre,
    required String apellido,
    required String username,
    required String cedula,
    required String carrera,
  }) async {
    if (usuarioSeleccionado == null) {
      return 'Debes seleccionar un usuario.';
    }

    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final uid = (usuarioSeleccionado!['uid'] ?? '').toString();

      await _service.editarUsuario(
        uid: uid,
        nombre: nombre,
        apellido: apellido,
        username: username,
        cedula: cedula,
        carrera: carrera,
      );

      await cargarUsuarios();

      try {
        usuarioSeleccionado = _usuarios.firstWhere(
          (u) => (u['uid'] ?? '').toString() == uid,
        );
      } catch (_) {}

      return null;
    } catch (e) {
      final mensaje = e.toString().replaceFirst('Exception: ', '').trim();
      errorMessage = mensaje.isEmpty
          ? 'Error al actualizar el usuario'
          : mensaje;
      notifyListeners();
      return errorMessage;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  void _aplicarFiltro() {
    final q = _busqueda.toLowerCase();

    if (q.isEmpty) {
      usuariosFiltrados = List.from(_usuarios);
      return;
    }

    usuariosFiltrados = _usuarios.where((u) {
      final nombre = (u['nombre'] ?? '').toString().toLowerCase();
      final apellido = (u['apellido'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final username = (u['username'] ?? '').toString().toLowerCase();
      final cedula = (u['cedula'] ?? '').toString().toLowerCase();
      final carrera = (u['carrera'] ?? '').toString().toLowerCase();

      final nombreCompleto = '$nombre $apellido';

      return nombre.contains(q) ||
          apellido.contains(q) ||
          nombreCompleto.contains(q) ||
          email.contains(q) ||
          username.contains(q) ||
          cedula.contains(q) ||
          carrera.contains(q);
    }).toList();
  }
}