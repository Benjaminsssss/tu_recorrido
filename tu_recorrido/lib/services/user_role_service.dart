import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';

/// Servicio para gestionar usuarios y roles en el sistema
class UserRoleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _usersCollection = 'users';
  
  /// Cache del usuario actual
  static AppUser? _currentUser;
  
  /// Stream del usuario actual
  static Stream<AppUser?> get currentUserStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
        return null;
      }
      
      _currentUser = await getUserById(firebaseUser.uid);
      return _currentUser;
    });
  }
  
  /// Obtener usuario actual desde cache o Firebase
  static Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    
    // Si ya está en cache, lo devolvemos
    if (_currentUser?.uid == firebaseUser.uid) {
      return _currentUser;
    }
    
    // Sino, lo cargamos desde Firestore
    _currentUser = await getUserById(firebaseUser.uid);
    return _currentUser;
  }
  
  /// Obtener usuario por ID
  static Future<AppUser?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
      if (!doc.exists) return null;
      
      return AppUser.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error al obtener usuario: $e');
      return null;
    }
  }
  
  /// Crear o actualizar usuario con rol
  static Future<void> createOrUpdateUser({
    required String uid,
    required Map<String, dynamic> userData,
    UserRole? role,
  }) async {
    try {
      final data = Map<String, dynamic>.from(userData);
      
      // Asignar rol por defecto si no se especifica
      data['role'] = role?.value ?? UserRole.user.value;
      
      await _firestore.collection(_usersCollection).doc(uid).set(
        data,
        SetOptions(merge: true),
      );
      
      // Limpiar cache si es el usuario actual
      if (_currentUser?.uid == uid) {
        _currentUser = null;
      }
      
    } catch (e) {
      debugPrint('Error al crear/actualizar usuario: $e');
      rethrow;
    }
  }
  
  /// Verificar si el usuario actual es administrador
  static Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();
    return user?.role.isAdmin ?? false;
  }
  
  /// Verificar si el usuario actual tiene un permiso específico
  static Future<bool> hasPermission(bool Function(UserPermissions) permission) async {
    final user = await getCurrentUser();
    if (user == null) return false;
    
    return permission(user.permissions);
  }
  
  /// Obtener todos los usuarios (solo para administradores)
  static Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('nombre')
          .get();
      
      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener usuarios: $e');
      return [];
    }
  }
  
  /// Cambiar rol de un usuario (solo para super administradores)
  static Future<void> changeUserRole(String uid, UserRole newRole) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'role': newRole.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Rol actualizado para usuario $uid: ${newRole.displayName}');
    } catch (e) {
      debugPrint('Error al cambiar rol: $e');
      rethrow;
    }
  }
  
  /// Método para que los administradores promuevan usuarios a admin
  /// (puede ser llamado desde una interfaz de administración)
  static Future<void> promoteToAdmin(String uid) async {
    final currentUser = await getCurrentUser();
    if (currentUser?.role.isAdmin != true) {
      throw Exception('Solo los super administradores pueden promover usuarios');
    }
    
    await changeUserRole(uid, UserRole.admin);
  }
  
  /// Obtener estadísticas de usuarios por rol
  static Future<Map<String, int>> getUserRoleStats() async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();
      final stats = <String, int>{};
      
      for (final role in UserRole.values) {
        stats[role.displayName] = 0;
      }
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final roleString = data['role'] ?? 'user';
        final role = UserRole.fromString(roleString);
        stats[role.displayName] = (stats[role.displayName] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      debugPrint('Error al obtener estadísticas de roles: $e');
      return {};
    }
  }
}
