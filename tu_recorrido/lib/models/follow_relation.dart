import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para la relación de seguimiento entre usuarios
class FollowRelation {
  final String followerId;    // UID del usuario que sigue
  final String followingId;   // UID del usuario seguido
  final String followerName;  // Nombre del seguidor (para mostrar)
  final String? followerPhoto; // Foto del seguidor
  final String followingName; // Nombre del seguido (para mostrar)
  final String? followingPhoto; // Foto del seguido
  final DateTime timestamp;   // Cuándo empezó a seguir

  FollowRelation({
    required this.followerId,
    required this.followingId,
    required this.followerName,
    this.followerPhoto,
    required this.followingName,
    this.followingPhoto,
    required this.timestamp,
  });

  /// Crea desde Firestore - para followers/{userId}/followers/{followerId}
  factory FollowRelation.fromFollowerDoc(String userId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FollowRelation(
      followerId: doc.id,
      followingId: userId,
      followerName: data['displayName'] ?? data['email'] ?? 'Usuario',
      followerPhoto: data['photoURL'],
      followingName: '', // No se necesita en este contexto
      followingPhoto: null,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Crea desde Firestore - para following/{userId}/following/{followingId}
  factory FollowRelation.fromFollowingDoc(String userId, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FollowRelation(
      followerId: userId,
      followingId: doc.id,
      followerName: '', // No se necesita en este contexto
      followerPhoto: null,
      followingName: data['displayName'] ?? data['email'] ?? 'Usuario',
      followingPhoto: data['photoURL'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convierte a Map para guardar en followers/{userId}/followers/{followerId}
  Map<String, dynamic> toFollowerMap() {
    return {
      'displayName': followerName,
      'photoURL': followerPhoto,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Convierte a Map para guardar en following/{userId}/following/{followingId}
  Map<String, dynamic> toFollowingMap() {
    return {
      'displayName': followingName,
      'photoURL': followingPhoto,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
