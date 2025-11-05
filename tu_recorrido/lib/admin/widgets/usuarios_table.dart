import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../services/user_role_service.dart';
import '../../utils/colores.dart';

class UsuariosTable extends StatefulWidget {
  const UsuariosTable({super.key});

  @override
  State<UsuariosTable> createState() => _UsuariosTableState();
}

class _UsuariosTableState extends State<UsuariosTable> {
  bool _loading = true;
  List<AppUser> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await UserRoleService.getAllUsers();
      if (mounted) setState(() => _users = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar usuarios: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeRole(AppUser user, UserRole role) async {
    try {
      await UserRoleService.changeUserRole(user.uid, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rol actualizado')));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar rol: $e')));
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar al usuario ${user.nombre}? Esta acción removerá su documento.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Coloressito.badgeRed), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando usuario: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Coloressito.borderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people),
              const SizedBox(width: 8),
              Text('Gestión de Usuarios', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Coloressito.adventureGreen),
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar'),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (_loading) const Center(child: CircularProgressIndicator()) else SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Rol')),
                DataColumn(label: Text('Acciones')),
              ],
              rows: _users.map((u) {
                return DataRow(cells: [
                  DataCell(SizedBox(width: 200, child: Text(u.nombre ?? u.email ?? '-', overflow: TextOverflow.ellipsis))),
                  DataCell(SizedBox(width: 250, child: Text(u.email ?? '-', overflow: TextOverflow.ellipsis))),
                  DataCell(Text(u.role.displayName)),
                  DataCell(Row(children: [
                    PopupMenuButton<UserRole>(
                      icon: const Icon(Icons.swap_vert),
                      onSelected: (r) => _changeRole(u, r),
                      itemBuilder: (ctx) => UserRole.values.map((r) => PopupMenuItem(value: r, child: Text(r.displayName))).toList(),
                      tooltip: 'Cambiar rol',
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => _deleteUser(u), icon: const Icon(Icons.delete), color: Coloressito.badgeRed),
                  ])),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
