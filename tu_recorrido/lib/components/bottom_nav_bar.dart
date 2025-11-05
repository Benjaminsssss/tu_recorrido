import 'package:flutter/material.dart';

/// Barra inferior reutilizable con tres opciones: Inicio, Colección, Mapa
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const BottomNavBar(
      {super.key, required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF156A79),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BottomNavItem(
              icon: Icons.home,
              label: 'Inicio',
              selected: currentIndex == 0,
              onTap: () => onChanged(0),
            ),
            BottomNavItem(
              icon: Icons.collections, // Ícono más elegante para colección
              label: 'Colección',
              selected: currentIndex == 1,
              onTap: () => onChanged(1),
            ),
            BottomNavItem(
              icon: Icons.my_location,
              label: 'Mapa',
              selected: currentIndex == 2,
              onTap: () => onChanged(2),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            selected
                ? Stack(
                    children: [
                      // Borde gris
                      Icon(
                        icon,
                        color: Colors.grey.shade600,
                      ),
                      // Ícono amarillo llamativo encima
                      Icon(
                        icon,
                        color:
                            const Color(0xFFFFD700), // Amarillo oro llamativo
                        size:
                            22, // Ligeramente más pequeño para mostrar el borde gris
                      ),
                    ],
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFFFD700)
                    : Colors
                        .white, // Amarillo oro llamativo cuando seleccionado
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                shadows: selected
                    ? [
                        Shadow(
                          color: Colors.grey.shade600,
                          blurRadius: 1,
                          offset: const Offset(1, 1),
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
