// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
// dart:typed_data not required here
import 'package:tu_recorrido/models/insignia.dart';
import 'package:tu_recorrido/models/estacion.dart';
import 'package:tu_recorrido/services/insignia_service.dart';
import 'package:tu_recorrido/services/estacion_service.dart';
import 'package:tu_recorrido/services/coleccion_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// removed unused import
import 'package:tu_recorrido/admin/widgets/insignias_table.dart';

/// Pantalla básica de administración de insignias.
/// Esta pantalla provee un listado y un formulario simple para crear insignias.
class InsigniasAdminScreen extends StatefulWidget {
  const InsigniasAdminScreen({super.key});

  @override
  State<InsigniasAdminScreen> createState() => _InsigniasAdminScreenState();
}

class _InsigniasAdminScreenState extends State<InsigniasAdminScreen> {
  List<Insignia> _insignias = [];
  // removed unused loading flag (InsigniasTable handles its own loading)
  // Mapa para saber por insigniaId qué estación la tiene asignada
  final Map<String, Estacion> _estacionPorInsignia = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    // loading handled by InsigniasTable; skip local loading flag
    // debug: iniciar carga
    // ignore: avoid_print
    print('InsigniasAdminScreen._load: starting');
    final messenger = ScaffoldMessenger.of(context);
    try {
      _insignias = await InsigniaService.obtenerTodas();
      // debug: cantidad recibida
      debugPrint(
          'InsigniasAdminScreen._load: loaded ${_insignias.length} insignias');
      // Cargar estaciones y mapear por insigniaID
      try {
        final estaciones = await EstacionService.obtenerEstacionesActivas();
        _estacionPorInsignia.clear();
        for (final e in estaciones) {
          final ref = e.insigniaID;
          if (ref != null) {
            _estacionPorInsignia[ref.id] = e;
          }
        }
      } catch (e, st) {
        debugPrint('No se pudieron cargar estaciones: $e');
        debugPrint(st.toString());
      }
    } on FirebaseException catch (e) {
      // Handle Firestore permission errors or other Firebase exceptions
      _insignias = [];
      // debug: log mensaje de FirebaseException
      debugPrint(
          'InsigniasAdminScreen._load: FirebaseException -> ${e.message}');
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text('Error al cargar insignias: ${e.message}')));
      }
    } catch (e, st) {
      _insignias = [];
      // debug: log error y stacktrace
      debugPrint('InsigniasAdminScreen._load: unexpected error -> $e');
      debugPrint(st.toString());
      if (mounted) {
        messenger.showSnackBar(SnackBar(
            content: Text('Error inesperado al cargar insignias: $e')));
      }
    } finally {
      // no local loading state to update
    }
  }

  // _crearInsignia removed: InsigniasTable implements create flows

  Future<void> _migrarInsigniasExistentes() async {
    final messenger = ScaffoldMessenger.of(context);

    // Mostrar confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Migrar insignias existentes'),
        content: const Text(
            'Esto actualizará todas las estaciones que tienen insignias asignadas para que las insignias aparezcan correctamente en el Album de los usuarios.\n\n¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Migrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // no local loading state to update
      messenger.showSnackBar(
        const SnackBar(content: Text('Iniciando migración...')),
      );

      await InsigniaService.migrarInsigniasExistentes();

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Migración completada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Error en migración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // no local loading state to update
    }
  }

  Future<void> _eliminarVisitaPalacio() async {
    final messenger = ScaffoldMessenger.of(context);

    // Buscar el ID del Palacio de la Moneda
    String? palacioId;
    try {
      final estaciones = await EstacionService.obtenerEstacionesActivas();
      final palacio = estaciones
          .where((e) => e.nombre.toLowerCase().contains('palacio'))
          .firstOrNull;
      palacioId = palacio?.id;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text('Error buscando Palacio: $e'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (palacioId == null) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('No se encontró el Palacio de la Moneda'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    // Confirmar eliminación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar visita del Palacio'),
        content: const Text(
            '¿Eliminar la visita al Palacio de la Moneda para poder probar de nuevo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ColeccionService.eliminarVisitaTemporal(palacioId);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Visita del Palacio eliminada. Ya puedes escanear de nuevo.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Error eliminando visita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Insignias'),
        actions: [
          IconButton(
            onPressed: _migrarInsigniasExistentes,
            icon: const Icon(Icons.sync),
            tooltip: 'Migrar insignias existentes',
          ),
          IconButton(
            onPressed: _eliminarVisitaPalacio,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Eliminar visita del Palacio (testing)',
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: InsigniasTable(),
      ),
      // InsigniasTable includes its own create button
    );
  }
}
