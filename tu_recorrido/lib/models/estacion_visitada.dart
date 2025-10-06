import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para las estaciones patri visitadas
// simplemente es la coleccion de las estaciones visitadas
class EstacionVisitada {
  final String id; // ID del documento en Firestore
  final String userId; // ID del usuario que visitó
  final String estacionId; // ID de la estación visitada
  final String estacionCodigo; // Código de la estación
  final String estacionNombre; // Nombre de la estación
  final DateTime fechaVisita; // Cuándo fue visitada
  final double? latitudVisita; // Dónde estaba el usuario al visitarla
  final double? longitudVisita; // Coordenadas de la visita

  const EstacionVisitada({
    required this.id,
    required this.userId,
    required this.estacionId,
    required this.estacionCodigo,
    required this.estacionNombre,
    required this.fechaVisita,
    this.latitudVisita,
    this.longitudVisita,
  });

  /// Crear desde documento de Firestore
  factory EstacionVisitada.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EstacionVisitada(
      id: doc.id,
      userId: data['userId'] ?? '',
      estacionId: data['estacionId'] ?? '',
      estacionCodigo: data['estacionCodigo'] ?? '',
      estacionNombre: data['estacionNombre'] ?? '',
      fechaVisita:
          (data['fechaVisita'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitudVisita: data['latitudVisita']?.toDouble(),
      longitudVisita: data['longitudVisita']?.toDouble(),
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    final map = {
      'userId': userId,
      'estacionId': estacionId,
      'estacionCodigo': estacionCodigo,
      'estacionNombre': estacionNombre,
      'fechaVisita': Timestamp.fromDate(fechaVisita),
    };

    if (latitudVisita != null) {
      map['latitudVisita'] = latitudVisita!;
    }
    if (longitudVisita != null) {
      map['longitudVisita'] = longitudVisita!;
    }

    return map;
  }

  /// Crear copia con cambios
  EstacionVisitada copyWith({
    String? id,
    String? userId,
    String? estacionId,
    String? estacionCodigo,
    String? estacionNombre,
    DateTime? fechaVisita,
    double? latitudVisita,
    double? longitudVisita,
  }) {
    return EstacionVisitada(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      estacionId: estacionId ?? this.estacionId,
      estacionCodigo: estacionCodigo ?? this.estacionCodigo,
      estacionNombre: estacionNombre ?? this.estacionNombre,
      fechaVisita: fechaVisita ?? this.fechaVisita,
      latitudVisita: latitudVisita ?? this.latitudVisita,
      longitudVisita: longitudVisita ?? this.longitudVisita,
    );
  }
}
