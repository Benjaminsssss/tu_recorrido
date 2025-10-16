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
    final theme = Theme.of(context);
    final items = const [
      _PillItem(Icons.home_rounded, 'Inicio'),
      _PillItem(Icons.map_rounded, 'Mapa'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: StadiumBorder(
              side: BorderSide(color: Colors.black.withOpacity(0.06)),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _PillButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                    color: theme.colorScheme.primary,
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
  final Color color;

  const _PillButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected ? color.withOpacity(0.12) : Colors.transparent;
    final fg = selected ? color : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: fg),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
