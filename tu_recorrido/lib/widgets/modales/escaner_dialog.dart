import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/estacion.dart';
import 'package:tu_recorrido/services/places/coleccion_service.dart';
import 'package:tu_recorrido/utils/theme/colores.dart';

/// Dialog para ingresar código QR manualmente
class DialogCodigoQR extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onValidar;

  const DialogCodigoQR({
    super.key,
    required this.controller,
    required this.onValidar,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Coloressito.surfaceDark,
      title: const Text(
        'Código QR Detectado',
        style: TextStyle(color: Coloressito.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ingresa el código de la estación:',
            style: TextStyle(color: Coloressito.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: const TextStyle(color: Coloressito.textPrimary),
            decoration: InputDecoration(
              hintText: 'Ej: PLAZA_ARMAS_001',
              hintStyle: const TextStyle(color: Coloressito.textMuted),
              filled: true,
              fillColor: Coloressito.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Coloressito.borderLight),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            controller.clear();
          },
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Coloressito.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onValidar(controller.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Coloressito.adventureGreen,
          ),
          child: const Text(
            'Validar',
            style: TextStyle(color: Coloressito.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Dialog para mostrar información de estación encontrada
class DialogEstacionEncontrada extends StatelessWidget {
  final Estacion estacion;
  final VoidCallback onMarcarVisitada;

  const DialogEstacionEncontrada({
    super.key,
    required this.estacion,
    required this.onMarcarVisitada,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Coloressito.surfaceDark,
      title: Row(
        children: [
          Icon(Icons.celebration, color: Coloressito.badgeYellow, size: 28),
          const SizedBox(width: 8),
          const Text(
            '¡Estación Encontrada!',
            style: TextStyle(color: Coloressito.textPrimary),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEncabezadoEstacion(),
          const SizedBox(height: 12),
          _buildDescripcion(),
          const SizedBox(height: 12),
          _buildUbicacion(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: Coloressito.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onMarcarVisitada();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Coloressito.adventureGreen,
          ),
          child: const Text(
            'Marcar como Visitada',
            style: TextStyle(color: Coloressito.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildEncabezadoEstacion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: Coloressito.buttonGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            estacion.nombre,
            style: const TextStyle(
              color: Coloressito.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Código: ${estacion.codigo}',
            style: const TextStyle(
              color: Coloressito.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescripcion() {
    return Text(
      estacion.descripcion,
      style: const TextStyle(
        color: Coloressito.textSecondary,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildUbicacion() {
    return Row(
      children: [
        Icon(Icons.location_on, color: Coloressito.adventureGreen, size: 16),
        const SizedBox(width: 4),
        Text(
          '${estacion.latitud.toStringAsFixed(4)}, ${estacion.longitud.toStringAsFixed(4)}',
          style: const TextStyle(color: Coloressito.textMuted, fontSize: 12),
        ),
      ],
    );
  }

}

/// Servicio helper para manejar las acciones del escáner
class EscanerHelper {
  /// Marcar estación como visitada con manejo de ubicación
  static Future<void> marcarComoVisitada(
    Estacion estacion,
    Function(String, Color) mostrarMensaje,
  ) async {
    try {
      // Obtener ubicación actual del usuario (opcional)
      Position? posicion;
      try {
        posicion = await Geolocator.getCurrentPosition();
      } catch (e) {
        // No importa si no se puede obtener la ubicación
        debugPrint('No se pudo obtener ubicación: $e');
      }

      // Marcar como visitada en Firestore
      await ColeccionService.marcarComoVisitada(
        estacion,
        latitudUsuario: posicion?.latitude,
        longitudUsuario: posicion?.longitude,
      );

      mostrarMensaje(
        '¡${estacion.nombre} agregada a tu colección!',
        Coloressito.adventureGreen,
      );

      // Vibración de éxito
      HapticFeedback.mediumImpact();
    } catch (e) {
      mostrarMensaje('Error: $e', Coloressito.badgeRed);
    }
  }

  /// Mostrar mensaje en SnackBar
  static void mostrarMensaje(
    BuildContext context,
    String mensaje,
    Color color,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: color));
  }
}
