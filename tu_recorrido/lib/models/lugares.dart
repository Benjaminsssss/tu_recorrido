import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  // ⭐️ NUEVO: Método para actualizar el rating
  void updateRating(double newRating) {
    rating = newRating;
  }
}
