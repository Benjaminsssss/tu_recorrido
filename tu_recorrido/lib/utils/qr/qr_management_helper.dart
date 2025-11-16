import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tu_recorrido/services/places/estacion_service.dart';
import 'package:tu_recorrido/services/qr/qr_service.dart';
import 'package:tu_recorrido/utils/logging/app_logger.dart';

/// Helper para generar códigos QR para estaciones existentes en Firestore
/// NO crea nuevas estaciones, solo actualiza las existentes con códigos QR
class QRManagementHelper {
  /// Generar códigos QR para todas las estaciones existentes que no tengan
  static Future<void> generarQRParaEstacionesExistentes() async {
    try {
      AppLogger.info('Buscando estaciones existentes en Firestore...');

      // Obtener todas las estaciones activas
      final estaciones = await EstacionService.obtenerEstacionesActivas();

      if (estaciones.isEmpty) {
        AppLogger.warning('No se encontraron estaciones en Firestore');
        return;
      }

      AppLogger.info('Encontradas ${estaciones.length} estaciones:');
      for (final estacion in estaciones) {
        AppLogger.info('  • ${estacion.nombre}');
      }
      AppLogger.info('');

      int actualizadas = 0;
      int yaConQR = 0;

      for (final estacion in estaciones) {
        try {
          // Verificar si ya tiene código QR
          if (estacion.codigoQR.isNotEmpty &&
              QRService.esCodigoValido(estacion.codigoQR)) {
            AppLogger.info(
                '${estacion.nombre} - Ya tiene QR válido: ${estacion.codigoQR}');
            yaConQR++;
            continue;
          }

          // Generar nuevo código QR
          final nuevoCodigoQR =
              QRService.generarCodigoQR(estacion.id, estacion.nombre);

          // Actualizar la estación en Firestore
          await FirebaseFirestore.instance
              .collection('estaciones')
              .doc(estacion.id)
              .update({'codigoQR': nuevoCodigoQR});

          AppLogger.info(
              '${estacion.nombre} - Nuevo QR generado: $nuevoCodigoQR');
          actualizadas++;
        } catch (e) {
          AppLogger.error('Error actualizando ${estacion.nombre}', e);
        }
      }

      AppLogger.info('');
      AppLogger.info('RESUMEN:');
      AppLogger.info('  • Total estaciones: ${estaciones.length}');
      AppLogger.info('  • Ya tenían QR: $yaConQR');
      AppLogger.info('  • QR generados: $actualizadas');
      AppLogger.info('');

      if (actualizadas > 0) {
        AppLogger.info('¡Códigos QR generados exitosamente!');
        await _mostrarTodosLosQR();
      } else {
        AppLogger.info('No se necesitaron actualizaciones');
      }
    } catch (e) {
      AppLogger.error('Error general', e);
    }
  }

  /// Mostrar todos los códigos QR existentes
  static Future<void> _mostrarTodosLosQR() async {
    try {
      AppLogger.info('');
      AppLogger.info('CÓDIGOS QR DISPONIBLES:');
      AppLogger.info('=' * 50);

      final estaciones = await EstacionService.obtenerEstacionesActivas();

      for (final estacion in estaciones) {
        if (estacion.codigoQR.isNotEmpty) {
          AppLogger.info('🏛️  ${estacion.nombre}');
          AppLogger.info('   QR: ${estacion.codigoQR}');
          AppLogger.info('   Código Legacy: ${estacion.codigo}');
          AppLogger.info('');
        }
      }
    } catch (e) {
      AppLogger.error('Error mostrando códigos', e);
    }
  }

  /// Verificar el estado de códigos QR de todas las estaciones
  static Future<void> verificarEstadoQR() async {
    try {
      AppLogger.info('Verificando estado de códigos QR...');
      AppLogger.info('');

      final estaciones = await EstacionService.obtenerEstacionesActivas();

      if (estaciones.isEmpty) {
        AppLogger.warning('No hay estaciones en Firestore');
        return;
      }

      int conQRValido = 0;
      int sinQR = 0;
      int conQRInvalido = 0;

      for (final estacion in estaciones) {
        if (estacion.codigoQR.isEmpty) {
          AppLogger.info('${estacion.nombre} - Sin código QR');
          sinQR++;
        } else if (QRService.esCodigoValido(estacion.codigoQR)) {
          AppLogger.info(
              '${estacion.nombre} - QR válido: ${estacion.codigoQR}');
          conQRValido++;
        } else {
          AppLogger.warning(
              '${estacion.nombre} - QR inválido: ${estacion.codigoQR}');
          conQRInvalido++;
        }
      }

      AppLogger.info('');
      AppLogger.info('ESTADO ACTUAL:');
      AppLogger.info('  • Con QR válido: $conQRValido');
      AppLogger.info('  • Sin QR: $sinQR');
      AppLogger.info('  • QR inválido: $conQRInvalido');
      AppLogger.info('  • Total: ${estaciones.length}');
    } catch (e) {
      AppLogger.error('Error verificando estado', e);
    }
  }

  /// Método helper para ejecutar desde la interfaz de admin
  static Future<Map<String, dynamic>> ejecutarDesdeAdmin() async {
    try {
      final estaciones = await EstacionService.obtenerEstacionesActivas();

      if (estaciones.isEmpty) {
        return {
          'success': false,
          'message': 'No se encontraron estaciones en Firestore',
          'total': 0,
          'updated': 0,
        };
      }

      int actualizadas = 0;

      for (final estacion in estaciones) {
        if (estacion.codigoQR.isEmpty ||
            !QRService.esCodigoValido(estacion.codigoQR)) {
          final nuevoCodigoQR =
              QRService.generarCodigoQR(estacion.id, estacion.nombre);

          await FirebaseFirestore.instance
              .collection('estaciones')
              .doc(estacion.id)
              .update({'codigoQR': nuevoCodigoQR});

          actualizadas++;
        }
      }

      return {
        'success': true,
        'message': 'Códigos QR generados exitosamente',
        'total': estaciones.length,
        'updated': actualizadas,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'total': 0,
        'updated': 0,
      };
    }
  }
}
