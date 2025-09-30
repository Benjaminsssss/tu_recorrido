import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- NUEVO

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  static final FirebaseFirestore _db = FirebaseFirestore.instance; // <-- NUEVO

  // Stream para escuchar cambios en el estado de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  // Usuario actual
  static User? get currentUser => _auth.currentUser;

  // ------------------ Helper perfil en Firestore ------------------
  static Future<void> _upsertUserProfile(User user, {String? displayName}) async {
    final data = <String, dynamic>{
      'email': user.email,
      'displayName': displayName ?? user.displayName,
      'photoURL': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // si es primera vez, también guardamos createdAt
    await _db.collection('users').doc(user.uid).set({
      'createdAt': FieldValue.serverTimestamp(),
      ...data,
    }, SetOptions(merge: true));
  }
  // ----------------------------------------------------------------

  // Iniciar sesión con Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // usuario canceló

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // <-- NUEVO: crear/actualizar perfil en Firestore
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

  // Registrarse con email y contraseña
  static Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar el nombre de usuario
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();

      // <-- NUEVO: crear/actualizar perfil en Firestore
      await _upsertUserProfile(userCredential.user!, displayName: displayName);

      if (kDebugMode) {
        print('Usuario registrado: ${userCredential.user?.displayName}');
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Error de registro: ${e.code} - ${e.message}');
      }
      throw _handleFirebaseAuthError(e);
    }
  }

  // Iniciar sesión con email y contraseña
  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // (Opcional pero recomendado) asegura existencia/actualización del perfil
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

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      if (kDebugMode) {
        print('Usuario cerró sesión');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cerrar sesión: $e');
      }
      throw 'Error al cerrar sesión';
    }
  }

  // Restablecer contraseña
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (kDebugMode) {
        print('Email de restablecimiento enviado a: $email');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Error al enviar email de restablecimiento: ${e.code} - ${e.message}');
      }
      throw _handleFirebaseAuthError(e);
    }
  }

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
