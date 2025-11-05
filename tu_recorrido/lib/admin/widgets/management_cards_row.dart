import 'package:flutter/material.dart';
import '../screens/insignias_admin_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/gestion_estaciones_screen.dart';
import '../../utils/colores.dart';

class ManagementCardsRow extends StatelessWidget {
  const ManagementCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'Gestión Estación',
        'subtitle': 'Crear / Editar / Eliminar estaciones',
        'icon': Icons.location_on,
        'color': Coloressito.adventureGreen,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GestionEstacionesScreen())),
      },
      {
        'title': 'Gestión Insignia',
        'subtitle': 'Crear / Asignar / Editar insignias',
        'icon': Icons.emoji_events,
        'color': Coloressito.badgeYellow,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InsigniasAdminScreen())),
      },
      {
        'title': 'Gestión Usuarios',
        'subtitle': 'Actualizar roles y eliminar usuarios',
        'icon': Icons.people,
        'color': Coloressito.badgeRed,
        'onTap': () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserManagementScreen())),
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((it) {
        return InkWell(
          onTap: it['onTap'] as void Function()?,
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Coloressito.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                          padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (it['color'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                          child: Icon(it['icon'] as IconData, color: it['color'] as Color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(it['subtitle'] as String, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
