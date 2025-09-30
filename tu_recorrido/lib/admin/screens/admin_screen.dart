import 'package:flutter/material.dart';
import '../../utils/colores.dart';
import '../../widgets/pantalla_base.dart';
import '../../utils/estaciones_data.dart';
import 'crear_estacion.dart';

/// Acceso a todas las funcionalidades de admin
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  /// Crear UNA estación de prueba (para que se cargue más rápido)
  Future<void> _crearEstacionPrueba(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Coloressito.surfaceDark,
        title: const Text(
          'Crear Estación de Prueba',
          style: TextStyle(color: Coloressito.textPrimary),
        ),
        content: const Text(
          '¿Crear Plaza de Armas en Firestore para probar el escáner QR?\n\nCódigo que obtendrás: PLAZA_ARMAS_001',
          style: TextStyle(color: Coloressito.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Coloressito.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Coloressito.adventureGreen,
            ),
            child: const Text(
              'Crear',
              style: TextStyle(color: Coloressito.textPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!context.mounted) return;

    // Mostrar diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Coloressito.surfaceDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Coloressito.adventureGreen),
            ),
            const SizedBox(height: 16),
            const Text(
              'Creando Plaza de Armas...',
              style: TextStyle(color: Coloressito.textPrimary),
            ),
          ],
        ),
      ),
    );

    try {
      await EstacionesData.crearEstacionPrueba();
      
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de progreso
      
      // Mostrar éxito con el código QR
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plaza de Armas creada!\nUsa código: PLAZA_ARMAS_001'),
          backgroundColor: Coloressito.adventureGreen,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de progreso
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Coloressito.badgeRed,
        ),
      );
    }
  }

  /// Crear estaciones de ejemplo en Firestore
  Future<void> _crearEstacionesEjemplo(BuildContext context) async {
    // MUESTRA diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Coloressito.surfaceDark,
        title: const Text(
          'Crear Estaciones de Ejemplo',
          style: TextStyle(color: Coloressito.textPrimary),
        ),
        content: const Text(
          '¿Deseas crear 8 estaciones patrimoniales de Santiago en Firestore?\n\nEsto incluye: Plaza de Armas, La Moneda, Cerro Santa Lucía, etc.',
          style: TextStyle(color: Coloressito.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Coloressito.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Coloressito.adventureGreen,
            ),
            child: const Text(
              'Crear',
              style: TextStyle(color: Coloressito.textPrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!context.mounted) return;

    // Muestra diálogo de progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Coloressito.surfaceDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Coloressito.adventureGreen),
            ),
            const SizedBox(height: 16),
            const Text(
              'Creando estaciones...',
              style: TextStyle(color: Coloressito.textPrimary),
            ),
          ],
        ),
      ),
    );

    try {
      await EstacionesData.crearEstacionesEjemplo();
      
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de progreso
      
      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡8 estaciones patrimoniales creadas exitosamente!'),
          backgroundColor: Coloressito.adventureGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de progreso
      
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Coloressito.badgeRed,
        ),
      );
    }
  }

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
          
          const SizedBox(height: 12),
          
          // Botones para crear estaciones
          Row(
            children: [
              Expanded(
                child: _buildBotonAccion(
                  context: context,
                  icono: Icons.science,
                  texto: 'Crear 1 Estación\n(Plaza de Armas)',
                  color: Coloressito.badgeGreen,
                  onTap: () => _crearEstacionPrueba(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonAccion(
                  context: context,
                  icono: Icons.upload,
                  texto: 'Crear 8 Estaciones\n(Todas)',
                  color: Coloressito.badgeYellow,
                  onTap: () => _crearEstacionesEjemplo(context),
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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