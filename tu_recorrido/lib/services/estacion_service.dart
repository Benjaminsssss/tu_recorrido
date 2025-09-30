import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/estacion.dart';

/// Servicio para manejar estaciones patrimoniales en Firestore
/// Permite crear, leer, actualizar y eliminar estaciones
class EstacionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'estaciones';

  /// Crear una nueva estación
  static Future<String> crearEstacion(Estacion estacion) async {
    try {
      // Verificar que el código no exista
      final existe = await _existeCodigo(estacion.codigo);
      if (existe) {
        throw Exception('Ya existe una estación con el código: ${estacion.codigo}');
      }

      // Guardar en Firestore
      final docRef = await _firestore
          .collection(_collection)
          .add(estacion.toFirestore());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear estación: $e');
    }
  }

  /// Obtener estación por código QR
  static Future<Estacion?> obtenerPorCodigo(String codigo) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('codigo', isEqualTo: codigo)
          .where('activa', isEqualTo: true)
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

  /// Obtener todas las estaciones activas
  static Future<List<Estacion>> obtenerEstacionesActivas() async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('activa', isEqualTo: true)
          .orderBy('fechaCreacion', descending: true)
          .get();

      return query.docs
          .map((doc) => Estacion.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener estaciones: $e');
    }
  }

  /// Actualizar estación
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

  /// Desactivar estación (no la elimina, solo la oculta)
  static Future<void> desactivarEstacion(String id) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update({'activa': false});
    } catch (e) {
      throw Exception('Error al desactivar estación: $e');
    }
  }

  /// Verificar si existe un código
  static Future<bool> _existeCodigo(String codigo) async {
    final query = await _firestore
        .collection(_collection)
        .where('codigo', isEqualTo: codigo)
        .limit(1)
        .get();
    
    return query.docs.isNotEmpty;
  }

  /// Generar código único para nueva estación
  static String generarCodigo(String nombre) {
    // Convertir nombre a código (ej: "Plaza de Armas" -> "PLAZA_ARMAS")
    final codigoBase = nombre
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    
    // Agregar timestamp para unicidad
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    
    return '${codigoBase}_$timestamp';
  }
}