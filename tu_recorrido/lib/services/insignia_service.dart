import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:tu_recorrido/models/insignia.dart';

/// Servicio para CRUD básico de insignias y helper para subir imagen a Storage.
class InsigniaService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static final _collection = _firestore.collection('insignias');

  /// Crea una insignia subiendo la imagen a Storage y guardando el documento en Firestore.
  /// Nota: usa [File], por lo que en web no funcionará sin adaptar (usar bytes).
  /// Crea una insignia subiendo la imagen a Storage y guardando el documento en Firestore.
  /// Soporta plataformas web y mobile/desktop.
  /// - En mobile/desktop usa [imageFile] y `putFile`.
  /// - En web usa [imageBytes] y `putData`. [fileName] se usa para la extensión.
  static Future<Insignia> createInsigniaWithImage({
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
    required String nombre,
    required String descripcion,
  }) async {
    final docRef = _collection.doc();

    // Determinar storage ref y subir según plataforma/entrada
    String imageUrl;

    if (kIsWeb || imageBytes != null) {
      // Web path: necesitamos un nombre de archivo para la extensión
      final safeName = fileName ?? '${docRef.id}.png';
      final storageRef =
          _storage.ref().child('insignias/${docRef.id}_$safeName');

      final uploadTask =
          storageRef.putData(imageBytes ?? await imageFile!.readAsBytes());
      final snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
    } else {
      // Mobile/desktop: usar putFile
      if (imageFile == null) {
        throw Exception('imageFile is required for non-web upload');
      }
      final ext = imageFile.path.split('.').last;
      final storageRef = _storage.ref().child('insignias/${docRef.id}.$ext');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    final now = DateTime.now();

    final insigniaData = {
      'nombre': nombre,
      'descripcion': descripcion,
      'imagenUrl': imageUrl,
      'fechaCreacion': Timestamp.fromDate(now),
    };

    await docRef.set(insigniaData);

    return Insignia(
      id: docRef.id,
      nombre: nombre,
      descripcion: descripcion,
      imagenUrl: imageUrl,
      fechaCreacion: now,
    );
  }

  static Future<List<Insignia>> obtenerTodas() async {
    try {
      try {
        final snapshot =
            await _collection.orderBy('fechaCreacion', descending: true).get();
        debugPrint(
            'InsigniaService.obtenerTodas: fetched ${snapshot.docs.length} docs');
        return snapshot.docs.map((d) => Insignia.fromFirestore(d)).toList();
      } catch (e) {
        // fallback to createdAt
        final snapshot =
            await _collection.orderBy('createdAt', descending: true).get();
        debugPrint(
            'InsigniaService.obtenerTodas (fallback): fetched ${snapshot.docs.length} docs');
        return snapshot.docs.map((d) => Insignia.fromFirestore(d)).toList();
      }
    } catch (e, st) {
      // Log error para facilitar diagnóstico en runtime
      // ignore: avoid_print
      print('InsigniaService.obtenerTodas: error -> $e');
      // ignore: avoid_print
      print(st);
      rethrow;
    }
  }

  static Future<void> deleteInsignia(String id) async {
    final docRef = _collection.doc(id);
    // Primero obtener URL (si existe) para eliminar el archivo en Storage (no obligatorio)
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final imagenUrl = data['imagenUrl'] as String?;
      if (imagenUrl != null && imagenUrl.isNotEmpty) {
        try {
          // Intentamos derivar la referencia desde la URL — esto puede fallar para URL públicas
          final ref = _storage.refFromURL(imagenUrl);
          await ref.delete();
        } catch (e) {
          // Si falla, no detenemos la operación; la imagen puede quedar en storage.
        }
      }
    }

    await docRef.delete();
  }

  static Future<void> actualizarInsignia(
      String id, Map<String, dynamic> changes) async {
    await _collection.doc(id).update(changes);
  }

  /// Asigna una insignia a una estación (almacena DocumentReference en estaciones/{estacionId}.insigniaID)
  static Future<void> assignInsigniaToEstacion({
    required String insigniaId,
    required String estacionId,
  }) async {
    final estacionRef =
        FirebaseFirestore.instance.collection('estaciones').doc(estacionId);
    final insigniaRef = _collection.doc(insigniaId);

    // Obtener los datos de la insignia para copiar la imagen al badgeImage
    final insigniaDoc = await insigniaRef.get();
    if (!insigniaDoc.exists) {
      throw Exception('Insignia no encontrada');
    }

    final insigniaData = insigniaDoc.data() as Map<String, dynamic>;
    final imagenUrl = insigniaData['imagenUrl'] as String?;
    final nombre = insigniaData['nombre'] as String? ?? '';

    // Crear el objeto badgeImage con los datos de la insignia
    Map<String, dynamic>? badgeImage;
    if (imagenUrl != null && imagenUrl.isNotEmpty) {
      badgeImage = {
        'url': imagenUrl,
        'alt': nombre,
        // No tenemos el path de Storage, pero la url es suficiente para mostrar la imagen
      };
    }

    // Actualizar la estación con la referencia y la imagen de la insignia
    final updateData = <String, dynamic>{
      'insigniaID': insigniaRef,
    };

    if (badgeImage != null) {
      updateData['badgeImage'] = badgeImage;
    }

    await estacionRef.update(updateData);
  }

  /// Migrar todas las estaciones que tienen insignias asignadas pero no tienen badgeImage
  /// Esta función debe ejecutarse una vez para corregir datos existentes
  static Future<void> migrarInsigniasExistentes() async {
    try {
      // Obtener todas las estaciones
      final estacionesSnapshot =
          await FirebaseFirestore.instance.collection('estaciones').get();

      int actualizadas = 0;
      int errores = 0;

      for (final estacionDoc in estacionesSnapshot.docs) {
        try {
          final estacionData = estacionDoc.data();
          final insigniaRef = estacionData['insigniaID'] as DocumentReference?;
          final badgeImage = estacionData['badgeImage'];

          // Si tiene insignia asignada pero no tiene badgeImage
          if (insigniaRef != null && badgeImage == null) {
            // Obtener los datos de la insignia
            final insigniaDoc = await insigniaRef.get();
            if (insigniaDoc.exists) {
              final insigniaData = insigniaDoc.data() as Map<String, dynamic>;
              final imagenUrl = insigniaData['imagenUrl'] as String?;
              final nombre = insigniaData['nombre'] as String? ?? '';

              if (imagenUrl != null && imagenUrl.isNotEmpty) {
                // Actualizar la estación con el badgeImage
                await estacionDoc.reference.update({
                  'badgeImage': {
                    'url': imagenUrl,
                    'alt': nombre,
                  }
                });
                actualizadas++;
                print(
                    '✅ Estación ${estacionDoc.id} actualizada con badgeImage');
              }
            }
          }
        } catch (e) {
          errores++;
          print('❌ Error actualizando estación ${estacionDoc.id}: $e');
        }
      }

      print(
          '🎯 Migración completada: $actualizadas estaciones actualizadas, $errores errores');
    } catch (e) {
      print('💥 Error en migración: $e');
      rethrow;
    }
  }

  /// Otorga una insignia a un usuario: crea users/{userId}/insignias/{insigniaId}
  /// Guarda fechaObtenida y una referencia opcional a la estación que la generó.
  static Future<void> otorgarInsigniaAUsuario({
    required String userId,
    required String insigniaId,
    String? estacionId,
  }) async {
    final userInsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('insignias')
        .doc(insigniaId);

    final estacionRef = estacionId != null
        ? FirebaseFirestore.instance.collection('estaciones').doc(estacionId)
        : null;

    final data = {
      'fechaObtenida': Timestamp.fromDate(DateTime.now()),
      'estacionRef': estacionRef,
    };

    await userInsRef.set(data);
  }

  /// Comprueba si el usuario ya tiene la insignia (evitar duplicados)
  static Future<bool> usuarioTieneInsignia({
    required String userId,
    required String insigniaId,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('insignias')
        .doc(insigniaId)
        .get();

    return doc.exists;
  }
}
