import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/album_photo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para diagnosticar y migrar fotos del álbum
class AlbumMigrationService {
  static const String _albumItemsKey = 'album_items';

  /// Diagnóstico completo del estado del álbum
  static Future<Map<String, dynamic>> diagnoseAlbum() async {
    final result = <String, dynamic>{};

    try {
      // 1. Verificar usuario actual
      final currentUser = FirebaseAuth.instance.currentUser;
      result['currentUser'] = {
        'exists': currentUser != null,
        'uid': currentUser?.uid,
        'isAnonymous': currentUser?.isAnonymous ?? false,
      };

      // 2. Verificar fotos en SharedPreferences (sistema anterior)
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString(_albumItemsKey);

      if (itemsJson != null) {
        try {
          final List<dynamic> itemsList = json.decode(itemsJson);
          final photoItems =
              itemsList.where((item) => item['type'] == 'photo').toList();

          result['sharedPrefsPhotos'] = {
            'count': photoItems.length,
            'items': photoItems
                .map((item) => {
                      'id': item['id'],
                      'title': item['title'],
                      'parentId': item['parentId'],
                      'imagePath': item['imagePath'],
                      'hasBase64': item['base64'] != null,
                      'date': item['date'],
                    })
                .toList(),
          };
        } catch (e) {
          result['sharedPrefsPhotos'] = {
            'error': 'Error parsing SharedPreferences: $e',
          };
        }
      } else {
        result['sharedPrefsPhotos'] = {
          'count': 0,
          'message': 'No hay datos en SharedPreferences',
        };
      }

      // 3. Verificar fotos en Firebase
      if (currentUser != null) {
        try {
          final firebasePhotos = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('album_photos')
              .get();

          result['firebasePhotos'] = {
            'count': firebasePhotos.docs.length,
            'items': firebasePhotos.docs
                .map((doc) => {
                      'id': doc.id,
                      'data': doc.data(),
                    })
                .toList(),
          };
        } catch (e) {
          result['firebasePhotos'] = {
            'error': 'Error accediendo a Firebase: $e',
          };
        }
      } else {
        result['firebasePhotos'] = {
          'error': 'No hay usuario autenticado',
        };
      }

      // 4. Verificar si hay fotos perdidas que necesitan migración
      final sharedPrefsCount =
          result['sharedPrefsPhotos']['count'] as int? ?? 0;
      final firebaseCount = result['firebasePhotos']['count'] as int? ?? 0;

      result['migrationNeeded'] = sharedPrefsCount > firebaseCount;
      result['migrationInfo'] = {
        'sharedPrefsPhotos': sharedPrefsCount,
        'firebasePhotos': firebaseCount,
        'difference': sharedPrefsCount - firebaseCount,
      };
    } catch (e) {
      result['generalError'] = e.toString();
    }

    return result;
  }

  /// Migrar fotos de SharedPreferences a Firebase
  static Future<Map<String, dynamic>> migratePhotosToFirebase() async {
    final result = <String, dynamic>{
      'migrated': 0,
      'errors': <String>[],
      'details': <Map<String, dynamic>>[],
    };

    try {
      // Verificar autenticación
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        result['error'] = 'No hay usuario autenticado';
        return result;
      }

      // Leer datos de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getString(_albumItemsKey);

      if (itemsJson == null) {
        result['error'] = 'No hay datos en SharedPreferences para migrar';
        return result;
      }

      final List<dynamic> itemsList = json.decode(itemsJson);
      final photoItems =
          itemsList.where((item) => item['type'] == 'photo').toList();

      if (photoItems.isEmpty) {
        result['error'] = 'No hay fotos en SharedPreferences para migrar';
        return result;
      }

      // Verificar qué fotos ya existen en Firebase
      final existingPhotos = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('album_photos')
          .get();

      final existingIds = existingPhotos.docs.map((doc) => doc.id).toSet();

      // Migrar cada foto que no esté ya en Firebase
      for (final item in photoItems) {
        final itemId = item['id'] as String;

        if (existingIds.contains(itemId)) {
          result['details'].add({
            'id': itemId,
            'action': 'skipped',
            'reason': 'Ya existe en Firebase',
          });
          continue;
        }

        try {
          // Crear documento AlbumPhoto desde los datos de SharedPreferences
          final albumPhoto = AlbumPhoto(
            id: itemId,
            badgeId: item['parentId'] ?? 'unknown',
            imageUrl: item['imagePath'] ?? '', // Nota: puede ser base64 o URL
            description: item['description'],
            uploadDate: item['date'] != null
                ? DateTime.tryParse(item['date']) ?? DateTime.now()
                : DateTime.now(),
            location: item['location'],
            metadata: {
              'migratedFromSharedPrefs': true,
              'originalData': item,
              'migrationDate': DateTime.now().toIso8601String(),
            },
          );

          // Guardar en Firebase
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .collection('album_photos')
              .doc(itemId)
              .set(albumPhoto.toJson());

          result['migrated']++;
          result['details'].add({
            'id': itemId,
            'action': 'migrated',
            'badgeId': albumPhoto.badgeId,
          });
        } catch (e) {
          result['errors'].add('Error migrando $itemId: $e');
          result['details'].add({
            'id': itemId,
            'action': 'error',
            'error': e.toString(),
          });
        }
      }
    } catch (e) {
      result['error'] = 'Error general durante la migración: $e';
    }

    return result;
  }

  /// Formatear resultado del diagnóstico
  static String formatDiagnosis(Map<String, dynamic> diagnosis) {
    final buffer = StringBuffer();
    buffer.writeln('=== DIAGNÓSTICO DEL ÁLBUM ===\n');

    // Usuario actual
    final currentUser = diagnosis['currentUser'] as Map<String, dynamic>?;
    if (currentUser != null) {
      buffer.writeln('👤 Usuario actual:');
      buffer.writeln('  - Existe: ${currentUser['exists']}');
      if (currentUser['exists'] == true) {
        buffer.writeln('  - UID: ${currentUser['uid']}');
        buffer.writeln('  - Es anónimo: ${currentUser['isAnonymous']}');
      }
      buffer.writeln();
    }

    // Fotos en SharedPreferences
    final sharedPrefsPhotos =
        diagnosis['sharedPrefsPhotos'] as Map<String, dynamic>?;
    if (sharedPrefsPhotos != null) {
      buffer.writeln('💾 Fotos en SharedPreferences:');
      if (sharedPrefsPhotos.containsKey('error')) {
        buffer.writeln('  - Error: ${sharedPrefsPhotos['error']}');
      } else {
        buffer.writeln('  - Cantidad: ${sharedPrefsPhotos['count']}');
        if (sharedPrefsPhotos['count'] > 0) {
          buffer.writeln('  - Fotos encontradas:');
          final items = sharedPrefsPhotos['items'] as List<dynamic>? ?? [];
          for (final item in items.take(5)) {
            // Mostrar solo las primeras 5
            buffer.writeln(
                '    • ${item['id']} (${item['parentId']}) - ${item['title']}');
          }
          if (items.length > 5) {
            buffer.writeln('    • ... y ${items.length - 5} más');
          }
        }
      }
      buffer.writeln();
    }

    // Fotos en Firebase
    final firebasePhotos = diagnosis['firebasePhotos'] as Map<String, dynamic>?;
    if (firebasePhotos != null) {
      buffer.writeln('🔥 Fotos en Firebase:');
      if (firebasePhotos.containsKey('error')) {
        buffer.writeln('  - Error: ${firebasePhotos['error']}');
      } else {
        buffer.writeln('  - Cantidad: ${firebasePhotos['count']}');
        if (firebasePhotos['count'] > 0) {
          buffer.writeln('  - Fotos encontradas:');
          final items = firebasePhotos['items'] as List<dynamic>? ?? [];
          for (final item in items.take(5)) {
            // Mostrar solo las primeras 5
            final data = item['data'] as Map<String, dynamic>? ?? {};
            buffer.writeln(
                '    • ${item['id']} (${data['badgeId']}) - ${data['description'] ?? 'Sin descripción'}');
          }
          if (items.length > 5) {
            buffer.writeln('    • ... y ${items.length - 5} más');
          }
        }
      }
      buffer.writeln();
    }

    // Información de migración
    final migrationNeeded = diagnosis['migrationNeeded'] as bool? ?? false;
    final migrationInfo = diagnosis['migrationInfo'] as Map<String, dynamic>?;
    if (migrationInfo != null) {
      buffer.writeln('🔄 Estado de migración:');
      buffer
          .writeln('  - Migración necesaria: ${migrationNeeded ? 'SÍ' : 'NO'}');
      buffer.writeln(
          '  - SharedPrefs: ${migrationInfo['sharedPrefsPhotos']} fotos');
      buffer.writeln('  - Firebase: ${migrationInfo['firebasePhotos']} fotos');
      buffer.writeln('  - Diferencia: ${migrationInfo['difference']} fotos');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Formatear resultado de migración
  static String formatMigrationResult(Map<String, dynamic> result) {
    final buffer = StringBuffer();
    buffer.writeln('=== RESULTADO DE MIGRACIÓN ===\n');

    if (result.containsKey('error')) {
      buffer.writeln('❌ Error: ${result['error']}');
      return buffer.toString();
    }

    buffer.writeln('✅ Fotos migradas: ${result['migrated']}');
    buffer.writeln('❌ Errores: ${(result['errors'] as List).length}');

    final errors = result['errors'] as List<String>;
    if (errors.isNotEmpty) {
      buffer.writeln('\nErrores encontrados:');
      for (final error in errors) {
        buffer.writeln('  • $error');
      }
    }

    final details = result['details'] as List<Map<String, dynamic>>;
    if (details.isNotEmpty) {
      buffer.writeln('\nDetalles:');
      for (final detail in details) {
        final action = detail['action'];
        final id = detail['id'];
        switch (action) {
          case 'migrated':
            buffer.writeln('  ✅ $id -> Migrada (badge: ${detail['badgeId']})');
            break;
          case 'skipped':
            buffer.writeln('  ⏭️ $id -> ${detail['reason']}');
            break;
          case 'error':
            buffer.writeln('  ❌ $id -> Error: ${detail['error']}');
            break;
        }
      }
    }

    return buffer.toString();
  }
}
