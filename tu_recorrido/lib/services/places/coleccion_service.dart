import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tu_recorrido/models/estacion.dart';
import 'package:tu_recorrido/models/estacion_visitada.dart';
import 'package:tu_recorrido/models/place.dart';

/// Servicio para manejar la colección de estaciones visitadas por el usuario
/// Ahora usa subcolecciones: users/{userId}/estaciones_visitadas/{estacionId}
/// Esto hace más eficiente el acceso a los datos por usuario
class ColeccionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';
  static const String _estacionesVisitadasSubcollection =
      'estaciones_visitadas';

  /// Obtener el ID del usuario actual
  static Future<String?> _obtenerUserId() async {
    // Exigir que exista un usuario autenticado en Firebase y NO anónimo.
    // Si no hay un usuario (o es anónimo), devolvemos null para que el caller
    // lance la excepción y la UI pida al usuario autenticarse.
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && firebaseUser.isAnonymous == false) {
        return firebaseUser.uid;
      }
      // No autenticado o usuario anónimo -> no permitimos continuar
      return null;
    } catch (e) {
      // En caso de error inesperado, no permitimos operaciones sin auth
      return null;
    }
  }

  /// Marca una estación como visitada por el usuario actual
  static Future<void> marcarComoVisitada(
    Estacion estacion, {
    double? latitudUsuario,
    double? longitudUsuario,
  }) async {
    final userId = await _obtenerUserId();
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Verifica si ya fue visitada
      final yaVisitada = await _yaFueVisitada(userId, estacion.id);
      if (yaVisitada) {
        throw Exception('Esta estación ya fue visitada anteriormente');
      }

      // Intentar obtener la imagen de la insignia desde el documento de la estación
      PlaceImage? badgeImage;
      try {
        final doc =
            await _firestore.collection('estaciones').doc(estacion.id).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data['badgeImage'] != null) {
            final badgeMap =
                Map<String, dynamic>.from(data['badgeImage'] as Map);
            badgeImage = PlaceImage.fromJson(badgeMap);
          }
        }
      } catch (_) {
        // ignorar si no puede leerse la imagen; la visita igual se guarda
      }

      // Crea un registro de visita
      final visita = EstacionVisitada(
        id: estacion.id, // Usamos el ID de la estación como ID del documento
        estacionId: estacion.id,
        estacionCodigo: estacion.codigo,
        estacionNombre: estacion.nombre,
        fechaVisita: DateTime.now(),
        latitudVisita: latitudUsuario,
        longitudVisita: longitudUsuario,
        badgeImage: badgeImage,
      );

      // Guarda en la subcolección del usuario
      final payload = visita.toFirestore();

      // Comprobar que el uid autenticado coincide con la ruta destino
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUid = currentUser?.uid;
      if (currentUid == null) {
        throw Exception('Usuario no autenticado en Firebase (currentUid == null)');
      }
      if (currentUid != userId) {
        // UID mismatch -> no intentamos escribir para otro usuario
        throw Exception('UID mismatch: FirebaseAuth uid=$currentUid does not match target userId=$userId. Escribe solamente en users/{yourUid}.');
      }

      try {
        await _firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection(_estacionesVisitadasSubcollection)
            .doc(estacion.id) // Usar el ID de la estación como ID del documento
            .set(payload);
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied') {
          throw Exception('Permission denied al escribir visita: ${fe.message}. Verifica reglas de Firestore y que el UID autenticado coincida con la ruta users/{uid}.');
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Error al marcar estación como visitada: $e');
    }
  }

  /// Obtiene todas las estaciones visitadas por el usuario especificado o el actual
  static Future<List<EstacionVisitada>> obtenerEstacionesVisitadas({String? userId}) async {
    final uid = userId ?? await _obtenerUserId();
    if (uid == null) {
      return [];
    }

    try {
      final query = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_estacionesVisitadasSubcollection)
          .orderBy('fechaVisita', descending: true)
          .get();

      return query.docs
          .map((doc) => EstacionVisitada.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener estaciones visitadas: $e');
    }
  }

  /// Observa en tiempo real las estaciones visitadas por el usuario especificado o el actual.
  /// Devuelve un Stream que emite la lista ordenada por fecha (desc).
  static Stream<List<EstacionVisitada>> watchEstacionesVisitadas({String? userId}) async* {
    final uid = userId ?? await _obtenerUserId();
    if (uid == null) {
      yield [];
      return;
    }

    final coll = _firestore
        .collection(_usersCollection)
        .doc(uid)
        .collection(_estacionesVisitadasSubcollection)
        .orderBy('fechaVisita', descending: true);

    yield* coll.snapshots().map((query) =>
        query.docs.map((doc) => EstacionVisitada.fromFirestore(doc)).toList());
  }

  /// Obtiene las estadísticas del progreso del usuario
  static Future<Map<String, int>> obtenerEstadisticas() async {
    final userId = await _obtenerUserId();
    if (userId == null) {
      return {'visitadas': 0, 'total': 0, 'porcentaje': 0};
    }

    try {
      // Cuenta las estaciones visitadas en la subcolección del usuario
      final visitadasQuery = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_estacionesVisitadasSubcollection)
          .get();

      // Cuenta el total de estaciones activas
      final totalQuery = await _firestore
          .collection('estaciones')
          .where('activa', isEqualTo: true)
          .get();

      final visitadas = visitadasQuery.docs.length;
      final total = totalQuery.docs.length;
      final porcentaje = total > 0 ? ((visitadas / total) * 100).round() : 0;

      return {'visitadas': visitadas, 'total': total, 'porcentaje': porcentaje};
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Verifica si una estación ya fue visitada por el usuario
  static Future<bool> yaFueVisitada(String estacionId) async {
    final userId = await _obtenerUserId();
    if (userId == null) return false;

    return await _yaFueVisitada(userId, estacionId);
  }

  /// Método para verificar visita - ahora más eficiente con subcolección
  static Future<bool> _yaFueVisitada(String userId, String estacionId) async {
    final doc = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_estacionesVisitadasSubcollection)
        .doc(estacionId) // Acceso directo al documento
        .get();

    return doc.exists;
  }

  /// FUNCIÓN TEMPORAL: Eliminar una visita específica (para testing)
  /// Esta función es solo para pruebas y debugging
  static Future<void> eliminarVisitaTemporal(String estacionId) async {
    final userId = await _obtenerUserId();
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
    await _firestore
      .collection(_usersCollection)
      .doc(userId)
      .collection(_estacionesVisitadasSubcollection)
      .doc(estacionId)
      .delete();
    } catch (e) {
      throw Exception('Error al eliminar visita: $e');
    }
  }

  /// Obtiene estaciones visitadas en un periodo especifico
  /// Y si no se pasan fechas, obtiene todas las visitas
  static Future<List<EstacionVisitada>> obtenerVisitasPorPeriodo({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final userId = await _obtenerUserId();
    if (userId == null) return [];

    try {
      Query query = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_estacionesVisitadasSubcollection);

      if (desde != null) {
        query = query.where(
          'fechaVisita',
          isGreaterThanOrEqualTo: Timestamp.fromDate(desde),
        );
      }

      if (hasta != null) {
        query = query.where(
          'fechaVisita',
          isLessThanOrEqualTo: Timestamp.fromDate(hasta),
        );
      }

      final result = await query.orderBy('fechaVisita', descending: true).get();

      return result.docs
          .map((doc) => EstacionVisitada.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener visitas por período: $e');
    }
  }

  /// Método auxiliar para obtener estadísticas de un usuario específico (útil para admin)
  static Future<Map<String, int>> obtenerEstadisticasDeUsuario(
      String userId) async {
    try {
      // Cuenta las estaciones visitadas en la subcolección del usuario
      final visitadasQuery = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_estacionesVisitadasSubcollection)
          .get();

      // Cuenta el total de estaciones activas
      final totalQuery = await _firestore
          .collection('estaciones')
          .where('activa', isEqualTo: true)
          .get();

      final visitadas = visitadasQuery.docs.length;
      final total = totalQuery.docs.length;
      final porcentaje = total > 0 ? ((visitadas / total) * 100).round() : 0;

      return {'visitadas': visitadas, 'total': total, 'porcentaje': porcentaje};
    } catch (e) {
      throw Exception('Error al obtener estadísticas del usuario: $e');
    }
  }
}