import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db;

  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  static const String coleccionUsuarios='usuarios';

  CollectionReference<Map<String,dynamic>> get _usersRef =>
      _db.collection(coleccionUsuarios);

  // Crea/Sobrescribe el perfil completo
  Future<void> createUserProfile({
    required String uid,
    required Map<String,dynamic> data,
  }) async {
    await _usersRef.doc(uid).set(data);
  }

  // Obtiene el perfil. Bull si no existe
  Future<Map<String,dynamic>?> getUserProfile(String uid) async {
    final snap=await _usersRef.doc(uid).get();
    if(!snap.exists) return null;
    return snap.data();
  }

  // Actualización de campos
  Future<void> updateUserProfile({
    required String uid,
    required Map<String,dynamic> data,
  }) async {
    await _usersRef.doc(uid).set(data,SetOptions(merge:true));
  }

  // Upsert explícito
  Future<void> upsertUserProfile({
    required String uid,
    required Map<String,dynamic> data,
  }) async {
    await _usersRef.doc(uid).set(data,SetOptions(merge:true));
  }

  // Elimina campos específicos
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
}