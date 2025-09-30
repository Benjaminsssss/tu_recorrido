import 'package:flutter/material.dart';
import '../models/estacion_visitada.dart';
import '../services/coleccion_service.dart';
import '../utils/colores.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/estadisticas_progreso.dart';
import '../widgets/lista_estaciones.dart';
import '../widgets/pantalla_base.dart';

/// vista que muestra la coleccion de "estaciones" que visito el usuario
/// en pocas palabras es un pasaporte virtual
class ColeccionScreen extends StatefulWidget {
  const ColeccionScreen({super.key});

  @override
  State<ColeccionScreen> createState() => _ColeccionScreenState();
}

class _ColeccionScreenState extends State<ColeccionScreen> {
  List<EstacionVisitada> _estacionesVisitadas = [];
  Map<String, int> _estadisticas = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Cargar estaciones visitadas y descripción
  Future<void> _cargarDatos() async {
    try {
      final estaciones = await ColeccionService.obtenerEstacionesVisitadas();
      final stats = await ColeccionService.obtenerEstadisticas();
      
      if (mounted) {
        setState(() {
          _estacionesVisitadas = estaciones;
          _estadisticas = stats;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        _mostrarError('Error al cargar colección: $e');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Coloressito.badgeRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitadas = _estadisticas['visitadas'] ?? 0;
    final total = _estadisticas['total'] ?? 0;
    final porcentaje = _estadisticas['porcentaje'] ?? 0;

    return PantallaBase(
      titulo: 'Mi Colección',
      mostrarCargando: _cargando,
      onRefresh: _cargarDatos,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas generales
          EstadisticasProgreso(
            visitadas: visitadas,
            total: total,
            porcentaje: porcentaje,
          ),
          
          const SizedBox(height: 24),
          
          // Lista de estaciones visitadas
          const Text(
            'Estaciones Visitadas',
            style: TextStyle(
              color: Coloressito.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (_estacionesVisitadas.isEmpty)
            const EstadoVacio.coleccionVacia()
          else
            ListaEstaciones(estaciones: _estacionesVisitadas),
        ],
      ),
    );
  }


}