import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final usuariosSnap = await _firestore.collection('usuarios').get();

    final usuarios = await Future.wait(
      usuariosSnap.docs.map((doc) async {
        final data = doc.data();
        final uid = doc.id;

        final resultados = await Future.wait([
          _contarLibrosPublicados(uid),
          _tieneActividadActiva(uid),
        ]);

        final librosPublicados = resultados[0] as int;
        final tieneActividadActiva = resultados[1] as bool;

        return {
          'uid': uid,
          'nombre': (data['nombre'] ?? '').toString(),
          'apellido': (data['apellido'] ?? '').toString(),
          'email': (data['email'] ?? '').toString(),
          'cedula': (data['cedula'] ?? '').toString(),
          'carrera': (data['carrera'] ?? '').toString(),
          'username': (data['username'] ?? '').toString(),
          'status': (data['status'] ?? 'activo').toString(),
          'role': (data['role'] ?? data['rol'] ?? '').toString(),
          'avatarEmoji': (data['avatarEmoji'] ?? '🙂').toString(),
          'fechaRegistro': data['fechaRegistro'] ?? data['fecha_registro'],
          'librosPublicados': librosPublicados,
          'tieneActividadActiva': tieneActividadActiva,
        };
      }),
    );

    usuarios.sort((a, b) {
      final nombreA = '${a['nombre']} ${a['apellido']}'.trim().toLowerCase();
      final nombreB = '${b['nombre']} ${b['apellido']}'.trim().toLowerCase();
      return nombreA.compareTo(nombreB);
    });

    return usuarios;
  }

  Future<String?> suspenderUsuario(String uid) async {
    final tieneActividad = await _tieneActividadActiva(uid);

    if (tieneActividad) {
      return 'No se puede suspender esta cuenta porque el usuario tiene préstamos o solicitudes activas.';
    }

    await _firestore.collection('usuarios').doc(uid).update({
      'status': 'suspendido',
    });

    return 'Cuenta suspendida correctamente.';
  }

  Future<String?> reactivarUsuario(String uid) async {
    await _firestore.collection('usuarios').doc(uid).update({
      'status': 'activo',
    });

    return 'Cuenta reactivada correctamente.';
  }

  Future<String?> eliminarUsuario(String uid) async {
    final tieneActividad = await _tieneActividadActiva(uid);

    if (tieneActividad) {
      return 'No se puede eliminar esta cuenta porque el usuario tiene préstamos o solicitudes activas.';
    }

    await _eliminarMaterialesDelUsuario(uid);
    await _eliminarFavoritosDelUsuario(uid);
    await _firestore.collection('usuarios').doc(uid).delete();

    return 'Cuenta eliminada correctamente.';
  }

  Future<void> editarUsuario({
    required String uid,
    required String nombre,
    required String apellido,
    required String username,
    required String cedula,
    required String carrera,
  }) async {
    final usernameLimpio = username.trim().toLowerCase();
    final cedulaLimpia = cedula.trim();

    if (cedulaLimpia.isNotEmpty) {
      final qCedula = await _firestore
          .collection('usuarios')
          .where('cedula', isEqualTo: cedulaLimpia)
          .get();

      final existeOtraCedula = qCedula.docs.any((d) => d.id != uid);
      if (existeOtraCedula) {
        throw Exception('Esa cédula ya está registrada en el sistema.');
      }
    }

    final qUsername = await _firestore.collection('usuarios').get();
    final existeOtroUsername = qUsername.docs.any((d) {
      if (d.id == uid) return false;

      final data = d.data();
      final actual = (data['username'] ?? '').toString().trim().toLowerCase();
      final email = (data['email'] ?? '').toString().trim().toLowerCase();
      final fallback = email.contains('@') ? email.split('@').first.trim() : '';

      return actual == usernameLimpio || fallback == usernameLimpio;
    });

    if (existeOtroUsername) {
      throw Exception('Ese nombre de usuario ya está registrado en el sistema.');
    }

    await _firestore.collection('usuarios').doc(uid).update({
      'nombre': nombre.trim(),
      'apellido': apellido.trim(),
      'username': usernameLimpio,
      'cedula': cedulaLimpia,
      'carrera': carrera.trim(),
    });
  }

  Future<int> _contarLibrosPublicados(String uid) async {
    try {
      final porOwnerId = await _firestore
          .collection('materials')
          .where('ownerId', isEqualTo: uid)
          .get();

      if (porOwnerId.docs.isNotEmpty) {
        return porOwnerId.docs.length;
      }

      final porUserId = await _firestore
          .collection('materials')
          .where('userId', isEqualTo: uid)
          .get();

      return porUserId.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> _tieneActividadActiva(String uid) async {
    try {
      final chatsSnap = await _firestore
          .collection('chats')
          .where('participants', arrayContains: uid)
          .get();

      for (final doc in chatsSnap.docs) {
        final data = doc.data();
        final estado = _normalizarEstado((data['status'] ?? '').toString());

        if (_esEstadoActivo(estado)) {
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  bool _esEstadoActivo(String estado) {
    const estadosActivos = {
      'pendiente',
      'esperando_confirmacion',
      'rentado',
      'devolucion_pendiente',
    };

    return estadosActivos.contains(estado);
  }

  String _normalizarEstado(String raw) {
    return raw
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  Future<void> _eliminarMaterialesDelUsuario(String uid) async {
    final materialesPorOwner = await _firestore
        .collection('materials')
        .where('ownerId', isEqualTo: uid)
        .get();

    if (materialesPorOwner.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in materialesPorOwner.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return;
    }

    final materialesPorUser = await _firestore
        .collection('materials')
        .where('userId', isEqualTo: uid)
        .get();

    if (materialesPorUser.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in materialesPorUser.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _eliminarFavoritosDelUsuario(String uid) async {
    try {
      final favSnap = await _firestore
          .collection('favoritos')
          .where('userId', isEqualTo: uid)
          .get();

      if (favSnap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in favSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      // Si la colección no existe o no se usa, no bloqueamos la eliminación.
    }
  }
}