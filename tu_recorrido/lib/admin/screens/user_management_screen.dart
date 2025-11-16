import 'package:flutter/material.dart';
import '../../services/user_role_service.dart';
import 'package:tu_recorrido/utils/theme/colores.dart';
import 'package:tu_recorrido/widgets/base/role_protected_widget.dart';
import 'package:tu_recorrido/widgets/base/pantalla_base.dart';
import '../widgets/usuarios_table.dart';

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
      final stats = await UserRoleService.getUserRoleStats();
      setState(() {
        _roleStats = stats;
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

  // Changing user roles is done via UsuariosTable; keep logic there for single-responsibility.

  @override
  Widget build(BuildContext context) {
    return AdminProtectedWidget(
      child: PantallaBase(
        titulo: 'Gestión de Usuarios',
        backgroundColor: Colors.white,
        appBarBackgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Recargar usuarios',
          ),
        ],
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
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
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
    // Use the reusable UsuariosTable widget for consistency with other management tables
    return const UsuariosTable();
  }
}
