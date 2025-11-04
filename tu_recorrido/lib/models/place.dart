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
  final String?
      path; // ruta en Firebase Storage (ej: 'estaciones/{placeId}/main_123.jpg')
  final String? base64;
  final String alt;
  final String? fuenteSugerida;

  PlaceImage(
      {this.url,
      this.path,
      this.base64,
      required this.alt,
      this.fuenteSugerida});

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
    // Support both legacy 'place' JSON and the newer 'estacion' document shape.
    final id = json['id'] as String? ?? json['id_estacion'] as String? ?? '';
    final nombre = (json['nombre'] ??
        json['name'] ??
        json['nombreEstacion'] ??
        '') as String;
    final region =
        json['region'] as String? ?? json['country'] as String? ?? 'Chile';
    final comuna = (json['comuna'] ?? json['city'] ?? '') as String;
    final shortDesc =
        (json['shortDesc'] ?? json['short_description'] ?? '') as String;
    final descripcion =
        (json['descripcion'] ?? json['description'] ?? '') as String;
    final mejorMomento =
        (json['mejorMomento'] ?? json['bestTime'] ?? 'Todo el año') as String;

    // imagenes may be a list of Map<String,dynamic> or legacy PlaceImage json
    final imagenesRaw = (json['imagenes'] as List<dynamic>?) ??
        (json['images'] as List<dynamic>?) ??
        [];
    final imagenes = imagenesRaw.map((e) {
      if (e is Map<String, dynamic>) return PlaceImage.fromJson(e);
      if (e is Map) return PlaceImage.fromJson(Map<String, dynamic>.from(e));
      return PlaceImage(url: null, path: null, base64: null, alt: '');
    }).toList();

    final badge =
        (json['badge'] != null && json['badge'] is Map<String, dynamic>)
            ? PlaceBadge.fromJson(json['badge'] as Map<String, dynamic>)
            : PlaceBadge(
                nombre: json['category']?.toString() ?? 'General',
                tema: json['tema']?.toString() ?? 'Cultura');

    final badgeImage = (json['badgeImage'] != null &&
            json['badgeImage'] is Map<String, dynamic>)
        ? PlaceImage.fromJson(json['badgeImage'] as Map<String, dynamic>)
        : null;

    final lat = (json['lat'] as num?)?.toDouble() ??
        (json['latitud'] as num?)?.toDouble() ??
        (json['latitude'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble() ??
        (json['longitud'] as num?)?.toDouble() ??
        (json['longitude'] as num?)?.toDouble();

    return Place(
      id: id,
      nombre: nombre,
      region: region,
      comuna: comuna,
      shortDesc: shortDesc,
      descripcion: descripcion,
      mejorMomento: mejorMomento,
      badge: badge,
      imagenes: imagenes,
      badgeImage: badgeImage,
      lat: lat,
      lng: lng,
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
