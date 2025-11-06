import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../services/coleccion_service.dart';
import '../services/album_photos_service.dart';
import '../models/estacion_visitada.dart';
import '../models/place.dart';
import '../models/user_state.dart';
import '../widgets/simple_insignia_modal.dart';

import '../components/bottom_nav_bar.dart';
import '../widgets/user_profile_header.dart';

/// Album/colección: muestra insignias (badges) y sus fotos asociadas.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

enum AlbumItemType { badge, photo }

class AlbumItem {
  final String id;
  final AlbumItemType type;
  final String title;
  final String? parentId; // si es foto, referencia a la insignia
  final String? imagePath; // asset or file path
  final String? base64; // en web puede guardarse la imagen como base64
  final String? location;
  final DateTime date;
  String? description;

  AlbumItem({
    required this.id,
    required this.type,
    required this.title,
    this.parentId,
    this.imagePath,
    this.base64,
    this.location,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'title': title,
        'parentId': parentId,
        'imagePath': imagePath,
        'base64': base64,
        'location': location,
        'date': date.toIso8601String(),
        'description': description,
      };

  static AlbumItem fromJson(Map<String, dynamic> j) {
    return AlbumItem(
      id: j['id'] ?? UniqueKey().toString(),
      type: j['type'] == 'AlbumItemType.photo'
          ? AlbumItemType.photo
          : AlbumItemType.badge,
      title: j['title'] ?? 'Item',
      parentId: j['parentId'],
      imagePath: j['imagePath'],
      base64: j['base64'],
      location: j['location'],
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      description: j['description'],
    );
  }
}

class _AlbumScreenState extends State<AlbumScreen> {
  final List<AlbumItem> _items = [];
  int _currentIndex = 1; // 0=Inicio,1=Colección,2=Mapa
  late SharedPreferences _prefs;
  final ImagePicker _picker = ImagePicker();
  bool _loading = true;
  Stream<List<EstacionVisitada>>? _visitasStream;
  StreamSubscription<List<EstacionVisitada>>? _visitasSub;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _startVisitasListener();
  }

  Future<void> _loadPhotos() async {
    _prefs = await SharedPreferences.getInstance();

    // Clear existing photos
    _items.removeWhere((item) => item.type == AlbumItemType.photo);

    try {
      // 1. Cargar fotos desde Firebase (nuevo sistema)
      final firebasePhotos = await _loadPhotosFromFirebase();
      _items.addAll(firebasePhotos);

      // 2. Cargar fotos desde SharedPreferences (sistema legacy) solo si no hay fotos en Firebase
      if (firebasePhotos.isEmpty) {
        final legacyPhotos = await _loadPhotosFromSharedPrefs();
        _items.addAll(legacyPhotos);
      }
    } catch (e) {
      // print('Error cargando fotos desde Firebase: $e');

      // Fallback: cargar desde SharedPreferences
      try {
        final legacyPhotos = await _loadPhotosFromSharedPrefs();
        _items.addAll(legacyPhotos);
      } catch (e2) {
        // print('Error cargando fotos desde SharedPrefs: $e2');
      }
    }

    _items.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) setState(() => _loading = false);
  }

  /// Cargar fotos desde Firebase (nuevo sistema)
  Future<List<AlbumItem>> _loadPhotosFromFirebase() async {
    try {
      // Usar AlbumPhotosService para obtener fotos del usuario
      final albumPhotos = await AlbumPhotosService.getUserPhotos();

      return albumPhotos
          .map((photo) => AlbumItem(
                id: photo.id,
                type: AlbumItemType.photo,
                title: 'Experiencia', // Título genérico para fotos
                parentId: photo.badgeId,
                imagePath: photo.imageUrl, // URL de Firebase Storage
                base64: null, // No necesitamos base64 con Firebase
                location: photo.location,
                date: photo.uploadDate,
                description: photo.description,
              ))
          .toList();
    } catch (e) {
      // print('Error obteniendo fotos de Firebase: $e');
      rethrow;
    }
  }

  /// Cargar fotos desde SharedPreferences (sistema legacy)
  Future<List<AlbumItem>> _loadPhotosFromSharedPrefs() async {
    final raw = _prefs.getStringList('album_items') ?? [];
    final photos = <AlbumItem>[];

    for (final s in raw) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final it = AlbumItem.fromJson(m);
        if (it.type == AlbumItemType.photo) {
          photos.add(it);
        }
      } catch (e) {
        print('Error parsing legacy photo: $e');
      }
    }

    return photos;
  }

  /// Recargar solo las fotos desde Firebase y actualizar la UI
  Future<void> _reloadPhotosFromFirebase() async {
    try {
      // Remover fotos existentes
      _items.removeWhere((item) => item.type == AlbumItemType.photo);

      // Cargar fotos desde Firebase
      final firebasePhotos = await _loadPhotosFromFirebase();
      _items.addAll(firebasePhotos);

      // Reordenar por fecha
      _items.sort((a, b) => b.date.compareTo(a.date));

      // Actualizar UI
      if (mounted) setState(() {});
    } catch (e) {
      print('Error recargando fotos desde Firebase: $e');
    }
  }

  void _startVisitasListener() {
    _visitasStream = ColeccionService.watchEstacionesVisitadas();
    _visitasSub = _visitasStream?.listen((visitas) async {
      // Convertir visitas a AlbumItem badges
      final badges = visitas.map((ev) {
        return AlbumItem(
          id: ev.id,
          type: AlbumItemType.badge,
          title: ev.estacionNombre.isNotEmpty
              ? ev.estacionNombre
              : ev.estacionCodigo,
          parentId: null,
          imagePath: ev.badgeImage?.url, // Usar la URL de la insignia
          location: (ev.latitudVisita != null && ev.longitudVisita != null)
              ? '${ev.latitudVisita}, ${ev.longitudVisita}'
              : null,
          date: ev.fechaVisita,
        );
      }).toList();

      // Remove existing badge items and re-add from stream (keep photos)
      _items
        ..removeWhere((e) => e.type == AlbumItemType.badge)
        ..addAll(badges);

      _items.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) setState(() {});
    }, onError: (_) {
      // Ignorar errores temporales en el stream
    });
  }

  Future<void> _saveItems() async {
    // Persistir únicamente las fotos (las badges se obtienen desde Firestore)
    final photos = _items
        .where((e) => e.type == AlbumItemType.photo)
        .map((e) => jsonEncode(e.toJson()))
        .toList();
    await _prefs.setStringList('album_items', photos);
  }

  int _totalPhotosCount() =>
      _items.where((e) => e.type == AlbumItemType.photo).length;

  Future<void> _addPhotoFor(String parentId) async {
    try {
      // Verificar límite con Firebase
      final hasReachedLimit =
          await AlbumPhotosService.hasReachedPhotoLimit(maxPhotos: 50);
      if (hasReachedLimit) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Has alcanzado el límite de 50 fotos de experiencia')));
        return;
      }

      // Seleccionar imagen
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (file == null) return;

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
                Text('Subiendo imagen...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Subir foto a Firebase
      await AlbumPhotosService.uploadPhoto(
        imageFile: file,
        badgeId: parentId,
        description: null, // El usuario puede agregar descripción después
        metadata: {
          'source': 'user_gallery',
          'originalName': file.name,
          'addedFrom': 'album_screen',
        },
      );

      // Recargar fotos desde Firebase para mostrar la nueva foto
      await _reloadPhotosFromFirebase();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Imagen agregada exitosamente'),
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

  void _openDetail(AlbumItem item) async {
    final edited = await showModalBottomSheet<AlbumItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final TextEditingController descCtrl =
            TextEditingController(text: item.description ?? '');
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(item.title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildItemImage(item, width: 240, height: 160),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      'Fecha: ${item.date.toLocal().toString().split('.').first}'),
                  if (item.location != null)
                    Text('Ubicación: ${item.location}'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Descripción personal'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón de eliminar solo para fotos del usuario
                      if (item.type == AlbumItemType.photo)
                        TextButton.icon(
                          onPressed: () =>
                              _showDeleteConfirmation(context, item),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Eliminar',
                              style: TextStyle(color: Colors.red)),
                        )
                      else
                        const SizedBox(), // Espacio vacío si no es foto
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              item.description = descCtrl.text.trim();
                              Navigator.pop(context, item);
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (edited != null) {
      // Actualizar Firebase si la foto proviene de Firebase
      try {
        await AlbumPhotosService.updatePhotoDescription(
            edited.id, edited.description);
        print('✅ Descripción actualizada en Firebase para foto ${edited.id}');
      } catch (e) {
        print('❌ Error actualizando descripción en Firebase: $e');
      }

      // Actualizar lista local y SharedPreferences (para compatibilidad)
      final idx = _items.indexWhere((e) => e.id == edited.id);
      if (idx != -1) {
        setState(() => _items[idx] = edited);
        await _saveItems();
      }
    }
  }

  void _showPhotoOptionsOverlay(BuildContext context, AlbumItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Imagen de fondo
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildItemImage(item, width: 300, height: 300),
                ),
              ),
              // Overlay con opciones
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha((0.7 * 255).round()),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withAlpha((0.7 * 255).round()),
                    ],
                  ),
                ),
                child: Container(
                  width: 300,
                  height: 300,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón cerrar
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 28),
                        ),
                      ),
                      // Botones Ver y Editar
                      Row(
                        children: [
                          // Botón Ver (mitad izquierda)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                _showPhotoViewer(context, item);
                              },
                              child: Container(
                                height: 60,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue
                                      .withAlpha((0.8 * 255).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Ver',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Botón Editar (mitad derecha)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(dialogContext).pop();
                                _openDetail(item);
                              },
                              child: Container(
                                height: 60,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange
                                      .withAlpha((0.8 * 255).round()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Editar',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhotoViewer(BuildContext context, AlbumItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext dialogContext) {
        return GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                // Contenido principal centrado
                Center(
                  child: SingleChildScrollView(
                    child: GestureDetector(
                      onTap:
                          () {}, // Prevenir que se cierre cuando se toca la imagen/descripción
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Imagen grande
                          Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.98,
                              maxHeight: item.description != null &&
                                      item.description!.isNotEmpty
                                  ? MediaQuery.of(context).size.height * 0.75
                                  : MediaQuery.of(context).size.height * 0.90,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.5 * 255).round()),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildItemImage(item),
                            ),
                          ),
                          // Descripción solo si existe
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 35),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(0xFFFAF9F6)
                                        .withAlpha((0.98 * 255).round()),
                                    const Color(0xFFF5F5DC)
                                        .withAlpha((0.95 * 255).round()),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFD4C5A9)
                                      .withAlpha((0.3 * 255).round()),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8B4513)
                                        .withAlpha((0.08 * 255).round()),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha((0.03 * 255).round()),
                                    blurRadius: 25,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Text(
                                item.description!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFF2C3E50),
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                  fontFamily: 'serif',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, AlbumItem item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar imagen'),
          content: const Text(
              '¿Estás seguro de que quieres eliminar esta imagen? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
                Navigator.of(context).pop(); // Cerrar el modal de la imagen
                await _deletePhoto(item);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePhoto(AlbumItem item) async {
    if (item.type != AlbumItemType.photo) return;

    try {
      // Detectar si es una foto de Firebase (URL de Firebase Storage)
      if (item.imagePath != null &&
          item.imagePath!.startsWith('http') &&
          item.imagePath!.contains('firebasestorage.googleapis.com')) {
        // Eliminar desde Firebase
        await AlbumPhotosService.deletePhoto(item.id);
      } else {
        // Eliminar archivo local (fotos antiguas)
        if (!kIsWeb &&
            item.imagePath != null &&
            !item.imagePath!.startsWith('http')) {
          try {
            final file = File(item.imagePath!);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            print('Error eliminando archivo local: $e');
          }
        }
      }

      // Remover de la lista local y guardar
      setState(() {
        _items.removeWhere((e) => e.id == item.id);
      });

      await _saveItems();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📷 Imagen eliminada del álbum'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error eliminando imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildItemImage(AlbumItem item, {double? width, double? height}) {
    if (item.type == AlbumItemType.photo) {
      // Primero intentar mostrar desde Firebase (URL)
      if (item.imagePath != null && item.imagePath!.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.imagePath!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        );
      }

      // Fallback: mostrar desde base64 (fotos antiguas)
      if (item.base64 != null && item.base64!.isNotEmpty) {
        try {
          final bytes = base64Decode(item.base64!);
          return Image.memory(bytes,
              width: width, height: height, fit: BoxFit.cover);
        } catch (_) {}
      }

      // Fallback: mostrar desde archivo local (fotos muy antiguas)
      if (item.imagePath != null && !item.imagePath!.startsWith('http')) {
        final f = File(item.imagePath!);
        if (f.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child:
                Image.file(f, width: width, height: height, fit: BoxFit.cover),
          );
        }
      }
    }

    // Para badges/insignias
    if (item.type == AlbumItemType.badge &&
        item.imagePath != null &&
        item.imagePath!.isNotEmpty) {
      // Si la insignia tiene una imagen, mostrarla
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item.imagePath!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Si falla la carga de la imagen, mostrar el ícono por defecto
            return _buildDefaultBadgeIcon(width: width, height: height);
          },
        ),
      );
    }

    // Insignia sin imagen o fallback
    return _buildDefaultBadgeIcon(width: width, height: height);
  }

  Widget _buildDefaultBadgeIcon({double? width, double? height}) {
    return Container(
      width: width ?? 120,
      height: height ?? 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700)
                .withAlpha((0.3 * 255).round()), // Dorado suave
            const Color(0xFFFFA500)
                .withAlpha((0.5 * 255).round()), // Naranja suave
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events, // Trofeo/copa para insignias
              size: (width ?? 120) * 0.4,
              color: const Color(0xFFB8860B), // Dorado oscuro
            ),
            if ((width ?? 120) > 60) // Solo mostrar texto si hay espacio
              Text(
                'Insignia',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB8860B),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onNavChanged(int idx) {
    if (idx == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (idx == 2) {
      Navigator.pushNamed(context, '/menu');
    } else {
      setState(() => _currentIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header colapsable
          SliverAppBar(
            expandedHeight: 280, // Altura ajustada al contenido real del header
            pinned: false, // No se queda fijo arriba
            floating: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false, // Elimina la flecha de volver
            flexibleSpace: FlexibleSpaceBar(
              background: const UserProfileHeader(),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          
          // Contador de insignias fijo
          SliverPersistentHeader(
            pinned: true, // Se queda fijo al hacer scroll
            delegate: _InsigniasCounterDelegate(),
          ),
          
          // Contenido principal
          _loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _items.where((e) => e.type == AlbumItemType.badge).isEmpty
                  ? SliverFillRemaining(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        child: _buildEmptyStateNoBadges(theme),
                      ),
                    )
                  : _buildPremiumBadgesListSliver(context),
        ],
      ),
      bottomNavigationBar:
          BottomNavBar(currentIndex: _currentIndex, onChanged: _onNavChanged),
    );
  }

  Widget _buildEmptyStateNoBadges(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
              ],
            ),
            child: const Icon(Icons.photo_album, size: 56, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text('Aún no has desbloqueado insignias',
              style:
                  theme.textTheme.titleMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 8),
          const Text(
            'Escanea códigos QR en las estaciones para desbloquear insignias.\nMientras no tengas insignias, no podrás agregar fotos al álbum.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBadgesListSliver(BuildContext context) {
    final badges = _items.where((e) => e.type == AlbumItemType.badge).toList();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) {
              return const SizedBox(height: 16); // Separador
            }
            
            final badgeIndex = index ~/ 2;
            final badge = badges[badgeIndex];
            final photos = _items
                .where((i) =>
                    i.type == AlbumItemType.photo && i.parentId == badge.id)
                .toList();
            final canAdd = _totalPhotosCount() < 10;

            return _PremiumBadgeCard(
              badge: badge,
              photos: photos,
              canAdd: canAdd,
              onTapInsignia: () => _openInsigniaModal(badge),
              onAddPhoto: () => _addPhotoFor(badge.id),
              onTapPhoto: (photo) => _showPhotoOptionsOverlay(context, photo),
              buildItemImage: _buildItemImage,
            );
          },
          childCount: badges.length * 2 - 1, // badges + separadores
        ),
      ),
    );
  }

  Widget _buildPremiumBadgesList(BuildContext context) {
    final badges = _items.where((e) => e.type == AlbumItemType.badge).toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), // Igual que Home
      itemCount: badges.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 16), // Espaciado más consistente
      itemBuilder: (context, index) {
        final badge = badges[index];
        final photos = _items
            .where(
                (i) => i.type == AlbumItemType.photo && i.parentId == badge.id)
            .toList();
        final canAdd = _totalPhotosCount() < 10;

        return _PremiumBadgeCard(
          badge: badge,
          photos: photos,
          canAdd: canAdd,
          onTapInsignia: () => _openInsigniaModal(badge),
          onAddPhoto: () => _addPhotoFor(badge.id),
          onTapPhoto: (photo) => _showPhotoOptionsOverlay(context, photo),
          buildItemImage: _buildItemImage,
        );
      },
    );
  }

  /// Abre el modal épico de insignia con animaciones
  void _openInsigniaModal(AlbumItem badge) {
    // Crear EstacionVisitada temporal para el modal
    final estacionVisitada = EstacionVisitada(
      id: badge.id,
      estacionId: badge.id,
      estacionCodigo: 'QR_${badge.id}',
      estacionNombre: badge.title,
      fechaVisita: badge.date,
      badgeImage: badge.imagePath != null
          ? PlaceImage(url: badge.imagePath, alt: badge.title)
          : null,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SimpleInsigniaModal(estacion: estacionVisitada),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    try {
      _visitasSub?.cancel();
    } catch (_) {}
    super.dispose();
  }
}

// Widget premium para las cards de insignias con efectos especiales
class _PremiumBadgeCard extends StatefulWidget {
  final AlbumItem badge;
  final List<AlbumItem> photos;
  final bool canAdd;
  final VoidCallback onTapInsignia;
  final VoidCallback onAddPhoto;
  final Function(AlbumItem) onTapPhoto;
  final Widget Function(AlbumItem,
      {required double width, required double height}) buildItemImage;

  const _PremiumBadgeCard({
    required this.badge,
    required this.photos,
    required this.canAdd,
    required this.onTapInsignia,
    required this.onAddPhoto,
    required this.onTapPhoto,
    required this.buildItemImage,
  });

  @override
  State<_PremiumBadgeCard> createState() => _PremiumBadgeCardState();
}

class _PremiumBadgeCardState extends State<_PremiumBadgeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: 8, end: 20).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // Fondo blanco limpio
                color: Colors.white,
                // Sombras profundas para sensación de profundidad
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.15 * 255).round()),
                    blurRadius: _elevationAnimation.value,
                    spreadRadius: _elevationAnimation.value * 0.3,
                    offset: Offset(0, _elevationAnimation.value * 0.5),
                  ),
                ],
                // Bordes marrones claros sutiles
                border: Border.all(
                  color: _isHovered
                      ? const Color(0xFFD2B48C) // Tan claro
                      : const Color(0xFFDDD0C0)
                          .withAlpha((0.8 * 255).round()), // Beige muy sutil
                  width: _isHovered ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  // Textura sutil de papel
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withAlpha((0.1 * 255).round()),
                        Colors.transparent,
                        Colors.black.withAlpha((0.02 * 255).round()),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila superior con insignia y título
                        Row(
                          children: [
                            // Insignia completamente sin contenedor visible
                            GestureDetector(
                              onTap: widget.onTapInsignia,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: widget.buildItemImage(widget.badge,
                                    width: 90, height: 90),
                              ),
                            ),

                            const SizedBox(width: 20),

                            // Título con tipografía elegante
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.badge.title,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4A4A4A),
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withAlpha((0.1 * 255).round()),
                                          blurRadius: 2,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Botón de agregar foto simple
                            if (widget.canAdd)
                              IconButton(
                                onPressed: widget.onAddPhoto,
                                icon: const Icon(
                                  Icons.photo_library,
                                  size: 28,
                                  color: Color(0xFF87CEEB), // Azul celeste
                                ),
                                tooltip: 'Agregar foto desde galería',
                              ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Galería de fotos que llega casi al límite del card
                        Container(
                          height: 180,
                          width:
                              double.infinity, // Ocupa todo el ancho disponible
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.5 * 255).round()),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          child: widget.photos.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.photo_library_outlined,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Agrega tus experiencias fotográficas',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: widget.photos.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, i) {
                                    final photo = widget.photos[i];
                                    return GestureDetector(
                                      onTap: () => widget.onTapPhoto(photo),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 220,
                                          height: 160,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(
                                                    (0.1 * 255).round()),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: widget.buildItemImage(photo,
                                              width: 220, height: 160),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Delegate para el contador de insignias fijo
class _InsigniasCounterDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 56.0; // Altura mínima cuando está colapsado
  
  @override
  double get maxExtent => 56.0; // Altura máxima (igual que mínima porque no cambia)

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Consumer<UserState>(
      builder: (context, userState, _) {
        return FutureBuilder<int>(
          future: userState.getInsigniasCount(),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            
            return Container(
              color: Colors.white,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: Colors.amber[600],
                            size: 28,
                            shadows: [
                              Shadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              count == 1 ? 'Insignia obtenida' : 'Insignias obtenidas',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  bool shouldRebuild(_InsigniasCounterDelegate oldDelegate) => true;
}
