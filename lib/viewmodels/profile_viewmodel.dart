import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  ProfileViewModel(this._authService, this._userService);

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  // Datos de perfil
  String? nombre;
  String? apellido;
  String? email;
  String? cedula;
  String? carrera;
  String? rol;
  String? avatarEmoji;

  String get username {
    final e = (email ?? '').trim();
    if (e.isEmpty) return 'usuario';
    final at = e.indexOf('@');
    return at > 0 ? e.substring(0, at) : e;
  }

  String get nombreCompleto {
    final n = (nombre ?? '').trim();
    final a = (apellido ?? '').trim();
    if (n.isEmpty && a.isEmpty) return 'Nombre del usuario';
    if (a.isEmpty) return n;
    if (n.isEmpty) return a;
    return '$n $a';
  }

  Future<void> cargarPerfil() async {
    isLoading = true;
    errorMessage = null;

    // Limpieza de estado al empezar a cargar
    nombre = null;
    apellido = null;
    cedula = null;
    carrera = null;
    rol = null;
    avatarEmoji = null;

    notifyListeners();

    try {
      final user = _authService.currentUser;

      if (user == null) {
        email = null;
        errorMessage = "No hay sesión activa.";
        return;
      }

      // Default desde Auth
      email = user.email;

      final data = await _userService.getUserProfile(user.uid);

      if (data == null) {
        return;
      }

      final n = data['nombre'];
      if (n is String && n.trim().isNotEmpty) nombre = n.trim();

      final a = data['apellido'];
      if (a is String && a.trim().isNotEmpty) apellido = a.trim();

      final e = data['email'];
      if (e is String && e.trim().isNotEmpty) email = e.trim();

      final c = data['cedula'];
      if (c is String && c.trim().isNotEmpty) cedula = c.trim();

      final ca = data['carrera'];
      if (ca is String && ca.trim().isNotEmpty) carrera = ca.trim();

      final r = data['rol'];
      if (r is String && r.trim().isNotEmpty) rol = r.trim();

      final em = data['avatarEmoji'];
      if (em is String && em.trim().isNotEmpty) avatarEmoji = em.trim();
    } catch (_) {
      errorMessage = "Error cargando perfil";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? validarPerfil({
    required String nombre,
    required String apellido,
    required String cedula,
    required String carrera,
  }) {
    if (nombre.trim().isEmpty || apellido.trim().isEmpty) {
      return "❌ Por favor, completa nombre y apellido.";
    }
    if (cedula.trim().isEmpty) {
      return "❌ Por favor, ingresa la cédula.";
    }
    final ced = cedula.trim();
    if (!RegExp(r'^\d{6,10}$').hasMatch(ced)) {
      return "❌ La cédula debe contener solo números (6 a 10 dígitos).";
    }
    if (carrera.trim().isEmpty) {
      return "❌ Por favor, indica tu carrera.";
    }
    return null;
  }

  Future<bool> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String cedula,
    required String carrera,
    String? avatarEmoji,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      errorMessage = "No hay sesión activa.";
      notifyListeners();
      return false;
    }

    final msg = validarPerfil(
      nombre: nombre,
      apellido: apellido,
      cedula: cedula,
      carrera: carrera,
    );

    if (msg != null) {
      errorMessage = msg;
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'cedula': cedula.trim(),
        'carrera': carrera.trim(),
        'email': (email ?? user.email ?? '').trim(),

        if ((rol ?? '').trim().isNotEmpty) 'rol': rol!.trim(),
      };

      final em = (avatarEmoji ?? '').trim();
      if (em.isNotEmpty) {
        data['avatarEmoji'] = em;
      }

      await _userService.upsertUserProfile(uid: user.uid, data: data);

      // Refresca estado local
      this.nombre = nombre.trim();
      this.apellido = apellido.trim();
      this.cedula = cedula.trim();
      this.carrera = carrera.trim();
      if (em.isNotEmpty) this.avatarEmoji = em;

      return true;
    } catch (_) {
      errorMessage = "Error guardando perfil";
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}