import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class ProfileViewModel extends ChangeNotifier {

  //Servicios que conectan con Firebase Auth y Firestore
  final AuthService _authService;
  final UserService _userService;

  ProfileViewModel(this._authService, this._userService);

  //Estados observables para la UI
  bool isLoading = false;
  bool isSaving = false;

  //Datos del perfil del usuario
  String? errorMessage;
  String? nombre;
  String? apellido;
  String? email;
  String? cedula;
  String? carrera;
  String? rol;
  String? avatarEmoji;

  //Obtiene el username a partir del correo
  String get username {
    final e = (email ?? '').trim();
    if (e.isEmpty) return 'usuario';

    final at = e.indexOf('@');
    return at > 0 ? e.substring(0, at) : e;
  }

  //Rol que se muestra en la interfaz
  String get rolMostrado {
    final r = (rol ?? '').trim();

    //Si no hay rol definido se muestra Estudiante
    if (r.isEmpty) return "Estudiante";

    return r;
  }

  // Normaliza un estatus para poder comparar aunque venga con espacios, mayúsculas o guiones.
  // Ej: "Devolución pendiente" -> "devolucion_pendiente"
  String normalizarStatus(String raw) {
    final s = raw.toLowerCase().trim();
    return s
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  // Regla de negocio:
  // - En `chats`, participants[0] es el solicitante (quien pidió el libro).
  // - "Bajo mi cuidado" = YO soy el solicitante (participants[0])
  //   y status indica préstamo activo (devolucion_pendiente / rentado).
  bool esBajoMiCuidado({
    required String uidActual,
    required List<dynamic> participants,
    required String status,
  }) {
    if (participants.isEmpty) return false;

    // participants[0] = solicitante (quien pidió el libro)
    final solicitanteId = participants.first.toString().trim();
    final statusNorm = normalizarStatus(status);

    // Bajo mi cuidado cuando YO soy el solicitante y el préstamo ya fue aprobado
    // (devolución pendiente / rentado).
    final esPrestamoActivo = statusNorm == 'devolucion_pendiente' || statusNorm == 'rentado';

    return solicitanteId == uidActual && esPrestamoActivo;
  }

  // Regla de negocio (vista Propietario):
  // - En `chats`, participants[1] es el propietario (dueño del libro).
  // - "Mis préstamos" = YO soy el propietario y el préstamo está activo
  //   (devolución pendiente / rentado).
  bool esMisPrestamos({
    required String uidActual,
    required List<dynamic> participants,
    required String status,
  }) {
    if (participants.length < 2) return false;

    final propietarioId = participants[1].toString().trim();
    final statusNorm = normalizarStatus(status);

    final esPrestamoActivo = statusNorm == 'devolucion_pendiente' || statusNorm == 'rentado';

    return propietarioId == uidActual && esPrestamoActivo;
  }

  // Regla complementaria (si la quieres):
  // "Reservados" = YO soy solicitante y status == pendiente.
  bool esReservaPendiente({
    required String uidActual,
    required List<dynamic> participants,
    required String status,
  }) {
    if (participants.isEmpty) return false;

    final solicitanteId = participants.first.toString().trim();
    final statusNorm = normalizarStatus(status);

    return solicitanteId == uidActual && statusNorm == 'pendiente';
  }

  //Limpia los datos del ViewModel para evitar datos viejos
  void _clearAll() {
    nombre = null;
    apellido = null;
    email = null;
    cedula = null;
    carrera = null;
    rol = null;
    avatarEmoji = null;
  }

  //Carga el perfil desde Firestore
  Future<void> cargarPerfil() async {

    isLoading = true;
    errorMessage = null;

    //Se limpian los datos antes de volver a cargarlos
    _clearAll();

    notifyListeners();

    try {

      final user = _authService.currentUser;

      //Si no hay sesión activa
      if (user == null) {
        errorMessage = "No hay sesión activa.";
        return;
      }

      //Correo viene desde Firebase Auth
      email = user.email;

      //Obtiene documento del usuario en Firestore
      final data = await _userService.getUserProfile(user.uid);

      //Si el documento no existe todavía
      if (data == null) {

        //Se usa un emoji por defecto
        avatarEmoji = "🙂";

        //Rol por defecto
        rol = "Estudiante";

        return;
      }

      //Mapeo de datos desde Firestore al ViewModel

      final n = data['nombre'];
      if (n is String && n.trim().isNotEmpty) {
        nombre = n.trim();
      }

      final a = data['apellido'];
      if (a is String && a.trim().isNotEmpty) {
        apellido = a.trim();
      }

      final e = data['email'];
      if (e is String && e.trim().isNotEmpty) {
        email = e.trim();
      }

      final c = data['cedula'];
      if (c is String && c.trim().isNotEmpty) {
        cedula = c.trim();
      }

      final ca = data['carrera'];
      if (ca is String && ca.trim().isNotEmpty) {
        carrera = ca.trim();
      }

      final r = data['rol'];
      if (r is String && r.trim().isNotEmpty) {
        rol = r.trim();
      }

      final em = data['avatarEmoji'];
      if (em is String && em.trim().isNotEmpty) {
        avatarEmoji = em.trim();
      }

      //Valores por defecto si Firestore no los tiene
      avatarEmoji ??= "🙂";

      //IMPORTANTE:
      //Si no hay rol guardado se asigna Estudiante,
      //pero si ya existe un rol (ej: Admin) se mantiene.
      rol ??= "Estudiante";

    } catch (_) {

      errorMessage = "Error cargando perfil";

    } finally {

      isLoading = false;

      notifyListeners();
    }
  }

  //Reglas de validación del formulario
  String? validarPerfil({
    required String nombre,
    required String apellido,
    required String cedula,
    required String carrera,
  }) {

    //Nombre y apellido obligatorios
    if (nombre.trim().isEmpty || apellido.trim().isEmpty) {
      return "❌ Por favor, completa nombre y apellido.";
    }

    //Cédula obligatoria
    if (cedula.trim().isEmpty) {
      return "❌ Por favor, ingresa la cédula.";
    }

    final ced = cedula.trim();

    //Solo números entre 6 y 10 dígitos
    if (!RegExp(r'^\d{6,10}$').hasMatch(ced)) {
      return "❌ La cédula debe contener solo números (6 a 10 dígitos).";
    }

    //Carrera obligatoria
    if (carrera.trim().isEmpty) {
      return "❌ Por favor, indica tu carrera.";
    }

    return null;
  }

  //Actualiza el perfil del usuario en Firestore
  Future<bool> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String cedula,
    required String carrera,
    String? avatarEmoji,
    String? rol,
  }) async {

    final user = _authService.currentUser;

    //Verifica que exista sesión
    if (user == null) {
      errorMessage = "No hay sesión activa.";
      notifyListeners();
      return false;
    }

    //Validación del formulario
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

      //Datos que se enviarán a Firestore
      final data = <String, dynamic>{
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'cedula': cedula.trim(),
        'carrera': carrera.trim(),
        'email': (email ?? user.email ?? '').trim(),
      };

      //Emoji opcional
      final em = (avatarEmoji ?? '').trim();

      if (em.isNotEmpty) {
        data['avatarEmoji'] = em;
      }

      //ARREGLO PRINCIPAL DEL BUG DEL ADMIN
      //Se conserva el rol actual del usuario para evitar que
      //Firestore lo sobrescriba o lo elimine al actualizar perfil.
      final rolActual = (this.rol ?? '').trim();

      if (rolActual.isNotEmpty) {
        data['rol'] = rolActual;
      }

      //Se guarda o actualiza el documento en Firestore
      await _userService.upsertUserProfile(
        uid: user.uid,
        data: data,
      );

      //Actualiza estado local del ViewModel
      this.nombre = nombre.trim();
      this.apellido = apellido.trim();
      this.cedula = cedula.trim();
      this.carrera = carrera.trim();

      if (em.isNotEmpty) {
        this.avatarEmoji = em;
      }

      if (rolActual.isNotEmpty) {
        this.rol = rolActual;
      }

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
