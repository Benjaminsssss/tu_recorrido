import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para diagnosticar problemas de autenticación
class DebugAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Diagnóstico completo del estado de autenticación
  static Future<Map<String, dynamic>> diagnoseAuth() async {
    final result = <String, dynamic>{};

    try {
      // 1. Estado actual del usuario
      final currentUser = _auth.currentUser;
      result['currentUser'] = {
        'exists': currentUser != null,
        'uid': currentUser?.uid,
        'email': currentUser?.email,
        'isAnonymous': currentUser?.isAnonymous,
        'providerData': currentUser?.providerData
            .map((p) => {
                  'providerId': p.providerId,
                  'uid': p.uid,
                  'email': p.email,
                })
            .toList(),
      };

      // 2. Si no hay usuario, intentar crear uno anónimo
      if (currentUser == null) {
        try {
          final userCredential = await _auth.signInAnonymously();
          final newUser = userCredential.user;
          result['anonymousSignIn'] = {
            'success': true,
            'uid': newUser?.uid,
            'isAnonymous': newUser?.isAnonymous,
          };

          // 3. Intentar crear documento de usuario
          if (newUser != null) {
            try {
              await _firestore.collection('users').doc(newUser.uid).set({
                'uid': newUser.uid,
                'email': newUser.email ?? 'anonimo@ejemplo.com',
                'displayName': 'Usuario Anónimo de Prueba',
                'nombre': 'Usuario Anónimo',
                'activo': true,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
                'role': null,
              });
              result['userDocCreation'] = {'success': true};
            } catch (e) {
              result['userDocCreation'] = {
                'success': false,
                'error': e.toString(),
              };
            }
          }
        } catch (e) {
          result['anonymousSignIn'] = {
            'success': false,
            'error': e.toString(),
          };
        }
      } else {
        // 3. Usuario ya existe, verificar documento en Firestore
        try {
          final userDoc =
              await _firestore.collection('users').doc(currentUser.uid).get();
          result['userDocExists'] = userDoc.exists;
          if (!userDoc.exists) {
            // Intentar crear el documento
            try {
              await _firestore.collection('users').doc(currentUser.uid).set({
                'uid': currentUser.uid,
                'email': currentUser.email ?? 'anonimo@ejemplo.com',
                'displayName': currentUser.displayName ?? 'Usuario Anónimo',
                'nombre': 'Usuario Anónimo',
                'activo': true,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
                'role': null,
              });
              result['userDocCreation'] = {'success': true};
            } catch (e) {
              result['userDocCreation'] = {
                'success': false,
                'error': e.toString(),
              };
            }
          }
        } catch (e) {
          result['userDocCheck'] = {
            'success': false,
            'error': e.toString(),
          };
        }
      }

      // 4. Probar escribir en album_photos
      final finalUser = _auth.currentUser;
      if (finalUser != null) {
        try {
          final testPhotoId =
              'test_photo_${DateTime.now().millisecondsSinceEpoch}';
          await _firestore
              .collection('users')
              .doc(finalUser.uid)
              .collection('album_photos')
              .doc(testPhotoId)
              .set({
            'id': testPhotoId,
            'badgeId': 'test_badge',
            'imageUrl': 'https://example.com/test.jpg',
            'uploadDate': FieldValue.serverTimestamp(),
            'description': 'Foto de prueba para diagnóstico',
          });

          // Si llegamos aquí, el write fue exitoso, ahora lo eliminamos
          await _firestore
              .collection('users')
              .doc(finalUser.uid)
              .collection('album_photos')
              .doc(testPhotoId)
              .delete();

          result['albumPhotoTest'] = {'success': true};
        } catch (e) {
          result['albumPhotoTest'] = {
            'success': false,
            'error': e.toString(),
          };
        }
      }
    } catch (e) {
      result['generalError'] = e.toString();
    }

    return result;
  }

  /// Mostrar resultado del diagnóstico en formato legible
  static String formatDiagnosis(Map<String, dynamic> diagnosis) {
    final buffer = StringBuffer();
    buffer.writeln('=== DIAGNÓSTICO DE AUTENTICACIÓN ===\n');

    // Usuario actual
    final currentUser = diagnosis['currentUser'] as Map<String, dynamic>?;
    if (currentUser != null) {
      buffer.writeln('👤 Usuario actual:');
      buffer.writeln('  - Existe: ${currentUser['exists']}');
      if (currentUser['exists'] == true) {
        buffer.writeln('  - UID: ${currentUser['uid']}');
        buffer.writeln('  - Email: ${currentUser['email']}');
        buffer.writeln('  - Es anónimo: ${currentUser['isAnonymous']}');
      }
      buffer.writeln();
    }

    // Sign in anónimo
    final anonymousSignIn =
        diagnosis['anonymousSignIn'] as Map<String, dynamic>?;
    if (anonymousSignIn != null) {
      buffer.writeln('🔑 Autenticación anónima:');
      buffer.writeln('  - Éxito: ${anonymousSignIn['success']}');
      if (anonymousSignIn['success'] == true) {
        buffer.writeln('  - UID: ${anonymousSignIn['uid']}');
      } else {
        buffer.writeln('  - Error: ${anonymousSignIn['error']}');
      }
      buffer.writeln();
    }

    // Creación de documento de usuario
    final userDocCreation =
        diagnosis['userDocCreation'] as Map<String, dynamic>?;
    if (userDocCreation != null) {
      buffer.writeln('📄 Creación documento usuario:');
      buffer.writeln('  - Éxito: ${userDocCreation['success']}');
      if (userDocCreation['success'] != true) {
        buffer.writeln('  - Error: ${userDocCreation['error']}');
      }
      buffer.writeln();
    }

    // Test de album_photos
    final albumPhotoTest = diagnosis['albumPhotoTest'] as Map<String, dynamic>?;
    if (albumPhotoTest != null) {
      buffer.writeln('📸 Test escritura album_photos:');
      buffer.writeln('  - Éxito: ${albumPhotoTest['success']}');
      if (albumPhotoTest['success'] != true) {
        buffer.writeln('  - Error: ${albumPhotoTest['error']}');
      }
      buffer.writeln();
    }

    // Error general
    final generalError = diagnosis['generalError'];
    if (generalError != null) {
      buffer.writeln('❌ Error general: $generalError');
    }

    return buffer.toString();
  }
}