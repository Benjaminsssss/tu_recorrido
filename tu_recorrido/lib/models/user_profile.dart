import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para el perfil público de un usuario
/// Este modelo se usa para mostrar información de otros usuarios
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? backgroundURL;
  final String? nombre;
  final String? apodo;
  final String? region;
  final String? comuna;
  final bool activo;
  
  // Estadísticas sociales
  final int followersCount;
  final int followingCount;
  final int badgesCount;
  final int placesVisitedCount;
  
  // Configuración de privacidad
  final bool isPublic;
  final bool showBadges;
  final bool showAlbum;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.backgroundURL,
    this.nombre,
    this.apodo,
    this.region,
    this.comuna,
    this.activo = true,
    this.followersCount = 0,
    this.followingCount = 0,
    this.badgesCount = 0,
    this.placesVisitedCount = 0,
    this.isPublic = true,
    this.showBadges = true,
    this.showAlbum = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea un UserProfile desde un documento de Firestore
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      backgroundURL: data['backgroundURL'],
      nombre: data['nombre'],
      apodo: data['apodo'],
      region: data['region'],
      comuna: data['comuna'],
      activo: data['activo'] ?? true,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      badgesCount: data['badgesCount'] ?? 0,
      placesVisitedCount: data['placesVisitedCount'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      showBadges: data['showBadges'] ?? true,
      showAlbum: data['showAlbum'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convierte el UserProfile a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'backgroundURL': backgroundURL,
      'nombre': nombre,
      'apodo': apodo,
      'region': region,
      'comuna': comuna,
      'activo': activo,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'badgesCount': badgesCount,
      'placesVisitedCount': placesVisitedCount,
      'isPublic': isPublic,
      'showBadges': showBadges,
      'showAlbum': showAlbum,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Obtiene el nombre a mostrar (prioridad: displayName > nombre > apodo > email)
  String get displayNameOrEmail {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (nombre != null && nombre!.isNotEmpty) return nombre!;
    if (apodo != null && apodo!.isNotEmpty) return apodo!;
    return email;
  }

  /// Obtiene la ubicación formateada
  String? get ubicacion {
    if (comuna != null && region != null) {
      return '$comuna, $region';
    } else if (comuna != null) {
      return comuna;
    } else if (region != null) {
      return region;
    }
    return null;
  }

  /// Copia el perfil con nuevos valores
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? backgroundURL,
    String? nombre,
    String? apodo,
    String? region,
    String? comuna,
    bool? activo,
    int? followersCount,
    int? followingCount,
    int? badgesCount,
    int? placesVisitedCount,
    bool? isPublic,
    bool? showBadges,
    bool? showAlbum,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      backgroundURL: backgroundURL ?? this.backgroundURL,
      nombre: nombre ?? this.nombre,
      apodo: apodo ?? this.apodo,
      region: region ?? this.region,
      comuna: comuna ?? this.comuna,
      activo: activo ?? this.activo,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      badgesCount: badgesCount ?? this.badgesCount,
      placesVisitedCount: placesVisitedCount ?? this.placesVisitedCount,
      isPublic: isPublic ?? this.isPublic,
      showBadges: showBadges ?? this.showBadges,
      showAlbum: showAlbum ?? this.showAlbum,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
