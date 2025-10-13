import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para las estaciones patrimoniales (como Poképaradas)
/// Cada estación representa un lugar histórico de Santiago
class Estacion {
  final String id; // ID único en Firestore
  final String codigo; // Código para QR (ej: "PLAZA_ARMAS_001")
  final String nombre; // Nombre descriptivo (ej: "Plaza de Armas")
  final String descripcion; // Info histórica del lugar
  final double latitud; // Coordenadas GPS
  final double longitud; // Coordenadas GPS
  final DateTime fechaCreacion;
  final bool activa; // Si está disponible para visitar

  const Estacion({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.fechaCreacion,
    this.activa = true,
  });

  /// Crear Estacion desde documento de Firestore
  factory Estacion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Estacion(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      latitud: (data['latitud'] ?? 0.0).toDouble(),
      longitud: (data['longitud'] ?? 0.0).toDouble(),
      fechaCreacion:
          (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      activa: data['activa'] ?? true,
    );
  }

  /// Convertir a Map para guardar en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'latitud': latitud,
      'longitud': longitud,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'activa': activa,
    };
  }

  /// Crear copia con cambios
  Estacion copyWith({
    String? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    double? latitud,
    double? longitud,
    DateTime? fechaCreacion,
    bool? activa,
  }) {
    return Estacion(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activa: activa ?? this.activa,
    );
  }
}
