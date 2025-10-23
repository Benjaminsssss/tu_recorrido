import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/estacion.dart';
import 'qr_service.dart';
import '../utils/app_logger.dart';

/// Servicio para manejar estaciones patrimoniales en Firestore
/// Permite crear, leer, actualizar y eliminar estaciones
class EstacionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'estaciones';

  /// Crea una nueva estación con código QR único
  static Future<String> crearEstacion(Estacion estacion) async {
    try {
      // Verifica que el código no exista
      final existe = await _existeCodigo(estacion.codigo);
      if (existe) {
        throw Exception(
          'Ya existe una estación con el código: ${estacion.codigo}',
        );
      }

      // Generar código QR único si no se proporcionó
      String codigoQR = estacion.codigoQR;
      if (codigoQR.isEmpty) {
        codigoQR = QRService.generarCodigoQR(estacion.id, estacion.nombre);
      }

      // Crear nueva estación con código QR
      final estacionConQR = estacion.copyWith(codigoQR: codigoQR);

      // Guardar en Firestore
      final docRef = await _firestore
          .collection(_collection)
          .add(estacionConQR.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear estación: $e');
    }
  }

  /// Obtiene estación por código QR
  static Future<Estacion?> obtenerPorCodigoQR(String codigoQR) async {
    try {
      // Validar formato del código QR
      if (!QRService.esCodigoValido(codigoQR)) {
        return null;
      }

      // Optimizar consulta: usar índice compuesto (activa, codigoQR)
      final query = await _firestore
          .collection(_collection)
          .where('activa', isEqualTo: true)
          .where('codigoQR', isEqualTo: codigoQR)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return Estacion.fromFirestore(query.docs.first);
    } catch (e) {
      throw Exception('Error al buscar estación por QR: $e');
    }
  }

  /// Obtiene estación por código QR (método legacy - mantener compatibilidad)
  static Future<Estacion?> obtenerPorCodigo(String codigo) async {
    try {
      // Primero intentar buscar por código QR
      if (QRService.esCodigoValido(codigo)) {
        return await obtenerPorCodigoQR(codigo);
      }

      // Buscar por código legacy - optimizar orden de filtros
      final query = await _firestore
          .collection(_collection)
          .where('activa', isEqualTo: true)
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return Estacion.fromFirestore(query.docs.first);
    } catch (e) {
      throw Exception('Error al buscar estación: $e');
    }
  }

  /// Obtiene todas las estaciones activas
  static Future<List<Estacion>> obtenerEstacionesActivas() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('activa', isEqualTo: true)
          .orderBy('fechaCreacion', descending: true)
          .get();

      return query.docs.map((doc) => Estacion.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener estaciones: $e');
    }
  }

  /// Actualiza una estación
  static Future<void> actualizarEstacion(String id, Estacion estacion) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(estacion.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar estación: $e');
    }
  }

  /// Desactiva una estación (no la elimina, solo la oculta)
  static Future<void> desactivarEstacion(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'activa': false,
      });
    } catch (e) {
      throw Exception('Error al desactivar estación: $e');
    }
  }

  /// Verifica si existe un código
  static Future<bool> _existeCodigo(String codigo) async {
    final query = await _firestore
        .collection(_collection)
        .where('codigo', isEqualTo: codigo)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Genera un código único para nueva estación (ej: "Plaza de Armas" -> "PLAZA_ARMAS")
  static String generarCodigo(String nombre) {
    final codigoBase = nombre
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);

    return '${codigoBase}_$timestamp';
  }

  /// Genera código QR para estaciones existentes que no lo tengan
  static Future<void> generarQRParaEstacionesExistentes() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('activa', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      int contador = 0;

      for (final doc in query.docs) {
        final data = doc.data();
        final codigoQR = data['codigoQR'] as String?;

        // Si no tiene código QR, generar uno
        if (codigoQR == null || codigoQR.isEmpty) {
          final estacion = Estacion.fromFirestore(doc);
          final nuevoCodigoQR =
              QRService.generarCodigoQR(doc.id, estacion.nombre);

          batch.update(doc.reference, {'codigoQR': nuevoCodigoQR});
          contador++;
        }
      }

      if (contador > 0) {
        await batch.commit();
        AppLogger.info('Se generaron códigos QR para $contador estaciones');
      } else {
        AppLogger.info('ℹTodas las estaciones ya tienen código QR');
      }
    } catch (e) {
      throw Exception('Error al generar códigos QR: $e');
    }
  }
}
