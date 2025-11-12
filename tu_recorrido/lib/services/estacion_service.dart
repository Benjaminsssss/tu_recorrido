import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/estacion.dart';
import 'qr_service.dart';
import '../utils/app_logger.dart';

/// Servicio para manejar estaciones patrimoniales en Firestore
/// Permite crear, leer, actualizar y eliminar estaciones
class EstacionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
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

      // Validación mínima en cliente para evitar payloads inválidos
      if (estacion.codigo.trim().isEmpty) {
        throw Exception('El código de la estación no puede estar vacío');
      }

      // Generar código QR único si no se proporcionó
      String codigoQR = estacion.codigoQR;
      if (codigoQR.isEmpty) {
        codigoQR = QRService.generarCodigoQR(estacion.id, estacion.nombre);
      }

      // Crear nueva estación con código QR
      final estacionConQR = estacion.copyWith(codigoQR: codigoQR);

      // Preparar payload garantizando compatibilidad con consumidores (Home, UI)
      final Map<String, dynamic> base = Map.from(estacionConQR.toFirestore());

      // Normalizamos el payload: usamos server timestamps para fechas de creación
      // y añadimos campos por defecto para evitar rechazos por reglas estrictas.
      final Map<String, dynamic> payload = {};

      // Copiar solo keys esperadas para evitar enviar keys extra
      final allowed = [
        'insigniaID',
        'codigo',
        'codigoQR',
        'nombre',
        'descripcion',
        'comuna',
        'imagenes',
        'latitud',
        'longitud',
        'activa'
      ];

      for (final k in allowed) {
        if (base.containsKey(k)) payload[k] = base[k];
      }

      // Fechas: preferimos serverTimestamp para consistencia
      payload['fechaCreacion'] = FieldValue.serverTimestamp();
      // Legacy: mantener createdAt para compatibilidad con UI antigua
      payload['createdAt'] = FieldValue.serverTimestamp();

      // Duplicados legacy de coordenadas que consumen algunas vistas
      payload['lat'] = estacionConQR.latitud;
      payload['lng'] = estacionConQR.longitud;

      // Campos de rating por defecto
      payload['rating'] = 0;
      payload['totalRatings'] = 0;

      // updatedAt para marcar la operación inicial
      payload['updatedAt'] = FieldValue.serverTimestamp();

      // Guardar en Firestore
      final docRef = await _firestore.collection(_collection).add(payload);

      AppLogger.info('Estación creada: ${docRef.id} (codigo: ${estacion.codigo})');

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
      // Prefer 'fechaCreacion' but some older documents may use 'createdAt'.
      try {
        final query = await _firestore
            .collection(_collection)
            .where('activa', isEqualTo: true)
            .orderBy('fechaCreacion', descending: true)
            .get();

        return query.docs.map((doc) => Estacion.fromFirestore(doc)).toList();
      } catch (e) {
        // Fallback to createdAt if fechaCreacion is not available/indexed
        final query = await _firestore
            .collection(_collection)
            .where('activa', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        return query.docs.map((doc) => Estacion.fromFirestore(doc)).toList();
      }
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

  /// Establece el campo `badgeImage` del documento de estación con el objeto provisto.
  static Future<void> setBadgeImage(
      String id, Map<String, dynamic> image) async {
    try {
      await _firestore.collection(_collection).doc(id).set({
        'badgeImage': image,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al setear badgeImage: $e');
    }
  }

  /// Añade elementos al array `imagenes` de la estación.
  static Future<void> addEstacionImages(
      String id, List<Map<String, dynamic>> images) async {
    try {
      for (final img in images) {
        await _firestore.collection(_collection).doc(id).set({
          'imagenes': FieldValue.arrayUnion([img]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Error al agregar imagenes a estación: $e');
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

  /// Elimina permanentemente una estación y sus recursos relacionados.
  /// Intentará eliminar las imágenes referenciadas en `imagenes` y `badgeImage`
  /// en Storage (si las URLs son referencias de Firebase Storage). Si la
  /// eliminación de algún archivo falla, seguirá con la eliminación del
  /// documento para no dejar inconsistencias vistas desde la app.
  static Future<void> deleteEstacion(String id) async {
    try {
      final docRef = _firestore.collection(_collection).doc(id);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        // Borrar imágenes listadas en `imagenes` (si tienen 'url')
        final imgs = (data['imagenes'] as List<dynamic>?) ?? [];
        for (final imgRaw in imgs) {
          try {
            final img = imgRaw as Map<String, dynamic>;
            final url = img['url'] as String?;
            if (url != null && url.isNotEmpty) {
              final ref = _storage.refFromURL(url);
              await ref.delete();
            }
          } catch (e) {
            // No interrumpir si no podemos borrar un archivo.
          }
        }

        // Borrar badgeImage si existe
        try {
          final badge = data['badgeImage'] as Map<String, dynamic>?;
          final badgeUrl = badge?['url'] as String?;
          if (badgeUrl != null && badgeUrl.isNotEmpty) {
            final ref = _storage.refFromURL(badgeUrl);
            await ref.delete();
          }
        } catch (e) {
          // ignorar error de borrado de badge
        }
      }

      // Finalmente eliminar documento
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar estación: $e');
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
