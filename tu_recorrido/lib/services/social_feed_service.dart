import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed_item.dart';

/// Servicio para gestionar el feed social de actividades
class SocialFeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Obtiene el feed social del usuario actual
  /// Muestra actividades de los usuarios que sigue
  Future<List<FeedItem>> getFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      Query query = _firestore
          .collection('feed')
          .doc(currentUserId)
          .collection('items')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => FeedItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener feed: $e');
    }
  }

  /// Stream del feed social (actualizaciones en tiempo real)
  Stream<List<FeedItem>> getFeedStream({int limit = 20}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('feed')
        .doc(currentUserId)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedItem.fromFirestore(doc))
            .toList());
  }

  /// Crea un item de feed cuando un usuario obtiene una insignia
  /// Este método distribuye el item a todos los seguidores
  Future<void> createBadgeFeedItem({
    required String badgeId,
    required String badgeName,
    required String badgeImageUrl,
  }) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Obtener información del usuario actual
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final userName = userData['displayName'] ?? 
                       userData['nombre'] ?? 
                       userData['email'] ?? 
                       'Usuario';
      final userPhotoURL = userData['photoURL'];

      // Crear el item del feed
      final feedItem = FeedItem.badgeObtained(
        userId: currentUserId!,
        userName: userName,
        userPhotoURL: userPhotoURL,
        badgeId: badgeId,
        badgeName: badgeName,
        badgeImageUrl: badgeImageUrl,
        timestamp: DateTime.now(),
      );

      // Obtener lista de seguidores
      final followersSnapshot = await _firestore
          .collection('followers')
          .doc(currentUserId)
          .collection('followers')
          .get();

      // Crear batch para operaciones masivas
      final batch = _firestore.batch();

      // Agregar el item al feed de cada seguidor
      for (final followerDoc in followersSnapshot.docs) {
        final feedRef = _firestore
            .collection('feed')
            .doc(followerDoc.id)
            .collection('items')
            .doc(); // Auto-generar ID

        batch.set(feedRef, feedItem.toMap());
      }

      // Ejecutar batch
      await batch.commit();
    } catch (e) {
      print('Error al crear item de insignia en feed: $e');
    }
  }

  /// Crea un item de feed cuando un usuario visita un lugar
  /// Este método distribuye el item a todos los seguidores
  Future<void> createPlaceVisitedFeedItem({
    required String placeId,
    required String placeName,
    String? placeImageUrl,
    double? placeLatitude,
    double? placeLongitude,
  }) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Obtener información del usuario actual
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final userName = userData['displayName'] ?? 
                       userData['nombre'] ?? 
                       userData['email'] ?? 
                       'Usuario';
      final userPhotoURL = userData['photoURL'];

      // Crear el item del feed
      final feedItem = FeedItem.placeVisited(
        userId: currentUserId!,
        userName: userName,
        userPhotoURL: userPhotoURL,
        placeId: placeId,
        placeName: placeName,
        placeImageUrl: placeImageUrl,
        placeLatitude: placeLatitude,
        placeLongitude: placeLongitude,
        timestamp: DateTime.now(),
      );

      // Obtener lista de seguidores
      final followersSnapshot = await _firestore
          .collection('followers')
          .doc(currentUserId)
          .collection('followers')
          .get();

      // Crear batch para operaciones masivas
      final batch = _firestore.batch();

      // Agregar el item al feed de cada seguidor
      for (final followerDoc in followersSnapshot.docs) {
        final feedRef = _firestore
            .collection('feed')
            .doc(followerDoc.id)
            .collection('items')
            .doc(); // Auto-generar ID

        batch.set(feedRef, feedItem.toMap());
      }

      // Ejecutar batch
      await batch.commit();
    } catch (e) {
      print('Error al crear item de lugar visitado en feed: $e');
    }
  }

  /// Elimina un item específico del feed
  Future<void> deleteFeedItem(String itemId) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      await _firestore
          .collection('feed')
          .doc(currentUserId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar item del feed: $e');
    }
  }

  /// Limpia todo el feed del usuario actual
  Future<void> clearFeed() async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final snapshot = await _firestore
          .collection('feed')
          .doc(currentUserId)
          .collection('items')
          .get();

      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error al limpiar feed: $e');
    }
  }

  /// Elimina items del feed más antiguos que una fecha específica
  Future<void> cleanOldFeedItems({int daysOld = 30}) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final snapshot = await _firestore
          .collection('feed')
          .doc(currentUserId)
          .collection('items')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error al limpiar items antiguos del feed: $e');
    }
  }

  /// Obtiene actividad reciente de usuarios seguidos
  /// (Alternativa para generar feed dinámicamente en lugar de pre-generarlo)
  Future<List<Map<String, dynamic>>> getFollowingActivity({
    int limit = 20,
  }) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Obtener lista de usuarios seguidos
      final followingSnapshot = await _firestore
          .collection('following')
          .doc(currentUserId)
          .collection('following')
          .get();

      if (followingSnapshot.docs.isEmpty) {
        return [];
      }

      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();
      final activities = <Map<String, dynamic>>[];

      // Por cada usuario seguido, obtener sus últimas insignias y lugares visitados
      // Nota: En producción, considera usar Cloud Functions para optimizar esto
      for (final userId in followingIds.take(10)) { // Limitar para no sobrecargar
        // Obtener usuario
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;
        final userName = userData['displayName'] ?? userData['email'] ?? 'Usuario';
        final userPhoto = userData['photoURL'];

        // Obtener últimas insignias
        final badgesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('insignias')
            .orderBy('fechaObtenida', descending: true)
            .limit(3)
            .get();

        for (final badgeDoc in badgesSnapshot.docs) {
          activities.add({
            'type': 'badge',
            'userId': userId,
            'userName': userName,
            'userPhoto': userPhoto,
            'badgeId': badgeDoc.id,
            'timestamp': badgeDoc.data()['fechaObtenida'],
          });
        }

        // Obtener últimos lugares visitados
        final placesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('estaciones_visitadas')
            .orderBy('fechaVisita', descending: true)
            .limit(3)
            .get();

        for (final placeDoc in placesSnapshot.docs) {
          final placeData = placeDoc.data();
          activities.add({
            'type': 'place',
            'userId': userId,
            'userName': userName,
            'userPhoto': userPhoto,
            'placeId': placeData['estacionId'],
            'placeName': placeData['estacionNombre'],
            'timestamp': placeData['fechaVisita'],
          });
        }
      }

      // Ordenar por timestamp y limitar
      activities.sort((a, b) {
        final aTime = (a['timestamp'] as Timestamp).toDate();
        final bTime = (b['timestamp'] as Timestamp).toDate();
        return bTime.compareTo(aTime);
      });

      return activities.take(limit).toList();
    } catch (e) {
      throw Exception('Error al obtener actividad de seguidos: $e');
    }
  }
}
