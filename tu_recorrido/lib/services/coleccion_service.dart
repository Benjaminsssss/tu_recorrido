import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/estacion.dart';
import '../models/estacion_visitada.dart';
import '../models/place.dart';
import 'auth_local_service.dart';

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
    // Intentar obtener usuario de Firebase
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.uid;
    }

    // Si no hay usuario de Firebase, verificar si hay uno local
    final localUser = await AuthLocalService.obtenerUsuarioActual();
    if (localUser != null) {
      return localUser['id'];
    }

    // Si no hay usuario local, inicializar uno por defecto para desarrollo
    await AuthLocalService.inicializarUsuarioPorDefecto();
    final nuevoUsuario = await AuthLocalService.obtenerUsuarioActual();
    return nuevoUsuario?['id'];
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
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_estacionesVisitadasSubcollection)
          .doc(estacion.id) // Usar el ID de la estación como ID del documento
          .set(visita.toFirestore());
    } catch (e) {
      throw Exception('Error al marcar estación como visitada: $e');
    }
  }

  /// Obtiene todas las estaciones visitadas por el usuario actual
  static Future<List<EstacionVisitada>> obtenerEstacionesVisitadas() async {
    final userId = await _obtenerUserId();
    if (userId == null) {
      return [];
    }

    try {
      final query = await _firestore
          .collection(_usersCollection)
          .doc(userId)
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

  /// Observa en tiempo real las estaciones visitadas por el usuario actual.
  /// Devuelve un Stream que emite la lista ordenada por fecha (desc).
  static Stream<List<EstacionVisitada>> watchEstacionesVisitadas() async* {
    final userId = await _obtenerUserId();
    if (userId == null) {
      yield [];
      return;
    }

    final coll = _firestore
        .collection(_usersCollection)
        .doc(userId)
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
