import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para las estaciones patrimoniales (como Poképaradas)
/// Cada estación representa un lugar histórico de Santiago
class Estacion {
  final String id; // ID único en Firestore
  final DocumentReference?
      insigniaID; // Referencia a documento en `insignias` (nullable)
  final String codigo; // Código para QR (ej: "PLAZA_ARMAS_001")
  final String
      codigoQR; // Código QR único generado (ej: "TR_ABC123_1640995200")
  final String nombre; // Nombre descriptivo (ej: "Plaza de Armas")
  final String descripcion; // Info histórica del lugar
  final double latitud; // Coordenadas GPS
  final double longitud; // Coordenadas GPS
  final DateTime fechaCreacion;
  final bool activa; // Si está disponible para visitar
  final List<Map<String, dynamic>>
      imagenes; // Imágenes asociadas al card/estación
  final String? comuna;

  const Estacion({
    required this.id,
    this.insigniaID,
    required this.codigo,
    required this.codigoQR,
    required this.nombre,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.fechaCreacion,
    this.activa = true,
    this.imagenes = const [],
    this.comuna,
  });

  /// Crear Estacion desde documento de Firestore
  factory Estacion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Estacion(
      id: doc.id,
      insigniaID: data['insigniaID'] as DocumentReference?,
      codigo: data['codigo'] ?? '',
      codigoQR: data['codigoQR'] ?? '',
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      latitud: (data['latitud'] ?? 0.0).toDouble(),
      longitud: (data['longitud'] ?? 0.0).toDouble(),
      fechaCreacion:
          (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activa: data['activa'] ?? true,
      imagenes: ((data['imagenes'] as List<dynamic>?) ?? [])
          .cast<Map<String, dynamic>>(),
      comuna: data['comuna'] as String?,
    );
  }

  /// Convertir a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'insigniaID': insigniaID,
      'codigo': codigo,
      'codigoQR': codigoQR,
      // Mantener claves modernas y legacy para compatibilidad con la UI
      'nombre': nombre,
      // legacy 'name' removed to avoid duplicate fields; UI reads 'nombre' and falls back to 'name' when needed
      'descripcion': descripcion,
      // legacy 'description' removed to avoid duplicate fields; UI should read 'descripcion' first
      // Card-related fields (use existing 'nombre' and 'descripcion' for main values)
      'comuna': comuna,
      'imagenes': imagenes,
      'latitud': latitud,
      'longitud': longitud,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'activa': activa,
    };
  }

  /// Crear copia con cambios
  Estacion copyWith({
    String? id,
    DocumentReference? insigniaID,
    String? codigo,
    String? codigoQR,
    String? nombre,
    String? descripcion,
    double? latitud,
    double? longitud,
    DateTime? fechaCreacion,
    bool? activa,
    List<Map<String, dynamic>>? imagenes,
    String? comuna,
  }) {
    return Estacion(
      id: id ?? this.id,
      insigniaID: insigniaID ?? this.insigniaID,
      codigo: codigo ?? this.codigo,
      codigoQR: codigoQR ?? this.codigoQR,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activa: activa ?? this.activa,
      imagenes: imagenes ?? this.imagenes,
      comuna: comuna ?? this.comuna,
    );
  }
}
