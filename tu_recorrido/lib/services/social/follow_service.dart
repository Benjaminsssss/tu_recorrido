import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tu_recorrido/models/follow_relation.dart';
import 'package:tu_recorrido/models/user_profile.dart';

/// Servicio para gestionar el seguimiento de usuarios
class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene el ID del usuario actual
  String? get currentUserId => _auth.currentUser?.uid;

  /// Sigue a un usuario
  /// 
  /// Crea documentos en:
  /// - following/{currentUserId}/following/{targetUserId}
  /// - followers/{targetUserId}/followers/{currentUserId}
  /// 
  /// Incrementa contadores de followingCount y followersCount
  Future<void> followUser(String targetUserId) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    if (currentUserId == targetUserId) {
      throw Exception('No puedes seguirte a ti mismo');
    }

    try {
      // Obtener información del usuario actual
      final currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (!currentUserDoc.exists) {
        throw Exception('Usuario actual no encontrado');
      }

      final currentUserData = currentUserDoc.data()!;
      final currentUserName = currentUserData['displayName'] ?? 
                             currentUserData['nombre'] ?? 
                             currentUserData['email'] ?? 
                             'Usuario';
      final currentUserPhoto = currentUserData['photoURL'];

      // Obtener información del usuario objetivo
      final targetUserDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();
      
      if (!targetUserDoc.exists) {
        throw Exception('Usuario objetivo no encontrado');
      }

      final targetUserData = targetUserDoc.data()!;
      final targetUserName = targetUserData['displayName'] ?? 
                            targetUserData['nombre'] ?? 
                            targetUserData['email'] ?? 
                            'Usuario';
      final targetUserPhoto = targetUserData['photoURL'];

      final now = Timestamp.now();

      // Usar batch para operaciones atómicas
      final batch = _firestore.batch();

      // 1. Agregar a la lista de "following" del usuario actual
      // Escribimos en ambas ubicaciones para mantener compatibilidad:
      // - top-level: /following/{current}/following/{target}
      // - subcollection: /users/{current}/following/{target}
      // Solo subcolección bajo users/{current}/following/{target}
      final followingUsersRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

      final followingData = {
        'displayName': targetUserName,
        'photoURL': targetUserPhoto,
        'timestamp': now,
      };

      batch.set(followingUsersRef, followingData);

      // 2. Agregar a la lista de "followers" del usuario objetivo
      // 2. Agregar a la lista de "followers" del usuario objetivo (ambas ubicaciones)
      // Solo subcolección bajo users/{target}/followers/{current}
      final followersUsersRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

      final followerData = {
        'displayName': currentUserName,
        'photoURL': currentUserPhoto,
        'timestamp': now,
      };

      batch.set(followersUsersRef, followerData);

      // 3. Incrementar contador de "following" del usuario actual
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(1),
        'updatedAt': now,
      });

      // 4. Incrementar contador de "followers" del usuario objetivo
      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followersCount': FieldValue.increment(1),
        'updatedAt': now,
      });

      // Ejecutar todas las operaciones
      await batch.commit();
    } catch (e) {
      throw Exception('Error al seguir usuario: $e');
    }
  }

  /// Deja de seguir a un usuario
  /// 
  /// Elimina documentos de:
  /// - following/{currentUserId}/following/{targetUserId}
  /// - followers/{targetUserId}/followers/{currentUserId}
  /// 
  /// Decrementa contadores de followingCount y followersCount
  Future<void> unfollowUser(String targetUserId) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    if (currentUserId == targetUserId) {
      throw Exception('No puedes dejar de seguirte a ti mismo');
    }

    try {
      final now = Timestamp.now();

      // Usar batch para operaciones atómicas
      final batch = _firestore.batch();

      // 1. Eliminar de la lista de "following" del usuario actual
        final followingUsersRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId);

        batch.delete(followingUsersRef);

      // 2. Eliminar de la lista de "followers" del usuario objetivo
        final followersUsersRef = _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(currentUserId);

        batch.delete(followersUsersRef);

      // 3. Decrementar contador de "following" del usuario actual
      final currentUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(currentUserRef, {
        'followingCount': FieldValue.increment(-1),
        'updatedAt': now,
      });

      // 4. Decrementar contador de "followers" del usuario objetivo
      final targetUserRef = _firestore.collection('users').doc(targetUserId);
      batch.update(targetUserRef, {
        'followersCount': FieldValue.increment(-1),
        'updatedAt': now,
      });

      // Ejecutar todas las operaciones
      await batch.commit();
    } catch (e) {
      throw Exception('Error al dejar de seguir usuario: $e');
    }
  }

  /// Verifica si el usuario actual sigue a otro usuario
  Future<bool> isFollowing(String targetUserId) async {
    if (currentUserId == null) return false;
    if (currentUserId == targetUserId) return false;

    try {
      // Primero verificar subcolección dentro de users/
      final usersDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .doc(targetUserId)
          .get();
      return usersDoc.exists;
    } catch (e) {
      print('Error al verificar si sigue al usuario: $e');
      return false;
    }
  }

  /// Obtiene la lista de seguidores de un usuario
  /// 
  /// [userId] - ID del usuario (por defecto el usuario actual)
  /// [limit] - Número máximo de resultados
  /// [startAfter] - Documento para paginación
  Future<List<FollowRelation>> getFollowers({
    String? userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) {
      throw Exception('Usuario no especificado');
    }

    try {
      // Leer únicamente subcolección bajo users/{uid}/followers
      final usersRef = _firestore.collection('users').doc(targetUserId).collection('followers');
      Query query = usersRef.orderBy('timestamp', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => FollowRelation.fromFollowerDoc(targetUserId, doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener seguidores: $e');
    }
  }

  /// Obtiene la lista de usuarios seguidos por un usuario
  /// 
  /// [userId] - ID del usuario (por defecto el usuario actual)
  /// [limit] - Número máximo de resultados
  /// [startAfter] - Documento para paginación
  Future<List<FollowRelation>> getFollowing({
    String? userId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) {
      throw Exception('Usuario no especificado');
    }

    try {
      // Leer únicamente subcolección bajo users/{uid}/following
      final usersRef = _firestore.collection('users').doc(targetUserId).collection('following');
      Query query = usersRef.orderBy('timestamp', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => FollowRelation.fromFollowingDoc(targetUserId, doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios seguidos: $e');
    }
  }

  /// Obtiene el número de seguidores de un usuario
  Future<int> getFollowersCount(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;
      
      return (userDoc.data()?['followersCount'] ?? 0) as int;
    } catch (e) {
      print('Error al obtener contador de seguidores: $e');
      return 0;
    }
  }

  /// Obtiene el número de usuarios seguidos
  Future<int> getFollowingCount(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;
      
      return (userDoc.data()?['followingCount'] ?? 0) as int;
    } catch (e) {
      print('Error al obtener contador de seguidos: $e');
      return 0;
    }
  }

  /// Stream que escucha cambios en el estado de seguimiento de un usuario
  Stream<bool> followStatusStream(String targetUserId) {
    if (currentUserId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Stream de seguidores de un usuario
  Stream<List<FollowRelation>> followersStream({
    String? userId,
    int limit = 20,
  }) async* {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) {
      yield [];
      return;
    }

    final usersRef = _firestore.collection('users').doc(targetUserId).collection('followers');
    yield* usersRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
          .map((doc) => FollowRelation.fromFollowerDoc(targetUserId, doc))
          .toList());
  }

  /// Stream de usuarios seguidos
  Stream<List<FollowRelation>> followingStream({
    String? userId,
    int limit = 20,
  }) async* {
    final targetUserId = userId ?? currentUserId;
    if (targetUserId == null) {
      yield [];
      return;
    }

    final usersRef = _firestore.collection('users').doc(targetUserId).collection('following');
    yield* usersRef
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
          .map((doc) => FollowRelation.fromFollowingDoc(targetUserId, doc))
          .toList());
  }

  /// Obtiene usuarios sugeridos para seguir
  /// (Usuarios que no sigues actualmente)
  Future<List<UserProfile>> getSuggestedUsers({int limit = 10}) async {
    if (currentUserId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Obtener lista de usuarios que ya sigue
      final followingSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('following')
          .get();

      final followingIds = followingSnapshot.docs.map((doc) => doc.id).toSet();
      followingIds.add(currentUserId!); // Excluir al usuario actual

      // Obtener usuarios aleatorios (limitado por Firestore)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('activo', isEqualTo: true)
          .limit(limit * 3) // Obtener más para filtrar
          .get();

      // Filtrar usuarios que no sigue
      final suggestions = usersSnapshot.docs
          .where((doc) => !followingIds.contains(doc.id))
          .map((doc) => UserProfile.fromFirestore(doc))
          .take(limit)
          .toList();

      return suggestions;
    } catch (e) {
      throw Exception('Error al obtener sugerencias de usuarios: $e');
    }
  }
}