import 'package:flutter/material.dart';

class BottomPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomPillNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _PillItem(Icons.home_rounded, 'Inicio'),
      _PillItem(Icons.map_rounded, 'Mapa'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFFAFBF8), // Fondo igual al Scaffold
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8F4), // tinte muy leve
            border: Border.all(
              color: const Color(0xFFE8EAE4), // neutro cálido
              width: 1,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _PillButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillItem {
  final IconData icon;
  final String label;
  const _PillItem(this.icon, this.label);
}

class _PillButton extends StatelessWidget {
  final _PillItem item;
  final bool selected;
  final VoidCallback onTap;

  const _PillButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Activo: oliva oscuro #4E5338, Inactivo: oliva grisado #7B8063 @ 72%
    final inactiveColor = const Color(0xFF7B8063).withOpacity(0.72);
    final activeColor = const Color(0xFF4E5338); // oliva oscuro
    final indicatorColor = const Color(0xFFC88400); // miel/mostaza
    final fg = selected ? activeColor : inactiveColor;

    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: const BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 24, color: fg),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: fg,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            // Indicador activo: línea miel
            if (selected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  height: 2,
                  width: 20,
                  decoration: BoxDecoration(
                    color: indicatorColor, // miel/mostaza
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
