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
  // ESTACIONES (antes "places")
  // =========================

  /// Crea un documento en la colección `estaciones` y devuelve su id.
  Future<String> createEstacion({
    required String nombre,
    required double lat,
    required double lng,
    String category = 'general',
    String? country,
    String? city,
  }) async {
    final ref = await _db.collection('estaciones').add({
      'nombre': nombre,
      'lat': lat,
      'lng': lng,
      'category': category,
      'country': country,
      'city': city,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchEstaciones() {
    return _db
        .collection('estaciones')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> deleteEstacion(String estacionId) async {
    await _db.collection('estaciones').doc(estacionId).delete();
  }

  /// Actualiza el campo `imageUrl` de un place.
  Future<void> updateEstacionImageUrl(
      {required String estacionId, required String imageUrl}) async {
    await _db.collection('estaciones').doc(estacionId).set({
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Actualiza campos parciales del place (merge)
  Future<void> updateEstacionPartial(
      {required String estacionId, required Map<String, dynamic> data}) async {
    await _db.collection('estaciones').doc(estacionId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Añade un objeto de imagen al array `imagenes` del place.
  /// El `image` debe ser un Map con al menos la clave `url` (p.ej. {'url': ..., 'alt': ...}).
  Future<void> addEstacionImage(
      {required String estacionId, required Map<String, dynamic> image}) async {
    await _db.collection('estaciones').doc(estacionId).set({
      'imagenes': FieldValue.arrayUnion([image]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Remueve un objeto de imagen del array `imagenes` del place.
  /// Es importante pasar la misma estructura que está guardada en Firestore para que `arrayRemove` funcione.
  Future<void> removeEstacionImage(
      {required String estacionId, required Map<String, dynamic> image}) async {
    await _db.collection('estaciones').doc(estacionId).update({
      'imagenes': FieldValue.arrayRemove([image]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reemplaza el array `imagenes` del place por la lista dada.
  Future<void> setEstacionImages(
      {required String estacionId,
      required List<Map<String, dynamic>> images}) async {
    await _db.collection('estaciones').doc(estacionId).set({
      'imagenes': images,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Devuelve la lista de imágenes almacenadas en el documento 'estaciones/{placeId}'.
  Future<List<Map<String, dynamic>>> getEstacionImages(
      String estacionId) async {
    final doc = await _db.collection('estaciones').doc(estacionId).get();
    final data = doc.data();
    if (data == null) return [];
    final imgs = (data['imagenes'] as List<dynamic>?) ?? [];
    return imgs.cast<Map<String, dynamic>>();
  }
}
