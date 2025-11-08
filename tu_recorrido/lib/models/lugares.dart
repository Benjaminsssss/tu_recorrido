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

  PlaceResult({
    required this.placeId,
    required this.nombre,
    required this.ubicacion,
    this.rating,
    this.esGenerado = false,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final geo = json['geometry']?['location'];
    return PlaceResult(
      placeId: json['place_id'] ?? '',
      nombre: json['name'] ?? 'Sin nombre',
      ubicacion: LatLng(
        (geo?['lat'] ?? 0).toDouble(),
        (geo?['lng'] ?? 0).toDouble(),
      ),
      rating:
          json['rating'] == null ? null : (json['rating'] as num).toDouble(),
      esGenerado: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'place_id': placeId,
        'name': nombre,
        'lat': ubicacion.latitude,
        'lng': ubicacion.longitude,
        'rating': rating,
        'esGenerado': esGenerado,
      };

  PlaceResult copyWith({
    String? placeId,
    String? nombre,
    LatLng? ubicacion,
    double? rating,
    bool? esGenerado,
  }) {
    return PlaceResult(
      placeId: placeId ?? this.placeId,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      rating: rating ?? this.rating,
      esGenerado: esGenerado ?? this.esGenerado,
    );
  }
}

/// Utilidades de lugares
class LugaresUtils {
  static const double _earthRadiusKm = 6371.0;

  static double _deg2rad(double d) => d * pi / 180;

  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) =>
      distanceKm(lat1, lon1, lat2, lon2) * 1000;

  static Future<List<PlaceResult>> fetchNearby({
    required LatLng centro,
    required int radiusMeters,
    required String type,
  }) async {
    const apiKey = String.fromEnvironment('GOOGLE_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      throw Exception('API KEY vacía');
    }
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${centro.latitude},${centro.longitude}'
      '&radius=$radiusMeters&type=$type&key=$apiKey',
    );
    final resp = await http.get(url);
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    final data = json.decode(resp.body);
    final status = data['status'];
    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Places: $status');
    }
    return (data['results'] as List)
        .map((r) => PlaceResult.fromJson(r))
        .toList();
  }

  static List<PlaceResult> filtrarYOrdenarPorDistancia({
    required List<PlaceResult> lugares,
    required double userLat,
    required double userLng,
    required double radioKm,
  }) {
    final filtrados = lugares.where((p) {
      final d = distanceKm(
        userLat,
        userLng,
        p.ubicacion.latitude,
        p.ubicacion.longitude,
      );
      return d <= radioKm;
    }).toList()
      ..sort((a, b) {
        final da = distanceKm(
          userLat,
          userLng,
          a.ubicacion.latitude,
          a.ubicacion.longitude,
        );
        final db = distanceKm(
          userLat,
          userLng,
          b.ubicacion.latitude,
          b.ubicacion.longitude,
        );
        return da.compareTo(db);
      });
    return filtrados;
  }

  static List<PlaceResult> generarSinteticos({
    required LatLng center,
    required int count,
    required double radioKm,
  }) {
    final List<PlaceResult> gen = [];
    final rnd = Random();
    final radiusMeters = radioKm * 1000;
    for (int i = 0; i < count; i++) {
      final r = sqrt(rnd.nextDouble()) * radiusMeters;
      final theta = rnd.nextDouble() * 2 * pi;
      final deltaLat = (r * cos(theta)) / 111320.0;
      final deltaLng =
          (r * sin(theta)) / (111320.0 * cos(center.latitude * pi / 180));
      final pos =
          LatLng(center.latitude + deltaLat, center.longitude + deltaLng);
      gen.add(
        PlaceResult(
          placeId: 'synthetic_$i',
          nombre: 'Lugar cercano ${i + 1}',
          ubicacion: pos,
          rating: null,
          esGenerado: true,
        ),
      );
    }
    return gen;
  }
}
