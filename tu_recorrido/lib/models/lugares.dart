import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  // ⭐️ NUEVO: Método para actualizar el rating
  void updateRating(double newRating) {
    rating = newRating;
  }

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
}