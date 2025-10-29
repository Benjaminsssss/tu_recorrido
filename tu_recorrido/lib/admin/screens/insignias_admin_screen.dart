                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// dart:typed_data not required here
import 'package:tu_recorrido/models/insignia.dart';
import 'package:tu_recorrido/services/insignia_service.dart';
import 'package:tu_recorrido/services/estacion_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tu_recorrido/utils/admin_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _otorgarInsignia(String insigniaId) async {
    final emailController = TextEditingController();
    final uidController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Otorgar insignia a usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (opcional)')),
            const SizedBox(height: 8),
            Text('O ingresa UID si no tienes email', style: Theme.of(context).textTheme.bodySmall),
            TextField(controller: uidController, decoration: const InputDecoration(labelText: 'UID (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final uid = uidController.text.trim();
              if (email.isEmpty && uid.isEmpty) return;

              Navigator.of(context).pop();

              String? targetUid = uid.isNotEmpty ? uid : null;

              if (targetUid == null && email.isNotEmpty) {
                // Buscar usuario por email
                final query = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

                  if (query.docs.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no encontrado por email')));
                    }
                    return;
                  }

                targetUid = query.docs.first.id;
              }

              try {
                await InsigniaService.otorgarInsigniaAUsuario(userId: targetUid!, insigniaId: insigniaId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insignia otorgada')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al otorgar insignia: $e')));
                }
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
    try {
      _insignias = await InsigniaService.obtenerTodas();
    } on FirebaseException catch (e) {
      // Handle Firestore permission errors or other Firebase exceptions
      _insignias = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar insignias: ${e.message}')));
      }
    } catch (e) {
      _insignias = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error inesperado al cargar insignias: $e')));
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
      builder: (_) => AlertDialog(
        title: const Text('Crear insignia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreController, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: descripcionController, decoration: const InputDecoration(labelText: 'Descripcion')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              final descripcion = descripcionController.text.trim();
              if (nombre.isEmpty || descripcion.isEmpty) return;

              Navigator.of(context).pop();

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
    // Cargar estaciones disponibles
    final estaciones = await EstacionService.obtenerEstacionesActivas();

    String? estacionSeleccionadaId;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (estacionSeleccionadaId == null) return;
              Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Insignias')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_insignias.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No hay insignias creadas aún', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 28),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      title: Text(ins.nombre),
                      subtitle: Text(ins.descripcion),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
