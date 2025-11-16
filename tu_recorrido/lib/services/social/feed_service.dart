import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tu_recorrido/models/feed_place_post.dart';

/// Servicio para gestionar el feed de actividad reciente de usuarios seguidos
class FeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene el feed de actividad de los usuarios que sigo
  /// Agrupa fotos por lugar visitado
  Stream<List<FeedPlacePost>> getFeedStream() async* {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      yield [];
      return;
    }

    // Stream de los usuarios que sigo
    await for (final followingSnapshot in _db
        .collection('following')
        .doc(currentUser.uid)
        .collection('following')
        .snapshots()) {
      
      if (followingSnapshot.docs.isEmpty) {
        yield [];
        continue;
      }

      // Lista de IDs de usuarios que sigo
      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toList();

      // Mapa para agrupar fotos por usuario+lugar
      final Map<String, FeedPlacePost> groupedPosts = {};

      for (final userId in followingIds) {
        try {
          // Obtener información del usuario
          final userDoc = await _db.collection('users').doc(userId).get();
          if (!userDoc.exists) continue;

          final userData = userDoc.data()!;
          final userName = userData['displayName'] ?? userData['nombre'] ?? 'Usuario';
          final userPhotoURL = userData['photoURL'];

          // Obtener estaciones visitadas del usuario para obtener ratings
          final estacionesVisitadasSnapshot = await _db
              .collection('users')
              .doc(userId)
              .collection('estaciones_visitadas')
              .get();

          final Map<String, double> ratingsMap = {};
          for (final doc in estacionesVisitadasSnapshot.docs) {
            final data = doc.data();
            final estacionId = data['estacionId'];
            final rating = data['rating']?.toDouble();
            if (estacionId != null && rating != null) {
              ratingsMap[estacionId] = rating;
            }
          }

          // Obtener fotos del álbum del usuario (últimas 20)
          final photosSnapshot = await _db
              .collection('users')
              .doc(userId)
              .collection('album_photos')
              .orderBy('uploadDate', descending: true)
              .limit(20)
              .get();

          for (final photoDoc in photosSnapshot.docs) {
            final photoData = photoDoc.data();
            final badgeId = photoData['badgeId'] ?? '';
            
            if (badgeId.isEmpty) continue;

            // Clave única para agrupar: userId + placeId
            final groupKey = '${userId}_$badgeId';

            // Si ya existe un post para este usuario+lugar, agregar foto
            if (groupedPosts.containsKey(groupKey)) {
              groupedPosts[groupKey]!.photos.add(PhotoInPost(
                photoId: photoDoc.id,
                photoUrl: photoData['imageUrl'] ?? '',
                description: photoData['description'],
                uploadDate: (photoData['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              ));
            } else {
              // Crear nuevo post para este usuario+lugar
              String placeName = 'Lugar';
              String? placeImageUrl;
              
              try {
                final estacionDoc = await _db.collection('estaciones').doc(badgeId).get();
                if (estacionDoc.exists) {
                  final estacionData = estacionDoc.data()!;
                  placeName = estacionData['nombre'] ?? 'Lugar';
                  
                  // Obtener primera imagen del lugar
                  final imagenes = estacionData['imagenes'] as List<dynamic>?;
                  if (imagenes != null && imagenes.isNotEmpty) {
                    placeImageUrl = imagenes[0]['url'];
                  }
                }
              } catch (e) {
                print('Error obteniendo info del lugar: $e');
              }

              groupedPosts[groupKey] = FeedPlacePost(
                userId: userId,
                userName: userName,
                userPhotoURL: userPhotoURL,
                placeId: badgeId,
                placeName: placeName,
                placeImageUrl: placeImageUrl,
                photos: [
                  PhotoInPost(
                    photoId: photoDoc.id,
                    photoUrl: photoData['imageUrl'] ?? '',
                    description: photoData['description'],
                    uploadDate: (photoData['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  ),
                ],
                rating: ratingsMap[badgeId],
                mostRecentUpload: (photoData['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }
          }
        } catch (e) {
          print('Error obteniendo fotos del usuario $userId: $e');
        }
      }

      // Convertir a lista y ordenar por fecha más reciente
      final feedList = groupedPosts.values.toList();
      feedList.sort((a, b) => b.mostRecentUpload.compareTo(a.mostRecentUpload));

      yield feedList.take(30).toList(); // Limitar a 30 posts de lugares
    }
  }

  /// Obtiene el conteo de usuarios que sigo
  Future<int> getFollowingCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    try {
      final snapshot = await _db
          .collection('following')
          .doc(currentUser.uid)
          .collection('following')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error obteniendo conteo de siguiendo: $e');
      return 0;
    }
  }
}