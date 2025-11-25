import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Modelo para un lugar (Google Places o generado)
class PlaceResult {
  final String placeId;
  final String nombre;
  final LatLng ubicacion;
  double? rating; // ⭐️ Cambiado a no-final para poder actualizar
  final bool esGenerado;
  final String? imageUrl; // url de la imagen principal
  final String? badgeImageUrl; // url del badge principal

  PlaceResult({
    required this.placeId,
    required this.nombre,
    required this.ubicacion,
    this.rating,
    this.esGenerado = false,
    this.imageUrl,
    this.badgeImageUrl,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final geo = json['geometry']?['location'];
    String? imageUrl;
    String? badgeImageUrl;
    if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      final img0 = (json['images'] as List)[0];
      if (img0 is Map && img0['url'] != null) {
        imageUrl = img0['url'] as String?;
      }
    }
    if (json['badgeImage'] != null && json['badgeImage'] is Map && json['badgeImage']['url'] != null) {
      badgeImageUrl = json['badgeImage']['url'] as String?;
    }

    return PlaceResult(
      placeId: json['place_id'] ?? json['id'] ?? '',
      nombre: json['name'] ?? json['nombre'] ?? 'Sin nombre',
      ubicacion: LatLng(
        (geo != null ? (geo['lat'] as num?)?.toDouble() : (json['lat'] as num?)?.toDouble()) ?? 0.0,
        (geo != null ? (geo['lng'] as num?)?.toDouble() : (json['lng'] as num?)?.toDouble()) ?? 0.0,
      ),
      rating: json['rating'] == null ? null : (json['rating'] as num).toDouble(),
      esGenerado: false,
      imageUrl: imageUrl,
      badgeImageUrl: badgeImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'nombre': nombre,
      'lat': ubicacion.latitude,
      'lng': ubicacion.longitude,
      'rating': rating,
      'esGenerado': esGenerado,
      'imageUrl': imageUrl,
      'badgeImageUrl': badgeImageUrl,
    };
  }

  PlaceResult copyWith({
    String? placeId,
    String? nombre,
    LatLng? ubicacion,
    double? rating,
    bool? esGenerado,
    String? imageUrl,
    String? badgeImageUrl,
  }) {
    return PlaceResult(
      placeId: placeId ?? this.placeId,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      rating: rating ?? this.rating,
      esGenerado: esGenerado ?? this.esGenerado,
      imageUrl: imageUrl ?? this.imageUrl,
      badgeImageUrl: badgeImageUrl ?? this.badgeImageUrl,
    );
  }
}