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
// services are used by other admin screens; keep imports minimal here

/// Acceso a todas las funcionalidades de admin (protegido por roles)
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  // QR management helpers removed from AdminScreen; functionality kept in tools/services.

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
              // Welcome + summary row (moved above the management buttons)
              _buildWelcomeCard(context),
              const SizedBox(height: 20),

              // Top management cards (like the design attachment)
              _buildTopGestiones(context),
              const SizedBox(height: 20),

              // Two-column area: Acciones Rápidas | Actividad Reciente
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

              // Estadísticas (reuse previous section)
              _buildSeccionEstadisticas(),
              const SizedBox(height: 16),
              // Tabla de gestión de estaciones removed from home — use the
              // "Gestión Estación" card to navigate to the dedicated view.
            ],
          ),
        ),
      ),
    );
  }

  /// Top management cards (Estación, Insignia, Usuarios)
  Widget _buildTopGestiones(BuildContext context) {
    return const ManagementCardsRow();
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return const WelcomeSummary();
  }

  // _statCard removed; stats widget moved to `WelcomeSummary` in widgets.

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

  // _actividadStream removed; activity feed is provided by `ActividadRecienteWidget`.

  // Header and sections refactored into widgets under lib/admin/widgets

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

  // Decorative helper removed; cards and buttons are provided by widgets.
}
