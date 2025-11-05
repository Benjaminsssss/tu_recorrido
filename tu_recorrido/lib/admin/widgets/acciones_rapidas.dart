import 'package:flutter/material.dart';
import '../../utils/colores.dart';

class AccionesRapidasWidget extends StatelessWidget {
  final VoidCallback? onShowQR;
  final VoidCallback? onViewUserVisits;
  final VoidCallback? onCreateStation;

  const AccionesRapidasWidget(
      {super.key, this.onShowQR, this.onViewUserVisits, this.onCreateStation});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'label': 'Mostrar QR estaciones',
        'icon': Icons.qr_code,
        'color': Coloressito.adventureGreen,
        'cb': onShowQR
      },
      {
        'label': 'Ver puntos visitados',
        'icon': Icons.map,
        'color': Coloressito.badgeYellow,
        'cb': onViewUserVisits
      },
      {
        'label': 'Crear estación',
        'icon': Icons.add,
        'color': Coloressito.badgeBlue,
        'cb': onCreateStation
      },
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Coloressito.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on),
              const SizedBox(width: 8),
              Text('Acciones Rápidas',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          // Lista de acciones como filas (ListTile)
          ...actions.asMap().entries.map((entry) {
            final a = entry.value;
            final idx = entry.key;
            return Column(
              children: [
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: (a['color'] as Color),
                    child: Icon(a['icon'] as IconData,
                        color: Colors.white, size: 14),
                  ),
                  title: Text(a['label'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: a['cb'] as void Function()?,
                  trailing: const Icon(Icons.chevron_right,
                      size: 18, color: Colors.grey),
                ),
                if (idx != actions.length - 1) const Divider(height: 0),
              ],
            );
          }),
        ],
      ),
    );
  }
}
