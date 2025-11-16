import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/estacion.dart';
import '../../services/estacion_service.dart';
import '../../utils/colores.dart';
import 'package:tu_recorrido/widgets/base/pantalla_base.dart';

/// Pantalla para generar y mostrar códigos QR de estaciones
/// Permite a los administradores ver y descargar QR de lugares
class GeneradorQRScreen extends StatefulWidget {
  const GeneradorQRScreen({super.key});

  @override
  State<GeneradorQRScreen> createState() => _GeneradorQRScreenState();
}

class _GeneradorQRScreenState extends State<GeneradorQRScreen> {
  List<Estacion> _estaciones = [];
  bool _cargando = true;
  Estacion? _estacionSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarEstaciones();
  }

  Future<void> _cargarEstaciones() async {
    if (!mounted) return;

    try {
      final estaciones = await EstacionService.obtenerEstacionesActivas();
      if (mounted) {
        setState(() {
          _estaciones = estaciones;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estaciones: $e'),
            backgroundColor: Coloressito.badgeRed,
          ),
        );
      }
    }
  }

  Future<void> _generarQRParaTodasEstaciones() async {
    try {
      await EstacionService.generarQRParaEstacionesExistentes();
      await _cargarEstaciones(); // Recargar para mostrar los nuevos QR

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Códigos QR generados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar QR: $e'),
            backgroundColor: Coloressito.badgeRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Generador QR - Admin',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _cargarEstaciones,
          tooltip: 'Recargar estaciones',
        ),
        IconButton(
          icon: const Icon(Icons.qr_code_2),
          onPressed: _generarQRParaTodasEstaciones,
          tooltip: 'Generar QR para todas las estaciones',
        ),
      ],
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con información
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Coloressito.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings,
                            color: Coloressito.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Panel de Administrador',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Total estaciones: ${_estaciones.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de estaciones
                  _buildListaEstaciones(),

                  // Mostrar QR seleccionado
                  if (_estacionSeleccionada != null)
                    _buildVistaQR(_estacionSeleccionada!),
                ],
              ),
            ),
    );
  }

  Widget _buildListaEstaciones() {
    if (_estaciones.isEmpty) {
      return SizedBox(
        height: 200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No hay estaciones disponibles',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: _estacionSeleccionada != null ? 300 : 500,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _estaciones.length,
        itemBuilder: (context, index) {
          final estacion = _estaciones[index];
          final tieneQR = estacion.codigoQR.isNotEmpty;

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tieneQR
                      ? Coloressito.adventureGreen
                          .withAlpha((0.08 * 255).round())
                      : Colors.orange.withAlpha((0.08 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tieneQR ? Icons.qr_code : Icons.qr_code_scanner,
                  color: tieneQR ? Coloressito.adventureGreen : Colors.orange,
                ),
              ),
              title: Text(
                estacion.nombre,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // QR line highlighted in a subtle rounded box to make it stand out
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: tieneQR
                          ? Coloressito.surfaceLight
                          : Colors.orange.withAlpha((0.06 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Coloressito.borderLight),
                    ),
                    child: Text(
                      tieneQR ? 'QR: ${estacion.codigoQR}' : 'Sin código QR',
                      style: TextStyle(
                        color: tieneQR ? Colors.black87 : Colors.orange,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ID: ${estacion.codigo}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              trailing: tieneQR
                  ? const Icon(Icons.visibility, color: Colors.blue)
                  : const Icon(Icons.warning, color: Colors.orange),
              onTap: tieneQR
                  ? () => setState(() => _estacionSeleccionada = estacion)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVistaQR(Estacion estacion) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header de la estación — usar fondo claro y texto oscuro para legibilidad
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Coloressito.borderLight),
            ),
            child: Column(
              children: [
                Text(
                  estacion.nombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // QR code text inside a highlighted pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Coloressito.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Coloressito.borderLight),
                  ),
                  child: Text(
                    'Código QR: ${estacion.codigoQR}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Código QR
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: QrImageView(
                data: estacion.codigoQR,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
                backgroundColor: Colors.white,
                errorStateBuilder: (cxt, err) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.error, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text(
                          'Error al generar QR',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // opcional: Implementar compartir QR
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función de compartir próximamente'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // opcional: Implementar descargar QR
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Función de descarga próximamente'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
