import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Gestionar roles de usuarios desde Firebase Console o scripts
class AdminUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Convertir usuario en administrador usando su email
  static Future<void> makeUserAdmin(String email) async {
    try {
      // Buscar usuario por email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('Usuario no encontrado con email: $email');
        return;
      }

      final userDoc = querySnapshot.docs.first;

      // Actualizar rol a admin
      await userDoc.reference.update({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Usuario $email promovido a administrador');

    } catch (e) {
      debugPrint('Error al promover usuario: $e');
      rethrow;
    }
  }


  /// Degradar usuario a usuario normal
  static Future<void> makeUserNormal(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('Usuario no encontrado con email: $email');
        return;
      }

      final userDoc = querySnapshot.docs.first;

      await userDoc.reference.update({
        'role': 'user',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Usuario $email degradado a usuario normal');

    } catch (e) {
      debugPrint('Error al degradar usuario: $e');
      rethrow;
    }
  }

  /// Listar todos los administradores
  static Future<List<Map<String, dynamic>>> listAdmins() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['admin'])
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'nombre': data['nombre'],
          'email': data['email'],
          'role': data['role'],
        };
      }).toList();

    } catch (e) {
      debugPrint('Error al listar administradores: $e');
      return [];
    }
  }
}

///
/// Para hacer admin a un usuario:
/// ```javascript
/// const admin = require('firebase-admin');
/// const db = admin.firestore();
///
/// async function makeAdmin(email) {
///   const userQuery = await db.collection('users').where('email', '==', email).limit(1).get();
///   if (userQuery.empty) {
///     console.log('Usuario no encontrado');
///     return;
///   }
///
///   const userDoc = userQuery.docs[0];
///   await userDoc.ref.update({
///     role: 'admin',
///     updatedAt: admin.firestore.FieldValue.serverTimestamp()
///   });
///
///   console.log(`Usuario ${email} promovido a admin`);
/// }
///
/// // Ejecutar
/// makeAdmin('tu-email@ejemplo.com');
/// ```