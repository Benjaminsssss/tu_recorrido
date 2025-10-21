import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

/// Modelo de usuario del sistema
class AppUser {
  final String uid;
  final String nombre;
  final String apodo;
  final String email;
  final String? fechaNacimiento;
  final String? region;
  final String? comuna;
  final UserRole role;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    required this.nombre,
    required this.apodo,
    required this.email,
    this.fechaNacimiento,
    this.region,
    this.comuna,
    this.role = UserRole.user, // Por defecto usuario normal
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Crear desde documento de Firestore
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppUser(
      uid: doc.id,
      nombre: data['nombre'] ?? '',
      apodo: data['apodo'] ?? '',
      email: data['email'] ?? '',
      fechaNacimiento: data['fechaNacimiento'] as String?,
      region: data['region'] as String?,
      comuna: data['comuna'] as String?,
      role: UserRole.fromString(data['role'] ?? 'user'),
      activo: data['activo'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'apodo': apodo,
      'email': email,
      'role': role.value,
      'activo': activo,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fechaNacimiento != null) map['fechaNacimiento'] = fechaNacimiento;
    if (region != null) map['region'] = region;
    if (comuna != null) map['comuna'] = comuna;
    if (createdAt == null) map['createdAt'] = FieldValue.serverTimestamp();

    return map;
  }

  /// Obtener permisos del usuario
  UserPermissions get permissions => UserPermissions(role);

  /// Crear copia con cambios
  AppUser copyWith({
    String? uid,
    String? nombre,
    String? apodo,
    String? email,
    String? fechaNacimiento,
    String? region,
    String? comuna,
    UserRole? role,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      apodo: apodo ?? this.apodo,
      email: email ?? this.email,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      region: region ?? this.region,
      comuna: comuna ?? this.comuna,
      role: role ?? this.role,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
