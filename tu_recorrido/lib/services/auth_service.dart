// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream para escuchar cambios en el estado de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuario actual (puede ser null si no hay sesión)
  static User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // Helper: crear/actualizar perfil mínimo en Firestore (idempotente)
  // - Incluye uid (útil para consultas)
  // - No pisa campos propietarios (como fechaNacimiento, region, etc.) gracias a merge:true
  // ---------------------------------------------------------------------------
  static Future<void> _upsertUserProfile(
    User user, {
    String? displayName,
  }) async {
    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'displayName': (displayName ?? user.displayName)?.trim(),
      'photoURL': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('users').doc(user.uid).set(
      {
        'createdAt': FieldValue.serverTimestamp(),
        ...data,
      },
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // usuario canceló

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // upsert de perfil mínimo en Firestore
      await _upsertUserProfile(userCredential.user!);

      if (kDebugMode) {
        print('Usuario autenticado: ${userCredential.user?.displayName}');
        print('Email: ${userCredential.user?.email}');
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Error de Firebase Auth: ${e.code} - ${e.message}');
      }
      throw _handleFirebaseAuthError(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error general en Google Sign In: $e');
      }
      throw 'Error inesperado durante la autenticación con Google';
    }
  }

  // ---------------------------------------------------------------------------
  // Registro con Email/Password
  // ---------------------------------------------------------------------------
  static Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final uc = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await uc.user?.updateDisplayName(displayName);
      await uc.user?.reload();

      // crea/actualiza perfil en Firestore
      await _upsertUserProfile(uc.user!, displayName: displayName);

      // 👇 enviar verificación
      if (!(uc.user?.emailVerified ?? false)) {
        await uc.user?.sendEmailVerification();
        if (kDebugMode) {
          print('📧 Email de verificación enviado a: ${uc.user?.email}');
        }
      }

      if (kDebugMode) {
        print('Usuario registrado: ${uc.user?.displayName}');
      }
      return uc;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Error de registro: ${e.code} - ${e.message}');
      }
      throw _handleFirebaseAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Reenviar email de verificación
  // ---------------------------------------------------------------------------
  static Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (kDebugMode) {
          print('📧 Email de verificación reenviado a: ${user.email}');
        }
      } else {
        throw 'No hay usuario o ya está verificado';
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Error al reenviar verificación: ${e.code} - ${e.message}');
      }
      throw _handleFirebaseAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Login con Email/Password
  // ---------------------------------------------------------------------------
  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // mantener perfil fresco (no afecta tus campos extra)
      await _upsertUserProfile(userCredential.user!);

      if (kDebugMode) {
        print('Usuario inició sesión: ${userCredential.user?.displayName}');
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Error de inicio de sesión: ${e.code} - ${e.message}');
      }
      throw _handleFirebaseAuthError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Cerrar sesión
  // ---------------------------------------------------------------------------
  static Future<void> signOut() async {
    try {
      // Limpiar solo los datos del usuario en SharedPreferences (selectivo)
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Solo eliminar claves relacionadas con el usuario
      for (final key in keys) {
        if (key.startsWith('user_') || 
            key.startsWith('album_') ||
            key == 'nombre' ||
            key == 'avatarUrl' ||
            key == 'backgroundUrl') {
          await prefs.remove(key);
          if (kDebugMode) {
            print('🧹 Removido: $key');
          }
        }
      }
      
      if (kDebugMode) {
        print('🧹 SharedPreferences del usuario limpiados');
      }
      
      // Cerrar sesión en Firebase y Google
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      if (kDebugMode) {
        print('✅ Usuario cerró sesión completamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error al cerrar sesión: $e');
      }
      throw 'Error al cerrar sesión';
    }
  }

  // ---------------------------------------------------------------------------
  // Restablecer contraseña
  // ---------------------------------------------------------------------------
  static Future<void> resetPassword(String email) async {
    try {
      // Validación básica del formato de email
      if (email.trim().isEmpty || !email.contains('@')) {
        throw 'Ingrese un correo válido';
      }

      // Intentar enviar el email de restablecimiento
      // Firebase automáticamente maneja si el email existe o no
      await _auth.sendPasswordResetEmail(email: email.trim());

      if (kDebugMode) {
        print('Email de restablecimiento enviado a: ${email.trim()}');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(
            'Error al enviar email de restablecimiento: ${e.code} - ${e.message}');
      }

      // Manejar errores específicos de Firebase Auth
      switch (e.code) {
        case 'user-not-found':
          throw 'No existe una cuenta con ese correo';
        case 'invalid-email':
          throw 'El formato del correo no es válido';
        case 'too-many-requests':
          throw 'Demasiados intentos. Intenta más tarde';
        default:
          throw _handleFirebaseAuthError(e);
      }
    } catch (e) {
      // Mensaje genérico legible en UI
      throw e.toString();
    }
  }

  // ---------------------------------------------------------------------------
  // Mapeo de errores de FirebaseAuth a mensajes amigables
  // ---------------------------------------------------------------------------
  static String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'user-not-found':
        return 'No se encontró ningún usuario con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'El formato del email es inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con el mismo email pero diferentes credenciales';
      case 'invalid-credential':
        return 'Las credenciales son inválidas o han expirado';
      default:
        return 'Error de autenticación: ${e.message ?? 'Error desconocido'}';
    }
  }

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------
  static bool get isAuthenticated => _auth.currentUser != null;

  static Map<String, dynamic>? get userInfo {
    final user = _auth.currentUser;
    if (user == null) return null;
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
    };
  }
}
