// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// dart:typed_data not required here
import 'package:tu_recorrido/models/insignia.dart';
import 'package:tu_recorrido/models/estacion.dart';
import 'package:tu_recorrido/services/insignia_service.dart';
import 'package:tu_recorrido/services/estacion_service.dart';
import 'package:tu_recorrido/services/coleccion_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

/// Pantalla básica de administración de insignias.
/// Esta pantalla provee un listado y un formulario simple para crear insignias.
class InsigniasAdminScreen extends StatefulWidget {
  const InsigniasAdminScreen({super.key});

  @override
  State<InsigniasAdminScreen> createState() => _InsigniasAdminScreenState();
}

class _InsigniasAdminScreenState extends State<InsigniasAdminScreen> {
  List<Insignia> _insignias = [];
  bool _loading = true;
  // Mapa para saber por insigniaId qué estación la tiene asignada
  final Map<String, Estacion> _estacionPorInsignia = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _otorgarInsignia(String insigniaId) async {
    final messenger = ScaffoldMessenger.of(context);
    final emailController = TextEditingController();
    final uidController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Otorgar insignia a usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: emailController,
                decoration:
                    const InputDecoration(labelText: 'Email (opcional)')),
            const SizedBox(height: 8),
            Text('O ingresa UID si no tienes email',
                style: Theme.of(dialogContext).textTheme.bodySmall),
            TextField(
                controller: uidController,
                decoration: const InputDecoration(labelText: 'UID (opcional)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final uid = uidController.text.trim();
              if (email.isEmpty && uid.isEmpty) return;

              Navigator.of(dialogContext).pop();

              String? targetUid = uid.isNotEmpty ? uid : null;

              if (targetUid == null && email.isNotEmpty) {
                // Buscar usuario por email
                final query = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

                if (query.docs.isEmpty) {
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Usuario no encontrado por email')));
                  return;
                }

                targetUid = query.docs.first.id;
              }

              try {
                await InsigniaService.otorgarInsigniaAUsuario(
                    userId: targetUid!, insigniaId: insigniaId);
                if (!mounted) return;
                messenger.showSnackBar(
                    const SnackBar(content: Text('Insignia otorgada')));
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                    SnackBar(content: Text('Error al otorgar insignia: $e')));
              }
            },
            child: const Text('Otorgar'),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // debug: iniciar carga
    // ignore: avoid_print
    print('InsigniasAdminScreen._load: starting');
    // Capture ScaffoldMessenger before any await to avoid using BuildContext
    // after async gaps (prevents use_build_context_synchronously info).
    final messenger = ScaffoldMessenger.of(context);
    try {
      _insignias = await InsigniaService.obtenerTodas();
      // debug: cantidad recibida
      // ignore: avoid_print
      print(
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
        // ignore: avoid_print
        print('No se pudieron cargar estaciones: $e');
        // ignore: avoid_print
        print(st);
      }
    } on FirebaseException catch (e) {
      // Handle Firestore permission errors or other Firebase exceptions
      _insignias = [];
      // debug: log mensaje de FirebaseException
      // ignore: avoid_print
      print('InsigniasAdminScreen._load: FirebaseException -> ${e.message}');
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text('Error al cargar insignias: ${e.message}')));
      }
    } catch (e, st) {
      _insignias = [];
      // debug: log error y stacktrace
      // ignore: avoid_print
      print('InsigniasAdminScreen._load: unexpected error -> $e');
      // ignore: avoid_print
      print(st);
      if (mounted) {
        messenger.showSnackBar(SnackBar(
            content: Text('Error inesperado al cargar insignias: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _crearInsignia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final nombreController = TextEditingController();
    final descripcionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Crear insignia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: 'Descripcion')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              final descripcion = descripcionController.text.trim();
              if (nombre.isEmpty || descripcion.isEmpty) return;

              Navigator.of(dialogContext).pop();

              // En web usamos bytes; en mobile/desktop usamos File
              if (kIsWeb) {
                final bytes = await picked.readAsBytes();
                await InsigniaService.createInsigniaWithImage(
                  imageBytes: bytes,
                  fileName: picked.name,
                  nombre: nombre,
                  descripcion: descripcion,
                );
              } else {
                final file = File(picked.path);
                await InsigniaService.createInsigniaWithImage(
                  imageFile: file,
                  nombre: nombre,
                  descripcion: descripcion,
                );
              }

              await _load();
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _asignarInsignia(String insigniaId) async {
    // Cargar estaciones disponibles: sólo las que no tienen insignia asignada
    final todas = await EstacionService.obtenerEstacionesActivas();
    final estaciones = todas.where((e) => e.insigniaID == null).toList();

    // Si no hay estaciones libres, informar al admin
    if (estaciones.isEmpty) {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Asignar insignia a estación'),
          content: const Text(
              'No hay estaciones disponibles sin una insignia asignada.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Aceptar'))
          ],
        ),
      );
      return;
    }

    String? estacionSeleccionadaId;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Asignar insignia a estación'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: estaciones.length,
            itemBuilder: (context, i) {
              final e = estaciones[i];
              return RadioListTile<String>(
                title: Text(e.nombre),
                subtitle: Text(e.codigo),
                value: e.id,
                groupValue: estacionSeleccionadaId,
                onChanged: (v) => setState(() => estacionSeleccionadaId = v),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (estacionSeleccionadaId == null) return;
              Navigator.of(dialogContext).pop();
              // Actualizar estación con referencia a la insignia
              await InsigniaService.assignInsigniaToEstacion(
                  insigniaId: insigniaId, estacionId: estacionSeleccionadaId!);
              await _load();
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

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
      setState(() => _loading = true);
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
      if (mounted) {
        setState(() => _loading = false);
      }
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_insignias.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No hay insignias creadas aún',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _crearInsignia,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear primera insignia'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _insignias.length,
                  itemBuilder: (context, i) {
                    final ins = _insignias[i];
                    return ListTile(
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ins.imagenUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            // If image fails (CORS or network), show a gray placeholder instead
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.broken_image,
                                        color: Colors.grey, size: 28),
                                    const SizedBox(height: 6),
                                    TextButton.icon(
                                      icon: const Icon(Icons.open_in_new,
                                          size: 16),
                                      label: const Text('Abrir URL'),
                                      onPressed: () {
                                        // Mostrar diálogo con la URL y opción de copiar
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) =>
                                              AlertDialog(
                                            title:
                                                const Text('URL de la imagen'),
                                            content:
                                                SelectableText(ins.imagenUrl),
                                            actions: [
                                              TextButton(
                                                  onPressed: () async {
                                                    // Capture navigator before the async gap to avoid using
                                                    // the dialog BuildContext after an await.
                                                    final navigator =
                                                        Navigator.of(
                                                            dialogContext);
                                                    await Clipboard.setData(
                                                      ClipboardData(
                                                        text: ins.imagenUrl,
                                                      ),
                                                    );
                                                    navigator.pop();
                                                    if (!mounted) return;
                                                    messenger.showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'URL copiada al portapapeles'),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text('Copiar')),
                                              TextButton(
                                                  onPressed: () => Navigator.of(
                                                          dialogContext)
                                                      .pop(),
                                                  child: const Text('Cerrar')),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      title: Text(ins.nombre),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ins.descripcion),
                          const SizedBox(height: 6),
                          if (_estacionPorInsignia.containsKey(ins.id))
                            Row(
                              children: [
                                const Icon(Icons.place,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                    'Asignada a: ${_estacionPorInsignia[ins.id]!.nombre}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mostrar botón de asignar sólo si la insignia no está ya asignada
                          if (!_estacionPorInsignia.containsKey(ins.id))
                            IconButton(
                              icon: const Icon(Icons.link),
                              tooltip: 'Asignar a estación',
                              onPressed: () async {
                                await _asignarInsignia(ins.id);
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.emoji_events),
                            tooltip: 'Otorgar a usuario',
                            onPressed: () async {
                              await _otorgarInsignia(ins.id);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever),
                            onPressed: () async {
                              await InsigniaService.deleteInsignia(ins.id);
                              await _load();
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // TODO: Abrir detalle/editar y asignar a estación desde aquí (implementación futura)
                      },
                    );
                  },
                )),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearInsignia,
        child: const Icon(Icons.add),
      ),
    );
  }
}
