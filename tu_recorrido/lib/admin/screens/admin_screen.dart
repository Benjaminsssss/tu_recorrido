import 'package:flutter/material.dart';
import 'package:tu_recorrido/utils/theme/colores.dart';
import 'package:tu_recorrido/widgets/base/pantalla_base.dart';
import 'package:tu_recorrido/widgets/base/role_protected_widget.dart';
import '../widgets/management_cards_row.dart';
import '../widgets/welcome_summary.dart';
import '../widgets/acciones_rapidas.dart';
import '../widgets/actividad_reciente.dart';
import 'crear_estacion.dart';
import 'generador_qr_screen.dart';
import 'manage_estaciones_screen.dart';

/// Acceso a todas las funcionalidades de admin (protegido por roles)
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminProtectedWidget(
      child: PantallaBase(
        titulo: 'Panel de Administración',
        backgroundColor: Colors.white,
        appBarBackgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fila de bienvenida + resumen de estadisticas
              _buildWelcomeCard(context),
              const SizedBox(height: 20),

              // Tarjetas de gestión principales (como en el diseño adjunto)
              _buildTopGestiones(context),
              const SizedBox(height: 20),

              // Área de dos columnas: Acciones Rápidas | Actividad Reciente
              LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAccionesRapidas(context)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildActividadReciente(context)),
                    ],
                  );
                }

                return Column(
                  children: [
                    _buildAccionesRapidas(context),
                    const SizedBox(height: 12),
                    _buildActividadReciente(context),
                  ],
                );
              }),
              const SizedBox(height: 16),

              // Estadísticas 
              _buildSeccionEstadisticas(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjetas de gestión principales (Estación, Insignia, Usuarios)
  Widget _buildTopGestiones(BuildContext context) {
    return const ManagementCardsRow();
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return const WelcomeSummary();
  }

  // Área de acciones rápidas

  Widget _buildAccionesRapidas(BuildContext context) {
    return AccionesRapidasWidget(
      onShowQR: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const GeneradorQRScreen())),
      onViewUserVisits: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ManageEstacionesScreen())),
      onCreateStation: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CrearEstacionScreen())),
    );
  }

  Widget _buildActividadReciente(BuildContext context) {
    return const ActividadRecienteWidget();
  }

  // seccion de estadisticas generales

  Widget _buildSeccionEstadisticas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
}
