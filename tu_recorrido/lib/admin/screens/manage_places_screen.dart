import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/colores.dart';
import '../../widgets/pantalla_base.dart';
import '../../widgets/role_protected_widget.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class ManagePlacesScreen extends StatefulWidget {
  const ManagePlacesScreen({super.key});

  @override
  State<ManagePlacesScreen> createState() => _ManagePlacesScreenState();
}

class _ManagePlacesScreenState extends State<ManagePlacesScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _loadingUpload = false;

  Future<void> _uploadForPlace(String placeId) async {
    // Permitir seleccionar múltiples imágenes, respetando el límite de 5 por place
    final List<XFile>? pickedList = await _picker.pickMultiImage(imageQuality: 82);
    if (pickedList == null || pickedList.isEmpty) return;

    setState(() => _loadingUpload = true);
  try {
      // Obtener el documento actual para conocer cuántas imágenes ya hay
  final existing = await FirestoreService.instance.getPlaceImages(placeId);
      final availableSlots = 5 - existing.length;
      if (availableSlots <= 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya hay 5 imágenes, elimina alguna antes de subir más')));
        return;
      }

      // Si escogió más de lo permitido, recortar la lista
      final toUpload = pickedList.take(availableSlots).toList();

      for (var idx = 0; idx < toUpload.length; idx++) {
        final picked = toUpload[idx];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = kIsWeb ? _getExt(picked.name) : _getExt(picked.path);
        final path = 'places/$placeId/img_$timestamp$ext';

        String url;
        if (kIsWeb) {
          // En web, leer bytes y subir
          final bytes = await picked.readAsBytes();
          url = await StorageService.instance.uploadBytes(bytes, path, contentType: 'image/jpeg');
        } else {
          final file = File(picked.path);
          url = await StorageService.instance.uploadFile(file, path, contentType: 'image/jpeg');
        }
        // Añadir como nuevo elemento en el array 'imagenes' incluyendo la ruta en Storage
    final imageObj = {'url': url, 'alt': '', 'path': path};
    await FirestoreService.instance.addPlaceImage(placeId: placeId, image: imageObj);
      }

      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imágenes subidas y asignadas al lugar')));
      }
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: Coloressito.badgeRed));
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
        titulo: 'Gestionar Lugares',
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirestoreService.instance.watchPlaces(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No hay lugares registrados'));
            }

            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final doc = docs[i];
                final d = doc.data();
                final title = d['name']?.toString() ?? '—';
                final placeId = doc.id;
                final List<dynamic> imgsRaw = (d['imagenes'] as List<dynamic>?) ?? [];
                final images = imgsRaw.cast<Map<String, dynamic>>();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Coloressito.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Text('ID: $placeId', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Miniaturas horizontales
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
                                        ? Image.network(url, width: 120, height: 84, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey, width: 120, height: 84))
                                        : Container(width: 120, height: 84, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.black38)),
                                  ),
                                  // Botones: eliminar, mover izquierda/derecha
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Material(
                                      color: Colors.black26,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      child: InkWell(
                                        // ignore: use_build_context_synchronously
                                        onTap: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Confirmar'),
                                              content: const Text('¿Eliminar esta imagen y su archivo en Storage?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
                                              ],
                                            ),
                                          );
                                          if (confirm != true) return;

                                          try {
                                            // Primero remover la referencia en Firestore
                                            await FirestoreService.instance.removePlaceImage(placeId: placeId, image: img);
                                            // Si tenemos 'path', borrar el archivo en Storage
                                            final path = img['path']?.toString();
                                            if (path != null && path.isNotEmpty) {
                                              try {
                                                await StorageService.instance.deleteFile(path);
                                              } catch (_) {
                                                // no fatal: si no se pudo borrar el archivo, seguimos
                                              }
                                            }
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagen eliminada')));
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando imagen: $e')));
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(20),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6.0),
                                          child: Icon(Icons.delete, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Row(
                                      children: [
                                        // Mover izquierda
                                        Material(
                                          color: Colors.black26,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          child: InkWell(
                                            onTap: () async {
                                              try {
                                                final current = await FirestoreService.instance.getPlaceImages(placeId);
                                                if (idx > 0) {
                                                  final List<Map<String, dynamic>> updated = List<Map<String, dynamic>>.from(current);
                                                  final tmp = updated[idx - 1];
                                                  updated[idx - 1] = updated[idx];
                                                  updated[idx] = tmp;
                                                  await FirestoreService.instance.setPlaceImages(placeId: placeId, images: updated);
                                                }
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reordenando: $e')));
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Icon(Icons.arrow_left, size: 18, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Mover derecha
                                        Material(
                                          color: Colors.black26,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          child: InkWell(
                                            onTap: () async {
                                              try {
                                                final current = await FirestoreService.instance.getPlaceImages(placeId);
                                                if (idx < current.length - 1) {
                                                  final List<Map<String, dynamic>> updated = List<Map<String, dynamic>>.from(current);
                                                  final tmp = updated[idx + 1];
                                                  updated[idx + 1] = updated[idx];
                                                  updated[idx] = tmp;
                                                  await FirestoreService.instance.setPlaceImages(placeId: placeId, images: updated);
                                                }
                                              } catch (e) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error reordenando: $e')));
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6.0),
                                              child: Icon(Icons.arrow_right, size: 18, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Último elemento = botón para subir nueva imagen
                            final canAdd = images.length < 5;
                            return Container(
                              width: 120,
                              height: 84,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: canAdd ? Colors.white : Colors.grey.shade200,
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Center(
                                child: _loadingUpload
                                    ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator())
                                    : IconButton(
                                        onPressed: canAdd ? () => _uploadForPlace(placeId) : null,
                                        icon: Icon(Icons.upload_file, color: canAdd ? Coloressito.adventureGreen : Colors.grey),
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
