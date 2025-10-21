import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'lugares.dart';

/// Lista fija de lugares marcados manualmente
class MarcadoresData {
  static final List<PlaceResult> lugaresMarcados = [
    PlaceResult(
      placeId: 'm1',
      nombre: 'Plaza Central',
      ubicacion: const LatLng(-12.046374, -77.042793),
      rating: null, // Sin calificación inicial
    ),
    PlaceResult(
      placeId: 'm2',
      nombre: 'Museo de la Ciudad',
      ubicacion: const LatLng(-12.0458, -77.0305),
      rating: null,
    ),
    PlaceResult(
      placeId: 'm3',
      nombre: 'Parque Principal',
      ubicacion: const LatLng(-33.53063323882751, -70.59392076249718),
      rating: null,
    ),
    PlaceResult(
      placeId: 'm4',
      nombre: 'Mirador',
      ubicacion: const LatLng(-12.0531, -77.0509),
      rating: null,
    ),
    PlaceResult(
      placeId: 'm5',
      nombre: 'prueba',
      ubicacion: const LatLng(-33.530445947468806, -70.59353367599),
      rating: null,
    ),
    PlaceResult(
      placeId: 'm6',
      nombre: 'Unimarc',
      ubicacion: const LatLng(-33.526810215671425, -70.59585476249745),
      rating: null,
    ),
  ];

  // ⭐️ NUEVO: Método para actualizar el rating de un lugar
  static void updatePlaceRating(String placeId, double rating) {
    try {
      final place = lugaresMarcados.firstWhere(
        (p) => p.placeId == placeId,
      );
      place.updateRating(rating);
    } catch (e) {
      print('❌ Error: Lugar con placeId "$placeId" no encontrado');
    }
  }
}
