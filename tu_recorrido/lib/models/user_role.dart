/// Roles de usuarios en el sistema
enum UserRole {
  /// Usuario normal con acceso básico
  user('user', 'Usuario'),
  
  /// Administrador con acceso completo a todo
  admin('admin', 'Administrador');

  const UserRole(this.value, this.displayName);

  /// Valor del rol, como se almacenara en la base de datos
  final String value;
  
  /// Nombre para mostrar al usuario
  final String displayName;

  /// Obtiene el rol desde un string
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user, // Por defecto usuario normal
    );
  }

  /// Verifica si el rol tiene permisos de administrador
  bool get isAdmin => this == UserRole.admin;

}

/// Permisos específicos
class UserPermissions {
  final UserRole role;

  const UserPermissions(this.role);

  /// Puede acceder a vistas de administración
  bool get canAccessAdmin => role.isAdmin;

  /// crear/editar estaciones
  bool get canManageStations => role.isAdmin;

  /// Puede ver estadísticas globales
  bool get canViewGlobalStats => role.isAdmin;

  /// Puede gestionar otros usuarios
  bool get canManageUsers => role.isAdmin;

  /// Puede acceder a configuración del sistema
  bool get canAccessSystemConfig => role.isAdmin;
}