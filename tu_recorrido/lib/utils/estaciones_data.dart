import 'package:flutter/foundation.dart';
import '../models/estacion.dart';
import '../services/estacion_service.dart';

/// Datos de ejemplo para estaciones patrimoniales de Santiago
/// testing
class EstacionesData {
  
  /// Lista de estaciones patrimoniales importantes de Santiago
  static final List<Map<String, dynamic>> estacionesEjemplo = [
    {
      'nombre': 'Plaza de Armas',
      'descripcion': 'Corazón histórico de Santiago, fundada en 1541 por Pedro de Valdivia. Punto central de la ciudad colonial.',
      'latitud': -33.4372,
      'longitud': -70.6506,
    },
    {
      'nombre': 'Catedral Metropolitana',
      'descripcion': 'Principal templo católico de Chile, construida entre 1748 y 1800. Sede del Arzobispado de Santiago.',
      'latitud': -33.4366,
      'longitud': -70.6502,
    },
    {
      'nombre': 'Palacio de La Moneda',
      'descripcion': 'Sede del gobierno de Chile desde 1846. Edificio neoclásico construido entre 1784 y 1805.',
      'latitud': -33.4429,
      'longitud': -70.6544,
    },
    {
      'nombre': 'Cerro Santa Lucía',
      'descripcion': 'Cerro histórico donde Pedro de Valdivia fundó Santiago en 1541. Transformado en parque urbano por Benjamín Vicuña Mackenna.',
      'latitud': -33.4406,
      'longitud': -70.6427,
    },
    {
      'nombre': 'Teatro Municipal',
      'descripcion': 'Principal centro de artes escénicas de Chile, inaugurado en 1857. Obra maestra de la arquitectura neoclásica.',
      'latitud': -33.4356,
      'longitud': -70.6434,
    },
    {
      'nombre': 'Mercado Central',
      'descripcion': 'Mercado histórico construido en 1872, famoso por su arquitectura de hierro forjado y su gastronomía típica.',
      'latitud': -33.4302,
      'longitud': -70.6500,
    },
    {
      'nombre': 'Barrio Lastarria',
      'descripcion': 'Barrio bohemio y cultural, declarado Zona Típica en 1997. Centro de la vida artística y gastronómica de Santiago.',
      'latitud': -33.4372,
      'longitud': -70.6394,
    },
    {
      'nombre': 'Iglesia San Francisco',
      'descripcion': 'Iglesia más antigua de Santiago, construida entre 1586 y 1628. Único edificio colonial que sobrevive en el centro.',
      'latitud': -33.4419,
      'longitud': -70.6459,
    },
  ];

  /// Crear todas las estaciones Firestore
  static Future<void> crearEstacionesEjemplo() async {
    try {
      debugPrint('Creando estaciones de ejemplo...');
      
      for (final data in estacionesEjemplo) {
        final codigo = EstacionService.generarCodigo(data['nombre']);
        
        final estacion = Estacion(
          id: '', // Se genera automáticamente
          codigo: codigo,
          nombre: data['nombre'],
          descripcion: data['descripcion'],
          latitud: data['latitud'],
          longitud: data['longitud'],
          fechaCreacion: DateTime.now(),
        );

        await EstacionService.crearEstacion(estacion);
        debugPrint('Creada: ${estacion.nombre} ($codigo)');
        
        // Pequeña pausa para no saturar Firestore
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      debugPrint('Todas las estaciones de ejemplo fueron creadas exitosamente');
      
    } catch (e) {
      debugPrint('Error creando estaciones: $e');
      rethrow;
    }
  }

  /// Obtener códigos QR de ejemplo para testing
  static List<String> obtenerCodigosEjemplo() {
    return [
      'PLAZA_ARMAS_001',
      'CATEDRAL_METROPOLITANA_002',
      'PALACIO_MONEDA_003',
      'CERRO_SANTA_LUCIA_004',
      'TEATRO_MUNICIPAL_005',
      'MERCADO_CENTRAL_006',
      'BARRIO_LASTARRIA_007',
      'IGLESIA_SAN_FRANCISCO_008',
    ];
  }

  /// Generar códigos QR simulados (para testing)
  static String generarCodigoQRSimulado(String nombreEstacion) {
    return EstacionService.generarCodigo(nombreEstacion);
  }

  /// Crear solo UNA estación de prueba (Plaza de Armas)
  static Future<void> crearEstacionPrueba() async {
    try {
      debugPrint('Creando estación de prueba...');
      
      final codigo = EstacionService.generarCodigo('Plaza de Armas');
      
      final estacion = Estacion(
        id: '', // Se genera automáticamente
        codigo: codigo,
        nombre: 'Plaza de Armas',
        descripcion: 'Corazón histórico de Santiago, fundada en 1541 por Pedro de Valdivia. Punto central de la ciudad colonial.',
        latitud: -33.4372,
        longitud: -70.6506,
        fechaCreacion: DateTime.now(),
      );

      await EstacionService.crearEstacion(estacion);
      debugPrint('Estación creada: Plaza de Armas (Código: $codigo)');
      debugPrint('¡Usa este código en el escáner QR: $codigo');
      
    } catch (e) {
      debugPrint('Error creando estación: $e');
      rethrow;
    }
  }
}