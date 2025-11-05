import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/album_photos_service.dart';
import '../models/album_photo.dart';

/// Widget de ejemplo que muestra cómo usar AlbumPhotosService
/// Puedes usar este código como referencia para integrar con el álbum existente
class AlbumPhotosExample extends StatefulWidget {
  final String badgeId; // ID de la insignia para asociar la foto

  const AlbumPhotosExample({
    super.key,
    required this.badgeId,
  });

  @override
  State<AlbumPhotosExample> createState() => _AlbumPhotosExampleState();
}

class _AlbumPhotosExampleState extends State<AlbumPhotosExample> {
  final ImagePicker _picker = ImagePicker();
  List<AlbumPhoto> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final photos = await AlbumPhotosService.getUserPhotos();
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando fotos: $e')),
        );
      }
    }
  }

  Future<void> _addPhoto() async {
    try {
      // Verificar límite de fotos
      final hasReachedLimit =
          await AlbumPhotosService.hasReachedPhotoLimit(maxPhotos: 50);
      if (hasReachedLimit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Has alcanzado el límite de 50 fotos')),
          );
        }
        return;
      }

      // Seleccionar imagen
      final XFile? imageFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (imageFile == null) return;

      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 16),
                Text('Subiendo foto...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Subir foto a Firebase
      final albumPhoto = await AlbumPhotosService.uploadPhoto(
        imageFile: imageFile,
        badgeId: widget.badgeId,
        description: null, // El usuario puede agregar descripción después
        location: null, // Puedes obtener ubicación actual si es necesario
        metadata: {
          'source': 'user_gallery',
          'originalName': imageFile.name,
        },
      );

      // Actualizar lista local
      setState(() {
        _photos.insert(0, albumPhoto);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Foto agregada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error subiendo foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editPhotoDescription(AlbumPhoto photo) async {
    final controller = TextEditingController(text: photo.description ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descripción de la experiencia'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe tu experiencia en este lugar...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await AlbumPhotosService.updatePhotoDescription(
            photo.id, result.isEmpty ? null : result);

        // Actualizar lista local
        setState(() {
          final index = _photos.indexWhere((p) => p.id == photo.id);
          if (index != -1) {
            _photos[index] =
                photo.copyWith(description: result.isEmpty ? null : result);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Descripción actualizada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error actualizando descripción: $e')),
          );
        }
      }
    }
  }

  Future<void> _deletePhoto(AlbumPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar esta foto? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AlbumPhotosService.deletePhoto(photo.id);

        // Remover de lista local
        setState(() {
          _photos.removeWhere((p) => p.id == photo.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto eliminada'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error eliminando foto: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Fotos de Experiencia'),
        actions: [
          IconButton(
            onPressed: _addPhoto,
            icon: const Icon(Icons.add_a_photo),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No tienes fotos aún',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text(
                          'Toca + para agregar tu primera foto de experiencia'),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return GestureDetector(
                      onTap: () => _editPhotoDescription(photo),
                      onLongPress: () => _deletePhoto(photo),
                      child: Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                                child: Image.network(
                                  photo.imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error);
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    photo.description?.isNotEmpty == true
                                        ? photo.description!
                                        : 'Sin descripción',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          photo.description?.isNotEmpty == true
                                              ? null
                                              : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${photo.uploadDate.day}/${photo.uploadDate.month}/${photo.uploadDate.year}',
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
