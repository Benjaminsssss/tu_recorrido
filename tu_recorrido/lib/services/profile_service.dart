import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Obtiene el avatar del usuario en formato base64 desde Firestore
  static Future<String?> getAvatarBase64(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['avatarBase64'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting avatar: $e');
      return null;
    }
  }

  /// Guarda el avatar del usuario en Firebase Storage y Firestore
  static Future<void> saveAvatarBase64(String uid, Uint8List bytes) async {
    try {
      // Convertir a base64
      final base64String = base64Encode(bytes);

      // Guardar en Firestore
      await _firestore.collection('users').doc(uid).set({
        'avatarBase64': base64String,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Opcional: también subir a Storage para respaldo
      try {
        final ref = _storage.ref().child('avatars/$uid.jpg');
        await ref.putData(bytes);
      } catch (e) {
        debugPrint('Error uploading to Storage (non-critical): $e');
      }
    } catch (e) {
      debugPrint('Error saving avatar: $e');
      rethrow;
    }
  }

  /// Actualiza el perfil del usuario en Firestore
  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Obtiene los datos del perfil del usuario
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
}
