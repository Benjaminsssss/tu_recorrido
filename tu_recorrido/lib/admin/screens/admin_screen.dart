import 'package:flutter/material.dart';
import '../../utils/colores.dart';
import '../../widgets/pantalla_base.dart';
import '../../utils/qr_management_helper.dart';
import '../../widgets/role_protected_widget.dart';
import 'crear_estacion.dart';
import 'generador_qr_screen.dart';
import 'user_management_screen.dart';
import 'insignias_admin_screen.dart';

/// Acceso a todas las funcionalidades de admin (protegido por roles)
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  /// Genera códigos QR para estaciones existentes
  Future<void> _generarQRParaEstacionesExistentes(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Coloressito.surfaceDark,
        title: const Text(
          'Generar Códigos QR',
          style: TextStyle(color: Coloressito.textPrimary),
        ),
        content: const Text(
          '¿Generar códigos QR únicos para todas las estaciones existentes en Firestore?\n\nEsto actualizará las estaciones que no tengan códigos QR válidos.',
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
              'Generar QR',
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
              valueColor: AlwaysStoppedAnimation<Color>(
                Coloressito.adventureGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Generando códigos QR...',
              style: TextStyle(color: Coloressito.textPrimary),
            ),
          ],
        ),
      ),
    );

    try {
      final resultado = await QRManagementHelper.ejecutarDesdeAdmin();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de progreso

      if (resultado['success']) {
        // Mostrar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${resultado['message']}\n'
              'Total: ${resultado['total']} estaciones\n'
              'Actualizadas: ${resultado['updated']} códigos QR',
            ),
            backgroundColor: Coloressito.adventureGreen,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        throw Exception(resultado['message']);
      }
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
  /// Mostrar estado actual de códigos QR
  // ignore: unused_element
  Future<void> _mostrarEstadoQR(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Coloressito.surfaceDark,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Coloressito.badgeBlue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verificando estado de QR...',
              style: TextStyle(color: Coloressito.textPrimary),
            ),
          ],
        ),
      ),
    );

    try {
      await QRManagementHelper.verificarEstadoQR();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de progreso

      // Mostrar información (en consola por ahora)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Estado verificado. Revisa la consola de debug para más detalles.'),
          backgroundColor: Coloressito.badgeBlue,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de progreso

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
    return AdminProtectedWidget(
      child: PantallaBase(
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
            style: TextStyle(color: Coloressito.textSecondary, fontSize: 14),
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
            'Crear y gestionar las estaciones existentes en Firestore',
            style: TextStyle(color: Coloressito.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Botones principales - solo lo esencial
          Row(
            children: [
              Expanded(
                child: _buildBotonAccion(
                  context: context,
                  icono: Icons.add_location,
                  texto: 'Crear Nueva\nEstación',
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
                  icono: Icons.qr_code,
                  texto: 'Gestionar\nCódigos QR',
                  color: Coloressito.badgeBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const GeneradorQRScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Botones secundarios
          Row(
            children: [
              Expanded(
                child: _buildBotonAccion(
                  context: context,
                  icono: Icons.qr_code_2,
                  texto: 'Generar QR\nFaltantes',
                  color: Coloressito.badgeYellow,
                  onTap: () => _generarQRParaEstacionesExistentes(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBotonAccion(
                  context: context,
                  icono: Icons.people,
                  texto: 'Gestionar\nUsuarios',
                  color: Coloressito.badgeGreen,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UserManagementScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Botón para gestión de insignias
          Row(
            children: [
              Expanded(
                child: _buildBotonAccion(
                  context: context,
                  icono: Icons.emoji_events,
                  texto: 'Gestionar\nInsignias',
                  color: Coloressito.badgeBlue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const InsigniasAdminScreen(),
                    ),
                  ),
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
              Icon(Icons.analytics, color: Coloressito.badgeBlue, size: 24),
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
            style: TextStyle(color: Coloressito.textSecondary, fontSize: 14),
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
            Icon(icono, color: color, size: 32),
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
