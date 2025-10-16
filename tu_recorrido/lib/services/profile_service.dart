import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<DocumentSnapshot<Map<String, dynamic>>?> getUserProfile(String uid) async {
    if (uid.isEmpty) return null;
    return _db.collection('users').doc(uid).get();
  }

  static Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    await _db.collection('users').doc(uid).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<String> uploadAvatar(String uid, Uint8List bytes) async {
    final ref = _storage.ref().child('users').child(uid).child('avatar.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }
}
