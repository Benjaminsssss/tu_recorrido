// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================
  // USERS
  // =========================

  /// Crea o actualiza el doc del usuario en /users/{uid} con merge:true.
  /// - No pisa `createdAt` si el doc ya existe.
  /// - Siempre actualiza `updatedAt`.
  Future<void> upsertUser({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final DocumentReference<Map<String, dynamic>> docRef =
        _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(docRef);

      final Map<String, dynamic> payload = <String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final Map<String, dynamic>? current = snap.data();
      final bool needsCreatedAt =
          !snap.exists || current == null || !current.containsKey('createdAt');

      if (needsCreatedAt) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      tx.set(docRef, payload, SetOptions(merge: true));
    });
  }

  /// Actualiza campos puntuales del usuario (merge parcial, sin tocar createdAt).
  Future<void> updateUserPartial({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Devuelve el snapshot actual del usuario.
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  /// Observa cambios en el doc del usuario.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  /// ¿Existe el doc del usuario?
  Future<bool> userExists(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return snap.exists;
  }

  // =========================
  // PLACES
  // =========================

  Future<String> createPlace({
    required String name,
    required double lat,
    required double lng,
    String category = 'general',
  }) async {
    final ref = await _db.collection('places').add({
      'name': name,
      'lat': lat,
      'lng': lng,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPlaces() {
    return _db
        .collection('places')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deletePlace(String placeId) async {
    await _db.collection('places').doc(placeId).delete();
  }
}
