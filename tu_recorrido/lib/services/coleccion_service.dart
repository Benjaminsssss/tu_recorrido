import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/estacion.dart';
import '../models/estacion_visitada.dart';

/// Servicio para manejar la colección de estaciones visitadas por el usuario
/// Además permite marcar estaciones como visitadas y obtener el progreso del usuario
class ColeccionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'estaciones_visitadas';

  /// Marca una estación como visitada por el usuario actual
  static Future<void> marcarComoVisitada(
    Estacion estacion, {
    double? latitudUsuario,
    double? longitudUsuario,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Verifica si ya fue visitada
      final yaVisitada = await _yaFueVisitada(user.uid, estacion.id);
      if (yaVisitada) {
        throw Exception('Esta estación ya fue visitada anteriormente');
      }

      // Crea un registro de visita
      final visita = EstacionVisitada(
        id: '', // Se genera automáticamente
        userId: user.uid,
        estacionId: estacion.id,
        estacionCodigo: estacion.codigo,
        estacionNombre: estacion.nombre,
        fechaVisita: DateTime.now(),
        latitudVisita: latitudUsuario,
        longitudVisita: longitudUsuario,
      );

      await _firestore
          .collection(_collection)
          .add(visita.toFirestore());

    } catch (e) {
      throw Exception('Error al marcar estación como visitada: $e');
    }
  }

  /// Obtiene todas las estaciones visitadas por el usuario actual
  static Future<List<EstacionVisitada>> obtenerEstacionesVisitadas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    try {
      final query = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('fechaVisita', descending: true)
          .get();

      return query.docs
          .map((doc) => EstacionVisitada.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener estaciones visitadas: $e');
    }
  }

  /// Obtiene las estadísticas del progreso del usuario
  static Future<Map<String, int>> obtenerEstadisticas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'visitadas': 0, 'total': 0, 'porcentaje': 0};
    }

    try {
      // Cuenta las estaciones visitadas
      final visitadasQuery = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .get();

      // Cuenta el total de estaciones activas
      final totalQuery = await _firestore
          .collection('estaciones')
          .where('activa', isEqualTo: true)
          .get();

      final visitadas = visitadasQuery.docs.length;
      final total = totalQuery.docs.length;
      final porcentaje = total > 0 ? ((visitadas / total) * 100).round() : 0;

      return {
        'visitadas': visitadas,
        'total': total,
        'porcentaje': porcentaje,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Verifica si una estación ya fue visitada por el usuario
  static Future<bool> yaFueVisitada(String estacionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    return await _yaFueVisitada(user.uid, estacionId);
  }

  /// Método para verificar visita
  static Future<bool> _yaFueVisitada(String userId, String estacionId) async {
    final query = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('estacionId', isEqualTo: estacionId)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Obtiene estaciones visitadas en un periodo especifico
  /// Y si no se pasan fechas, obtiene todas las visitas
  static Future<List<EstacionVisitada>> obtenerVisitasPorPeriodo({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid);

      if (desde != null) {
        query = query.where('fechaVisita', isGreaterThanOrEqualTo: Timestamp.fromDate(desde));
      }

      if (hasta != null) {
        query = query.where('fechaVisita', isLessThanOrEqualTo: Timestamp.fromDate(hasta));
      }

      final result = await query
          .orderBy('fechaVisita', descending: true)
          .get();

      return result.docs
          .map((doc) => EstacionVisitada.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener visitas por período: $e');
    }
  }
}