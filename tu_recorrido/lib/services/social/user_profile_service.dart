import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tu_recorrido/models/user_profile.dart';
/// Servicio para gestionar perfiles públicos de usuarios
class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Obtiene el perfil público de un usuario
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }

      return UserProfile.fromFirestore(doc);
    } catch (e) {
      print('Error al obtener perfil de usuario: $e');
      return null;
    }
  }

  /// Stream del perfil de un usuario (actualizaciones en tiempo real)
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return UserProfile.fromFirestore(doc);
        });
  }

  /// Obtiene el perfil del usuario actual
  Future<UserProfile?> getCurrentUserProfile() async {
    if (currentUserId == null) return null;
    return getUserProfile(currentUserId!);
  }

  /// Stream del perfil del usuario actual
  Stream<UserProfile?> getCurrentUserProfileStream() {
    if (currentUserId == null) {
      return Stream.value(null);
    }
    return getUserProfileStream(currentUserId!);
  }

  /// Actualiza la configuración de privacidad del usuario actual
  Future<void> updatePrivacySettings({
    bool? isPublic,
    bool? showBadges,
    bool? showAlbum,
  }) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isPublic != null) updates['isPublic'] = isPublic;
      if (showBadges != null) updates['showBadges'] = showBadges;
      if (showAlbum != null) updates['showAlbum'] = showAlbum;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update(updates);
    } catch (e) {
      throw Exception('Error al actualizar configuración de privacidad: $e');
    }
  }

  /// Actualiza los contadores del perfil del usuario
  /// (Este método lo llamarás cuando el usuario obtenga insignias o visite lugares)
  Future<void> updateUserStats({
    String? userId,
    int? badgesCountDelta,
    int? placesVisitedCountDelta,
  }) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) {
      throw Exception('Usuario no especificado');
    }

    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (badgesCountDelta != null) {
        updates['badgesCount'] = FieldValue.increment(badgesCountDelta);
      }

      if (placesVisitedCountDelta != null) {
        updates['placesVisitedCount'] = FieldValue.increment(placesVisitedCountDelta);
      }

      await _firestore
          .collection('users')
          .doc(targetUserId)
          .update(updates);
    } catch (e) {
      print('Error al actualizar estadísticas de usuario: $e');
    }
  }

  /// Busca usuarios por nombre o email
  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase();

      // Buscar por displayName (case-insensitive es limitado en Firestore)
      // Esta es una búsqueda básica, para búsqueda avanzada considera usar Algolia
      final snapshot = await _firestore
          .collection('users')
          .where('activo', isEqualTo: true)
          .limit(100) // Obtener más para filtrar localmente
          .get();

      // Filtrar localmente
      final results = snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .where((profile) {
            final displayName = profile.displayNameOrEmail.toLowerCase();
            final nombre = profile.nombre?.toLowerCase() ?? '';
            final apodo = profile.apodo?.toLowerCase() ?? '';
            final email = profile.email.toLowerCase();
            
            return displayName.contains(queryLower) ||
                   nombre.contains(queryLower) ||
                   apodo.contains(queryLower) ||
                   email.contains(queryLower);
          })
          .take(limit)
          .toList();

      return results;
    } catch (e) {
      throw Exception('Error al buscar usuarios: $e');
    }
  }

  /// Obtiene las insignias de un usuario
  Future<List<Map<String, dynamic>>> getUserBadges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('insignias')
          .orderBy('fechaObtenida', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'fechaObtenida': data['fechaObtenida'],
          'estacionRef': data['estacionRef'],
        };
      }).toList();
    } catch (e) {
      print('Error al obtener insignias del usuario: $e');
      return [];
    }
  }

  /// Stream de insignias de un usuario
  Stream<List<Map<String, dynamic>>> getUserBadgesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('insignias')
        .orderBy('fechaObtenida', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'fechaObtenida': data['fechaObtenida'],
            'estacionRef': data['estacionRef'],
          };
        }).toList());
  }

  /// Obtiene el álbum de fotos de un usuario
  Future<List<Map<String, dynamic>>> getUserAlbumPhotos(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('album_photos')
          .orderBy('uploadDate', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error al obtener álbum del usuario: $e');
      return [];
    }
  }

  /// Stream del álbum de fotos de un usuario
  Stream<List<Map<String, dynamic>>> getUserAlbumPhotosStream(
    String userId, 
    {int limit = 20}
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('album_photos')
        .orderBy('uploadDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList());
  }

  /// Obtiene los lugares visitados por un usuario
  Future<List<Map<String, dynamic>>> getUserVisitedPlaces(
    String userId, 
    {int limit = 20}
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('estaciones_visitadas')
          .orderBy('fechaVisita', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error al obtener lugares visitados: $e');
      return [];
    }
  }

  /// Verifica si un usuario puede ver el perfil de otro usuario
  /// (basado en configuración de privacidad y si lo sigue)
  Future<bool> canViewProfile(String targetUserId) async {
    if (currentUserId == null) return false;
    if (currentUserId == targetUserId) return true; // Puede ver su propio perfil

    try {
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final isPublic = userData['isPublic'] ?? true;

      // Si el perfil es público, cualquiera puede verlo
      if (isPublic) return true;

      // Si es privado, verificar si lo sigue
      final followingDoc = await _firestore
          .collection('following')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();

      return followingDoc.exists;
    } catch (e) {
      print('Error al verificar permisos de visualización: $e');
      return false;
    }
  }

  /// Verifica si se pueden ver las insignias de un usuario
  Future<bool> canViewBadges(String targetUserId) async {
    if (currentUserId == null) return false;
    if (currentUserId == targetUserId) return true;

    try {
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final showBadges = userData['showBadges'] ?? true;
      
      if (!showBadges) return false;

      return await canViewProfile(targetUserId);
    } catch (e) {
      print('Error al verificar permisos de insignias: $e');
      return false;
    }
  }

  /// Verifica si se puede ver el álbum de un usuario
  Future<bool> canViewAlbum(String targetUserId) async {
    if (currentUserId == null) return false;
    if (currentUserId == targetUserId) return true;

    try {
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final showAlbum = userData['showAlbum'] ?? true;
      
      if (!showAlbum) return false;

      return await canViewProfile(targetUserId);
    } catch (e) {
      print('Error al verificar permisos de álbum: $e');
      return false;
    }
  }
}