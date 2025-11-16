import 'package:flutter/material.dart';
import '../../models/place.dart';

class BadgePill extends StatelessWidget {
  final PlaceBadge badge;
  const BadgePill({super.key, required this.badge});

  Color getThemeColor() {
    switch (badge.tema) {
      case "Historia":
        return Colors.brown.shade700;
      case "Arte":
        return Colors.purple.shade400;
      case "Naturaleza":
        return Colors.green.shade600;
      case "Arquitectura":
        return Colors.blueGrey.shade700;
      case "Cultura":
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getThemeColor().withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: getThemeColor(), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: getThemeColor(), size: 18),
          const SizedBox(width: 6),
          Text(
            badge.nombre,
            style: TextStyle(
              color: getThemeColor(),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}