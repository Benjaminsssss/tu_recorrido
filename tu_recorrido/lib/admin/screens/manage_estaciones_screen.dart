import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tu_recorrido/utils/theme/colores.dart';
import 'package:tu_recorrido/widgets/base/pantalla_base.dart';
import 'package:tu_recorrido/widgets/base/role_protected_widget.dart';
import 'package:tu_recorrido/services/infra/firestore_service.dart';
import 'package:tu_recorrido/services/storage/storage_service.dart';

class ManageEstacionesScreen extends StatefulWidget {
  const ManageEstacionesScreen({super.key});

  @override
  State<ManageEstacionesScreen> createState() => _ManageEstacionesScreenState();
}

class _ManageEstacionesScreenState extends State<ManageEstacionesScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _loadingUpload = false;

  Future<void> _uploadForEstacion(String estacionId) async {
    final pickedList = await _picker.pickMultiImage(imageQuality: 82);
    if (pickedList.isEmpty) {
      return;
    }

    setState(() => _loadingUpload = true);
    try {
      final existing =
          await FirestoreService.instance.getPlaceImages(estacionId);
      final availableSlots = 5 - existing.length;
      if (availableSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Ya hay 5 imágenes, elimina alguna antes de subir más')));
        }
        return;
      }

      final toUpload = pickedList.take(availableSlots).toList();

      for (var idx = 0; idx < toUpload.length; idx++) {
        final picked = toUpload[idx];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = kIsWeb ? _getExt(picked.name) : _getExt(picked.path);
        final path = 'estaciones/$estacionId/img_$timestamp$ext';

        String url;
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          url = await StorageService.instance
              .uploadBytes(bytes, path, contentType: 'image/jpeg');
        } else {
          final file = File(picked.path);
          url = await StorageService.instance
              .uploadFile(file, path, contentType: 'image/jpeg');
        }
        final imageObj = {'url': url, 'alt': '', 'path': path};
        await FirestoreService.instance
            .addPlaceImage(placeId: estacionId, image: imageObj);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Imágenes subidas y asignadas a la estación')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Coloressito.badgeRed));
      }
    } finally {
      if (mounted) setState(() => _loadingUpload = false);
    }
  }

  String _getExt(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(idx) : '.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return AdminProtectedWidget(
      child: PantallaBase(
        titulo: 'Gestionar Estaciones',
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.instance.watchEstaciones(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No hay estaciones registradas'));
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final d = doc.data();
                final title =
                    d['nombre']?.toString() ?? d['name']?.toString() ?? '—';
                final estacionId = doc.id;
                final List<dynamic> imgsRaw =
                    (d['imagenes'] as List<dynamic>?) ?? [];
                final images = imgsRaw.cast<Map<String, dynamic>>();

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          Text('ID: $estacionId',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            if (idx < images.length) {
                              final img = images[idx];
                              final url = img['url']?.toString();
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: url != null && url.isNotEmpty
                                        ? Image.network(url,
                                            width: 120,
                                            height: 84,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                    color: Colors.grey,
                                                    width: 120,
                                                    height: 84))
                                        : Container(
                                            width: 120,
                                            height: 84,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image,
                                                color: Colors.black38)),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Material(
                                      color: Colors.black26,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: InkWell(
                                        onTap: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Confirmar'),
                                              content: const Text(
                                                  '¿Eliminar esta imagen y su archivo en Storage?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(false),
                                                    child:
                                                        const Text('Cancelar')),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(ctx)
                                                            .pop(true),
                                                    child:
                                                        const Text('Eliminar')),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) return;
                                          if (!mounted) return;

                                          try {
                                            await FirestoreService.instance
                                                .removePlaceImage(
                                                    placeId: estacionId,
                                                    image: img);
                                            final path =
                                                img['path']?.toString();
                                            if (path != null &&
                                                path.isNotEmpty) {
                                              try {
                                                await StorageService.instance
                                                    .deleteFile(path);
                                              } catch (_) {}
                                            }
                                            if (!mounted) return;
                                            // ignore: use_build_context_synchronously
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Imagen eliminada')));
                                          } catch (e) {
                                            if (!mounted) return;
                                            // ignore: use_build_context_synchronously
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Error eliminando imagen: $e')));
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Icon(Icons.delete,
                                              size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Row(
                                      children: [
                                        Material(
                                          color: Colors.black26,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: InkWell(
                                            onTap: () async {
                                              try {
                                                final current =
                                                    await FirestoreService
                                                        .instance
                                                        .getPlaceImages(
                                                            estacionId);
                                                if (!mounted) return;
                                                if (idx > 0) {
                                                  final List<
                                                          Map<String, dynamic>>
                                                      updated = List<
                                                              Map<String,
                                                                  dynamic>>.from(
                                                          current);
                                                  final tmp = updated[idx - 1];
                                                  updated[idx - 1] =
                                                      updated[idx];
                                                  updated[idx] = tmp;
                                                  await FirestoreService
                                                      .instance
                                                      .setPlaceImages(
                                                          placeId: estacionId,
                                                          images: updated);
                                                }
                                              } catch (e) {
                                                if (!mounted) return;
                                                // ignore: use_build_context_synchronously
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            'Error reordenando: $e')));
                                              }
                                            },
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Icon(Icons.arrow_left,
                                                  size: 18,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Material(
                                          color: Colors.black26,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: InkWell(
                                            onTap: () async {
                                              try {
                                                final current =
                                                    await FirestoreService
                                                        .instance
                                                        .getPlaceImages(
                                                            estacionId);
                                                if (!mounted) return;
                                                if (idx < current.length - 1) {
                                                  final List<
                                                          Map<String, dynamic>>
                                                      updated = List<
                                                              Map<String,
                                                                  dynamic>>.from(
                                                          current);
                                                  final tmp = updated[idx + 1];
                                                  updated[idx + 1] =
                                                      updated[idx];
                                                  updated[idx] = tmp;
                                                  await FirestoreService
                                                      .instance
                                                      .setPlaceImages(
                                                          placeId: estacionId,
                                                          images: updated);
                                                }
                                              } catch (e) {
                                                if (!mounted) return;
                                                // ignore: use_build_context_synchronously
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            'Error reordenando: $e')));
                                              }
                                            },
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Icon(Icons.arrow_right,
                                                  size: 18,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            final canAdd = images.length < 5;
                            return Container(
                              width: 120,
                              height: 84,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: canAdd
                                    ? Colors.white
                                    : Colors.grey.shade200,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: _loadingUpload
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator())
                                    : IconButton(
                                        onPressed: canAdd
                                            ? () =>
                                                _uploadForEstacion(estacionId)
                                            : null,
                                        icon: Icon(Icons.upload_file,
                                            color: canAdd
                                                ? Coloressito.adventureGreen
                                                : Colors.grey),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
