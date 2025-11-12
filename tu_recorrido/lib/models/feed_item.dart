import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de items que pueden aparecer en el feed social
enum FeedItemType {
  badgeObtained,  // Usuario obtuvo una insignia
  placeVisited,   // Usuario visitó un lugar
}

/// Item del feed social para el tab "Siguiendo"
class FeedItem {
  final String id;
  final FeedItemType type;
  final String userId;           // Usuario que realizó la acción
  final String userName;         // Nombre del usuario
  final String? userPhotoURL;    // Foto del usuario
  final DateTime timestamp;      // Cuándo sucedió
  
  // Datos específicos según el tipo
  final String? badgeId;         // Si type == badgeObtained
  final String? badgeName;       // Nombre de la insignia
  final String? badgeImageUrl;   // Imagen de la insignia
  
  final String? placeId;         // Si type == placeVisited
  final String? placeName;       // Nombre del lugar
  final String? placeImageUrl;   // Imagen del lugar
  final double? placeLatitude;   // Coordenadas del lugar
  final double? placeLongitude;

  FeedItem({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    this.userPhotoURL,
    required this.timestamp,
    this.badgeId,
    this.badgeName,
    this.badgeImageUrl,
    this.placeId,
    this.placeName,
    this.placeImageUrl,
    this.placeLatitude,
    this.placeLongitude,
  });

  /// Crea un FeedItem desde Firestore
  factory FeedItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convertir el tipo de string a enum
    FeedItemType itemType = FeedItemType.values.firstWhere(
      (e) => e.toString() == 'FeedItemType.${data['type']}',
      orElse: () => FeedItemType.placeVisited,
    );
    
    return FeedItem(
      id: doc.id,
      type: itemType,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuario',
      userPhotoURL: data['userPhotoURL'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      badgeId: data['badgeId'],
      badgeName: data['badgeName'],
      badgeImageUrl: data['badgeImageUrl'],
      placeId: data['placeId'],
      placeName: data['placeName'],
      placeImageUrl: data['placeImageUrl'],
      placeLatitude: data['placeLatitude']?.toDouble(),
      placeLongitude: data['placeLongitude']?.toDouble(),
    );
  }

  /// Convierte el FeedItem a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'userId': userId,
      'userName': userName,
      'userPhotoURL': userPhotoURL,
      'timestamp': Timestamp.fromDate(timestamp),
      if (badgeId != null) 'badgeId': badgeId,
      if (badgeName != null) 'badgeName': badgeName,
      if (badgeImageUrl != null) 'badgeImageUrl': badgeImageUrl,
      if (placeId != null) 'placeId': placeId,
      if (placeName != null) 'placeName': placeName,
      if (placeImageUrl != null) 'placeImageUrl': placeImageUrl,
      if (placeLatitude != null) 'placeLatitude': placeLatitude,
      if (placeLongitude != null) 'placeLongitude': placeLongitude,
    };
  }

  /// Factory para crear un FeedItem de tipo "insignia obtenida"
  factory FeedItem.badgeObtained({
    required String userId,
    required String userName,
    String? userPhotoURL,
    required String badgeId,
    required String badgeName,
    required String badgeImageUrl,
    required DateTime timestamp,
  }) {
    return FeedItem(
      id: '', // Se genera en Firestore
      type: FeedItemType.badgeObtained,
      userId: userId,
      userName: userName,
      userPhotoURL: userPhotoURL,
      timestamp: timestamp,
      badgeId: badgeId,
      badgeName: badgeName,
      badgeImageUrl: badgeImageUrl,
    );
  }

  /// Factory para crear un FeedItem de tipo "lugar visitado"
  factory FeedItem.placeVisited({
    required String userId,
    required String userName,
    String? userPhotoURL,
    required String placeId,
    required String placeName,
    String? placeImageUrl,
    double? placeLatitude,
    double? placeLongitude,
    required DateTime timestamp,
  }) {
    return FeedItem(
      id: '', // Se genera en Firestore
      type: FeedItemType.placeVisited,
      userId: userId,
      userName: userName,
      userPhotoURL: userPhotoURL,
      timestamp: timestamp,
      placeId: placeId,
      placeName: placeName,
      placeImageUrl: placeImageUrl,
      placeLatitude: placeLatitude,
      placeLongitude: placeLongitude,
    );
  }

  /// Obtiene un título descriptivo para mostrar en el feed
  String get title {
    switch (type) {
      case FeedItemType.badgeObtained:
        return '$userName obtuvo la insignia "$badgeName"';
      case FeedItemType.placeVisited:
        return '$userName visitó "$placeName"';
    }
  }

  /// Obtiene la imagen principal a mostrar
  String? get mainImageUrl {
    switch (type) {
      case FeedItemType.badgeObtained:
        return badgeImageUrl;
      case FeedItemType.placeVisited:
        return placeImageUrl;
    }
  }
}
