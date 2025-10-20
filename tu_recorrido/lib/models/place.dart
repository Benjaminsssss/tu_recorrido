class PlaceBadge {
  final String nombre;
  final String tema; // "Historia"|"Arte"|"Naturaleza"|"Arquitectura"|"Cultura"

  const PlaceBadge({required this.nombre, required this.tema});
}

class PlaceImage {
  final String url;
  final String alt;
  final String? fuenteSugerida;

  const PlaceImage({required this.url, required this.alt, this.fuenteSugerida});
}

class Place {
  final String id;
  final String nombre;
  final String comuna;
  final String shortDesc;
  final String descripcion;
  final String mejorMomento;
  final PlaceBadge badge;
  final List<PlaceImage> imagenes;
  final double? lat;
  final double? lng;

  const Place({
    required this.id,
    required this.nombre,
    required this.comuna,
    required this.shortDesc,
    required this.descripcion,
    required this.mejorMomento,
    required this.badge,
    required this.imagenes,
    this.lat,
    this.lng,
  });
}
