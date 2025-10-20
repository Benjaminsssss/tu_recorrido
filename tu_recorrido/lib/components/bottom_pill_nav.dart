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
      _PillItem(Icons.explore, 'Mapa'), // Ícono de exploración más atractivo
    ];

    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFFAFBF8), // Fondo igual al Scaffold
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            // Fondo azul petróleo clarito sólido
            color: const Color(0xFF2B6B7F), // azul petróleo más claro
            border: Border.all(
              color: const Color(0xFF1A4D5C), // azul petróleo oscuro
              width: 1,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 3,
                offset: Offset(0, 1),
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
  // Ambos estados con el mismo color: blanco para contrastar con el fondo azul
  final iconColor = const Color(0xFFFFFFFF); // blanco
    final indicatorColor = const Color(0xFF66B7F0); // celeste claro

    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
  splashColor: indicatorColor.withValues(alpha: 0.3),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: const BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 20, color: iconColor),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: iconColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            // Indicador activo: línea celeste
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selected ? 1.0 : 0.0,
                child: Container(
                  height: 2,
                  width: 16,
                  decoration: BoxDecoration(
                    // Indicador celeste claro
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
