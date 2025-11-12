/// Modelo para agrupar fotos del feed por lugar
/// Un usuario puede subir múltiples fotos del mismo lugar
class FeedPlacePost {
  final String userId; // ID del usuario que visitó el lugar
  final String userName; // Nombre del usuario
  final String? userPhotoURL; // Foto de perfil del usuario
  
  final String placeId; // ID del lugar/insignia
  final String placeName; // Nombre del lugar
  final String? placeImageUrl; // Imagen principal del lugar
  
  final List<PhotoInPost> photos; // Lista de fotos subidas al álbum
  final double? rating; // Rating del lugar (1-5 estrellas)
  final DateTime mostRecentUpload; // Fecha de la foto más reciente

  FeedPlacePost({
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.placeId,
    required this.placeName,
    this.placeImageUrl,
    required this.photos,
    this.rating,
    required this.mostRecentUpload,
  });
}

/// Representa una foto dentro de un post de lugar
class PhotoInPost {
  final String photoId;
  final String photoUrl;
  final String? description;
  final DateTime uploadDate;

  PhotoInPost({
    required this.photoId,
    required this.photoUrl,
    this.description,
    required this.uploadDate,
  });
}
