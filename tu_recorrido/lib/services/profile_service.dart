import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  static final _db = FirebaseFirestore.instance;

  static Future<DocumentSnapshot<Map<String, dynamic>>?> getUserProfile(
      String uid) async {
    if (uid.isEmpty) return null;
    return _db.collection('users').doc(uid).get();
  }

  static Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    await _db.collection('users').doc(uid).set(
      {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Guarda la imagen de perfil como base64 en Firestore
  static Future<void> saveAvatarBase64(String uid, Uint8List bytes) async {
    if (uid.isEmpty) return;
    final base64String = base64Encode(bytes);
    await _db.collection('users').doc(uid).update({
      'photoBase64': base64String,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Obtiene la imagen de perfil en base64 desde Firestore
  static Future<String?> getAvatarBase64(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['photoBase64'] as String?;
  }
}
