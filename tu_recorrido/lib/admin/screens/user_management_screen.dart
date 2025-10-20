import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../services/user_role_service.dart';
import '../../utils/colores.dart';
import '../../widgets/role_protected_widget.dart';

/// vista para gestionar usuarios y roles
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminProtectedWidget(
      child: const _UserManagementContent(),
    );
  }
}

class _UserManagementContent extends StatefulWidget {
  const _UserManagementContent();

  @override
  State<_UserManagementContent> createState() => _UserManagementContentState();
}

class _UserManagementContentState extends State<_UserManagementContent> {
  List<AppUser> _users = [];
  Map<String, int> _roleStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final [users, stats] = await Future.wait([
        UserRoleService.getAllUsers(),
        UserRoleService.getUserRoleStats(),
      ]);

      setState(() {
        _users = users as List<AppUser>;
        _roleStats = stats as Map<String, int>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeUserRole(AppUser user, UserRole newRole) async {
    try {
      await UserRoleService.changeUserRole(user.uid, newRole);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol actualizado para ${user.nombre}'),
            backgroundColor: Coloressito.adventureGreen,
          ),
        );
        _loadData(); // Recargar datos
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar rol: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Coloressito.background,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Coloressito.badgeRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildUsersList(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas de Roles',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _roleStats.entries.map((entry) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${entry.value}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Coloressito.badgeRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUsersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lista de Usuarios',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.role.isAdmin
                      ? Coloressito.badgeRed
                      : Coloressito.adventureGreen,
                  child: Icon(
                    user.role.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                  ),
                ),
                title: Text(user.nombre),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email),
                    Text(
                      'Rol: ${user.role.displayName}',
                      style: TextStyle(
                        color: user.role.isAdmin
                            ? Coloressito.badgeRed
                            : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<UserRole>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (role) => _changeUserRole(user, role),
                  itemBuilder: (context) => UserRole.values.map((role) {
                    return PopupMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Icon(
                            role.isAdmin ? Icons.admin_panel_settings : Icons.person,
                            size: 16,
                            color: role.isAdmin
                                ? Coloressito.badgeRed
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(role.displayName),
                          if (user.role == role) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check, size: 16, color: Colors.green),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
                isThreeLine: true,
              );
            },
          ),
        ),
      ],
    );
  }
}