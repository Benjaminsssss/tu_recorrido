import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/colores.dart';

class EstacionImageManagerDialog extends StatefulWidget {
  final String estacionId;

  const EstacionImageManagerDialog({super.key, required this.estacionId});

  @override
  State<EstacionImageManagerDialog> createState() =>
      _EstacionImageManagerDialogState();
}

class _EstacionImageManagerDialogState
    extends State<EstacionImageManagerDialog> {
  bool _loading = true;
  bool _uploading = false;
  List<Map<String, dynamic>> _images = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _loading = true);
    try {
      final imgs =
          await FirestoreService.instance.getPlaceImages(widget.estacionId);
      if (mounted) {
        setState(() => _images = imgs.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cargando imágenes: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _uploadImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 82);
    if (picked.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final existing =
          await FirestoreService.instance.getPlaceImages(widget.estacionId);
      final available = 5 - existing.length;
      if (available <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Ya hay 5 imágenes. Elimina alguna antes de subir.')));
        }
        return;
      }

      final toUpload = picked.take(available).toList();

      for (var p in toUpload) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ext = kIsWeb ? _getExt(p.name) : _getExt(p.path);
        final path = 'estaciones/${widget.estacionId}/img_$timestamp$ext';
        String url;
        if (kIsWeb) {
          final bytes = await p.readAsBytes();
          url = await StorageService.instance
              .uploadBytes(bytes, path, contentType: 'image/jpeg');
        } else {
          final file = File(p.path);
          url = await StorageService.instance
              .uploadFile(file, path, contentType: 'image/jpeg');
        }
        final imageObj = {'url': url, 'alt': '', 'path': path};
        await FirestoreService.instance
            .addPlaceImage(placeId: widget.estacionId, image: imageObj);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imágenes subidas correctamente')));
        await _loadImages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error subiendo imágenes: $e'),
            backgroundColor: Coloressito.badgeRed));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  String _getExt(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(idx) : '.jpg';
  }

  Future<void> _removeImage(Map<String, dynamic> img) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Confirmar'),
              content:
                  const Text('¿Eliminar esta imagen y su archivo en Storage?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar')),
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Eliminar')),
              ],
            ));
    if (confirm != true) {
      return;
    }

    try {
      await FirestoreService.instance
          .removePlaceImage(placeId: widget.estacionId, image: img);
      final path = img['path']?.toString();
      if (path != null && path.isNotEmpty) {
        try {
          await StorageService.instance.deleteFile(path);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Imagen eliminada')));
        await _loadImages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error eliminando imagen: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestionar imágenes'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100,
                    child: _images.isEmpty
                        ? const Center(child: Text('No hay imágenes'))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, i) {
                              final img = _images[i];
                              final url = img['url']?.toString() ?? '';
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: url.isNotEmpty
                                        ? Image.network(url,
                                            width: 140,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                    width: 140,
                                                    height: 100,
                                                    color: Colors.grey))
                                        : Container(
                                            width: 140,
                                            height: 100,
                                            color: Colors.grey.shade200),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Material(
                                      color: Colors.black26,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: InkWell(
                                        onTap: () => _removeImage(img),
                                        borderRadius: BorderRadius.circular(20),
                                        child: const Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Icon(Icons.delete,
                                                size: 16, color: Colors.white)),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemCount: _images.length,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                          onPressed: _uploading ? null : _uploadImages,
                          icon: const Icon(Icons.upload_file),
                          label: _uploading
                              ? const Text('Subiendo...')
                              : const Text('Subir imágenes')),
                    ],
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar')),
      ],
    );
  }
}
