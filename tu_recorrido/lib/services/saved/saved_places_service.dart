import 'package:cloud_firestore/cloud_firestore.dart';

class SavedPlacesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guardar un lugar a favoritos del usuario
  static Future<void> savePlaceForUser(String userId, String placeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_places')
          .doc(placeId)
          .set({
        'placeId': placeId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al guardar lugar: $e');
    }
  }

  /// Eliminar un lugar de favoritos del usuario
  static Future<void> removePlaceForUser(String userId, String placeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_places')
          .doc(placeId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar lugar: $e');
    }
  }

  /// Verificar si un lugar está guardado
  static Future<bool> isPlaceSaved(String userId, String placeId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_places')
          .doc(placeId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Obtener todos los IDs de lugares guardados del usuario
  static Future<List<String>> getSavedPlaceIds(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_places')
          .orderBy('savedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream para escuchar cambios en lugares guardados
  static Stream<List<String>> getSavedPlacesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_places')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
}