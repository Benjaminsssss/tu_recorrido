import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para un post en el feed de actividad reciente
/// Representa una foto de álbum subida por un usuario seguido
class FeedPost {
  final String id;
  final String userId; // ID del usuario que subió la foto
  final String userName; // Nombre del usuario
  final String? userPhotoURL; // Foto de perfil del usuario
  
  final String photoId; // ID de la foto del álbum
  final String photoUrl; // URL de la foto
  final String? description; // Descripción/experiencia del usuario
  final DateTime uploadDate;
  
  final String badgeId; // ID de la insignia/lugar
  final String placeName; // Nombre del lugar
  final String? placeImageUrl; // Imagen del lugar (opcional)
  
  final double? rating; // Rating del lugar (1-5 estrellas)

  FeedPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.photoId,
    required this.photoUrl,
    this.description,
    required this.uploadDate,
    required this.badgeId,
    required this.placeName,
    this.placeImageUrl,
    this.rating,
  });

  /// Crea un FeedPost desde un documento de Firestore
  factory FeedPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FeedPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuario',
      userPhotoURL: data['userPhotoURL'],
      photoId: data['photoId'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      description: data['description'],
      uploadDate: (data['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      badgeId: data['badgeId'] ?? '',
      placeName: data['placeName'] ?? 'Lugar',
      placeImageUrl: data['placeImageUrl'],
      rating: data['rating']?.toDouble(),
    );
  }

  /// Convierte el FeedPost a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'photoId': photoId,
      'photoUrl': photoUrl,
      'description': description,
      'uploadDate': Timestamp.fromDate(uploadDate),
      'badgeId': badgeId,
      'placeName': placeName,
      'placeImageUrl': placeImageUrl,
      'rating': rating,
    };
  }
}
