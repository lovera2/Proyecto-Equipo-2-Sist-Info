import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db;

  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const String coleccionUsuarios='usuarios';

  CollectionReference<Map<String,dynamic>> get _usersRef =>
      _db.collection(coleccionUsuarios);

  //Crea/Sobrescribe el perfil completo
  Future<void> createUserProfile({
    required String uid,
    required Map<String,dynamic> data,
  }) async {
    await _usersRef.doc(uid).set(data);
  }

  //Obtiene el perfil. Bull si no existe
  Future<Map<String,dynamic>?> getUserProfile(String uid) async {
    final snap=await _usersRef.doc(uid).get();
    if(!snap.exists) return null;
    return snap.data();
  }

  //Actualización de campos
  Future<void> updateUserProfile({
    required String uid,
    required Map<String,dynamic> data,
  }) async {
    await _usersRef.doc(uid).set(data,SetOptions(merge:true));
  }

  //Upsert explícito
  Future<void> upsertUserProfile({
    required String uid,
    required Map<String,dynamic> data,
  }) async {
    await _usersRef.doc(uid).set(data,SetOptions(merge:true));
  }

  //Eliminación de campos específicos 
  Future<void> deleteUserFields({
    required String uid,
    required List<String> fields,
  }) async {
    final Map<String,dynamic> updates={};
    for(final f in fields){
      updates[f]=FieldValue.delete();
    }
    await _usersRef.doc(uid).update(updates);
  }

  // Stream
  Stream<Map<String,dynamic>?> userProfileStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((snap){
      if(!snap.exists) return null;
      return snap.data();
    });
  }

  // Referencia al doc
  DocumentReference<Map<String,dynamic>> userDoc(String uid)=>_usersRef.doc(uid);

  // LÓGICA DE FAVORITOS (COLECCIÓN SEPARADA)
  // Marcar como favorito
  Future<void> addFavorite({required String uid, required String bookId}) async {
    final docId = '${uid}_$bookId'; // Truco: ID único combinando ambos
    await _db.collection('favoritos').doc(docId).set({
      'userId': uid,
      'bookId': bookId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Quitar de favoritos
  Future<void> removeFavorite({required String uid, required String bookId}) async {
    final docId = '${uid}_$bookId';
    await _db.collection('favoritos').doc(docId).delete();
  }

  // Escuchar en tiempo real si un libro es favorito (Para que el corazón cambie de color)
  Stream<bool> isFavoriteStream({required String uid, required String bookId}) {
    final docId = '${uid}_$bookId';
    return _db.collection('favoritos').doc(docId).snapshots().map((snap) {
      return snap.exists; // Retorna true si existe en favoritos, false si no
    });
  }

  //Obtener todos los IDs de los libros favoritos de un usuario
  Stream<List<String>> getUserFavoritesStream(String uid) {
    return _db.collection('favoritos')
        .where('userId', isEqualTo: uid) // Solo pedimos los del usuario
        .snapshots()
        .map((snapshot) {
      
      //pasamos los documentos a una lista de Dart
      final docs = snapshot.docs.toList();
      
      //ordenamos la lista localmente por la fecha 'createdAt' (el más reciente primero)
      docs.sort((a, b) {
        final timeA = a.data()['createdAt'] as Timestamp?;
        final timeB = b.data()['createdAt'] as Timestamp?;
        
        // Manejo por si acaso algún documento viejo no tiene fecha
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        
        return timeB.compareTo(timeA); // Compara para ordenar descendentemente
      });

      //devolvemos solo la lista de los IDs de los libros ordenada
      return docs.map((doc) => doc.data()['bookId'] as String).toList();
    });
  }
}