import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar una foto de experiencia del álbum del usuario
class AlbumPhoto {
  final String id;
  final String badgeId; // ID de la insignia asociada
  final String imageUrl; // URL de Firebase Storage
  final String? thumbnailUrl; // URL de miniatura (opcional)
  final String? description; // Descripción/experiencia del usuario
  final DateTime uploadDate;
  final String? location; // "lat,lng" opcional
  final Map<String, dynamic>? metadata; // Datos adicionales

  AlbumPhoto({
    required this.id,
    required this.badgeId,
    required this.imageUrl,
    this.thumbnailUrl,
    this.description,
    required this.uploadDate,
    this.location,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'badgeId': badgeId,
    'imageUrl': imageUrl,
    'thumbnailUrl': thumbnailUrl,
    'description': description,
    'uploadDate': Timestamp.fromDate(uploadDate),
    'location': location,
    'metadata': metadata,
  };

  static AlbumPhoto fromJson(Map<String, dynamic> json) => AlbumPhoto(
    id: json['id'] ?? '',
    badgeId: json['badgeId'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    thumbnailUrl: json['thumbnailUrl'],
    description: json['description'],
    uploadDate: (json['uploadDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    location: json['location'],
    metadata: json['metadata'],
  );

  AlbumPhoto copyWith({
    String? id,
    String? badgeId,
    String? imageUrl,
    String? thumbnailUrl,
    String? description,
    DateTime? uploadDate,
    String? location,
    Map<String, dynamic>? metadata,
  }) {
    return AlbumPhoto(
      id: id ?? this.id,
      badgeId: badgeId ?? this.badgeId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      uploadDate: uploadDate ?? this.uploadDate,
      location: location ?? this.location,
      metadata: metadata ?? this.metadata,
    );
  }
}