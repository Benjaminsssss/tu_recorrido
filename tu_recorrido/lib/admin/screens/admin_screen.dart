import 'package:flutter/material.dart';
import '../../utils/colores.dart';
import '../../widgets/pantalla_base.dart';
import 'crear_estacion.dart';

/// Acceso a todas las funcionalidades de admin
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Panel de Administración',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderInfo(),
          
          const SizedBox(height: 32),
          
          // Sección de gestión de estaciones
          _buildSeccionEstaciones(context),
          
          const SizedBox(height: 24),
          
          // Sección de estadísticas generales
          _buildSeccionEstadisticas(),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
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
          Icon(
            Icons.admin_panel_settings,
            size: 48,
            color: Coloressito.textPrimary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Administrador',
            style: TextStyle(
              color: Coloressito.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gestiona las estaciones patrimoniales y el contenido de la aplicación',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Coloressito.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionEstaciones(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Coloressito.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Coloressito.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_city,
                color: Coloressito.adventureGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Gestión de Estaciones',
                style: TextStyle(
                  color: Coloressito.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Crear, editar y administrar las estaciones patrimoniales de Santiago',
            style: TextStyle(
              color: Coloressito.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBotonAccion(
                  context: context,
                  icono: Icons.add_location,
                  texto: 'Crear Estación',
                  color: Coloressito.adventureGreen,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CrearEstacionScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonAccion(
                  context: context,
                  icono: Icons.list,
                  texto: 'Ver Estaciones',
                  color: Coloressito.badgeBlue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función próximamente disponible'),
                        backgroundColor: Coloressito.badgeYellow,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionEstadisticas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Coloressito.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Coloressito.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Coloressito.badgeBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Estadísticas Generales',
                style: TextStyle(
                  color: Coloressito.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Próximamente: estadísticas de uso, estaciones más visitadas, etc.',
            style: TextStyle(
              color: Coloressito.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAccion({
    required BuildContext context,
    required IconData icono,
    required String texto,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}