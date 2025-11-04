import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/firestore_service.dart';
import '../../services/estacion_service.dart';
import '../../models/estacion.dart';
import '../../services/storage_service.dart';
import '../../utils/colores.dart';
import '../../widgets/pantalla_base.dart';
import '../../widgets/role_protected_widget.dart';

class CrearEstacionCardScreen extends StatefulWidget {
  const CrearEstacionCardScreen({super.key});

  @override
  State<CrearEstacionCardScreen> createState() =>
      _CrearEstacionCardScreenState();
}

class _CrearEstacionCardScreenState extends State<CrearEstacionCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comunaCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<Estacion> _estaciones = [];
  String? _selectedEstacionId;
  final ImagePicker _picker = ImagePicker();
  List<XFile> _pickedImages = [];
  List<Uint8List?> _pickedImagesBytes = [];
  bool _loading = false;

  String _getExt(String name) {
    final idx = name.lastIndexOf('.');
    return idx >= 0 ? name.substring(idx) : '.jpg';
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) {
      return;
    }

    final remaining = 5 - _pickedImages.length;
    if (remaining <= 0) {
      return;
    }
    final toTake = picked.take(remaining).toList();

    if (kIsWeb) {
      final List<Uint8List?> bytesList = [];
      for (final p in toTake) {
        try {
          bytesList.add(await p.readAsBytes());
        } catch (_) {
          bytesList.add(null);
        }
      }
      setState(() {
        _pickedImages = [..._pickedImages, ...toTake];
        _pickedImagesBytes = [..._pickedImagesBytes, ...bytesList];
      });
    } else {
      setState(() {
        _pickedImages = [..._pickedImages, ...toTake];
        _pickedImagesBytes = [
          ..._pickedImagesBytes,
          ...List<Uint8List?>.filled(toTake.length, null)
        ];
      });
    }
  }

  Future<void> _assignCardToEstacion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final name = _nameCtrl.text.trim();
      final placeId = await FirestoreService.instance
          .createPlace(name: name, lat: 0.0, lng: 0.0);

      final comuna = _comunaCtrl.text.trim();
      final descripcion = _descCtrl.text.trim();
      await FirestoreService.instance
          .updatePlacePartial(placeId: placeId, data: {
        'comuna': comuna.isNotEmpty ? comuna : '',
        'descripcion': descripcion,
        'shortDesc': descripcion.isNotEmpty
            ? (descripcion.length > 120
                ? '${descripcion.substring(0, 120)}...'
                : descripcion)
            : '',
        'mejorMomento': '',
        // No duplicar 'description' legacy key; prefer 'descripcion' in the document
      });

      if (_pickedImages.isNotEmpty) {
        final toUpload = _pickedImages.take(5).toList();
        for (var idx = 0; idx < toUpload.length; idx++) {
          final picked = toUpload[idx];
          final ts = DateTime.now().millisecondsSinceEpoch;
          final ext = kIsWeb ? _getExt(picked.name) : _getExt(picked.path);
          final path = 'estaciones/${_selectedEstacionId!}/img_$ts$ext';
          try {
            String url;
            if (kIsWeb &&
                idx < _pickedImagesBytes.length &&
                _pickedImagesBytes[idx] != null) {
              url = await StorageService.instance.uploadBytes(
                  _pickedImagesBytes[idx]!, path,
                  contentType: 'image/jpeg');
            } else {
              final file = File(picked.path);
              url = await StorageService.instance
                  .uploadFile(file, path, contentType: 'image/jpeg');
            }
            final imageObj = {'url': url, 'path': path, 'alt': name};
            await FirestoreService.instance
                .addPlaceImage(placeId: placeId, image: imageObj);
          } catch (e) {
            // ignore errors for single images
            debugPrint('Error subiendo imagen $idx: $e');
            continue;
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estación (card) creada')));
      _nameCtrl.clear();
      _comunaCtrl.clear();
      _descCtrl.clear();
      setState(() {
        _pickedImages = [];
        _pickedImagesBytes = [];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Coloressito.badgeRed));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _comunaCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminProtectedWidget(
      child: PantallaBase(
        titulo: 'Crear Estación (Card)',
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre de la estación (card)'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa un nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comunaCtrl,
                decoration: const InputDecoration(
                    labelText: 'Dirección breve / Comuna'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa la comuna o dirección breve'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Descripción (mostrar en Ver detalles)'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo),
                  label: const Text('Elegir imágenes (card, máx 5)')),
              const SizedBox(height: 6),
              const Text(
                'Selecciona hasta 5 imágenes. En web: Usa Ctrl/Cmd+click o Shift para seleccionar varias.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              if (_pickedImages.isNotEmpty)
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final p = _pickedImages[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb &&
                                    i < _pickedImagesBytes.length &&
                                    _pickedImagesBytes[i] != null
                                ? Image.memory(_pickedImagesBytes[i]!,
                                    width: 240, height: 160, fit: BoxFit.cover)
                                : Image.file(File(p.path),
                                    width: 240, height: 160, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _pickedImages.removeAt(i);
                                  if (i < _pickedImagesBytes.length) {
                                    _pickedImagesBytes.removeAt(i);
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loading ? null : _createPlace,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Crear')),
            ],
          ),
        ),
      ),
    );
  }
}
