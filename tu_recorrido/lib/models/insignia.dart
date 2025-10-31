import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo mínimo para Insignia (solo campos obligatorios)
class Insignia {
  final String id;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final DateTime fechaCreacion;

  Insignia({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.fechaCreacion,
  });

  factory Insignia.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Insignia(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      imagenUrl: data['imagenUrl'] ?? '',
      fechaCreacion:
          (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'imagenUrl': imagenUrl,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }
}
