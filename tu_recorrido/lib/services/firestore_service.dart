import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // USERS
  Future<void> upsertUser({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // PLACES
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
    return _db.collection('places').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> deletePlace(String placeId) async {
    await _db.collection('places').doc(placeId).delete();
  }
}
