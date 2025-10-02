import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'lugares.dart';

/// Lista fija de lugares marcados manualmente
class MarcadoresData {
  static final List<PlaceResult> lugaresMarcados = [
    PlaceResult(
      placeId: 'm1',
      nombre: 'Plaza Central',
      ubicacion: const LatLng(-12.046374, -77.042793),
      rating: 4.5,
    ),
    PlaceResult(
      placeId: 'm2',
      nombre: 'Museo de la Ciudad',
      ubicacion: const LatLng(-12.0458, -77.0305),
      rating: 4.2,
    ),
    PlaceResult(
      placeId: 'm3',
      nombre: 'Parque Principal',
      ubicacion: const LatLng(-12.0502, -77.0452),
      rating: 4.0,
    ),
    PlaceResult(
      placeId: 'm4',
      nombre: 'Mirador',
      ubicacion: const LatLng(-12.0531, -77.0509),
      rating: 4.7,
    ),
    PlaceResult(
      placeId: 'm5',
      nombre: 'unimarc',
      ubicacion: const LatLng(-33.526812908174755, -70.59580173995262),
      rating: 4.3,
    ),
  ];
}