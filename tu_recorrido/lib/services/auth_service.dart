import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Stream para escuchar cambios en el estado de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Usuario actual
  static User? get currentUser => _auth.currentUser;

  // Iniciar sesión con Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Activar el flujo de autenticación
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return null;
      }

      // Obtener los detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear una nueva credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Una vez firmado, devolver el UserCredential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
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

  // Manejar errores de Firebase Auth
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

  // Verificar si el usuario está autenticado
  static bool get isAuthenticated => _auth.currentUser != null;

  // Obtener información del usuario
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