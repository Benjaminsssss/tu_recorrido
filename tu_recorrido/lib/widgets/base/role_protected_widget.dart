import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import 'package:tu_recorrido/services/auth/user_role_service.dart';
import 'package:tu_recorrido/utils/theme/colores.dart';

/// Protege rutas basado en roles de usuario
class RoleProtectedWidget extends StatefulWidget {
  final Widget child;

  /// Tiene permisos?
  final bool Function(UserPermissions) hasPermission;

  /// Widget alternativo si no tiene permisos
  final Widget? fallback;

  /// Mensaje de error
  final String? errorMessage;

  /// Redirigir al login si no está autenticado
  final bool redirectToLogin;

  const RoleProtectedWidget({
    super.key,
    required this.child,
    required this.hasPermission,
    this.fallback,
    this.errorMessage,
    this.redirectToLogin = false,
  });

  @override
  State<RoleProtectedWidget> createState() => _RoleProtectedWidgetState();
}

class _RoleProtectedWidgetState extends State<RoleProtectedWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: UserRoleService.currentUserStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Usuario no autenticado
        if (!snapshot.hasData || snapshot.data == null) {
          if (widget.redirectToLogin) {
            // Redirigir al login después del build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/auth/login');
            });
            return const Center(child: CircularProgressIndicator());
          }

          return widget.fallback ??
              _buildNoPermissionWidget(
                'Debes iniciar sesión para acceder a esta funcionalidad',
              );
        }

        final user = snapshot.data!;

        // checkear permisos
        if (widget.hasPermission(user.permissions)) {
          return widget.child;
        }

        // No tiene permisos
        return widget.fallback ??
            _buildNoPermissionWidget(
              widget.errorMessage ??
                  'No tienes permisos para acceder a esta funcionalidad',
            );
      },
    );
  }

  Widget _buildNoPermissionWidget(String message) {
    return Scaffold(
      backgroundColor: Coloressito.background,
      appBar: AppBar(
        title: const Text('Acceso Restringido'),
        backgroundColor: Coloressito.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Coloressito.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Acceso Restringido',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Coloressito.primary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Coloressito.adventureGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Proteger vistas de administración
class AdminProtectedWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AdminProtectedWidget({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return RoleProtectedWidget(
      hasPermission: (permissions) => permissions.canAccessAdmin,
      errorMessage: 'Solo los administradores pueden acceder a esta sección',
      redirectToLogin: true,
      fallback: fallback,
      child: child,
    );
  }
}

/// Muestra información solo a usuarios con ciertos permisos
class ConditionalWidget extends StatefulWidget {
  final Widget child;
  final bool Function(UserPermissions) condition;
  final Widget? fallback;

  const ConditionalWidget({
    super.key,
    required this.child,
    required this.condition,
    this.fallback,
  });

  @override
  State<ConditionalWidget> createState() => _ConditionalWidgetState();
}

class _ConditionalWidgetState extends State<ConditionalWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: UserRoleService.getCurrentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return widget.fallback ?? const SizedBox.shrink();
        }

        final user = snapshot.data!;

        if (widget.condition(user.permissions)) {
          return widget.child;
        }

        return widget.fallback ?? const SizedBox.shrink();
      },
    );
  }
}
