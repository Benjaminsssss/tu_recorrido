import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

class PlaceBadge {
  final String nombre;
  final String tema; // Historia|Arte|Naturaleza|Arquitectura|Cultura

  PlaceBadge({required this.nombre, required this.tema});

  factory PlaceBadge.fromJson(Map<String, dynamic> json) => PlaceBadge(
        nombre: json['nombre'] as String,
        tema: json['tema'] as String,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'tema': tema,
      };
}

class PlaceImage {
  final String? url;
  final String? path; // ruta en Firebase Storage (ej: 'estaciones/{placeId}/main_123.jpg')
  final String? base64;
  final String alt;
  final String? fuenteSugerida;
  
  PlaceImage({this.url, this.path, this.base64, required this.alt, this.fuenteSugerida});

  factory PlaceImage.fromJson(Map<String, dynamic> json) {
    return PlaceImage(
      url: json['url'] as String?,
      path: json['path'] as String?,
      base64: json['base64'] as String?,
      alt: (json['alt'] as String?) ?? '',
      fuenteSugerida: json['fuenteSugerida'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (url != null) 'url': url,
        if (path != null) 'path': path,
        if (base64 != null) 'base64': base64,
        'alt': alt,
        if (fuenteSugerida != null) 'fuenteSugerida': fuenteSugerida,
      };

  /// Devuelve un ImageProvider ya sea desde base64 o desde URL.
  ImageProvider imageProvider() {
    if (base64 != null && base64!.isNotEmpty) {
      try {
        final bytes = base64Decode(base64!);
        return MemoryImage(Uint8List.fromList(bytes));
      } catch (_) {}
    }
    if (url != null && url!.isNotEmpty) return NetworkImage(url!);
    return const AssetImage('assets/img/insiginia.png');
  }
}

class Place {
  final String id;
  final String nombre;
  final String region; // País/Región
  final String comuna; // Ciudad
  final String shortDesc;
  final String descripcion;
  final String mejorMomento;
  final PlaceBadge badge;
  final PlaceImage? badgeImage;
  final List<PlaceImage> imagenes;
  final double? lat;
  final double? lng;

  Place({
    required this.id,
    required this.nombre,
    required this.region,
    required this.comuna,
    required this.shortDesc,
    required this.descripcion,
    required this.mejorMomento,
    required this.badge,
    required this.imagenes,
    this.badgeImage,
    this.lat,
    this.lng,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      region: json['region'] as String? ?? 'Chile',
      comuna: json['comuna'] as String,
      shortDesc: json['shortDesc'] as String,
      descripcion: json['descripcion'] as String,
      mejorMomento: json['mejorMomento'] as String,
      badge: PlaceBadge.fromJson(json['badge'] as Map<String, dynamic>),
      imagenes: (json['imagenes'] as List<dynamic>)
          .map((e) => PlaceImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      badgeImage: json['badgeImage'] != null
          ? PlaceImage.fromJson(json['badgeImage'] as Map<String, dynamic>)
          : null,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'region': region,
        'comuna': comuna,
        'shortDesc': shortDesc,
        'descripcion': descripcion,
        'mejorMomento': mejorMomento,
        'badge': badge.toJson(),
        'imagenes': imagenes.map((i) => i.toJson()).toList(),
        if (badgeImage != null) 'badgeImage': badgeImage!.toJson(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
}
