import 'package:flutter/material.dart';
import '../utils/colores.dart';

/// Widget reutilizable para mostrar estadísticas de progreso
/// Muestra visitadas, total y porcentaje con barra de progreso
class EstadisticasProgreso extends StatelessWidget {
  final int visitadas;
  final int total;
  final int porcentaje;
  final String titulo;
  final IconData icono;

  const EstadisticasProgreso({
    super.key,
    required this.visitadas,
    required this.total,
    required this.porcentaje,
    this.titulo = 'Progreso de Exploración',
    this.icono = Icons.emoji_events,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: Coloressito.buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Coloressito.glowColor,
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                color: Coloressito.badgeYellow,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  color: Coloressito.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Visitadas', visitadas.toString(), Coloressito.adventureGreen),
              _buildStatItem('Total', total.toString(), Coloressito.textSecondary),
              _buildStatItem('Completado', '$porcentaje%', Coloressito.badgeYellow),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Barra de progreso
          LinearProgressIndicator(
            value: total > 0 ? visitadas / total : 0,
            backgroundColor: Coloressito.surfaceDark,
            valueColor: const AlwaysStoppedAnimation<Color>(Coloressito.adventureGreen),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Coloressito.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}